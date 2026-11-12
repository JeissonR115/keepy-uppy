# Proposal

## Why

Keepy Uppy ya tiene un controlador compartido con salto variable, coyote time, buffering, dash, wall jump, wall-slide, escalada, técnicas encadenadas, colisiones de arena, cape y animaciones; no es una implementación vacía. Sin embargo, estos sistemas están repartidos entre el controlador y módulos de técnicas y aún no definen una recreación completa, calibrada y comprobable del comportamiento de las referencias, ni apariencias independientes P1/P2 con cabello procedural para P2. Esta propuesta consolida el contrato de movimiento y colisión, resuelve las brechas medidas y migra la presentación sin romper el juego de globo, el CPU ni la simultaneidad local.

## What Changes

- Reemplazar el comportamiento de movimiento actual por un controlador de plataforma de alta fidelidad inspirado en las referencias, manteniendo una única autoridad de movimiento para ambos jugadores y el CPU; primero comparar cada fórmula/estado actual para preservar técnicas del juego que no contradigan los criterios acordados.
- Definir parámetros físicos centralizados y verificables para aceleración, frenado, control aéreo, gravedad, caída, salto variable, coyote time, jump buffer, wall jump, wall-slide y dash; documentar cada diferencia de unidades y temporización respecto a las fuentes.
- Formalizar estados y transiciones, detección/resolución de suelo, pared y techo, hitboxes independientes del arte, esquinas, plataformas, trampolines y superficies de arena; mantener la geometría y roles actuales de los escenarios salvo defectos demostrados en el controlador.
- Separar la configuración visual del controlador: P1 y P2 tendrán recursos visuales distintos con animaciones correspondientes a estados, idénticas reglas físicas y colisiones, y orientación sincronizada.
- Diseñar para P2 un cabello procedural de segmentos con seguimiento estable de anclajes, inercia y respuesta a velocidad, salto, caída, giro y dash; será cosmético y no colisionable.
- Auditar procedencia y licencias antes de importar contenido externo. El repo A indica MIT para el proyecto pero atribuye los sprites a Nate Kling; el repo B declara que los derechos de sus assets de Celeste son de EXOK y que los usa con permiso, sin ofrecer aquí una licencia de redistribución. Solo incorporar esos sprites/código si se documentan términos aplicables al juego; en caso contrario, el arte debe ser suministrado con derechos o sustituido por arte original equivalente.
- Migrar referencias de escenas, scripts, recursos, instanciación y pruebas; conservar puntuación, turnos, doble toque, contactos, victoria/derrota, menús, controles, pausa, reinicio, mapas, interacciones de superficies y comportamiento de CPU.
- Mantener cada archivo de código bajo 400 líneas y verificar el límite con el script existente `scripts/check_source_line_limits.sh`.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `player-control`: reemplazar y ampliar el contrato observable de locomoción para especificar de forma completa los estados, límites, mecánicas aéreas, colisiones, dash, equivalencia P1/P2 y uso del mismo movimiento para el CPU.
- `pixel-art-presentation`: ampliar el contrato visual para permitir perfiles visuales independientes, animación por estado y cabello procedural de P2, sin acoplamiento con la física ni las colisiones.

## Impact

- Arquitectura y activos observados: Godot 4.7 (`project.godot`, `config/features`), `src/models/player/player_controller.gd`, `player_movement_constants.gd`, `player_input_reader.gd`, `player_jump_techniques.gd`, `player_dash_techniques.gd`, `player_climb_techniques.gd`, `player_surface_techniques.gd`, `player_presentation_controller.gd`, `cape.gd`/`cape.tscn`, `player_placeholder.tscn`, `cpu_controller.gd` y `cpu_interception_predictor.gd`. `src/scenes/levels/arena.tscn` instancia P1 y P2 desde la misma escena con distintos prefijos; `MatchManager`, `LevelManager`, `arena_camera.gd`, `BalloonController` y menús acceden a esos nodos.
- Integraciones a conservar: `src/managers/match_manager.gd`, `src/models/balloon/balloon_controller.gd`, superficies/capas y recursos de arena, `src/scenes/levels/arena*.tscn`, `src/scenes/main/main.tscn`, controles y CPU.
- Pruebas existentes que forman regresión: `tests/test_player_controller.gd`, `test_player_horizontal_movement.gd`, `test_player_jump.gd`, `test_dash.gd`, `test_dash_rescue.gd`, `test_player_collision.gd`, `test_player_wall_climb.gd`, `test_climbable_walls.gd`, `test_arena_surface_interactions.gd`, `test_player_cape.gd`, `test_visual_assets.gd`, `test_visual_feedback.gd`, `test_cpu_controller.gd`, `test_cpu_prediction.gd`, `test_balloon_turns.gd`, `test_round_scoring.gd` y `test_full_match.gd`.
- Cambios OpenSpec ya activos: `celeste-reference-movement-and-tileset-fidelity` y `player-sprite-animation-visuals` contienen contratos y tareas solapados; `animated-player-sprites-and-player-two-tint` figura completo. Antes de implementar, comparar su estado vigente con esta propuesta y cerrar, archivar o integrar explícitamente su trabajo para evitar aplicar dos veces cambios a los mismos archivos.
- Cambios esperados en código: modificar la escena/controlador y módulos existentes de `src/models/player/`, `src/scenes/levels/arena.tscn`, y las referencias mínimas de integración; crear solo módulos que separen responsabilidades demostrables (máquina de estados/tuning/rig de pelo). Eliminar módulos o recursos antiguos únicamente cuando búsqueda de referencias y pruebas confirmen que quedaron sin uso; no se plantea borrar CPU, cape automáticamente ni alterar TileSets.
