# Jugador y bot

## Descripción

`PlayerController` implementa el movimiento compartido para los dos personajes. Cuando `bot_enabled` está activo, un `CPUController` hijo selecciona intenciones para el jugador controlado por CPU; ambos usan las mismas físicas y se distinguen por `input_prefix`.

## Estructura

- `src/models/player/player_placeholder.tscn`: cuerpo animado, capa de efectos, colisión, anclajes y capa, indicador de prioridad, lector de entrada y área de rescate de dash.
- `src/models/player/player_controller.gd`: orquesta movimiento, callbacks físicos y contactos; es el único propietario de `move_and_slide()`.
- `src/models/player/player_input_reader.gd`: traduce acciones humanas y decisiones del bot a intenciones de movimiento.
- `src/models/player/player_dash_techniques.gd`: técnicas de dash, corrección de esquina, ducking, rescate y eventos de colisión.
- `src/models/player/player_climb_techniques.gd`: detección de muros escalables, velocidad/stamina de escalada, wall-slide y wall-jump.
- `src/models/player/player_surface_techniques.gd` y `player_jump_techniques.gd`: interacciones con plataformas de paso, trampolines, techos y altura variable de salto.
- `src/models/player/player_visual_profile.gd` más `player_visual_profile_p1.tres`/`p2.tres`: recursos independientes de frames, tintes, anclajes y mapas de clips.
- `src/models/player/player_presentation_controller.gd`: selección de clips por perfil, animaciones de estado, cape/hair cosméticos, pasos y escena compartida de píxel.
- `src/models/player/player_hair.gd` / `player_hair.tscn`: dos trazos P2 de segmentos limitados, sin objetos físicos.
- `src/models/player/cpu_controller.gd`: estados de CPU derivados del turno activo y decisiones de movimiento, salto y dash.
- `src/models/player/cpu_interception_predictor.gd`: simulación acotada de intercepción según el grupo de suelo puntuable, con resultado `{found, position, time}`.
- `src/models/player/cape.tscn` / `cape.gd`: relleno, contorno y simulación Verlet cosmética para P1, sin colisión.
- `src/models/player/player_action_catalog.gd`: catálogo de teclas, colores de identidad y paleta de movimiento (correr, ascender y caer).

La escena define un `CharacterBody2D` en la capa 2 (`collision_layer = 2`) con máscara `7` (capas 1, 2 y 3: entorno, jugadores y superficies/platforms). La plataforma unidireccional se identifica como bitmask `4` (índice de capa 3). La cápsula física es independiente del sprite: radio 5 px, altura 23 px y offset `(0, 0.5)`. `DashRescueArea` usa máscara `4` para detectar globos en ese bit de capa.

## Funcionamiento

