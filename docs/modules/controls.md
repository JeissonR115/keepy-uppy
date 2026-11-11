# Controles y asignaciones

## Descripción

Este módulo define las acciones para ambos jugadores, las traduce desde el Input Map de Godot y permite reasignar teclas. Las preferencias se guardan localmente en `user://controls.cfg`.

## Estructura

- `src/models/player/player_action_catalog.gd`: nombres, acciones, colores y teclas predeterminadas.
- `src/models/player/player_input_reader.gd`: lectura de acciones de un jugador.
- `src/managers/control_settings_manager.gd`: validación, carga, guardado y restauración.
- `src/scenes/ui/menus/control_settings.gd` y `.tscn`: menú para reasignar y restaurar controles.
- `src/scenes/ui/menu_keyboard_navigator.gd`: entradas compartidas para los menús.
- `project.godot`: acciones y asignaciones iniciales del Input Map.

## Funcionamiento

1. `ControlSettingsManager._enter_tree()` carga el archivo local. Si no existe, es inválido o está incompleto, restaura las asignaciones predeterminadas.
2. `PlayerActionCatalog` construye nombres como `player_1_left` y `player_2_jump` a partir del prefijo y la acción.
3. Cada `PlayerInputReader` recibe el prefijo correspondiente y usa `Input.get_axis`, `Input.is_action_just_pressed` y `Input.is_action_just_released`.
4. En el menú, elegir una acción inicia captura de teclado. El gestor valida la tecla, actualiza el Input Map y guarda el mapa completo.
5. La navegación de menús lee las acciones de Player 1 para arriba, abajo, confirmar y volver; mantiene W/S/F/G como teclas físicas de respaldo.

## Componentes principales

- `PlayerActionCatalog.PLAYERS`: datos para P1/P2, incluidas las siete acciones por jugador.
- `ControlSettingsManager.validate_binding()`: rechaza entradas que no sean teclas, teclas reservadas, combinaciones modificadas y duplicados entre acciones configurables.
- `try_set_binding()`: actualiza el Input Map y revierte el cambio si no se puede guardar.
- `load_or_restore_settings()`: exige versión compatible y un conjunto completo de acciones.
- `restore_default_bindings()`: restaura y guarda las teclas predeterminadas.
- `MenuKeyboardNavigator`: emite `moved`, `confirmed` y `cancelled` para el menú activo.

## Interacciones

`PlayerController` consulta `PlayerInputReader`; el bot también usa la configuración de acciones para su prefijo, aunque su conducta la decide `PlayerController`. Los menús `PauseMenu`, `PlayerCountMenu`, `ControlSettings` y la vista de ganador usan `MenuKeyboardNavigator`. `ControlSettings` llama a `ControlSettingsManager`; el gestor modifica el Input Map utilizado inmediatamente por los jugadores.

## Configuración

| Acción | Jugador 1 | Jugador 2 |
|---|---|---|
| Izquierda / derecha | A / D | Flechas izquierda / derecha |
| Arriba / abajo | W / S | Flechas arriba / abajo |
| Saltar | F | 1 |
| Dash | G | 2 |
| Agarrar pared | R | 4 |

La carrera acelera automáticamente hasta 130 px/s al mantener una dirección; no hay una tecla separada de boost. Las claves de boost que queden en archivos de configuración antiguos se ignoran.

Los nombres y las teclas predeterminadas están en `PlayerActionCatalog`. `ControlSettingsManager.SETTINGS_VERSION` es `1`, la ruta local es `user://controls.cfg`; Escape, F1–F12, modificadores y combinaciones con modificadores se reservan.

## Flujo de ejecución

La escena `Main` instancia `ControlSettingsManager` antes de cargar la arena. El gestor aplica las asignaciones al entrar al árbol. Durante el juego, los lectores consultan el Input Map cada frame de física. La pantalla de controles aparece desde pausa, mantiene la partida pausada y regresa al menú de pausa al cerrar.

Más información: [Jugador y bot](player.md) · [Interfaz](ui.md).
