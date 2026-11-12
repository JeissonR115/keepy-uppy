# Keepy Uppy

Local two-player balloon game prototype made with Godot 4.x.

## Run

Open this folder in Godot 4.x and run the project. The main scene is
`src/scenes/main/main.tscn`. Arenas use the reusable TileSet in
`assets/sprites/arena/foreground_tilesets.png` and are selected from the
arena catalog before each match.

At startup, choose **1 PLAYER** to play against a simple bot or **2 PLAYERS**
for local multiplayer, then choose the arena. Use Player 1's Up/Down controls
(W/S by default) and Jump (F) to select. In one-player mode, the bot controls
Player 2 and moves to intercept the balloon on its turn. If Player 1 is close
to the balloon on the bot's turn, it tries to challenge and push Player 1 away
first.

## Display

The logical viewport is 320x180 and displays at 960x540 while preserving its
16:9 aspect ratio. Canvas items use linear texture filtering and scale directly
to the window instead of being rendered through a low-resolution pixelated
viewport.

## Visuals

The project-wide GUI theme uses `DotGothic16-Regular.ttf` from
`assets/fonts/DotGothic16/`. Player visuals are basic colored rectangles; the
player cape remains procedurally simulated and follows its character anchors.
The arena terrain uses 16-pixel tiles; previews and the HUD remain separate
from gameplay geometry.

Verify the global font, rectangle visuals, screen-effect isolation, and cape
instances with:

```sh
godot --headless --path . --script res://tests/test_visual_assets.gd
```

## Audio

Sound effects are configured in `audio/sound_presets.json` and played through
the `AudioManager` autoload. The project has `SFX` and `UI` buses; generated
files live under `audio/sfx/`. The current WAVs are silent placeholders because
the exact preset exporters were unavailable. See `audio/PENDIENTES.md` for the
presets, render variations, and files that still need to be exported. Replace
the placeholders with exact synthesizer exports without changing the manifest.

Run the focused playback/manifest checks with:

```sh
godot --headless --path . --script res://tests/test_audio_manager.gd
```

Run all focused sound checks, including offline gameplay and local-action
dispatch, with:

```sh
for test in \
  tests/test_audio_*.gd \
  tests/test_player_audio.gd \
  tests/test_balloon_audio.gd \
  tests/test_match_menu_audio.gd; do
  godot --headless --path . --script "res://$test" || exit 1
done
```

Gameplay sounds are limited to the actions assigned in
`KEEPY_UPPY_BALLOON_SOUNDS.md`; landing, climbing, wall grabbing, dash refill,
death, and respawn remain silent.

Menu music (`assets/music/menu.wav`) starts automatically and loops while the
player is outside a match. Selecting a mode switches to looping
`assets/music/bgMusic.wav`, mixed at -4 dB and a slightly lower pitch
(0.92); menu music is mixed at -6 dB. The menu track returns automatically
when the match ends. Verify transitions and loop settings with:

```sh
godot --headless --path . --script res://tests/test_music_manager.gd
```

## Manual launch and render checklist

- [ ] Open the project in Godot 4.x and confirm there are no import or missing-resource errors.
- [ ] Choose each arena and confirm its floor, walls, platforms, players, and balloon are visible.
- [ ] Confirm the 960x540 window shows crisp, unblurred placeholder edges.
- [ ] Resize the window and confirm the game retains its 16:9 aspect ratio and integer pixel scaling.

## Player movement

Each player has seven separate Input Map actions: left, right, up, down, jump,
dash, and grab. Player 1 uses A/D/W/S, F, G, and R. Player 2 uses the
arrow keys and the physical top-row 1/2/4 keys. Actions can be rebound without
changing movement logic. Use the in-game **KEYS** menu to rebind them and save
the complete map locally; Project Settings > Input Map remains available for
development. On one-way platforms, hold **Down** and press **Jump** to drop
through.

Verify level switching and platform drop-through with:

