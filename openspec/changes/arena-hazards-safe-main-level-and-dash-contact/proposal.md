# Proposal

## Why

Las arenas actuales no tienen un nivel principal compacto y fácil de leer, y el juego no ofrece un contrato común de márgenes seguros ni miniaturas actualizadas para sus mapas. Además, hace falta ampliar la interacción de los escenarios con trampolines, pinchos y corrientes de aire, junto con una regla clara para los contactos repetidos con el globo durante un dash.

## What Changes

- Añadir al catálogo dos niveles: uno principal de 320 × 180 con solo el piso visible y límites de seguridad invisibles, y una arena secundaria que demuestre los elementos interactivos.
- Definir márgenes configurables para todos los niveles para mantener a los jugadores, el globo y los elementos interactivos dentro de la pantalla.
- Actualizar las miniaturas existentes para que representen los niveles actuales y crear las de los nuevos niveles.
- Hacer que los trampolines impulsen también a los jugadores, añadir pinchos que exploten el globo y otorguen el punto al rival del último jugador que lo tocó, y ventiladores parametrizables que empujen solo al globo.
- Después de un contacto válido entre el globo y un jugador durante su dash, ignorar nuevos contactos de ese mismo jugador con el globo hasta que termine esa activación del dash. Esto no desactiva las colisiones del jugador con la arena ni con el rival.

## Capabilities

### New Capabilities

- `arena-content-and-safety`: define el nivel principal compacto, la composición segura de todas las arenas y la correspondencia entre miniaturas y mapas.
- `arena-hazards`: define las interacciones reutilizables de trampolines, pinchos y ventiladores dentro de las arenas.

### Modified Capabilities

- `balloon-interaction`: limita a un contacto válido del globo por jugador durante la activación de dash después del primer contacto.
- `player-control`: establece que los trampolines también impulsan a los jugadores.
- `round-scoring`: añade puntuación por pinchos, otorgando el punto al rival del último jugador que tocó el globo.

## Impact

- Recursos y escenas en `src/resources/arenas`, `src/resources/arena_data.gd` y `src/scenes/levels`.
- Integración del catálogo y los límites en `src/managers/level_manager.gd` y `src/scenes/levels/arena_camera.gd`.
- Interacciones en `src/models/balloon/balloon_controller.gd`, `src/models/player/player_controller.gd` y `src/models/player/player_surface_techniques.gd`, más nuevas escenas reutilizables para pinchos y ventiladores.
- Miniaturas bajo `assets/sprites/arena` y presentación en el selector de niveles.
- Este cambio usa el catálogo y el selector del cambio pendiente `map-selection-tileset-arena-system`; debe integrarse sobre ese sistema para evitar duplicar su flujo.
