# Partida y puntuación

## Descripción

`MatchManager` concentra el estado de ronda, turnos de toque, prioridad, saques, faltas y marcador. No dibuja la interfaz; emite señales que escucha `Scoreboard`.

## Estructura

- `src/managers/match_manager.gd`: controlador competitivo instanciado como nodo `MatchManager` dentro de `Arena`.
- `src/scenes/levels/arena.tscn`: contiene las referencias hermanas `Player1`, `Player2` y `Balloon` que el gestor usa.
- `src/scenes/ui/hud/scoreboard.gd`: escucha señales para presentar resultados y estado.

## Funcionamiento

1. `_ready()` conecta señales del globo y jugadores y comienza una partida.
2. `_start_new_match()` limpia puntuaciones y estado, sortea el servidor (salvo que se use `coin_toss_override`), reinicia jugadores y coloca el globo.
3. `set_next_server()` define servidor, último jugador que tocó, jugador esperado y prioridad.
4. Los contactos del globo se guardan en listas hasta `resolve_pending_contacts()`. El método comprueba todos los candidatos del mismo ciclo; un contacto fuera de turno se resuelve como falta aunque el callback válido haya llegado primero.
5. Un golpe cuya velocidad vertical resultante apunta hacia abajo se marca como falta y se repite el saque sin sumar punto. Si el mismo jugador comete esa falta dos veces consecutivas, se le descuenta un punto (el marcador no baja de cero) y el siguiente saque pasa al rival.
6. Un toque fuera de turno concede punto al rival del infractor. En jugada normal, solo se puntúa al tocar el piso; suma el último jugador que tocó válidamente el globo. El piso antes de cualquier toque válido repite el saque.
7. Al llegar a `target_score`, se registra el set, se emite su resultado y se reinicia el marcador de puntos. Al llegar a `sets_to_win`, la partida pasa a `COMPLETE` y emite `match_ended`.
8. El siguiente saque normal corresponde al ganador del punto. Los reinicios esperan `round_intermission` antes de volver a colocar jugadores y globo.

## Componentes principales

- Estados `ACTIVE`, `ROUND_OVER`, `COMPLETE`.
- `expected_balloon_player`, `last_valid_toucher`, `round_server` y `next_server` representan turnos y saque.
- `priority_player` se usa para la fuerza de empujones entre jugadores; no determina quién debe tocar el globo.
- Señales principales: `balloon_turn_changed`, `score_changed`, `round_ended`, `set_won`, `set_ended`, `match_ended`, `downward_fault_replayed` y `priority_changed`.
- `_on_player_bumped()` aplica empujones normales y de dash, con excepciones para el bot.

## Interacciones

El globo informa de toques y piso; los jugadores aportan colisiones y posición. `MatchManager` llama `BalloonController.apply_pending_contact()` después de validar el turno. La interfaz usa las señales para actualizar marcador, estado, prioridad, turno y overlays. El menú de selección puede invocar `restart_match()`.

## Configuración

Valores exportados en `match_manager.gd`: `target_score` (5 puntos), `sets_to_win` (3), `round_intermission` (1.5 s), `balloon_spawn_offset` (30 px), posiciones de inicio (72,144) y (248,144), `coin_toss_override` (-1 para sorteo aleatorio), `match_seed_override` (-1 para generar una semilla de IA nueva por partida), fuerzas de empuje y `max_push_speed` (320).

## Flujo de ejecución

La partida comienza al instanciar la arena. El menú inicial pausa la escena hasta elegir uno o dos jugadores; luego habilita el bot opcional. Durante juego, el gestor resuelve contactos cada frame de proceso. Al terminar un punto reinicia el saque; al ganar el último set, la interfaz muestra ganador y espera confirmación para volver al menú de jugadores.

Más información: [Globo](balloon.md) · [Interfaz](ui.md) · [Arena](levels.md).
