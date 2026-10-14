from __future__ import annotations

import asyncio
import json
import uuid

import httpx

from .config import Settings


class LLMError(RuntimeError):
    def __init__(self, message: str, status: int | None = None):
        super().__init__(message)
        self.status = status


class ContextOverflowError(LLMError):
    pass


THINKING_LEVELS = ("low", "medium", "xhigh")


def thinking_params(level: str) -> dict:
    level = (level or "low").lower()
    if level in THINKING_LEVELS:
        return {"enable_thinking": True, "reasoning_effort": level}
    return {"enable_thinking": False}


def build_request(history: list[dict], s: Settings,
                  tools: list[dict] | None = None,
                  thinking: str = "low") -> dict:
    req: dict = {
        "model": s.model,
        "stream": True,
        "stream_options": {"include_usage": True},
        "max_tokens": s.max_output_tokens,
        "messages": history,
        **thinking_params(thinking),
    }
    if s.temperature is not None:
        req["temperature"] = s.temperature
    if s.top_p is not None:
        req["top_p"] = s.top_p
    if tools:
        req["tools"] = tools
    return req


def _error_from(chunk: dict, status: int | None) -> LLMError | None:
    err = chunk.get("error")
    if not err:
        return None
    msg = err.get("message", str(err)) if isinstance(err, dict) else str(err)
    low = msg.lower()
    if "context" in low or "too long" in low or "exceed" in low:
        return ContextOverflowError(msg, status)
    return LLMError(msg, status)


class LLMClient:
    """mtplx refuses a request for a session still held by a generation
    that has not registered our disconnect as a cancel (HTTP 409); the
    engine picks the cancel up within ~30 s, so retry with backoff."""

    BUSY_STATUS = 409

    def __init__(self, s: Settings, session_id: str | None = None):
        self.s = s
        self.session_id = session_id or uuid.uuid4().hex
        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(600.0, connect=10.0))

    @property
    def url(self) -> str:
        return self.s.base_url.rstrip("/") + "/v1/chat/completions"

    @property
    def headers(self) -> dict:
        return {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.s.api_key}",
            "x-mtplx-client": self.s.client_header,
            "x-mtplx-session-id": self.session_id,
        }

    def new_session_id(self) -> str:
        self.session_id = uuid.uuid4().hex
        return self.session_id

    async def close(self) -> None:
        await self._client.aclose()

    async def stream(self, request: dict):
        """Yields {"kind": "text"|"tool"|"finish", ...} events."""
        async with self._client.stream("POST", self.url, json=request,
                                       headers=self.headers) as resp:
            if resp.status_code != 200:
                body = (await resp.aread()).decode("utf-8", "replace")
                try:
                    data = json.loads(body)
                    err = _error_from(data, resp.status_code)
                except json.JSONDecodeError:
                    err = None
                raise (err or LLMError(body[:500], resp.status_code))
            async for line in resp.aiter_lines():
                if not line or not line.startswith("data:"):
                    continue
                payload = line[5:].strip()
                if payload == "[DONE]":
                    break
                try:
                    chunk = json.loads(payload)
                except json.JSONDecodeError:
                    continue
                err = _error_from(chunk, resp.status_code)
                if err:
                    raise err
                if chunk.get("usage") is not None:
                    yield {"kind": "finish", "reason": None,
                           "usage": chunk["usage"]}
                for choice in chunk.get("choices") or []:
                    delta = choice.get("delta") or {}
                    c = delta.get("reasoning_content")
                    if c:
                        yield {"kind": "reasoning", "text": c}
                    c = delta.get("content")
                    if c:
                        yield {"kind": "text", "text": c}
                    for tc in delta.get("tool_calls") or []:
                        fn = tc.get("function") or {}
                        yield {"kind": "tool",
                               "index": tc.get("index", 0),
                               "id": tc.get("id"),
                               "name": fn.get("name"),
                               "arguments": fn.get("arguments")}
                    if choice.get("finish_reason"):
                        yield {"kind": "finish",
                               "reason": choice["finish_reason"], "usage": None}

    async def stream_with_retry(self, request: dict, retries: int = 10):
        for attempt in range(max(retries, 1)):
            try:
                async for ev in self.stream(request):
                    yield ev
                return
            except LLMError as e:
                if e.status == self.BUSY_STATUS and attempt < retries - 1:
                    await asyncio.sleep(3.0)
                    continue
                raise

    async def complete(self, messages: list[dict], max_tokens: int = 3000,
                       retries: int = 10) -> str:
        for attempt in range(max(retries, 1)):
            try:
                req = {"model": self.s.model, "stream": False,
                       "max_tokens": max_tokens,
                       "enable_thinking": False, "messages": messages}
                if self.s.temperature is not None:
                    req["temperature"] = self.s.temperature
                resp = await self._client.post(self.url, json=req,
                                               headers=self.headers)
                if resp.status_code != 200:
                    body = resp.text
                    try:
                        err = _error_from(json.loads(body), resp.status_code)
                    except json.JSONDecodeError:
                        err = None
                    err = err or LLMError(body[:500], resp.status_code)
                else:
                    data = resp.json()
                    return ((data.get("choices") or [{}])[0]
                            .get("message", {}).get("content") or "")
            except httpx.HTTPError as e:
                err = LLMError(str(e)[:500])
            if err.status == self.BUSY_STATUS and attempt < retries - 1:
                await asyncio.sleep(3.0)
                continue
            if isinstance(err, ContextOverflowError):
                raise
            raise err
        raise RuntimeError("unreachable")

    async def wait_healthy(self, timeout: float = 420.0) -> None:
        """Block until the server answers /health (restart scenario)."""
        import time
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try:
                resp = await self._client.get(self.s.base_url.rstrip("/")
                                              + "/health")
                if resp.status_code == 200:
                    return
            except httpx.HTTPError:
                pass
            await asyncio.sleep(5.0)
        raise LLMError("server not healthy after wait")
