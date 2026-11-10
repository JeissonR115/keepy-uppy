# Jugador y bot

## Descripción

`PlayerController` implementa el movimiento para los dos personajes y, cuando se activa, una conducta sencilla de bot para Player 2. Los dos usan la misma escena y se distinguen por `input_prefix`.

## Estructura

- `src/models/player/player_placeholder.tscn`: cuerpo, colisión, sprite geométrico, indicador de prioridad, lector de entrada, área de rescate de dash y estela.
- `src/models/player/player_controller.gd`: movimiento, animación, dash, aceleración, IA y empujes detectados.
- `src/models/player/player_input_reader.gd`: puente a las acciones configuradas.
- `src/models/player/player_action_catalog.gd`: catálogo de teclas y colores.

La escena define un `CharacterBody2D` en la capa de colisión 2. Su máscara 3 le permite interactuar con el entorno (capa 1) y otros jugadores (capa 2). `DashRescueArea` busca el globo en la capa 4.

## Funcionamiento

1. Al iniciar, el controlador configura su `PlayerInputReader` con `input_prefix` y asigna colores de estado.
2. `_physics_process()` calcula el movimiento horizontal, aplica aceleración o frenado y gravedad, procesa salto y ejecuta `move_and_slide()`.
3. El salto usa búfer de entrada y tiempo de coyote; soltar el salto durante el ascenso reduce la velocidad vertical.
4. Dash reemplaza temporalmente la velocidad por `dash_direction * dash_speed`, activa el área de rescate y dibuja una estela. El área solo puede rescatar un globo por dash.
5. Boost acelera durante un periodo con enfriamiento y tope de velocidad horizontal propios.
6. Las colisiones laterales emiten `player_bumped`; `MatchManager` aplica el empuje según prioridad y dash.

## Componentes principales

- `PlayerController._physics_process()`: bucle de control físico.
- `_begin_dash()` / `_end_dash()`: activan y apagan el área y la estela.
- `_on_dash_rescue_area_body_entered()`: llama `BalloonController.apply_dash_rescue()`.
- `try_activate_accelerate()`: inicia boost si terminó el enfriamiento.
- `set_priority_indicator()`: muestra la prioridad visual.
- `show_touch_pixel()`: coloca el marcador del contacto y lo desvanece en dos segundos.
- Señal `player_bumped(player, opponent, while_dashing)`: informa colisión entre personajes.

## Interacciones

El controlador obtiene `MatchManager` y `BalloonController` como hermanos dentro de `Arena`. La entrada humana pasa por `PlayerInputReader`. El bot usa `MatchManager.expected_balloon_player` para moverse, saltar y rescatar solo durante su turno; si detecta al jugador 1 cerca del globo, intenta desafiarlo con dash. El globo recibe la llamada de rescate y la partida decide si el toque era válido.

## Configuración

Los valores son propiedades exportadas en `player_controller.gd`. Los principales son `max_run_speed` (140), `gravity` (900), `jump_velocity` (-340), `air_control` (0.65), `dash_speed` (360), `dash_duration` (0.16), `dash_cooldown` (0.45), `accelerate_speed_multiplier` (1.35), `accelerate_duration` (0.8), `accelerate_cooldown` (4.0) y `accelerate_max_speed` (210). El tamaño del área de rescate se ajusta con `dash_rescue_half_extents`.

El bot usa distancias constantes privadas al principio del script: tolerancia horizontal, alineación de salto, rango de dash y distancia de amenaza.

## Flujo de ejecución

`Arena` instancia `Player1` con prefijo `player_1` y `Player2` con `player_2`. El menú de jugadores establece `Player2.bot_enabled` al elegir un jugador. `MatchManager` llama `reset_for_round()` al iniciar o reiniciar el punto, y `PlayerController` vuelve a procesar movimiento en el siguiente ciclo físico.

Más información: [Controles](controls.md) · [Globo](balloon.md) · [Partida](match.md).
