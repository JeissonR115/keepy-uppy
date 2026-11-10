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
- [ ] Run the project and confirm the two players, balloon, floor, and side boundaries are visible without floating platforms.
- [ ] Confirm the 960x540 window shows crisp, unblurred placeholder edges.
- [ ] Resize the window and confirm the game retains its 16:9 aspect ratio and integer pixel scaling.

## Player movement

Each player has separate Input Map actions for left, right, up, down, jump,
dash, and accelerate. Player 1 uses A/D/W/S, F, G, and H. Player 2 uses the
arrow keys and the physical top-row 1/2/3 keys. Actions can be rebound without
changing movement logic. Use the in-game **KEYS** menu to rebind them and save
the complete map locally; Project Settings > Input Map remains available for
development.

## Pause and menu navigation

- Press **Escape** during play to open or close the pause menu.
- Use Player 1's current **Up/Down** actions (default W/S) to move through menu options.
- Use Player 1's **Jump** action (default F) to confirm and **Dash** (default G) to go back.
- Choose **Resume**, **Restart**, or **Controls**. Restart opens a confirmation with **No** selected by default. Controls opens the existing binding screen while the match stays paused.
- In the restart confirmation, use **W/S** and **F** to choose **No** or **Yes**; **G** returns to pause without changing the match. **Yes** resets points, sets, and the opening toss while retaining saved control bindings.
- The menu reads the live Player 1 Input Map, so remapping Up, Down, Jump, or Dash changes menu navigation too. Escape remains reserved; during key capture it cancels the capture.

Verify pause navigation, restart cancellation, controls entry, and gameplay isolation with:

```sh
godot --headless --path . --script res://tests/test_pause_menu.gd
```

Verify restart cancellation, fresh-match reset, and saved-control retention with:

```sh
godot --headless --path . --script res://tests/test_restart_confirmation.gd
```

Verify all 14 default bindings with:

```sh
godot --headless --path . --script res://tests/test_input_map.gd
```

Verify prohibited keys, modifier shortcuts, duplicate bindings, and available
keys with:

```sh
godot --headless --path . --script res://tests/test_control_settings_validation.gd
```

The in-game settings validator reserves Escape, F1-F12, and individual
modifier keys. It also rejects all modified key combinations and any physical
key already used by one of the other thirteen player actions. Rejected input
does not change the active Input Map binding.

Valid bindings are saved as a versioned, complete map in
`user://controls.cfg`. Missing, incomplete, malformed, unsupported, duplicate,
or prohibited settings restore all defaults so one bad entry cannot leave the
two players with a partial configuration.

Verify settings persistence and damaged-file recovery with:

```sh
godot --headless --path . --script res://tests/test_control_settings_persistence.gd
```

Verify the controls overlay, capture cancellation, reset, and pause/resume
behavior with:

```sh
godot --headless --path . --script res://tests/test_control_settings_ui.gd
```

Controls-menu acceptance checks (covered by `test_control_settings_ui.gd`):

- [x] Open the pause menu with Escape, choose **CONTROLS** with W/S and F, and keep play paused.
- [x] Use W/S to browse all seven actions for each player, plus capture cancel, Restore Defaults, and Back.
- [x] Use W/S to focus an action and F to start capture; press a valid key and confirm its displayed binding updates.
- [x] During capture, press Escape or G and cancel capture without changing the previous key.
- [x] Reject conflicting key assignments without replacing the existing binding.
- [x] Use W/S to reach **RESTORE DEFAULTS**, press F, and restore both players' documented defaults.
- [x] Use G to return to pause and choose **RESUME** with F.

Integration verification (Godot 4.7.2): all 22 `tests/test_*.gd` scripts passed
in headless mode, and the main scene started successfully with
`godot --headless --path . --quit-after 5`. Reproduce the complete automated
suite and scene launch with:

```sh
for test in tests/test_*.gd; do
  godot --headless --path . --script "res://$test" || exit 1
done
godot --headless --path . --quit-after 5
```

Run the automated independent-movement and remapping check with:

```sh
godot --headless --path . --script res://tests/test_player_controller.gd
```

Player accelerate uses a separate temporary speed boost: 0.8 seconds at 1.35x
normal run speed, a 4-second cooldown, and a 210 px/s cap. Ordinary horizontal
acceleration remains the rate used to reach the current run-speed target.
Verify boost duration, cooldown, cap, normal-speed return, and player
independence with:

```sh
godot --headless --path . --script res://tests/test_accelerate.gd
```

The control acceptance suite passed in Godot headless: defaults and simultaneous
inputs, all 14 capture rows, rejected and duplicate keys, cancel/reset,
save/load and damaged-file recovery, plus boost duration, cooldown, cap, and
independent player behavior. Run the commands above to reproduce each check.

Manual accelerate checks:

- [ ] Hold a direction and press the player's **ACCELERATE** key; confirm the boost raises top speed without changing ordinary run acceleration.
- [ ] Keep moving after 0.8 seconds and confirm normal run speed returns; press accelerate again before 4 seconds and confirm no second boost starts.
- [ ] Confirm speed stays at or below 210 px/s during boost and the other player's accelerate action remains independent.

Verify balloon contact and physics with:

```sh
godot --headless --path . --script res://tests/test_balloon_physics.gd
```

Verify dash rescue with:

```sh
godot --headless --path . --script res://tests/test_dash_rescue.gd
```

## Balloon, serve, and fault rules