```sh
godot --headless --path . --script res://tests/test_level_selection.gd
godot --headless --path . --script res://tests/test_arena_layout.gd
```

## Pause and menu navigation

- Press **Escape** during play to open or close the pause menu.
- At startup, the player-count menu is the only menu open. Select **Keyboard Controls** to edit bindings before choosing a game mode; returning from controls restores player selection. After choosing one or two players, choose a catalog arena and review its preview and details.
- Only one menu is shown at a time: opening pause hides player selection, and opening controls replaces the menu that launched it.
- The pause menu is a single vertical column: Player 1's **Up/Down** actions (default W/S) move between options; **Left/Right** do not change its selection. The restart confirmation uses **Left/Right** (default A/D) to choose Yes or No. Other menus also use Player 1's current directional actions; **Jump** confirms (default F) and **Dash** goes back (default G). Remapping those actions updates menu navigation too.
- Choose **Resume**, **Restart**, or **Controls**. Confirming **Restart** opens player-count and then arena selection; choosing an arena starts a fresh match and retains saved control bindings.
- Player-count, controls, and winner menus remain keyboard navigable. Escape opens or closes pause during play and cancels an active key capture.

Verify pause navigation, restart cancellation, controls entry, and gameplay isolation with:

```sh
godot --headless --path . --script res://tests/test_pause_menu.gd
```

Verify menu and HUD layouts are authored in their scenes with:

```sh
godot --headless --path . --script res://tests/test_ui_scene_ownership.gd
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

The project currently contains 47 `tests/test_*.gd` scripts. On the pre-refactor
Godot 4.7.2 baseline, 27 of 39 scripts exited successfully, 12 had documented
pre-existing failures, and the main scene exited successfully with
`godot --headless --path . --quit-after 5`. Run the current suite and scene launch
with:

```sh
for test in tests/test_*.gd; do
  godot --headless --path . --script "res://$test" || exit 1
