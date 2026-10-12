"""VPS TCP gateway: bridges clients to edge agents.

Stdlib only (runs on VPS python3.10 under pm2). One listen port; connections
are distinguished by the first bytes: edge agents send the IQEDGE\x00 hello,
everything else is a gRPC (TLS) client bridged to a free edge stream.

The gateway is a dumb byte pipe: it holds no secrets and never decrypts
the client TLS — authentication happens client<->Mac (pinned cert + token).

Frame layout mirrors iq_task/edge.py:
gateway -> edge: 0x01 client data, 0x02 client write-EOF, 0x03 client gone
edge -> gateway: 0x10 local data, 0x11 local write-EOF, 0x12 local closed
"""
import asyncio
import logging
import os
import struct
import sys

DEBUG = bool(os.environ.get("IQ_DEBUG"))
logging.basicConfig(level=logging.DEBUG if DEBUG else logging.INFO,
                    format="%(asctime)s %(levelname)s %(message)s",
                    stream=sys.stderr)
log = logging.getLogger("gw")

HOST = os.environ.get("IQ_TASK_GW_HOST", "0.0.0.0")
PORT = int(os.environ.get("IQ_TASK_GW_PORT", "46001"))
CLIENT_WAIT_TIMEOUT = 120

HELLO_MAGIC = b"IQEDGE\x00"

F_DATA_FROM_GW, F_CLIENT_EOF, F_CLIENT_GONE = 0x01, 0x02, 0x03
F_DATA_TO_GW, F_LOCAL_EOF, F_LOCAL_CLOSED = 0x10, 0x11, 0x12

CHUNK = 65536


class Edge:
    def __init__(self, reader, writer):
        self.reader = reader
        self.writer = writer
        self.busy = False
        self.dead = False
        self.q = asyncio.Queue()

    async def read_frame(self):
        t = await self.reader.readexactly(1)
        (length,) = struct.unpack(">I", await self.reader.readexactly(4))
        payload = await self.reader.readexactly(length) if length else b""
        return t[0], payload

    def send(self, frame_type, payload=b""):
        self.writer.write(struct.pack(">BI", frame_type, len(payload)))
        self.writer.write(payload)

    async def close(self):
        self.dead = True
        try:
            self.writer.close()
            await self.writer.wait_closed()
        except Exception:
            pass


class Gateway:
    def __init__(self):
        self.free = asyncio.Event()
        self.free.clear()
        self.edges: list[Edge] = []

    def add(self, edge):
        self.edges.append(edge)
        self.free.set()

    async def acquire(self):
        while True:
            for e in self.edges:
                if not e.busy and not e.dead:
                    e.busy = True
                    self.free.clear()
                    return e
            self.free.clear()
            try:
                await asyncio.wait_for(self.free.wait(),
                                       timeout=CLIENT_WAIT_TIMEOUT)
            except asyncio.TimeoutError:
                return None

    def release(self, edge):
        edge.busy = False
        self.free.set()


async def edge_reader(gw: Gateway, edge: Edge):
    while True:
        try:
            t, payload = await edge.read_frame()
        except (asyncio.IncompleteReadError, ConnectionError, OSError):
            break
        if DEBUG:
            log.debug("edge-frame 0x%02x len=%d", t, len(payload))
        await edge.q.put((t, payload))
    if not edge.dead:
        edge.dead = True
        log.info("edge socket died")
        await edge.q.put((99, b""))
        try:
            gw.edges.remove(edge)
        except ValueError:
            pass
        if not edge.busy:
            gw.free.set()
        await edge.close()


async def register_edge(gw: Gateway, reader, writer, head: bytes):
    try:
        rest = await asyncio.wait_for(reader.readuntil(b"\n"), timeout=15)
    except (asyncio.IncompleteReadError, asyncio.TimeoutError, ValueError):
        writer.write(b"ERR\n")
        writer.close()
        return
    line = head + rest
    if len(line) > 8192 or not line.startswith(HELLO_MAGIC):
        writer.write(b"ERR\n")
        writer.close()
        return
    writer.write(b"OK\n")
    await writer.drain()
    edge = Edge(reader, writer)
    gw.add(edge)
    log.info("edge registered (total %d)", len(gw.edges))
    asyncio.create_task(edge_reader(gw, edge))


async def handle_client(gw: Gateway, reader, writer, first: bytes):
    edge = await gw.acquire()
    if edge is None:
        log.warning("client rejected: no free edge")
        writer.close()
        return
    client_read_open = True
    pending = first
    log.info("client attached -> edge (first %d bytes)", len(first))

    async def client_to_edge():
        nonlocal client_read_open, pending
        while True:
            if pending:
                chunk, pending = pending, b""
            else:
                try:
                    chunk = await reader.read(CHUNK)
                except (ConnectionError, OSError):
                    chunk = b""
            if not chunk:
                client_read_open = False
                if DEBUG:
                    log.debug("client reader EOF")
                if not edge.dead:
                    edge.send(F_CLIENT_EOF)
                    edge.send(F_CLIENT_GONE)
                return
            if edge.dead:
                return
            if DEBUG:
                log.debug("client->edge %d bytes", len(chunk))
            edge.send(F_DATA_FROM_GW, chunk)

    async def edge_to_client():
        while True:
            t, payload = await edge.q.get()
            if t == 99:
                log.warning("edge died mid-session; closing client")
                return
            if t == F_DATA_TO_GW:
                if not client_read_open:
                    continue
                if DEBUG:
                    log.debug("edge->client %d bytes", len(payload))
                try:
                    writer.write(payload)
                    await writer.drain()
                except (ConnectionError, RuntimeError, OSError):
                    return
            elif t == F_LOCAL_EOF:
                if client_read_open:
                    if DEBUG:
                        log.debug("local EOF -> half-close client")
                    try:
                        writer.close_write()
                    except Exception:
                        pass
            elif t in (F_LOCAL_CLOSED, F_CLIENT_GONE):
                log.info("session end: 0x%02x", t)
                return

    t1 = asyncio.create_task(client_to_edge())
    t2 = asyncio.create_task(edge_to_client())
    await asyncio.wait({t1, t2}, return_when=asyncio.FIRST_COMPLETED)
    for t in (t1, t2):
        t.cancel()
    if not edge.dead and client_read_open:
        edge.send(F_CLIENT_GONE)
    writer.close()
    try:
        await writer.wait_closed()
    except Exception:
        pass
    if not edge.dead:
        gw.release(edge)


async def accept(gw: Gateway, reader, writer):
    try:
        head = await asyncio.wait_for(
            reader.readexactly(len(HELLO_MAGIC)), timeout=15)
    except (asyncio.IncompleteReadError, asyncio.TimeoutError,
            ConnectionError, OSError):
        writer.close()
        return
    if head.startswith(HELLO_MAGIC):
        asyncio.create_task(register_edge(gw, reader, writer, head))
    else:
        asyncio.create_task(handle_client(gw, reader, writer, head))


async def run():
    gw = Gateway()
    server = await asyncio.start_server(
        lambda r, w: asyncio.create_task(accept(gw, r, w)), HOST, PORT)
    print(f"iq-task gateway on {HOST}:{PORT} (debug={DEBUG})", flush=True)
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    asyncio.run(run())