- The balloon spawns 30 px above the opening server selected by the coin toss and above each subsequent point winner.
- The server is the first eligible player. Their serve counts as the first contact; after each accepted normal or dash-rescue touch, the other player becomes eligible.
- Touching out of turn or sending the balloon downward is an immediate fault and awards the point to the opponent. A floor contact awards the point against the last valid toucher and shows a short burst.
- Player priority for player-to-player pushes remains separate from the expected balloon toucher.
- The arena keeps the scoring floor and side walls; the three elevated platforms are removed.

Verify player-velocity impact direction, speed limits, and downward-hit faults with:

```sh
godot --headless --path . --script res://tests/test_balloon_contact_impulse.gd
```

Verify alternating turns, simultaneous callback-order faults, and single point awards with:

```sh
godot --headless --path . --script res://tests/test_balloon_turns.gd
```

Verify opening and next-point balloon spawn locations with:

```sh
godot --headless --path . --script res://tests/test_balloon_spawn.gd
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

Verify both coin-toss outcomes and that the toss occurs only once per match:

```sh
godot --headless --path . --script res://tests/test_coin_toss.gd
```

Verify scoreboard updates and viewport placement with:

```sh
godot --headless --path . --script res://tests/test_scoreboard.gd
```

Simulate the complete first-to-three-sets match acceptance flow with:

```sh
godot --headless --path . --script res://tests/test_full_match.gd
```

Balloon tuning defaults are exposed on the balloon controller and collision
shapes: gravity scale 0.35, air resistance 0.035, horizontal damping 0.08,
rebound 0.12, horizontal speed cap 360 px/s, vertical speed cap 420 px/s,
normal hit impulse 120-240, dash rescue impulse 300-360, same-player contact interval 0.10 s, body radius
9 px, player contact radius 16 px, and dash rescue zone 44x20 px.

Manual balloon checks:

- [ ] Hit the balloon from both sides and confirm each contact produces one clear impulse.
- [ ] Compare slow and fast player approaches and confirm normal-hit impulse scales within the configured minimum and maximum.
- [ ] Confirm dash rescue produces a distinct, direction-aware impulse and the rescue zone is larger than the balloon's body collider.
- [ ] Re-enter the balloon rapidly with the same player and confirm the contact interval prevents repeat hits while the other player can still contact it.
- [ ] Give the balloon large horizontal and vertical velocity and confirm each axis stays within its own configured cap.
- [ ] Confirm the balloon's arena-boundary rebound follows configured bounce and damping; floor contact ends the point once and shows the burst.
- [ ] Leave the balloon on the ground through several physics frames and confirm one ground event is reported for the round.
- [ ] Compare slow and fast normal contacts, then a dash rescue, and confirm the normal impulse scales within 120-240 while dash rescue remains distinct.

Manual player interaction checks:

- [ ] Confirm the balloon spawns above the server, the server serves first, and each valid normal or dash-rescue contact alternates the eligible player.
- [ ] Confirm an out-of-turn contact faults the touching player, including when both players contact in the same physics tick regardless of callback order.
- [ ] Confirm a downward-directed hit faults its player immediately, while accepted contacts update last-touch attribution and player priority independently.
- [ ] Push both players toward either side wall, confirm neither leaves the arena, then move them back toward the center and confirm both remain controllable.
- [ ] Compare priority and non-priority normal/dash pushes and confirm each resulting push velocity stays within the configured cap.

Manual match and score checks:

- [ ] Confirm the opening coin toss shows HEADS/P1 or TAILS/P2, with the selected player starting as server and priority.
- [ ] Let a serve fall without another valid touch and confirm the receiver scores; then make another valid touch and confirm the point goes to that toucher's opponent.
- [ ] Confirm each point winner serves next, including the first point after a set.
- [ ] Confirm the HUD shows points and sets; the first player to five points wins a set, 4-4 needs only one more point, and point scores reset while set scores remain.
- [ ] Win three sets and confirm the match winner is displayed with no extra point or set starting and no second coin toss between sets.
- [ ] Confirm duplicate ground notifications during a resolving point cannot award an extra point.
- [ ] Confirm the compact HUD stays within the viewport and its backdrop does not cover the balloon or players.

Manual movement checks:

- [ ] Move both players in opposite directions simultaneously and confirm they remain independent.
- [ ] Confirm idle, running, rising, falling, and dashing use distinct player visual treatments.
- [ ] Change a player's horizontal action in Project Settings > Input Map and confirm that player follows the new binding without code changes.
- [ ] Confirm players stop at the floor, arena side boundaries, and each other; no elevated platforms remain.
- [ ] Compare a tap jump with a held jump and confirm the held jump rises higher.
- [ ] Press jump within the Coyote Time window after leaving the floor, and confirm the jump still triggers.
- [ ] Press jump just before landing and confirm Jump Buffer triggers immediately on landing.
- [ ] Dash in each of the eight directions and confirm an un-directed dash follows the player's facing.
- [ ] Attempt to dash again during cooldown and confirm no second dash begins.
- [ ] Dash through the balloon, verify the rescue impulse follows dash direction, and confirm the zone and separate trail end with the dash.
- [ ] Re-enter the balloon with the same dash activation and confirm it is not hit a second time.
- [ ] Confirm the player with priority can push farther than the other player, including during dash.
- [ ] Confirm same-tick ties go to the non-priority player and a dash rescue takes priority over a normal hit.
- [ ] Confirm a gold outline identifies the priority player and moves when priority changes.
- [ ] Confirm balloon hits flash visibly and the dash trail appears only during the dash, without relying on sound.
