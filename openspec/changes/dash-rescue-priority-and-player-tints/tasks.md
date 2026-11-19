# Tasks

## 1. Prioridad de rescate durante el dash

- [ ] 1.1 Actualizar la selección de fuerza de empuje del dash para favorecer a `expected_balloon_player` sin cambiar `priority_player` ni la atribución del último toque; verificar que el dash del rescatista aplica el empuje fuerte y el del otro jugador el normal.
- [ ] 1.2 Verificar la prioridad al iniciar un saque, tras un toque válido y al comenzar una ronda nueva; comprobar que la ventaja de dash sigue siempre al jugador esperado para rescatar.

## 2. Indicador triangular de rescate

- [ ] 2.1 Añadir y actualizar un triángulo visible sobre el jugador esperado para rescatar en cada cambio de turno y reinicio de ronda; verificar cambios de jugador, visibilidad y que no se confunde con el indicador de prioridad de contacto.
- [ ] 2.2 Probar visualmente en la arena que el triángulo permanece sobre el jugador correcto durante movimiento, salto y dash, sin tapar la silueta ni el globo.

## 3. Tintes azules por perfil

- [ ] 3.1 Ajustar los perfiles visuales para dar a Player 1 un tinte azul y a Player 2 uno más intenso; verificar que ambos tonos se aplican al personaje y a sus efectos de presentación.
- [ ] 3.2 Revisar las animaciones de ambos jugadores en la arena y ajustar los valores hasta que el orden de intensidad sea claro y se conserven los detalles y siluetas.

## 4. Integración

- [ ] 4.1 Ejecutar una partida local con ambos jugadores y verificar que el turno de rescate, la ventaja de dash y el triángulo cambian de forma coordinada, mientras la prioridad de contacto conserva su comportamiento.
