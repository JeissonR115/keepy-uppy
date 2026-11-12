# Jugador y bot

## Descripción

`PlayerController` implementa el movimiento compartido para los dos personajes. Cuando `bot_enabled` está activo, un `CPUController` hijo selecciona intenciones para el jugador controlado por CPU; ambos usan las mismas físicas y se distinguen por `input_prefix`.

## Estructura

- `src/models/player/player_placeholder.tscn`: cuerpo, colisión, sprite geométrico, anclajes y capa, indicador de prioridad, lector de entrada y área de rescate de dash.
- `src/models/player/player_controller.gd`: orquesta movimiento, callbacks físicos y contactos; es el único propietario de `move_and_slide()`.
- `src/models/player/player_input_reader.gd`: traduce acciones humanas y decisiones del bot a intenciones de movimiento.
- `src/models/player/player_dash_techniques.gd`: técnicas de dash, corrección de esquina, ducking, rescate y eventos de colisión.
- `src/models/player/player_climb_techniques.gd`: detección de muros escalables, velocidad/stamina de escalada, wall-slide y wall-jump.
- `src/models/player/player_surface_techniques.gd` y `player_jump_techniques.gd`: interacciones con plataformas de paso, trampolines, techos y altura variable de salto.
- `src/models/player/player_presentation_controller.gd`: estado visual, coordinación de capa, paleta, pasos y escena compartida de píxel.
- `src/models/player/cpu_controller.gd`: estados de CPU derivados del turno activo y decisiones de movimiento, salto y dash.
- `src/models/player/cpu_interception_predictor.gd`: simulación acotada de intercepción, con entradas explícitas y resultado `{found, position, time}`.
- `src/models/player/cape.tscn` / `cape.gd`: relleno, contorno y simulación Verlet cosmética, sin colisión.
- `src/models/player/player_input_reader.gd`: puente a las acciones configuradas.
- `src/models/player/player_action_catalog.gd`: catálogo de teclas, colores de identidad y paleta de movimiento (correr, ascender y caer).

La escena define un `CharacterBody2D` en la capa de colisión 2. Su máscara incluye el entorno (capa 1), otros jugadores (capa 2) y plataformas unidireccionales (capa 4). `DashRescueArea` busca el globo en la capa 4.

## Funcionamiento

1. Al iniciar, el controlador configura su `PlayerInputReader` con `input_prefix` y asigna colores de estado.
2. `_physics_process()` calcula movimiento horizontal con una carrera automática de hasta 130 px/s, acelera a 1000 px/s² y aplica control aéreo de 0.65. El exceso de velocidad decae a 600 px/s² cuando se mantiene la dirección; al soltar o invertirla, vuelve rápidamente a la velocidad objetivo. No hay una acción separada de boost.
3. La gravedad es de 1100 px/s², limita la caída a 220 px/s y permite una caída rápida de 330 px/s a 350 px/s². El salto combina 0.1 s de coyote, 0.08 s de búfer y hasta 0.2 s de altura variable; saltar con dirección añade 50 px/s horizontales. En una plataforma unidireccional, Abajo + Salto desactiva brevemente solo su capa de colisión para permitir atravesarla.
4. Dash consume una carga, congela solo al jugador durante 0.05 s y después acelera en ocho direcciones durante 0.2 s, recorriendo más de 55 px con un pico de velocidad de 360 px/s. La carga se recupera al aterrizar tras la demora de 0.1 s; el dash termina a 160 px/s. Su área de rescate se activa al terminar el freeze, y la misma capa se estira hacia atrás con el impulso del dash; el área solo puede rescatar un globo por dash.
5. Las técnicas encadenadas conservan el movimiento: saltar desde un dash horizontal hace un super de 260 px/s y -105 px/s; el dash diagonal hacia abajo que aterriza hace un ultra de 1.2x y permite agacharse para un hyper de 325 px/s y -52.5 px/s. Saltar durante un dash hacia arriba junto a una pared hace un rebote de 170 px/s y -160 px/s, con salto variable y dirección forzada por sus ventanas configuradas.
7. Las colisiones laterales emiten `player_bumped`; `MatchManager` aplica el empuje según prioridad y dash.
8. En el aire, empujar hacia una pared limita la caída desde 20 hasta 160 px/s a lo largo de 1.2 s. Saltar junto a una pared hace un wall jump de 130 px/s alejándose y -105 px/s, aun sin Grab. Mantener Grab (R para P1, 4 para P2 por defecto) a 2 px de un TileMapLayer del grupo `climbable_wall` entra en escalada sin gravedad: arriba va a -45 px/s y consume 45.5 de stamina/s; quieto consume 10/s, abajo baja a 80 px/s sin costo. El salto de pared consume 27.5 y fuerza la dirección de salida por 0.16 s. Los límites de arena no se trepan a menos que se marquen explícitamente como escalables. La stamina máxima es 110, solo se restaura en el suelo, y por debajo de 20 el jugador parpadea.
9. `PlayerCape` simula seis filas de partículas Verlet en coordenadas globales después del movimiento, fija sus dos anclajes por tick y dibuja un polígono afinado con vértices redondeados. Cada jugador conserva su propia capa; teletransportes, respawns y puntos no finitos la reinician. Durante el freeze local del dash, la simulación se pausa.
10. El color de capa se deriva del jugador: con dash disponible conserva el tono con saturación mínima 0.9 y brillo 1.0; al gastar dash mantiene el tono con saturación 0.35x y brillo 0.6x hasta aterrizar. El relleno permanece opaco y el contorno usa el color oscurecido 0.4.

