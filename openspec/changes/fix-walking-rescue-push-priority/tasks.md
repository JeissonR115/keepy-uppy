# Tasks

## 1. Empuje simétrico según el turno de rescate

- [x] 1.1 Quitar la asimetría que descarta las colisiones normales de Player 2 y conservar solo las restricciones necesarias del modo CPU; verificar que ambos jugadores pueden empujar al caminar en partida local.
- [x] 1.2 Seleccionar las fuerzas normales y de dash comparando al jugador que inicia el empujón con `expected_balloon_player`, manteniendo `priority_player` para contactos del globo; verificar que la fuerza mayor cambia correctamente entre P1 y P2 cuando cambia el turno.
- [x] 1.3 Verificar en modo contra CPU que los filtros del bot siguen respetando el turno del globo y que no se producen empujes cuando el juego está inactivo.

## 2. Colisiones duplicadas

- [x] 2.1 Evitar que los reportes de ambos participantes apliquen dos empujes por una sola colisión y reiniciar la deduplicación en el tick siguiente; verificar una sola aplicación por tick y que un nuevo contacto posterior sí empuja.

## 3. Comprobación integrada

- [ ] 3.1 Jugar rondas alternando el turno de rescate y verificar visualmente que cada personaje puede empujar al caminar y al hacer dash, que solo el rescatista recibe la fuerza mayor y que la ventaja nunca queda fija en Player 1.