1. Al iniciar, el controlador configura su `PlayerInputReader` con `input_prefix` y asigna colores de estado.
2. `_physics_process()` calcula movimiento horizontal con una carrera automática de hasta 130 px/s, acelera y frena a 1500 px/s² y aplica control aéreo de 0.65. El exceso de velocidad decae a 600 px/s² cuando se mantiene la dirección; al soltar o invertirla, vuelve a la velocidad objetivo. No hay una acción separada de boost. P1, P2 y CPU entregan su intención al mismo controlador y usan estos parámetros compartidos.
3. La gravedad es de 1100 px/s², limita la caída a 220 px/s y permite una caída rápida de 330 px/s a 350 px/s². El salto inicia a -250 px/s, recorta a la mitad la velocidad ascendente al soltar temprano y combina 0.1 s de coyote, 0.08 s de búfer y hasta 0.2 s de altura variable; saltar con dirección añade 50 px/s horizontales. En una plataforma unidireccional, Abajo + Salto desactiva brevemente solo su capa de colisión para permitir atravesarla.
4. Dash consume una carga, congela solo al jugador durante 0.05 s y después acelera en ocho direcciones durante 0.2 s, recorriendo más de 55 px con un pico de velocidad de 360 px/s. La carga se recupera al aterrizar tras la demora de 0.1 s; el dash termina a 160 px/s. El controlador conserva si el dash comenzó apoyado para permitir un super-jump horizontal aunque el movimiento con velocidad vertical cero deje de reportar contacto con el piso; la ultra diagonal sigue necesitando contacto real. Su área de rescate se activa al terminar el freeze y solo puede rescatar un globo por dash.
5. Las técnicas encadenadas conservan el movimiento: saltar desde un dash horizontal hace un super de 260 px/s y -105 px/s; el dash diagonal hacia abajo que aterriza hace un ultra de 1.2x y permite agacharse para un hyper de 325 px/s y -52.5 px/s. Saltar durante un dash hacia arriba junto a una pared hace un rebote de 170 px/s y -160 px/s, con salto variable y dirección forzada por sus ventanas configuradas.
6. `AnimatedSprite2D` recibe sus `SpriteFrames`, mapas de estado, anclajes y tinte desde perfiles separados P1/P2. Ambos perfiles usan los recursos de cuerpo y efectos ya presentes en el proyecto; P2 mantiene la modulación naranja actual. `idle`, carrera lenta/rápida, salto, ascenso, caída normal/rápida, dash, escalada y wall-slide se eligen de los estados actuales. El efecto `jump` y la entrada a `climb` se reproducen una vez; `climbLoop` y `still` son capas de estado, y `danger` responde a `player_bumped`. Los efectos se dibujan por encima del cuerpo y no participan en colisiones.
7. El arte mide 32 × 32 px por fotograma y el cuerpo está desplazado 4 px hacia arriba para apoyar sus pies en el borde inferior de la cápsula. La geometría conservada en `player_placeholder.tscn` es una cápsula de radio 5 px, altura 23 px y centro desplazado 0.5 px. La capa, el indicador de prioridad y los anclajes mantienen sus nodos independientes.
8. Las colisiones laterales emiten `player_bumped`; `MatchManager` aplica el empuje según prioridad y dash.
9. En el aire, empujar hacia una pared limita la caída desde 20 hasta 160 px/s a lo largo de 1.2 s. Saltar junto a una pared hace un wall jump de 130 px/s alejándose y -105 px/s, aun sin Grab. Mantener Grab (R para P1, 4 para P2 por defecto) a 2 px de un TileMapLayer del grupo `climbable_wall` entra en escalada sin gravedad: arriba va a -45 px/s y consume 45.5 de stamina/s; quieto consume 10/s, abajo baja a 80 px/s sin costo. El salto de pared consume 27.5 y fuerza la dirección de salida por 0.16 s. Los límites de arena no se trepan a menos que se marquen explícitamente como escalables. La stamina máxima es 110, solo se restaura en el suelo, y por debajo de 20 el jugador parpadea.
10. `PlayerCape` simula seis filas de partículas Verlet en coordenadas globales después del movimiento, fija sus dos anclajes por tick y dibuja un polígono afinado con vértices redondeados. Solo P1 la usa; teletransportes, respawns y puntos no finitos la reinician. Durante el freeze local del dash, la simulación se pausa.
11. La cape se conserva solo en P1: con dash disponible sigue el tono de identidad con saturación mínima 0.9 y brillo 1.0; al gastar dash conserva el tono con saturación 0.35x y brillo 0.6x hasta aterrizar. El relleno permanece opaco y el contorno usa el color oscurecido 0.4.
12. `PlayerHair` se instancia solo para P2 desde los anclajes de su perfil, como adorno en lugar de la cape. Dos líneas de seis puntos usan segmentos de 2.5 px, inercia amortiguada y seguimiento del facing, velocidad y dirección de dash; limita delta a 1/30 s y se reinicia en `reset_for_round()`. Es geometría `Line2D` cosmética, sin cuerpos, áreas ni señales de contacto.

## Componentes principales

- `PlayerController._physics_process()`: bucle de control físico.
- `PlayerCape.simulate()`: integra partículas y restricciones de la capa.
- `_update_cosmetic_motion()`: avanza cape P1 o pelo P2 después del movimiento y respeta el freeze local.
- `_begin_dash()` / `_end_dash()`: activan y apagan el área de rescate; la capa acompaña el dash y se estira con su impulso.
- `_on_dash_rescue_area_body_entered()`: llama `BalloonController.apply_dash_rescue()`.
- `set_priority_indicator()`: muestra la prioridad visual.
- `show_touch_pixel()`: instancia `src/scenes/ui/components/touch_pixel.tscn` en coordenadas locales del jugador. Esta escena compartida configura el píxel 4×4, z-index 5 y desvanecimiento de dos segundos.
- Señal `player_bumped(player, opponent, while_dashing)`: informa colisión entre personajes.

## Interacciones

El controlador obtiene `MatchManager` y `BalloonController` como hermanos dentro de `Arena`. La entrada humana pasa por `PlayerInputReader`; la IA delega la predicción en `CPUInterceptionPredictor` y entrega intenciones a `PlayerController`, que sigue siendo el único responsable de ejecutar el movimiento. La FSM del CPU refleja si el juego está inactivo, si le corresponde el toque o si el turno pertenece al rival. En su turno, calcula una intersección descendente limitada por el horizonte de predicción y persigue ese punto; cuando todavía se espera el saque inicial, persigue el globo directamente. En turno rival, evade primero cualquier trayectoria de amenaza; solo si la zona es segura y la decisión de agresividad lo permite, se posiciona en el trayecto entre el rival y el globo. Todos los contactos, incluso los causados accidentalmente al evadir, pasan por la validación normal de `MatchManager`.

## Configuración

