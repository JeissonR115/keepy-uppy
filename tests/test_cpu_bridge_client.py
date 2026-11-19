import json
import socketserver
import threading
import unittest

from examples.cpu_bridge_client import CPUBridgeClient


SESSION_ID = "test-session"


class BridgeHandler(socketserver.StreamRequestHandler):
    def handle(self):
        self._send(
            {
                "type": "hello",
                "protocol_version": 1,
                "session_id": SESSION_ID,
            }
        )

        reset = self._receive()
        if (
            reset.get("type") != "command"
            or reset.get("command") != "reset"
            or reset.get("sequence") != 1
            or reset.get("payload") != {"seed": 42, "level": "classic"}
        ):
            raise AssertionError("Client sent an invalid reset command.")
        self._send(
            {
                "type": "command_result",
                "protocol_version": 1,
                "session_id": SESSION_ID,
                "sequence": 1,
                "ok": True,
                "result": {"ready": True, "observation": {"tick": 11}},
            }
        )
        step = self._receive()
        if (
            step.get("type") != "command"
            or step.get("command") != "step"
            or step.get("sequence") != 2
            or step.get("payload") != {"n": 1}
        ):
            raise AssertionError("Client sent an invalid step command.")
        self._send(
            {
                "type": "observation",
                "protocol_version": 1,
                "session_id": SESSION_ID,
                "sequence": 5,
                "observation": {"tick": 12},
            }
        )

        action = self._receive()
        expected_action = {
            "horizontal": 0.25,
            "jump": True,
            "dash": False,
            "dash_direction": {"x": 1.0, "y": 0.0},
            "down": False,
            "grab": True,
        }
        if (
            action.get("type") != "action"
            or action.get("sequence") != 5
            or action.get("action") != expected_action
        ):
            raise AssertionError("Client sent an invalid action response.")

        self._send(
            {
                "type": "command_result",
                "protocol_version": 1,
                "session_id": SESSION_ID,
                "sequence": 2,
                "ok": True,
                "result": {"steps": 1},
            }
        )
        probe = self._receive()
        if (
            probe.get("type") != "command"
            or probe.get("command") != "probe_movement"
            or probe.get("sequence") != 3
            or probe.get("payload")
            != {
                "movement": "jump",
                "level": "classic",
                "start_position": {"x": 160.0, "y": 152.0},
                "horizontal": 0.0,
            }
        ):
            raise AssertionError("Client sent an invalid movement probe command.")
        self._send(
            {
                "type": "command_result",
                "protocol_version": 1,
                "session_id": SESSION_ID,
                "sequence": 3,
                "ok": True,
                "result": {"landed": True},
            }
        )
        route = self._receive()
        if (
            route.get("type") != "command"
            or route.get("command") != "set_nav_route"
            or route.get("sequence") != 4
            or route.get("payload")
            != {"level": "classic", "start_node": 1, "destination_node": 2}
        ):
            raise AssertionError("Client sent an invalid navigation route command.")
        self._send(
            {
                "type": "command_result",
                "protocol_version": 1,
                "session_id": SESSION_ID,
                "sequence": 4,
                "ok": True,
                "result": {"route_node_ids": [1, 2]},
            }
        )
        close = self._receive()
        if (
            close.get("type") != "command"
            or close.get("command") != "close"
            or close.get("sequence") != 5
        ):
            raise AssertionError("Client sent an invalid close command.")
        self._send(
            {
                "type": "command_result",
                "protocol_version": 1,
                "session_id": SESSION_ID,
                "sequence": 5,
                "ok": True,
                "result": {},
            }
        )

    def _receive(self):
        line = self.rfile.readline()
        if not line:
            raise AssertionError("Client closed before sending the expected message.")
        return json.loads(line)

    def _send(self, message):
        self.wfile.write(json.dumps(message).encode("utf-8") + b"\n")
        self.wfile.flush()


class CPUBridgeClientTest(unittest.TestCase):
    def test_reset_observation_action_and_close(self):
        server = socketserver.ThreadingTCPServer(("127.0.0.1", 0), BridgeHandler)
        server_thread = threading.Thread(target=server.serve_forever, daemon=True)
        server_thread.start()
        try:
            with CPUBridgeClient(port=server.server_address[1]) as client:
                self.assertEqual(client.session_id, SESSION_ID)
                reset_sequence = client.reset(42, "classic")
                reset_result = client.receive()
                self.assertEqual(reset_sequence, 1)
                self.assertEqual(reset_result["type"], "command_result")
                self.assertEqual(
                    reset_result["result"],
                    {"ready": True, "observation": {"tick": 11}},
                )

                step_sequence = client.step(1)
                observation = client.receive()
                self.assertEqual(observation["type"], "observation")
                self.assertEqual(observation["observation"], {"tick": 12})
                client.send_action(
                    observation["sequence"],
                    {
                        "horizontal": 0.25,
                        "jump": True,
                        "dash": False,
                        "dash_direction": {"x": 1.0, "y": 0.0},
                        "down": False,
                        "grab": True,
                    },
                )
                step_result = client.receive()
                self.assertEqual(step_result["type"], "command_result")
                self.assertEqual(step_result["sequence"], step_sequence)

                probe_sequence = client.send_command(
                    "probe_movement",
                    {
                        "movement": "jump",
                        "level": "classic",
                        "start_position": {"x": 160.0, "y": 152.0},
                        "horizontal": 0.0,
                    },
                )
                probe_result = client.receive()
                self.assertEqual(probe_sequence, 3)
                self.assertEqual(probe_result["sequence"], probe_sequence)
                self.assertEqual(probe_result["result"], {"landed": True})

                route_sequence = client.set_nav_route("classic", 1, 2)
                route_result = client.receive()
                self.assertEqual(route_sequence, 4)
                self.assertEqual(route_result["result"], {"route_node_ids": [1, 2]})

                close_sequence = client.close_session()
                close_result = client.receive()
                self.assertEqual(close_sequence, 5)
                self.assertEqual(close_result["type"], "command_result")
                self.assertEqual(close_result["sequence"], close_sequence)
        finally:
            server.shutdown()
            server.server_close()
            server_thread.join()

    def test_set_nav_route_rejects_invalid_values(self):
        client = object.__new__(CPUBridgeClient)
        with self.assertRaises(ValueError):
            client.set_nav_route("classic", True, 2)


if __name__ == "__main__":
    unittest.main()
