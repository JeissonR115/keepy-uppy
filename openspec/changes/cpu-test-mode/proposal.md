# Proposal

## Why

La CPU de navegación existente puede ejecutar una ruta recibida externamente, pero no selecciona por sí misma el destino ni proporciona una explicación legible de su decisión. Un modo de prueba autónomo permitirá observar y evaluar navegación, intercepción y decisiones en las arenas sin iniciar un proceso Python.

## What Changes

- Añadir un modo **Test CPU** con selección de arena desde el catálogo, partida jugador contra CPU y retorno al menú.
- Hacer que la CPU use los grafos versionados incluidos en el juego para elegir destinos automáticamente, predecir la intercepción y ejecutar una FSM de saque, posicionamiento, golpe y evasión, sin faltas por fuera de turno ni golpes descendentes.
- Cargar grafos por arena desde `res://data/nav_graphs/`; cuando falte un grafo, continuar con el cerebro local actual.
- Exponer telemetría de decisión por tick y presentar ruta, destino, trayectoria predicha y explicación en un overlay/panel con capas, pausa, paso de tick y cámara lenta.
- Mantener el modo normal, el modo de dos jugadores y la interfaz actual sin cambios de comportamiento ni overlay.
- Añadir pruebas headless de predictor, selección de destino, FSM, telemetría, carga/fallback y aislamiento de modos.

## Capabilities

### New Capabilities

- `cpu-test-mode`: modo jugable local para navegación autónoma de CPU, explicación de decisiones y depuración visual.

### Modified Capabilities

Ninguna. Las reglas actuales de control, contacto y puntuación no cambian; el modo nuevo debe respetarlas.

## Impact

- CPU: `src/models/player/CPUBrain` y sus implementaciones, `CPUController`, `NavGraphBrain`, predictor y `NavGraphOverlay` bajo `src/models/player/`.
- Grafos por arena en `res://data/nav_graphs/`, originados en `../keepy-uppy-ai/graphs/` como copias versionadas de solo lectura.
- Selección/flujo de arena: `src/scenes/main/main.tscn`, `src/scenes/ui/menus/player_count_menu.*`, `src/managers/level_manager.gd` y catálogo.
- Escenas de UI y cobertura headless bajo `tests/`.
- Sin dependencia de Python ni cambios al protocolo TCP/JSON. El modo normal conserva su comportamiento vigente.
