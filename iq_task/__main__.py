import asyncio
import sys

from .api import serve


def _stage() -> None:
    from .stage import main
    sys.argv = sys.argv[1:]
    main()


def _edge() -> None:
    from .edge import main as edge_main
    asyncio.run(edge_main())


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "stage":
        _stage()
    elif cmd == "edge":
        _edge()
    else:
        try:
            asyncio.run(serve())
        except KeyboardInterrupt:
            pass
