#!/usr/bin/env python3

import argparse
import socket


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", required=True, type=int)
    arguments, _ = parser.parse_known_args()
    with socket.create_connection(
        (arguments.host, arguments.port),
        timeout=5,
    ) as connection:
        connection.settimeout(10)
        connection.recv(4096)
        connection.recv(1)


if __name__ == "__main__":
    main()
