# Proposal

## Why

El pelo actual no reproduce el sistema de `Godot-Celeste-Movement-Demo`: la aproximación anterior con hebras simuladas cayó hacia el suelo y la estela de una línea no muestra el mechón estático ni el acabado del demo. Hace falta trasladar el rig, su seguimiento de posiciones, su composición pixelada y sus transiciones a los dos perfiles de jugador existentes.

## What Changes

- Reemplazar la aproximación actual de `PlayerHair` por una adaptación fiel del rig y el algoritmo de trayectoria de pelo de la referencia: seis posiciones, límite por eje de 2 px, extensión en reposo, pivote espejado y composición por viewport.
- Reproducir la representación de la referencia con `Line2D`, curva de grosor, base de pelo, contorno shader y los estados cromáticos de movimiento, dash y aterrizaje; adaptar los pivotes de sus animaciones a los `AnimatedSprite2D` y perfiles que usa este proyecto.
- Aplicar pelo idéntico en comportamiento a P1 y P2 desde sus perfiles existentes, conservarlo cosmético y separar su actualización de la física de `PlayerController`.
- Revisar la procedencia y los términos de `hair.png` y `haipixelr.png`. Incluir esas texturas únicamente si se verifica permiso aplicable al proyecto; registrar la decisión y atribución en la documentación de assets.
- Añadir cobertura visual y determinista para reposo, movimiento, aceleración, giro, animaciones, dash, aterrizaje, orientación de ambos jugadores, reinicio y ausencia de colisiones.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `pixel-art-presentation`: añadir el contrato de pelo procedural fiel a la referencia, compartido por P1/P2, con sus reglas de renderizado, seguimiento y cambios visuales.

## Impact

- Código y escena: `src/models/player/player_hair.gd`, `player_hair.tscn`, `player_presentation_controller.gd`, perfiles visuales P1/P2 y su integración con `player_controller.gd`.
- Recursos sujetos a verificación de permiso: texturas de pelo del demo; shader y recursos de composición del rig.
- Pruebas y documentación: `tests/test_player_hair.gd`, `tests/test_visual_assets.gd`, `docs/modules/player.md`, `docs/modules/player_animation_assets.md` y el registro de procedencia de assets.
- Se conserva la escena del personaje, sus `SpriteFrames`, cápsulas, capas, áreas de rescate, dash, CPU y lógica de partida.
