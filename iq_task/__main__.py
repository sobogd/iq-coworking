import asyncio
import sys

from .api import serve


def _edge() -> None:
    from .edge import main as edge_main
    asyncio.run(edge_main())


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "edge":
        _edge()
    else:
        try:
            asyncio.run(serve())
        except KeyboardInterrupt:
            pass
