#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import socket
from typing import Any


PROTOCOL_VERSION = 1
MAX_MESSAGE_BYTES = 1_048_576
COMMANDS = {
    "reset",
    "step",
    "set_speed",
    "get_level_geometry",
    "load_nav_graph",
    "close",
}


class CPUBridgeError(RuntimeError):
    pass


class CPUBridgeClient:
    def __init__(
        self, host: str = "127.0.0.1", port: int = 8765, timeout: float = 10.0
    ) -> None:
        self._socket = socket.create_connection((host, port), timeout=timeout)
        self._socket.settimeout(timeout)
        self._reader = self._socket.makefile("rb")
        self._session_id = ""
        self._next_command_sequence = 1
        self._closed = False

        hello = self._read_json_line()
        if (
            hello.get("type") != "hello"
            or hello.get("protocol_version") != PROTOCOL_VERSION
            or not isinstance(hello.get("session_id"), str)
            or not hello["session_id"]
        ):
            self.close()
            raise CPUBridgeError("Server sent an invalid protocol hello.")
        self._session_id = hello["session_id"]

    def __enter__(self) -> "CPUBridgeClient":
        return self

    def __exit__(self, _exc_type: Any, _exc: Any, _traceback: Any) -> None:
        self.close()

    @property
    def session_id(self) -> str:
        return self._session_id

    def reset(self, seed: int, level: str) -> int:
        if isinstance(seed, bool) or not isinstance(seed, int):
            raise ValueError("seed must be an integer.")
        if not isinstance(level, str) or not level.strip():
            raise ValueError("level must be a non-empty string.")
        return self.send_command("reset", {"seed": seed, "level": level})

    def step(self, n: int = 1) -> int:
        if isinstance(n, bool) or not isinstance(n, int) or n <= 0:
            raise ValueError("n must be a positive integer.")
        return self.send_command("step", {"n": n})

    def set_speed(self, speed: float) -> int:
        if not isinstance(speed, (int, float)) or not math.isfinite(speed) or speed <= 0:
            raise ValueError("speed must be a finite positive number.")
        return self.send_command("set_speed", {"speed": speed})

    def get_level_geometry(self, level: str | None = None) -> int:
        payload: dict[str, Any] = {}
        if level is not None:
            if not isinstance(level, str) or not level.strip():
                raise ValueError("level must be a non-empty string when provided.")
            payload["level"] = level
        return self.send_command("get_level_geometry", payload)

    def load_nav_graph(self, graph: dict[str, Any]) -> int:
        if not isinstance(graph, dict):
            raise ValueError("graph must be a JSON object.")
        return self.send_command("load_nav_graph", {"graph": graph})

    def close_session(self) -> int:
        return self.send_command("close")

    def send_command(self, command: str, payload: dict[str, Any] | None = None) -> int:
        if command not in COMMANDS:
            raise ValueError(f"unsupported command: {command}")
        if payload is not None and not isinstance(payload, dict):
            raise ValueError("payload must be a JSON object.")
        sequence = self._next_command_sequence
        self._next_command_sequence += 1
        self._send_json_line(
            {
                "type": "command",
                "protocol_version": PROTOCOL_VERSION,
                "session_id": self._session_id,
                "sequence": sequence,
                "command": command,
                "payload": payload or {},
            }
        )
        return sequence

    def receive(self) -> dict[str, Any]:
        message = self._read_json_line()
        if message.get("protocol_version") != PROTOCOL_VERSION:
            raise CPUBridgeError("Server message has an unsupported protocol version.")
        if message.get("session_id") != self._session_id:
            raise CPUBridgeError("Server message belongs to a different session.")
        if message.get("type") == "error":
            raise CPUBridgeError(
                f"{message.get('code', 'protocol_error')}: "
                f"{message.get('message', 'The server rejected the message.')}"
            )
        return message

    def send_action(self, sequence: int, action: dict[str, Any]) -> None:
        if isinstance(sequence, bool) or not isinstance(sequence, int) or sequence <= 0:
            raise ValueError("sequence must be a positive integer.")
        self._validate_action(action)
        self._send_json_line(
            {
                "type": "action",
                "protocol_version": PROTOCOL_VERSION,
                "session_id": self._session_id,
                "sequence": sequence,
                "action": action,
            }
        )

    def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        self._reader.close()
        self._socket.close()

    def _read_json_line(self) -> dict[str, Any]:
        line = self._reader.readline(MAX_MESSAGE_BYTES + 2)
        if not line:
            raise CPUBridgeError("Server closed the connection.")
        if len(line) > MAX_MESSAGE_BYTES + 1 or not line.endswith(b"\n"):
            raise CPUBridgeError("Server message exceeds the 1 MiB line limit.")
        try:
            message = json.loads(line.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise CPUBridgeError("Server sent invalid UTF-8 JSON.") from error
        if not isinstance(message, dict):
            raise CPUBridgeError("Server message must be a JSON object.")
        return message

    def _send_json_line(self, message: dict[str, Any]) -> None:
        try:
            encoded = json.dumps(
                message, separators=(",", ":"), allow_nan=False
            ).encode("utf-8") + b"\n"
        except (TypeError, ValueError) as error:
            raise ValueError("Message is not valid finite JSON.") from error
        if len(encoded) - 1 > MAX_MESSAGE_BYTES:
            raise ValueError("Message exceeds the 1 MiB line limit.")
        self._socket.sendall(encoded)

    @staticmethod
    def _validate_action(action: dict[str, Any]) -> None:
        if not isinstance(action, dict):
            raise ValueError("action must be a JSON object.")
        required = {"horizontal", "jump", "dash", "dash_direction", "down", "grab"}
        if set(action) != required:
            raise ValueError(f"action must contain exactly: {', '.join(sorted(required))}.")
        horizontal = action["horizontal"]
        if (
            isinstance(horizontal, bool)
            or not isinstance(horizontal, (int, float))
            or not math.isfinite(horizontal)
            or abs(horizontal) > 1
        ):
            raise ValueError("horizontal must be finite and between -1 and 1.")
        for key in ("jump", "dash", "down", "grab"):
            if not isinstance(action[key], bool):
                raise ValueError(f"{key} must be boolean.")
        direction = action["dash_direction"]
        if not isinstance(direction, dict) or set(direction) != {"x", "y"}:
            raise ValueError("dash_direction must contain numeric x and y.")
        for key in ("x", "y"):
            value = direction[key]
            if (
                isinstance(value, bool)
                or not isinstance(value, (int, float))
                or not math.isfinite(value)
            ):
                raise ValueError(f"dash_direction.{key} must be finite numeric input.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Minimal client for the Godot CPU bridge.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--level", default="classic")
    parser.add_argument("--seed", type=int, default=1)
    args = parser.parse_args()

    neutral_action = {
        "horizontal": 0.0,
        "jump": False,
        "dash": False,
        "dash_direction": {"x": 0.0, "y": 0.0},
        "down": False,
        "grab": False,
    }

    with CPUBridgeClient(args.host, args.port) as client:
        reset_sequence = client.reset(args.seed, args.level)
        while True:
            message = client.receive()
            if (
                message.get("type") == "command_result"
                and message.get("sequence") == reset_sequence
            ):
                break
            if message.get("type") == "observation":
                client.send_action(message["sequence"], neutral_action)

        for _ in range(2):
            step_sequence = client.step(1)
            while True:
                message = client.receive()
                if message.get("type") == "observation":
                    client.send_action(message["sequence"], neutral_action)
                elif (
                    message.get("type") == "command_result"
                    and message.get("sequence") == step_sequence
                ):
                    break

        close_sequence = client.close_session()
        while True:
            message = client.receive()
            if (
                message.get("type") == "command_result"
                and message.get("sequence") == close_sequence
            ):
                break
            if message.get("type") == "observation":
                client.send_action(message["sequence"], neutral_action)


if __name__ == "__main__":
    main()
