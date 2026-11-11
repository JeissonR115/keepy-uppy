# Proposal

## Why

Las arenas ya usan TileSet, pero las plataformas de paso también detonan el globo y no hay una superficie diferenciada de trampolín o pared escalable. Además, el boost manual en H añade un control que el usuario quiere sustituir por una aceleración automática al correr.

## What Changes

- Definir comportamientos claros para las superficies del TileSet: piso sólido que puntúa, plataforma de paso que no colisiona con el globo, trampolín que lo rebota sin puntuar y muro escalable.
- Hacer que solo el contacto con una superficie marcada como piso de puntuación detone el globo una vez por ronda.
- Añadir un tile de trampolín que impulse el globo hacia arriba sin detonarlo ni otorgar punto.
- Eliminar la acción de boost asignada a H/3 y aumentar moderadamente la velocidad máxima al correr, aplicándola automáticamente al mantener una dirección.
- Habilitar la escalada en muros del TileSet usando la acción de agarre existente, con el comportamiento actual de stamina y salto de pared.
- Actualizar documentación y pruebas de física, puntuación y controles.

## Capabilities

### New Capabilities
- `arena-tile-surfaces`: Define los roles físicos y de juego de los tiles de arena, incluidos piso de puntuación, plataforma atravesable por el globo, trampolín y muro escalable.

### Modified Capabilities
- `balloon-interaction`: Limita la detonación/puntuación al piso designado y define el rebote del globo en el trampolín.
- `player-control`: Sustituye el boost manual por aceleración automática al correr y especifica la escalada de muros con agarre.

## Impact

Impacta el TileSet y los mapas en `assets/sprites/arena/` y `src/scenes/levels/`, las colisiones del `BalloonController`, el movimiento/acciones del `PlayerController` y `PlayerActionCatalog`, ajustes de controles, pruebas y documentación de mapas y movimiento. No requiere dependencias externas.
