# Interfaz

## Descripción

La interfaz presenta el marcador y estado de juego, la navegación de pausa y los menús de selección de jugadores, controles y ganador. Se ejecuta en `CanvasLayer`/`Control` para quedar separada de la física del nivel.

## Estructura

- `src/scenes/ui/hud/scoreboard.tscn` y `scoreboard.gd`: HUD, pausa, controles, ganador y aviso temporal de set.
- `src/scenes/ui/menus/pause_menu.tscn` y `pause_menu.gd`: pausa, continuar, reiniciar mediante selección de modo y acceso a controles.
- `src/scenes/ui/menus/control_settings.tscn` y `control_settings.gd`: captura de teclas y restauración.
- `src/scenes/ui/menus/player_count_menu.tscn` y `player_count_menu.gd`: selección de cantidad de jugadores, nivel y acceso a controles.
- `src/scenes/ui/components/menu_keyboard_navigator.gd`: navegación común por teclado.

Las escenas definen el layout y los controles fijos. `ControlSettings` crea desde el catálogo solo las filas repetidas por jugador y acción; el resto de los nodos visuales se conserva en sus escenas.

## Funcionamiento

1. `Scoreboard` conecta señales de `MatchManager` y actualiza puntos, sets, turno, prioridad y mensajes de estado.
2. Escape alterna la pausa durante juego. La pausa mantiene el árbol detenido y presenta Resume, Restart y Controls en una sola columna; W/S cambian la selección vertical y A/D no la alteran. En la confirmación de reinicio, A/D seleccionan Sí o No. F confirma y G regresa.
3. Al iniciar, el selector de jugadores es el único menú abierto. Incluye un botón para abrir la configuración de teclas; al volver, restaura el selector. Tras elegir uno o dos jugadores, se abre el selector de nivel. `Restart` solicita confirmación y, al aceptar, abre primero la selección de jugadores y luego la de nivel. La partida nueva comienza al confirmar el escenario.
4. Controles conserva el estado de pausa al abrirse. Permite recorrer las catorce acciones, cambiar una tecla, restaurar todas las asignaciones o volver al menú que la abrió. Izquierda/Derecha cambia al otro jugador manteniendo la misma acción seleccionada.
5. Al ganar un set, Scoreboard muestra brevemente el ganador, tanteo del set y acumulado de sets. Al completar el partido, el overlay de victoria permite regresar a selección de modo.
6. Los menús que pueden exceder el espacio disponible usan contenedores de scroll vertical que siguen el foco al navegar.

## Componentes principales

- `Scoreboard._input()`: gestiona Escape para pausar/reanudar y cerrar controles; el overlay de ganador conserva su propia navegación.
- `PauseMenu`: emite `controls_requested` y `player_count_requested`; mantiene su estado y opciones en una columna.
- `ControlSettings`: administra el foco, captura teclas y devuelve el control al menú que la abrió.
- `PlayerCountMenu`: aparece al inicio y tras reinicio/victoria, configura `Player2.bot_enabled`, presenta la selección de nivel y permite abrir controles sin superponer menús.
- `MenuKeyboardNavigator`: traduce acciones de Player 1 a señales comunes de movimiento, confirmación y cancelar.
- `MenuNavigationUtils`: comparte la lectura de acciones de menú, el avance cíclico de selección y las actualizaciones de foco/etiquetas.
- `Scoreboard._on_set_won()` y `_on_match_ended()`: despliegan el aviso de set y el overlay final.

## Interacciones

`Scoreboard` consulta `MatchManager` y `PlayerCountMenu`. Pausa solicita las otras pantallas a través de señales. La pantalla de controles usa `ControlSettingsManager`; el navegador compartido consulta las acciones configurables del catálogo. Los menús pueden usar mouse para activar botones además del teclado.

## Configuración

La resolución lógica es 320 × 180; tamaños y offsets de la interfaz se encuentran en `.tscn` o en constantes de los scripts. La pausa usa `process_mode = ALWAYS` para responder mientras el árbol está pausado. Las listas que pueden exceder el área disponible se envuelven en `ScrollContainer` con scroll horizontal deshabilitado y seguimiento de foco.

## Flujo de ejecución

`Scoreboard` se instancia en Arena y conecta señales durante `_ready()`. El menú de jugadores se instancia en Main y aparece al comenzar. Al pausar, los menús no destruyen ni recrean la partida; al seleccionar el nivel se actualiza la arena y `restart_match()` reinicia la partida antes de reanudar.

Más información: [Controles](controls.md) · [Partida](match.md) · [Niveles](levels.md).
