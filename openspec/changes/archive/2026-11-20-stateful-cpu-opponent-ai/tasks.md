# Tasks

## 1. Separación de decisiones y movimiento

- [x] 1.1 Añadir `CPUController` como hijo de `player_placeholder.tscn` y modelar los estados inactivo, turno propio y turno rival usando el estado existente de `MatchManager`; verificar activación/desactivación y transiciones en `tests/test_cpu_controller.gd`.
- [x] 1.2 Conectar las intenciones de movimiento, salto y dash a `PlayerController` sin cambiar la ruta humana ni sus físicas; verificar el control humano y el comportamiento bot existente con `tests/test_player_controller.gd` y `tests/test_player_interaction.gd`.
- [x] 1.3 Documentar la separación, estados y activación mediante `bot_enabled` en `docs/modules/player.md`; verificar que los nombres y el flujo descritos coincidan con la escena y el controlador.

## 2. Intercepción y dificultad reproducible

- [x] 2.1 Implementar un predictor de horizonte acotado que use el estado real y los parámetros conocidos del globo, y que devuelva recuperación segura si no hay intercepción confiable; verificar cruces, rebotes soportados, límites y casos inválidos con `tests/test_cpu_prediction.gd`.
- [x] 2.2 Añadir y validar `reaction_time`, `prediction_error_margin`, `aggression_level` y `dash_threshold_distance`, junto con una fuente pseudoaleatoria local ligada a la semilla; verificar límites de parámetros, offsets acotados y decisiones repetibles con `tests/test_cpu_difficulty.gd`.
- [x] 2.3 Documentar parámetros, rangos y semilla reproducible en `docs/modules/player.md`; verificar que cada valor documentado tenga una implementación y una prueba correspondiente.

## 3. Conducta durante el turno rival

- [x] 3.1 Implementar detección de amenaza y evasión prioritaria durante el turno rival, conservando la validación normal de contactos de `MatchManager`; verificar que el CPU no persiga ni solicite un dash hacia el globo fuera de turno en `tests/test_cpu_opponent_turn.gd`.
- [x] 3.2 Añadir posicionamiento de obstrucción condicionado por seguridad y agresividad configurable; verificar que la obstrucción solo ocurra fuera de la trayectoria de amenaza y use las colisiones existentes en `tests/test_cpu_opponent_turn.gd`.
- [x] 3.3 Documentar la prioridad de evasión y el alcance de la obstrucción en `docs/modules/player.md`; verificar la coherencia con las reglas de turno y faltas descritas en `docs/modules/match.md`.

## 4. Integración

- [x] 4.1 Ejecutar las pruebas nuevas y las regresiones `tests/test_player_interaction.gd`, `tests/test_balloon_turns.gd` y `tests/test_dash_rescue.gd` con el runner headless del proyecto; corregir cualquier regresión de turnos, movimiento, dash o contactos.
