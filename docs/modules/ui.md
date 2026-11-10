# Interfaz

## Descripción

La interfaz presenta el marcador y estado de juego, la navegación de pausa y los menús de selección de jugadores, controles y ganador. Se ejecuta en `CanvasLayer`/`Control` para quedar separada de la física del nivel.

## Estructura

- `src/scenes/ui/scoreboard.tscn` y `scoreboard.gd`: HUD, pausa, controles, ganador y aviso temporal de set.
- `src/scenes/ui/pause_menu.tscn` y `pause_menu.gd`: pausa, continuar, reiniciar mediante selección de modo y acceso a controles.
- `src/scenes/ui/control_settings.tscn` y `control_settings.gd`: captura de teclas y restauración.
- `src/scenes/ui/player_count_menu.tscn` y `player_count_menu.gd`: selección de un jugador contra bot o dos jugadores.
- `src/scenes/ui/menu_keyboard_navigator.gd`: navegación común por teclado.

## Funcionamiento

1. `Scoreboard` conecta señales de `MatchManager` y actualiza puntos, sets, turno, prioridad y mensajes de estado.
2. Escape alterna la pausa durante juego. La pausa mantiene el árbol detenido; W/S mueve la selección, F confirma y G regresa.
3. `Restart` abre la selección de modo. Al elegir 1 o 2 jugadores, `PlayerCountMenu` reinicia el MatchManager y configura si `Player2` usa el bot.
4. Controles conserva el estado de pausa al abrirse. Permite recorrer las catorce acciones, cambiar una tecla, restaurar todas las asignaciones o volver a pausa.
5. Al ganar un set, Scoreboard muestra brevemente el ganador, tanteo del set y acumulado de sets. Al completar el partido, el overlay de victoria permite regresar a selección de modo.
6. Los menús de pausa, controles y selección de jugadores incluyen contenedores de scroll vertical que siguen el foco al navegar.

## Componentes principales

- `Scoreboard._input()`: gestiona Escape y evita abrir pausa sobre selección de modo o ganador.
- `PauseMenu`: emite `controls_requested` y `player_count_requested`; mantiene su estado y opciones.
- `ControlSettings`: administra el foco, captura teclas y emite `returned_to_pause` al cerrar.
- `PlayerCountMenu`: configura `Player2.bot_enabled`, reinicia si se abrió desde reinicio o victoria y reanuda el árbol.
- `MenuKeyboardNavigator`: traduce acciones de Player 1 a señales comunes de movimiento, confirmación y cancelar.
- `Scoreboard._on_set_won()` y `_on_match_ended()`: despliegan el aviso de set y el overlay final.

## Interacciones

`Scoreboard` consulta `MatchManager` y `PlayerCountMenu`. Pausa solicita las otras pantallas a través de señales. La pantalla de controles usa `ControlSettingsManager`; el navegador compartido consulta las acciones configurables del catálogo. Los menús pueden usar mouse para activar botones además del teclado.

## Configuración

La resolución lógica es 320 × 180; tamaños y offsets de la interfaz se encuentran en `.tscn` o en constantes de los scripts. La pausa usa `process_mode = ALWAYS` para responder mientras el árbol está pausado. Las listas que pueden exceder el área disponible se envuelven en `ScrollContainer` con scroll horizontal deshabilitado y seguimiento de foco.

## Flujo de ejecución

`Scoreboard` se instancia en Arena y conecta señales durante `_ready()`. El menú de jugadores se instancia en Main y aparece al comenzar. Al pausar, los menús no destruyen ni recrean la partida; al seleccionar modo desde reinicio o victoria se ejecuta `restart_match()` antes de reanudar.

Más información: [Controles](controls.md) · [Partida](match.md) · [Niveles](levels.md).
