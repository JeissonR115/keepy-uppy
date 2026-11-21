#!/usr/bin/env python3

import json
import socket
import sys


def argument(name: str) -> str:
    return sys.argv[sys.argv.index(name) + 1]


def send_message(stream, message: dict) -> None:
    stream.write((json.dumps(message) + "\n").encode())


def main() -> int:
    host = argument("--host")
    port = int(argument("--port"))
    level = argument("--level")
    with socket.create_connection((host, port), timeout=5) as connection:
        stream = connection.makefile("rwb", buffering=0)
        hello = json.loads(stream.readline())
        session_id = hello["session_id"]
        send_message(
            stream,
            {
                "type": "command",
                "session_id": session_id,
                "sequence": 1,
                "command": "get_level_geometry",
                "payload": {"level": level},
            },
        )
        geometry = json.loads(stream.readline())
        if (
            geometry.get("type") != "command_result"
            or geometry.get("ok") is not True
            or geometry.get("result", {}).get("level") != level
        ):
            return 1
        while line := stream.readline():
            message = json.loads(line)
            if message.get("type") != "observation":
                continue
            send_message(
                stream,
                {
                    "type": "action",
                    "session_id": session_id,
                    "sequence": message["sequence"],
                    "action": {
                        "horizontal": -1.0,
                        "jump": False,
                        "dash": False,
                        "dash_direction": {"x": -1.0, "y": 0.0},
                        "down": False,
                        "grab": False,
                    },
                },
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
