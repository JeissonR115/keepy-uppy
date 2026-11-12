# Proposal

## Why

Los jugadores todavía se dibujan como polígonos, aunque ya hay animaciones de personaje y efectos en el proyecto. Usar esos sprites hará que las acciones se entiendan por su pose y movimiento, y un matiz naranja suave ayudará a distinguir al jugador 2 sin cambiar sus animaciones.

## What Changes

- Reemplazar la figura poligonal que representa el cuerpo de cada jugador por las secuencias PNG de `res://assets/sprites/Animations/player/`.
- Usar las animaciones de `res://assets/sprites/Animations/player_sweat/` como efectos visuales de las acciones correspondientes.
- Elegir las animaciones según los estados de movimiento ya existentes y orientarlas según la dirección del jugador.
- Aplicar al jugador 2 un matiz naranja leve sobre los mismos sprites y efectos; conservar para el jugador 1 la apariencia base de los recursos.
- Mantener independientes la presentación y las colisiones, y conservar la capa, el indicador de prioridad y los demás comentarios de juego.
- Actualizar las pruebas visuales y documentación afectadas.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `pixel-art-presentation`: el cuerpo de ambos jugadores debe usar sprites animados y efectos visuales existentes, y el segundo jugador debe distinguirse con un matiz naranja.

## Impact

- `src/models/player/player_placeholder.tscn`, `player_controller.gd` y `player_presentation_controller.gd`.
- Sprites bajo `assets/sprites/Animations/player/` y `assets/sprites/Animations/player_sweat/`.
- Pruebas de presentación y `docs/modules/player.md`.
- Sin cambios previstos a movimiento, entradas, reglas o geometría de colisión.
