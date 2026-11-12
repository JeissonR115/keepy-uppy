# Proposal

## Why

El jugador todavía se representa mediante un polígono procedural, aunque el proyecto ya incluye secuencias de sprites para movimiento, estados y efectos. Cambiar esa representación hará que el personaje use el arte disponible y dará feedback visual coherente sin alterar su comportamiento físico.

## What Changes

- Sustituir la forma poligonal del cuerpo por animaciones construidas con los fotogramas PNG existentes en `assets/sprites/player/Animations/`.
- Definir la selección y prioridad de animaciones para reposo, carrera, salto, caída, dash, escalada y deslizamiento por pared.
- Añadir una capa visual secundaria para los efectos disponibles en `player_sweat/`, activada por eventos y estados ya existentes.
- Sincronizar dirección y anclaje visual con el jugador, manteniendo independientes la representación, la lógica de movimiento y las colisiones.
- Conservar la capa procedural (cape) y los indicadores de prioridad existentes, y actualizar pruebas y documentación que asumen un polígono como cuerpo.
- Mantener fuera de alcance cualquier cambio a reglas, físicas, entradas o geometría de colisión del jugador.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `pixel-art-presentation`: el personaje del jugador debe representarse con sprites pixel-art animados y feedback visual sincronizado con sus estados actuales.

## Impact

- Escena y scripts en `src/models/player/`, especialmente `player_placeholder.tscn`, `player_controller.gd` y `player_presentation_controller.gd`.
- Recursos de animación bajo `assets/sprites/player/Animations/` y sus subdirectorios.
- Pruebas de presentación, feedback y capa del jugador; documentación en `docs/modules/player.md`.
- No se añaden dependencias externas ni se modifican interfaces de física o colisión.
