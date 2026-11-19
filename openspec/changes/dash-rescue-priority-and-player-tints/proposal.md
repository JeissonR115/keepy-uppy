# Proposal

## Why

La ventaja actual de empuje durante el dash sigue al jugador con prioridad de contacto, aunque quien necesita rescatar el globo sea el rival. Además, no hay una señal directa y persistente de quién debe tocarlo, y los perfiles visuales actuales no ofrecen la diferenciación azul solicitada.

## What Changes

- Dar mayor fuerza de interferencia al dash del jugador que debe rescatar el globo, manteniendo separada esa ventaja del crédito del último toque y de la resolución de contactos simultáneos.
- Mostrar un triángulo visible sobre el jugador cuyo turno es rescatar el globo y actualizarlo cuando cambie el turno.
- Aplicar un tinte azul al jugador 1 y un tinte azul más intenso al jugador 2, preservando la lectura de las animaciones y diferenciando ambos jugadores.

## Capabilities

### New Capabilities

### Modified Capabilities

- `balloon-interaction`: la ventaja de desplazamiento del dash corresponde al jugador esperado para rescatar el globo y cambia junto con el turno.
- `pixel-art-presentation`: se identifica al jugador esperado mediante un triángulo y se distinguen los jugadores con tintes azules de distinta intensidad.

## Impact

- `src/managers/match_manager.gd`: selección de prioridad de dash y actualización del jugador esperado.
- `src/models/player/player_controller.gd` y `src/models/player/player_placeholder.tscn`: presentación del indicador de turno.
- `src/models/player/player_visual_profile_p1.tres` y `player_visual_profile_p2.tres`: tintes de jugador.
- Especificaciones OpenSpec `balloon-interaction` y `pixel-art-presentation`.
