"""Edge agent: K persistent outbound TCP streams to the VPS gateway.

Frames between edge and gateway (1 type byte + 4-byte BE length + payload):
gateway -> edge: 0x01 client data, 0x02 client write-EOF, 0x03 client gone
edge -> gateway: 0x10 local data, 0x11 local write-EOF, 0x12 local closed

Each frame stream carries at most one session at a time; a session pipes
the remote gRPC client to the local server (127.0.0.1:46000).
"""
from __future__ import annotations

import asyncio
import os
import secrets
import socket
import struct
import sys

from .config import EDGE_K, env, get_credentials

VPS_HOST = os.environ.get("IQ_TASK_VPS_HOST", "46.225.143.221")
VPS_PORT = int(os.environ.get("IQ_TASK_VPS_PORT", "46000"))
LOCAL_HOST = "127.0.0.1"
LOCAL_PORT = int(os.environ.get("IQ_TASK_LOCAL_PORT", "46000"))

HELLO_MAGIC = b"IQEDGE\x00"

F_DATA_FROM_GW, F_CLIENT_EOF, F_CLIENT_GONE = 0x01, 0x02, 0x03
F_DATA_TO_GW, F_LOCAL_EOF, F_LOCAL_CLOSED = 0x10, 0x11, 0x12

CHUNK = 65536
DEBUG = bool(os.environ.get("IQ_DEBUG"))


def log(*a):
    if DEBUG:
        print("[edge]", *a, flush=True)


class Edge:
    def __init__(self, reader: asyncio.StreamReader,
                 writer: asyncio.StreamWriter):
        self.reader = reader
        self.writer = writer
        self.busy = False
        self.dead = False
        self.q: asyncio.Queue = asyncio.Queue()
        self._local: asyncio.StreamWriter | None = None
        self._tasks: list[asyncio.Task] = []

    async def read_frame(self) -> tuple[int, bytes]:
        t = await self.reader.readexactly(1)
        (length,) = struct.unpack(">I", await self.reader.readexactly(4))
        payload = await self.reader.readexactly(length) if length else b""
        return t[0], payload

    def send(self, frame_type: int, payload: bytes = b"") -> None:
        self.writer.write(struct.pack(">BI", frame_type, len(payload)))
        self.writer.write(payload)

    async def close(self) -> None:
        for t in self._tasks:
            t.cancel()
        try:
            self.writer.close()
            await self.writer.wait_closed()
        except Exception:
            pass
        if self._local is not None:
            self._local.close()
        self.dead = True
        await self.q.put((99, b""))


async def dial(token: str) -> Edge | None:
    try:
        reader, writer = await asyncio.wait_for(
            asyncio.open_connection(VPS_HOST, VPS_PORT), timeout=15)
    except OSError:
        return None
    writer.write(HELLO_MAGIC + token.encode() + b"\n")
    await writer.drain()
    ack = await reader.read(4)
    if ack != b"OK\n":
        writer.close()
        return None
    return Edge(reader, writer)


async def edge_reader(edge: Edge) -> None:
    while True:
        try:
            t, payload = await edge.read_frame()
        except (asyncio.IncompleteReadError, ConnectionError,
                asyncio.CancelledError):
            break
        await edge.q.put((t, payload))
    if not edge.dead:
        edge.dead = True
        await edge.q.put((99, b""))


async def edge_loop(edge: Edge) -> None:
    asyncio.create_task(edge_reader(edge))


async def run_session(edge: Edge, first: tuple[int, bytes]) -> None:
    try:
        local_reader, edge._local = await asyncio.wait_for(
            asyncio.open_connection(LOCAL_HOST, LOCAL_PORT), timeout=10)
    except (OSError, asyncio.TimeoutError):
        edge.send(F_CLIENT_GONE)
        edge.busy = False
        return
    local = edge._local

    local_write_open = True
    local_read_open = True

    pending = [first]

    async def gw_to_local():
        nonlocal local_write_open
        while True:
            if pending:
                t, payload = pending.pop(0)
            else:
                t, payload = await edge.q.get()
            if t == 99:
                return
            if t == F_DATA_FROM_GW:
                if not local_write_open:
                    continue
                try:
                    local.write(payload)
                    await local.drain()
                    log("local<- %d bytes" % len(payload))
                except (ConnectionError, RuntimeError):
                    log("local write FAIL")
                    return
            elif t == F_CLIENT_EOF:
                try:
                    local.close_write()
                    local_write_open = False
                except Exception:
                    return
            elif t == F_CLIENT_GONE:
                return

    async def local_to_gw():
        nonlocal local_read_open
        while local_read_open:
            try:
                chunk = await local_reader.read(CHUNK)
            except (ConnectionError, RuntimeError):
                chunk = b""
            if not chunk:
                log("LOCAL EOF (server closed connection)")
                local_read_open = False
                if not edge.dead:
                    edge.send(F_LOCAL_EOF)
                await asyncio.sleep(0.2)
                continue
            if edge.dead:
                return
            edge.send(F_DATA_TO_GW, chunk)
        if not edge.dead:
            edge.send(F_LOCAL_CLOSED)

    t1 = asyncio.create_task(gw_to_local())
    t2 = asyncio.create_task(local_to_gw())
    done, pending = await asyncio.wait({t1, t2},
                                       return_when=asyncio.FIRST_COMPLETED)
    for t in pending:
        t.cancel()
    local.close()
    if not edge.dead:
        edge.busy = False


async def edge_main_loop(edge: Edge) -> None:
    while not edge.dead:
        t, payload = await edge.q.get()
        if t == 99:
            break
        if edge.busy:
            log("requeue(busy) 0x%02x %d" % (t, len(payload)))
            await edge.q.put((t, payload))
            continue
        if t == F_CLIENT_GONE:
            continue
        edge.busy = True
        await run_session(edge, (t, payload))


async def connect_slot(slot: int, token: str,
                       edges: list[Edge | None]) -> None:
    while True:
        e = await dial(token)
        if e is not None:
            edges[slot] = e
            await edge_loop(e)
            asyncio.create_task(edge_main_loop(e))
            return
        await asyncio.sleep(min(30.0, 1.0 * (2 ** min(slot, 4))))


async def main() -> None:
    token = get_credentials()[2]
    if not token:
        print("IQ_TASK_EDGE_TOKEN is empty (~/work/.env)", file=sys.stderr)
        sys.exit(1)
    edges: list[Edge | None] = [None] * EDGE_K
    for slot in range(EDGE_K):
        asyncio.create_task(connect_slot(slot, token, edges))
    print(f"iq-task edge: K={EDGE_K} -> {VPS_HOST}:{VPS_PORT}")
    while True:
        await asyncio.sleep(3600)


if __name__ == "__main__":
    asyncio.run(main())
