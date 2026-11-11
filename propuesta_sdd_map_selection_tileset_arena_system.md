# SDD Proposal: Map Selection Menu with Preview & Dynamic TileSet Arena System

## 1. Context & Objectives

This document proposes the architectural specification for implementing:

1. A **Map Selection UI System** with real-time or dynamic previews.
2. A **TileSet-Based Arena System** refactoring using the spritesheet at `res://assets/sprites/arena/foreground_tilesets.png`.
3. Specialized physics interactions for **One-Way Platforms** (passable bottom-to-top by players/balloon, solid top-to-bottom for scoring/popping).
4. **Arena Boundary Mechanics** (invisible dynamic walls/collision limits).
5. **Scale & Physics Multipliers** based on arena size (larger arenas expand balloon trajectory & character momentum/momentum buildup).
6. **Extensible Architecture** for future hazards/mechanics (trampolines, spikes, slow-sand, and wind effects).

---

## 2. Requirements Breakdown

### 2.1 Map Selection Menu with Preview

- **UI Grid / Carousel:** List available arenas registered via custom Resource files (`ArenaData`).
- **Interactive/Render Preview:** Render a miniaturized preview of the selected map (using a `SubViewportContainer` + `SubViewport` or pre-rendered texture thumbnail).
- **Metadata Display:** Map Name, Recommended Players, Size Classification (Small, Medium, Large), and Theme/TileSet used.

### 2.2 TileSet Refactoring (`res://assets/sprites/arena/foreground_tilesets.png`)

- **TileMap / TileSet Setup:**
  - Source file: `res://assets/sprites/arena/foreground_tilesets.png`.
  - Selected default theme: e.g., `grass` or `stone` for Solid Ground, combined with platform edges from `scenery` or standard horizontal sections for One-Way platforms.
- **Physics Layer Config:**
  - **Layer 1: Solid Ground (Terrain).** Full physics collision box. Stops players, balloons, and objects.
  - **Layer 2: One-Way Platforms.** Configured with `one_way_collision = true`.
- **One-Way Platform Rule Engine:**
  - Players & Balloon pass from **Bottom to Top** seamlessly (`one_way_collision`).
  - When the Balloon hits the platform from **Top to Bottom**, it detects a floor impact -> triggers point score / balloon pop logic.

### 2.3 Arena Boundaries & Scaling System

- **Invisible World Boundaries (`StaticBody2D` or dynamic `WorldBoundary2D` / `Area2D`):** Automatically wraps around the perimeter defined in `ArenaData` to prevent the balloon/players from escaping.
- **Arena Scale Physics Multipliers (`ArenaData.scale_factor`):**
  - **Large Arenas:** Adjust balloon gravity/drag so it travels longer distances ($v_{\text{balloon}} \cdot \text{scale\_multiplier}$).
  - **Character Momentum Accumulation:** Add a sprint/momentum build-up curve for player speed when running continuously in larger spaces ($v_{\text{max\_speed}} = v_{\text{base}} + \text{accumulated\_momentum}$).

### 2.4 Extensible Tile & Hazard Architecture

- Dynamic layer/custom data system on `TileSet` or trigger `Area2D` components to easily integrate future features:
  - **Trampoline / Bouncy Blocks** (High elasticity physics material / bounce force).
  - **Spikes / Hazards** (Trigger damage/point loss on contact).
  - **Slow Blocks / Sand** (Reduces player movement speed & acceleration).
  - **Wind Zones / Global Wind Vector** (Stubs prepared for `Vector2` wind modifiers affecting balloon trajectory).

---

## 3. Data Architecture & Data Models

### 3.1 `ArenaData` Resource Definition (`res://scripts/resources/arena_data.gd`)

```gdscript
class_name ArenaData
extends Resource

enum ArenaSize { SMALL, MEDIUM, LARGE }

@export var id: String = "grass_classic"
@export var name: String = "Grassland Arena"
@export_multiline var description: String = "A standard medium-sized arena."
@export var preview_texture: Texture2D
@export var tilemap_scene: PackedScene
@export var size: ArenaSize = ArenaSize.MEDIUM
@export var arena_bounds: Rect2 = Rect2(0, 0, 1920, 1080)

# Physics Adjustments
@export var balloon_gravity_scale: float = 1.0
@export var balloon_speed_multiplier: float = 1.0
@export var max_player_speed_bonus: float = 0.0
```

---

## 4. System Implementation Plan

### Phase 1: TileSet Configuration

1. Import `res://assets/sprites/arena/foreground_tilesets.png` into Godot 4 `TileSet`.
2. Define a standard grid size (e.g., 16x16 or 8x8 based on sprite cell layout).
3. Create two main physics layers:
   - **Physics Layer 0 (Solid Ground):** Standard collision shape.
   - **Physics Layer 1 (OneWay Platform):** Collision shape enabled with `one_way = true` and `one_way_margin`.

### Phase 2: Dynamic Arena Loader & Boundaries

1. Create `ArenaController.gd` to instantiate maps based on `ArenaData`.
2. Programmatic creation of 4 `CollisionShape2D` walls bounding the `arena_bounds` rectangle.
3. Apply size-dependent physics settings to balloon and players upon arena load.

### Phase 3: Character Speed Accumulation Engine

1. Update `PlayerController.gd` with a momentum accumulation timer/variable:
   $$\text{current\_speed} = \min(\text{base\_speed} + \text{momentum\_rate} \cdot \Delta t, \text{max\_allowed\_speed})$$
2. Reset momentum when changing direction sharply or stopping.

### Phase 4: UI Map Selection with Live Preview

1. Create `MapSelectionMenu.tscn`.
2. Grid container populated with registered `ArenaData` resources.
3. Preview container displaying `SubViewport` rendering the selected map layout or dynamic thumbnail card.

---

## 5. Extensibility Roadmap (Future Proofing)

| Element             | Mechanics / Trigger Implementation                 | Tile / Node Strategy                              |
| :------------------ | :------------------------------------------------- | :------------------------------------------------ |
| **Trampoline**      | Adds upward impulse on collision                   | Custom Data Layer `is_bouncy` or `Area2D` overlay |
| **Spikes (Chuzos)** | Immediately pops balloon or stuns player           | Custom Data Layer `is_hazard` with damage signal  |
| **Sand (Arena)**    | Applies dampening multiplier to player velocity    | Custom Data Layer `friction` modifier             |
| **Wind System**     | Applies continuous `Vector2` force to Balloon body | Global `WindManager` broadcasting force vectors   |

---

## 6. Prompt for Code Generation

```text
Please implement the proposed SDD system in Godot 4 (GDScript):
1. Create the `ArenaData` resource script.
2. Build `MapSelectionMenu.tscn` with a list of maps, details panel, and preview display.
3. Build the dynamic `ArenaBase.gd` node that reads `ArenaData`, spawns invisible collision walls around `arena_bounds`, and sets environment scale physics for the balloon and player momentum.
4. Set up the `TileMap` configuration guidelines for `res://assets/sprites/arena/foreground_tilesets.png` with One-Way collision layers.
```