done
godot --headless --path . --quit-after 5
```

Run the automated independent-movement and remapping check with:

```sh
godot --headless --path . --script res://tests/test_player_controller.gd
godot --headless --path . --script res://tests/test_player_jump.gd
godot --headless --path . --script res://tests/test_player_horizontal_movement.gd
godot --headless --path . --script res://tests/test_player_wall_climb.gd
```

Verify cape geometry, dash-availability colors, per-player transitions, reset,
local freeze, and simulation recovery with:

```sh
godot --headless --path . --script res://tests/test_player_cape.gd
```

Verify balloon contact and physics with:

```sh
godot --headless --path . --script res://tests/test_balloon_physics.gd
```

Verify dash rescue with:

```sh
godot --headless --path . --script res://tests/test_dash_rescue.gd
```

## Balloon, serve, and fault rules

- The balloon spawns `balloon_spawn_offset` pixels above the opening server selected by the coin toss and above each subsequent point winner (100 px by default). It stays still until its first player touch, then resumes its reduced gravity (scale 0.14).
- The balloon collides physically with both players, and the HUD's `TURN` label shows who must touch it next.
- The server is the first eligible player. Their serve counts as the first contact; after each accepted normal or dash-rescue touch, the other player becomes eligible.
- Touching out of turn is a fault and awards the point to the opponent. Otherwise, a point is awarded only when the balloon reaches the floor after a contact; the last valid toucher scores. A downward hit replays the serve without scoring; the same player's second consecutive downward fault deducts one point before replaying.
- Player priority for player-to-player pushes remains separate from the expected balloon toucher.
- The arena keeps the scoring floor, side walls, and a ceiling. The balloon bounces from the walls and ceiling; touching the floor triggers the burst and resolves the point. After each set, a short overlay shows the set winner and score. Each touch briefly marks the player contact zone and balloon through the shared two-second pixel effect, and the balloon takes the last toucher's color.

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
shapes: gravity scale 0.14, air resistance 0.055, horizontal damping 0.08,
rebound 0.28, horizontal speed cap 220 px/s, maximum fall speed 90 px/s,
maximum speed after a hit 220 px/s,
normal hit impulse 120-240, dash rescue impulse 300-360, same-player contact interval 0.10 s, body radius
9 px, player contact radius 16 px, and dash rescue zone 44x20 px.

Manual balloon checks:

- [ ] Hit the balloon from both sides and confirm each contact produces one clear impulse.
- [ ] At the opening serve and after a point, confirm the balloon waits above the server, the HUD identifies the player who must touch it, and the balloon begins moving only after a touch.
- [ ] Move or jump into the balloon and confirm its body collides with the player instead of passing through.
- [ ] Compare slow and fast player approaches and confirm normal-hit impulse scales within the configured minimum and maximum.
- [ ] Confirm dash rescue produces a distinct, direction-aware impulse and the rescue zone is larger than the balloon's body collider.
- [ ] Re-enter the balloon rapidly with the same player and confirm the contact interval prevents repeat hits while the other player can still contact it.
- [ ] Give the balloon large horizontal and vertical velocity and confirm each axis stays within its own configured cap.
- [ ] Hit the balloon upward into the ceiling and confirm it bounces back into the arena without bursting or ending the point.
- [ ] Confirm the balloon's arena-boundary rebound follows configured bounce and damping; floor contact ends the point once and shows the burst.
- [ ] Leave the balloon on the ground through several physics frames and confirm one ground event is reported for the round.
- [ ] Compare slow and fast normal contacts, then a dash rescue, and confirm the normal impulse scales within 120-240 while dash rescue remains distinct.

Manual player interaction checks:

- [ ] Confirm the balloon spawns above the server, the server serves first, and each valid normal or dash-rescue contact alternates the eligible player.
- [ ] Confirm an out-of-turn contact faults the touching player, including when both players contact in the same physics tick regardless of callback order.
- [ ] Confirm a downward-directed hit replays the point without scoring, and the same player's second consecutive downward fault deducts one point before the replay.
- [ ] Confirm accepted contacts update last-touch attribution and player priority independently from the repeated-fault penalty.
- [ ] Push both players toward either side wall, confirm neither leaves the arena, then move them back toward the center and confirm both remain controllable.
- [ ] Compare priority and non-priority normal/dash pushes and confirm each resulting push velocity stays within the configured cap.
- [ ] Dash into the other player from either side and confirm the dash pushes them away; dash while pinned under the other player and confirm it frees the blocked player.

Manual match and score checks:

- [ ] Confirm the opening coin toss shows HEADS/P1 or TAILS/P2, with the selected player starting as server and priority.
- [ ] Let a serve fall without another valid touch and confirm the receiver scores; then make another valid touch and confirm the point goes to that toucher's opponent.
- [ ] Confirm each point winner serves next, including the first point after a set.
- [ ] Confirm the HUD shows points and sets; the first player to five points wins a set, 4-4 needs only one more point, and point scores reset while set scores remain.
- [ ] Win three sets and confirm the winner screen appears; select **OK** and confirm the player-count menu returns, then selecting a mode starts a fresh match.
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
- [ ] Confirm a dash pulses faster through its middle, travels at least 55 px, and stretches the same pixelated cape behind the player.
- [ ] Attempt to dash again during cooldown and confirm no second dash begins.
- [ ] Dash through the balloon, verify the rescue impulse follows dash direction, and confirm the same player cape trails during the dash while the rescue zone ends with it.
- [ ] Re-enter the balloon with the same dash activation and confirm it is not hit a second time.
- [ ] Confirm the player with priority can push farther than the other player, including during dash.
- [ ] Confirm a dash can push the other player and free a player trapped under them.
- [ ] Confirm same-tick ties go to the non-priority player and a dash rescue takes priority over a normal hit.
- [ ] Confirm a gold outline identifies the priority player and moves when priority changes.
- [ ] Confirm balloon hits flash visibly and the player's cape remains visible and trails behind during dash, without relying on sound.
