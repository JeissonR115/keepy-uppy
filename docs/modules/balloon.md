# Globo y física

## Descripción

El globo es un cuerpo rígido 2D con gravedad reducida. El controlador convierte los contactos de jugador en impulsos con dirección e intensidad calculadas a partir de la posición y velocidad del jugador.

## Estructura

- `src/models/balloon/balloon_placeholder.tscn`: cuerpo rígido, forma circular, globo geométrico, cuerda, explosión visual y área de contacto.
- `src/models/balloon/balloon_controller.gd`: física, detección de contactos, cálculo de impulsos y señales.

El cuerpo está en la capa 4 y colisiona con las capas 1 y 2. `PlayerContactArea` detecta jugadores en la capa 2. El globo colisiona con ambos personajes y el entorno.

## Funcionamiento

1. `reset_round()` sitúa el globo sobre el jugador servidor, limpia velocidades y estados. Si espera el primer toque, `_integrate_forces()` mantiene su posición y velocidad en cero.
2. Al entrar un jugador en el área, el controlador comprueba el enfriamiento por jugador y activa la gravedad tras el primer contacto.
3. Un contacto normal combina el vector entre jugador y globo con la dirección de movimiento del jugador. La rapidez de aproximación y velocidad del jugador influyen en la fuerza.
4. Dash usa `apply_dash_rescue()` y la dirección del dash para calcular un impulso distinto y más fuerte.
5. El impulso queda pendiente hasta que `MatchManager` valida quién tenía el turno; entonces `apply_pending_contact()` ajusta la velocidad y aplica el impulso.
6. El integrador reduce gradualmente el movimiento y limita las velocidades. El piso activa `ground_touched` una vez por punto y muestra `GroundBurst`.

## Componentes principales

- `player_hit(player)` y `dash_rescued(player, dash_direction)`: contactos que `MatchManager` registra para resolver el turno.
- `ground_touched`: contacto con un cuerpo del grupo `scoring_ground`.
- `contact_visualized(player, balloon_position)`: permite que la interfaz coloque los marcadores del contacto.
- `apply_pending_contact()`: aplica un contacto reservado y devuelve la velocidad resultante para evaluar golpe descendente.
- `reset_round()`: restablece espera, velocidad, enfriamientos y efecto de suelo.
- `show_contact_pixel()`: dibuja el punto de impacto y lo desvanece en dos segundos.

## Interacciones

`PlayerController` puede iniciar un rescate de dash. `MatchManager` escucha las señales de contacto y del piso, valida el turno y el sentido del golpe. `Scoreboard` escucha la señal visual y coloca un píxel sobre el globo y otro en la zona de contacto del jugador.

## Configuración

Los valores exportados viven en `balloon_controller.gd`. Parámetros principales: `gravity_strength` (0.14), `rebound_strength` (0.28), `max_fall_speed` (90), `max_hit_speed` (220), `max_horizontal_speed` (220), `air_resistance` (0.055), radios de colisión y contacto (9 y 16). Impulsos normales y de dash se ajustan por separado con `player_hit_impulse`, `dash_rescue_impulse` y sus límites.

El material físico del globo usa rebote 0.28. Las paredes y el techo pertenecen a la escena de geometría activa; solo la capa de suelo del grupo `scoring_ground` termina la jugada.

## Flujo de ejecución

`MatchManager` coloca el globo al seleccionar servidor. El primer toque válido lo libera. Después alterna el jugador esperado. Cuando el cuerpo toca el suelo, el controlador emite una sola señal hasta que se llame a `reset_round()`.

Más información: [Partida y puntuación](match.md) · [Jugador](player.md) · [Arena](levels.md).