## Componentes principales

- `PlayerController._physics_process()`: bucle de control físico.
- `PlayerCape.simulate()`: integra partículas y restricciones de la capa.
- `_begin_dash()` / `_end_dash()`: activan y apagan el área de rescate; la capa acompaña el dash y se estira con su impulso.
- `_on_dash_rescue_area_body_entered()`: llama `BalloonController.apply_dash_rescue()`.
- `set_priority_indicator()`: muestra la prioridad visual.
- `show_touch_pixel()`: instancia `src/scenes/ui/components/touch_pixel.tscn` en coordenadas locales del jugador. Esta escena compartida configura el píxel 4×4, z-index 5 y desvanecimiento de dos segundos.
- Señal `player_bumped(player, opponent, while_dashing)`: informa colisión entre personajes.

## Interacciones

El controlador obtiene `MatchManager` y `BalloonController` como hermanos dentro de `Arena`. La entrada humana pasa por `PlayerInputReader`; la IA delega la predicción en `CPUInterceptionPredictor` y entrega intenciones a `PlayerController`, que sigue siendo el único responsable de ejecutar el movimiento. La FSM del CPU refleja si el juego está inactivo, si le corresponde el toque o si el turno pertenece al rival. En su turno, calcula una intersección descendente limitada por el horizonte de predicción y persigue ese punto; cuando todavía se espera el saque inicial, persigue el globo directamente. En turno rival, evade primero cualquier trayectoria de amenaza; solo si la zona es segura y la decisión de agresividad lo permite, se posiciona en el trayecto entre el rival y el globo. Todos los contactos, incluso los causados accidentalmente al evadir, pasan por la validación normal de `MatchManager`.

## Configuración

La configuración objetivo de movimiento y capa está centralizada en `src/models/player/player_movement_constants.gd`; el proyecto fija la física en 60 ticks por segundo. Además de los valores de carrera, gravedad y salto descritos arriba, incluye los valores de dash, pared, escalada, stamina y feedback de fatiga; la capa usa seis filas, segmentos de 2.5 px, gravedad de 250 px/s² y cuatro iteraciones de restricciones. Los valores se mantienen en el módulo central para que el controlador, la simulación y sus pruebas compartan el mismo ajuste.

Dash, sus estados, pared, escalada, stamina, capa, paleta y sus tiempos usan `player_movement_constants.gd`; la velocidad máxima al correr es 130 px/s. Agacharse reduce la cápsula 6 px y la restaura al salir de la postura. La capa usa segmentos de 2.5 px, gravedad de 250 px/s², damping de 0.90, empuje de viento de 3.0, cuatro iteraciones, taper de 0.6 y reinicio a 48 px. El tamaño del área de rescate se ajusta con `dash_rescue_half_extents`.

`CPUController` expone `reaction_time` (0.1 s, rango 0–2 s), `prediction_error_margin` (8 px, rango 0–64 px), `aggression_level` (0.35, rango 0–1), `dash_threshold_distance` (56 px, rango 0–200 px) y `prediction_horizon` (3 s, rango 0.25–5 s). El error se sortea una vez por turno propio y queda acotado por el margen configurado. La agresividad se sortea al entrar al turno rival. `MatchManager.match_seed_override` permite fijar la semilla (`-1` genera una nueva); cada CPU deriva su flujo pseudoaleatorio local de la semilla de partida y el prefijo del jugador, sin consumir el RNG global al decidir.

## Flujo de ejecución

`Arena` instancia `Player1` con prefijo `player_1` y `Player2` con `player_2`. El menú de jugadores establece `Player2.bot_enabled` al elegir un jugador. `MatchManager` llama `reset_for_round()` al iniciar o reiniciar el punto, y `PlayerController` vuelve a procesar movimiento en el siguiente ciclo físico.

Más información: [Controles](controls.md) · [Globo](balloon.md) · [Partida](match.md).
