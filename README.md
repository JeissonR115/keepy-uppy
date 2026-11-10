# Keepy Uppy

Local two-player balloon game prototype made with Godot 4.x.

## Run

Open this folder in Godot 4.x and run the project. The main scene is
`src/scenes/main/main.tscn`. The current arena uses built-in geometric
placeholders and does not require external art or audio.

## Display

The logical viewport is 320x180, displayed at 960x540 (integer 3x scale).
The viewport keeps its 16:9 aspect ratio and uses nearest-neighbor filtering
for canvas textures.

## Audio

No owner-supplied audio files are present, so the prototype has no audio
dependencies or hooks. Player states, balloon impacts, priority, and round
results are communicated visually.

## Manual launch and render checklist

- [ ] Open the project in Godot 4.x and confirm there are no import or missing-resource errors.
- [ ] Run the project and confirm the two players, balloon, platforms, and ground are visible.
- [ ] Confirm the 960x540 window shows crisp, unblurred placeholder edges.
- [ ] Resize the window and confirm the game retains its 16:9 aspect ratio and integer pixel scaling.

## Player movement

Each player has separate Input Map actions for left, right, jump, and dash.
Player 1 uses A/D, Space, and Shift, with W/S for vertical dash direction.
Player 2 uses Left/Right, Enter, and Right Ctrl, with Up/Down for vertical
dash direction. Actions can be rebound in Project Settings without changing
the movement script.

Run the automated independent-movement and remapping check with:

```sh
godot --headless --path . --script res://tests/test_player_controller.gd
```

Verify balloon contact and physics with:

```sh
godot --headless --path . --script res://tests/test_balloon_physics.gd
```

Verify dash rescue with:

```sh
godot --headless --path . --script res://tests/test_dash_rescue.gd
```

Verify contact priority and player push strengths with:

```sh
godot --headless --path . --script res://tests/test_player_interaction.gd
```

Verify movement-state visuals, priority feedback, and balloon impact feedback with:

```sh
godot --headless --path . --script res://tests/test_visual_feedback.gd
```

Verify point assignment and the round/match lifecycle with:

```sh
godot --headless --path . --script res://tests/test_round_scoring.gd
```

Manual balloon checks:

- [ ] Hit the balloon from both sides and confirm each contact produces one clear impulse.
- [ ] Confirm the balloon rebounds from the scoring ground and does not exceed its configured speed.
- [ ] Leave the balloon on the ground through several physics frames and confirm one ground event is reported for the round.

Manual round and score checks:

- [ ] Confirm the scoreboard shows both player labels and starts at 0 - 0.
- [ ] Let the balloon touch the scoring ground and confirm the point and round result appear on the scoreboard.
- [ ] Confirm the score remains visible after the next round starts.
- [ ] Reach the configured target and confirm the winner is displayed without another round starting.

Manual movement checks:

- [ ] Move both players in opposite directions simultaneously and confirm they remain independent.
- [ ] Confirm idle, running, rising, falling, and dashing use distinct player visual treatments.
- [ ] Change a player's horizontal action in Project Settings > Input Map and confirm that player follows the new binding without code changes.
- [ ] Confirm players stop at the ground, platforms, and each other.
- [ ] Compare a tap jump with a held jump and confirm the held jump rises higher.
- [ ] Walk off a platform, press jump within the Coyote Time window, and confirm the jump still triggers.
- [ ] Press jump just before landing and confirm Jump Buffer triggers immediately on landing.
- [ ] Dash in each of the eight directions and confirm an un-directed dash follows the player's facing.
- [ ] Attempt to dash again during cooldown and confirm no second dash begins.
- [ ] Dash through the balloon, verify the rescue impulse follows dash direction, and confirm the zone and separate trail end with the dash.
- [ ] Re-enter the balloon with the same dash activation and confirm it is not hit a second time.
- [ ] Confirm the player with priority can push farther than the other player, including during dash.
- [ ] Confirm same-tick ties go to the non-priority player and a dash rescue takes priority over a normal hit.
- [ ] Confirm a gold outline identifies the priority player and moves when priority changes.
- [ ] Confirm balloon hits flash visibly and the dash trail appears only during the dash, without relying on sound.
