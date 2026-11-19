import os
import socket
import subprocess
import time
import unittest
from pathlib import Path
from typing import Any

from examples.cpu_bridge_client import CPUBridgeClient


ROOT = Path(__file__).resolve().parents[1]
NEUTRAL_ACTION = {
    "horizontal": 0.0,
    "jump": False,
    "dash": False,
    "dash_direction": {"x": 0.0, "y": 0.0},
    "down": False,
    "grab": False,
}
CLASSIC_GRAPH = {
    "schema_version": 1,
    "level": "classic",
    "nodes": [
        {"id": 1, "position": {"x": 248.0, "y": 144.0}},
        {"id": 2, "position": {"x": 232.0, "y": 144.0}},
        {"id": 3, "position": {"x": 200.0, "y": 110.0}},
        {"id": 4, "position": {"x": 160.0, "y": 110.0}},
        {"id": 5, "position": {"x": 120.0, "y": 148.0}},
        {"id": 6, "position": {"x": 80.0, "y": 110.0}},
    ],
    "edges": [
        {"from": 1, "to": 2, "action": "WALK", "cost": 1.0, "bidirectional": True},
        {"from": 2, "to": 3, "action": "JUMP", "cost": 1.2},
        {"from": 3, "to": 4, "action": "DASH", "cost": 0.9},
        {"from": 4, "to": 5, "action": "DROP", "cost": 1.1},
        {"from": 5, "to": 6, "action": "WALL_JUMP", "cost": 1.8},
        {"from": 1, "to": 6, "action": "WALK", "cost": 20.0},
    ],
}


class CPUBridgeEndToEndTest(unittest.TestCase):
    def test_python_client_controls_simulation_and_fallback(self):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
            probe.bind(("127.0.0.1", 0))
            port = probe.getsockname()[1]
        godot = os.environ.get("GODOT_BIN", "godot")
        process = subprocess.Popen(
            [
                godot,
                "--headless",
                "--path",
                str(ROOT),
                "res://src/scenes/simulation/cpu_simulation.tscn",
                "--",
                f"--port={port}",
                "--level=classic",
                "--speed=8",
                "--seed=42",
                "--mode=cpu-vs-cpu",
            ],
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        client: CPUBridgeClient | None = None
        reconnect: CPUBridgeClient | None = None
        process_output = ""
        try:
            client = self._connect(process, port)
            speed_sequence = client.set_speed(8)
            speed_result, _ = self._wait_for_result(client, speed_sequence)
            self.assertEqual(speed_result["physics_ticks_per_second"], 480)

            reset_sequence = client.reset(42, "classic")
            reset_result, _ = self._wait_for_result(client, reset_sequence)
            self.assertIn("observation", reset_result)

            geometry_sequence = client.get_level_geometry("classic")
            geometry_result, _ = self._wait_for_result(client, geometry_sequence)
            self.assertEqual(geometry_result["level"], "classic")
            self.assertTrue(geometry_result["platforms"])

            graph_sequence = client.load_nav_graph(CLASSIC_GRAPH)
            graph_result, _ = self._wait_for_result(client, graph_sequence)
            self.assertEqual(graph_result["node_count"], 6)
            self.assertEqual(graph_result["edge_count"], 7)

            route_sequence = client.set_nav_route("classic", 1, 6)
            route_result, _ = self._wait_for_result(client, route_sequence)
            self.assertEqual(route_result["route_node_ids"], [1, 2, 3, 4, 5, 6])

            initial_observation = dict(reset_result["observation"])
            initial_observation.pop("tick", None)
            first_step, _ = self._step(client, 10)
            first_observation = first_step["observation"]
            self.assertLess(
                first_observation["players"]["player_2"]["position"]["x"],
                248.0,
            )

            reset_sequence = client.reset(42, "classic")
            repeated_reset, _ = self._wait_for_result(client, reset_sequence)
            repeated_initial_observation = dict(repeated_reset["observation"])
            repeated_initial_observation.pop("tick", None)
            self.assertEqual(repeated_initial_observation, initial_observation)
            route_sequence = client.set_nav_route("classic", 1, 6)
            repeated_route, _ = self._wait_for_result(client, route_sequence)
            self.assertEqual(repeated_route["route_node_ids"], [1, 2, 3, 4, 5, 6])
            repeated_step, _ = self._step(client, 10)
            repeated_observation = repeated_step["observation"]
            first_observation.pop("tick", None)
            repeated_observation.pop("tick", None)
            self.assertEqual(first_observation, repeated_observation)

            reset_sequence = client.reset(42, "classic")
            self._wait_for_result(client, reset_sequence)
            episode_result, episode_events = self._step(client, 600)
            self.assertTrue(episode_result["episode_ended"])
            self.assertTrue(episode_events)
            self.assertEqual(episode_events[-1]["type"], "point")
            self.assertLess(episode_result["steps"], 600)

            reset_sequence = client.reset(43, "classic")
            fallback_reset, _ = self._wait_for_result(client, reset_sequence)
            fallback_start_tick = fallback_reset["observation"]["tick"]
            client.step(20)
            self._wait_for_observation(client)
            client.close()
            client = None
            time.sleep(0.5)

            reconnect = self._connect(process, port)
            fallback_step, _ = self._step(reconnect, 10)
            self.assertEqual(fallback_step["steps"], 10)
            self.assertGreater(
                fallback_step["observation"]["tick"],
                fallback_start_tick + 20,
            )
            close_sequence = reconnect.close_session()
            self._wait_for_result(reconnect, close_sequence)
            reconnect.close()
            reconnect = None
        finally:
            if client is not None:
                client.close()
            if reconnect is not None:
                reconnect.close()
            if process.poll() is None:
                process.terminate()
            try:
                process_output, _ = process.communicate(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process_output, _ = process.communicate(timeout=10)

        self.assertIn(
            "Remote CPU brain is using LocalBrain: Python client disconnected.",
            process_output,
        )

    def _connect(self, process: subprocess.Popen[str], port: int) -> CPUBridgeClient:
        deadline = time.monotonic() + 15.0
        last_error: OSError | None = None
        while time.monotonic() < deadline:
            if process.poll() is not None:
                self.fail(f"Godot exited before accepting a client ({process.returncode}).")
            try:
                return CPUBridgeClient(port=port, timeout=20.0)
            except OSError as error:
                last_error = error
                time.sleep(0.05)
        self.fail(f"Godot bridge did not accept a client: {last_error}")
        raise AssertionError("unreachable")

    def _wait_for_result(
        self, client: CPUBridgeClient, sequence: int
    ) -> tuple[dict[str, Any], list[dict[str, Any]]]:
        events: list[dict[str, Any]] = []
        while True:
            message = client.receive()
            if message["type"] == "observation":
                client.send_action(message["sequence"], NEUTRAL_ACTION)
            elif message["type"] == "episode_event":
                events.append(message["event"])
            elif (
                message["type"] == "command_result"
                and message["sequence"] == sequence
            ):
                return message["result"], events

    def _wait_for_observation(self, client: CPUBridgeClient) -> dict[str, Any]:
        while True:
            message = client.receive()
            if message["type"] == "observation":
                return message

    def _step(
        self, client: CPUBridgeClient, n: int
    ) -> tuple[dict[str, Any], list[dict[str, Any]]]:
        sequence = client.step(n)
        return self._wait_for_result(client, sequence)


if __name__ == "__main__":
    unittest.main()
