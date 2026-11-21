# Proposal

## Why

La interfaz de depuración de Test CPU incluye el menú de opciones, el botón de alternancia y gráficos/indicadores, pero algunos pueden permanecer activos después de salir del modo. Este cambio define un ciclo de vida único para toda esa interfaz y conserva el menú y la presentación normales fuera de Test CPU.

## What Changes

- Limitar el panel, el botón, los gráficos de navegación y los indicadores de estado CPU al modo Test CPU; retirarlos y desactivar sus controles al salir.
- Añadir un botón de alternancia accesible mientras Test CPU está activo, incluso si el panel de opciones está oculto.
- Conservar los controles de simulación y las opciones de capas existentes al mostrar de nuevo el panel.
- Cubrir la alternancia, todos los elementos visuales y controles en las rutas de salida, y el aislamiento de partidas normales con pruebas.

## Capabilities

### New Capabilities

- `cpu-test-debug-ui`: ciclo de vida y visibilidad de la interfaz de depuración exclusiva del modo Test CPU.

### Modified Capabilities

Ninguna. La capacidad de navegación autónoma existente no cambia.

## Impact

- `src/scenes/ui/debug/cpu_debug_panel.gd`, `src/models/player/nav_graph_overlay.gd` y `src/managers/cpu_test_debug_controller.gd`.
- Creación y limpieza de la interfaz en `src/scenes/ui/menus/player_count_menu.gd`.
- Pruebas de controles, salida y aislamiento del modo en `tests/`.
