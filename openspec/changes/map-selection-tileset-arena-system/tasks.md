# Tasks

## 1. Arena data and TileSet foundation

- [ ] 1.1 Inspect `foreground_tilesets.png` in Godot, confirm cell spacing and padding, then configure atlas sources and solid/one-way physics layers; verify representative tiles render and collide in the editor.
- [x] 1.2 Create typed arena metadata and an ordered catalog with duplicate-id and invalid-scene handling; verify the classic arena resource loads from the catalog and invalid entries are reported.
- [x] 1.3 Create the classic arena geometry scene with explicit solid, one-way, and scoring surfaces; verify player upward passage/drop-through and balloon contact behavior in the editor/game.
- [x] 1.4 Document how to add an arena resource, map scene, preview, bounds, and spawns in `docs/modules/levels.md`; verify the steps match the actual asset paths and catalog fields.

## 2. Runtime map loading and world configuration

- [x] 2.1 Add a persistent map root and arena loader that replaces only active map geometry; verify player, balloon, match manager, and HUD references still resolve after loading the classic map.
- [x] 2.2 Apply selected arena spawns to the match setup before match restart and configure camera/world bounds from arena data; verify the classic 320 × 180 arena preserves its current framing and positions.
- [x] 2.3 Migrate the fixed floor and walls out of `arena.tscn` into the classic map scene while preserving scoring groups and collision masks; verify balloon scoring still resolves once on the scoring floor and not on transit platforms.

## 3. Arena selection and preview

- [x] 3.1 Replace hard-coded map options with catalog-driven arena entries while preserving player-count selection, keyboard navigation, cancellation, and paused-menu flow; verify adding a catalog entry requires no map-specific menu branch.
- [x] 3.2 Show selected arena preview, name, size or recommended players, and theme with a fallback when preview is absent; verify changing selection updates the displayed metadata.
- [x] 3.3 Load the confirmed map and apply its settings before restarting the match; verify cancel returns to the previous menu and confirm starts on the chosen arena.

## 4. Integration and additional arena

- [x] 4.1 Add a second arena with different bounds and spawn positions using only the resource/catalog and map scene workflow; verify it appears, loads, constrains camera and entities, and does not require map-specific gameplay code.
- [x] 4.2 Update level documentation and relevant scene/module references to describe the implemented catalog-driven flow; verify documented paths and selection behavior match the project.
- [x] 4.3 Run the project in Godot and exercise both arena selections through a complete round; verify no scene/resource errors, correct platform traversal, camera bounds, and exactly one score on designated ground contact.