La configuración objetivo de movimiento y capa está centralizada en `src/models/player/player_movement_constants.gd`. `project.godot` no declara un override para `physics/common/physics_ticks_per_second`; Godot usa su valor predeterminado de 60 ticks por segundo. Además de los valores de carrera, gravedad y salto descritos arriba, incluye los valores de dash, pared, escalada, stamina y feedback de fatiga; la capa usa seis filas, segmentos de 2.5 px, gravedad de 250 px/s² y cuatro iteraciones de restricciones. Los valores se mantienen en el módulo central para que el controlador, la simulación y sus pruebas compartan el mismo ajuste.

Dash, sus estados, pared, escalada, stamina, capa, paleta y sus tiempos usan `player_movement_constants.gd`; la velocidad máxima al correr es 130 px/s. Agacharse reduce la cápsula 6 px y la restaura al salir de la postura. La capa usa segmentos de 2.5 px, gravedad de 250 px/s², damping de 0.90, empuje de viento de 3.0, cuatro iteraciones, taper de 0.6 y reinicio a 48 px. El tamaño del área de rescate se ajusta con `dash_rescue_half_extents`.

`CPUController` expone `reaction_time` (0.1 s, rango 0–2 s), `prediction_error_margin` (8 px, rango 0–64 px), `aggression_level` (0.35, rango 0–1), `dash_threshold_distance` (56 px, rango 0–200 px) y `prediction_horizon` (3 s, rango 0.25–5 s). El error se sortea una vez por turno propio y queda acotado por el margen configurado. La agresividad se sortea al entrar al turno rival. `MatchManager.match_seed_override` permite fijar la semilla (`-1` genera una nueva); cada CPU deriva su flujo pseudoaleatorio local de la semilla de partida y el prefijo del jugador, sin consumir el RNG global al decidir.

## Flujo de ejecución

`Arena` instancia `Player1` con prefijo `player_1` y `Player2` con `player_2`. El menú de jugadores establece `Player2.bot_enabled` al elegir un jugador. `MatchManager` llama `reset_for_round()` al iniciar o reiniciar el punto, y `PlayerController` vuelve a procesar movimiento en el siguiente ciclo físico.

Más información: [Controles](controls.md) · [Globo](balloon.md) · [Partida](match.md).


## Línea base de caracterización

Antes de modificar el controlador en `complete-celeste-style-player-system`, se ejecutaron con Godot 4.7.2 los diez scripts de aceptación indicados en la tarea 1.4. El estado observado en este workspace fue:

- Pasaron `test_player_collision.gd`, `test_arena_surface_interactions.gd`, `test_cpu_controller.gd`, `test_balloon_turns.gd` y `test_full_match.gd`.
- Fallaron `test_player_horizontal_movement.gd` (la aceleración no alcanza la velocidad objetivo dentro de 0.12 s), `test_player_jump.gd` (mantener salto no produjo mayor altura en su primera comprobación), `test_dash.gd` (distancia de dash medida 11.62 px frente al rango esperado de 55–75 px), `test_player_wall_climb.gd` (Grab no entró a escalada dentro del rango) y `test_cpu_prediction.gd` (la intercepción quedó debajo del límite de scoring-ground).
- Godot además informó que no pudo escribir `user://logs/godot.log` en este entorno; los asserts anteriores sí se ejecutaron y los resultados se registran como línea base del workspace, no como regresiones de este cambio.

No se añadieron pruebas de caracterización en esta etapa: cada brecha identificada ya tiene un assert en los scripts nombrados. Los casos posteriores del salto que el primer assert aborta se vuelven a verificar al corregir la implementación.

## Cobertura de los contratos

| Contrato | Comprobación asociada |
|---|---|
| Entradas independientes y remapeables | `test_player_controller.gd`, `test_input_map.gd` |
| Aceleración, frenado, inversión, límite y control aéreo | `test_player_horizontal_movement.gd`, `test_player_controller.gd` |
| Altura variable, coyote y buffer | `test_player_jump.gd` |
| Dash cardinal/diagonal, fallback, duración, colisión y carga | `test_dash.gd`, `test_dash_rescue.gd`, `test_player_collision.gd` |
| Suelo, paredes, techos, cápsula y esquinas | `test_player_wall_climb.gd`, `test_climbable_walls.gd`, `test_player_collision.gd` |
| CPU comparte ejecución, predicción de suelo y reglas de turno | `test_cpu_controller.gd`, `test_cpu_prediction.gd`, `test_cpu_opponent_turn.gd`, `test_full_match.gd` |
| Perfiles, capas físicas, marcos y dimensiones visuales | `test_visual_assets.gd` |
| Animaciones de estado, prioridad e impactos | `test_visual_feedback.gd` |
| Pelo P2 cosmético y cape P1 cosmética | `test_player_hair.gd`, `test_player_cape.gd` |
| Arena principal importable/ejecutable con recursos locales, escala nítida y manifiesto estable | `test_arena_layout.gd`, `test_full_match.gd`, `test_visual_assets.gd`, `player_animation_assets.md` |
| Feedback sin depender de audio | `test_visual_feedback.gd` |
