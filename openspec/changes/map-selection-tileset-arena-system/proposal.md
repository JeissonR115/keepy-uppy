# Proposal

## Why

La arena actual es una escena de prueba con límites y piso dibujados y configurados a mano, lo que hace costoso crear y mantener mapas. Se necesita una base reutilizable de arenas descritas por datos, construidas con TileSet y seleccionables antes de iniciar una partida.

## What Changes

- Refactorizar la geometría fija de la arena hacia escenas de mapa basadas en TileSet, con colisiones sólidas y plataformas unidireccionales configurables.
- Añadir recursos `ArenaData` para registrar escenas, nombre, descripción, vista previa, dimensiones, spawns y ajustes compatibles de física.
- Añadir un catálogo de arenas y un selector con lista y vista previa; iniciar la partida con la arena elegida y conservar el flujo existente de selección de modo/jugadores.
- Calcular los límites del mundo y de cámara a partir de los datos de cada arena, manteniendo jugadores y globo dentro del espacio jugable.
- Definir cómo las superficies de arena etiquetadas como puntuables informan al globo y al sistema de puntuación, sin convertir cada plataforma decorativa en piso de puntuación.
- Dejar un camino extensible para propiedades de terreno y peligros futuros, sin incluir trampas, viento ni nuevos peligros en esta entrega.

## Capabilities

### New Capabilities
- `arena-catalog`: Recursos y catálogo que describen arenas seleccionables, sus escenas, metadatos, spawns y dimensiones.
- `arena-selection`: Flujo de selección de mapas con metadatos y vista previa, integrado antes del inicio de la partida.
- `tile-based-arenas`: Construcción de arenas con TileSet, colisiones, plataformas unidireccionales y límites definidos por datos.

### Modified Capabilities
- `round-scoring`: Precisar que solo las superficies identificadas explícitamente como piso puntuable terminan la ronda al contacto del globo.

## Impact

- Escenas y scripts bajo `src/scenes/levels`, `src/managers` y `src/scenes/ui/menus`; integración con `src/scenes/main/main.tscn`, `PlayerCountMenu`, cámara, `BalloonController` y `MatchManager`.
- Recurso de arena y escenas de mapa nuevas bajo `src/resources` y `src/scenes/levels`; importación de `assets/sprites/arena/foreground_tilesets.png` en Godot 4.
- La arena inicial actual se convierte en el primer mapa registrado. Los ajustes por tamaño se expresan como datos explícitos y conservadores; las arenas sin ajustes conservan la física actual.
- No requiere dependencias externas ni cambia el formato de guardado.
