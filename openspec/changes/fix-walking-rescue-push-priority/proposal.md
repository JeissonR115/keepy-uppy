# Proposal

## Why

Actualmente Player 1 puede empujar al caminar, mientras que el empuje normal de Player 2 se descarta en el manejador de colisiones. Esto deja la ventaja fija en Player 1, aunque el turno del globo pertenezca al otro jugador, y hace que el juego sea injusto.

## What Changes

- Hacer simétrico el empuje por colisión al caminar para ambos jugadores.
- Asignar el empuje más fuerte al jugador esperado para rescatar el globo tanto al caminar como al hacer dash; el otro jugador conserva el empuje normal configurado.
- Mantener la prioridad de contacto para resolver toques simultáneos separada de la ventaja de empuje ligada al turno de rescate.
- Evitar que una misma colisión aplique el empuje dos veces por reportarse desde ambos personajes.

## Capabilities

### New Capabilities

### Modified Capabilities

- `balloon-interaction`: el empuje entre jugadores es simétrico y la ventaja de desplazamiento, caminando o con dash, sigue al jugador esperado para tocar el globo.

## Impact

- `src/managers/match_manager.gd`: filtros de colisión entre jugadores y selección de fuerza según el turno de rescate.
- `src/models/player/player_dash_techniques.gd` y `src/models/player/player_controller.gd`: emisión de colisiones y posible prevención de empujes duplicados.
- Especificación OpenSpec `balloon-interaction`.

Esta propuesta complementa `dash-rescue-priority-and-player-tints`: precisa que la ventaja corresponde al jugador esperado durante cualquier empuje, no solo durante el dash.
