# Arenas y TileSet

## Estructura actual

- `src/scenes/main/main.tscn` mantiene la raíz de la partida y abre la selección inicial.
- `src/scenes/levels/arena.tscn` contiene jugadores, globo, cámara, marcador y gestores persistentes.
- `src/scenes/levels/arena_classic.tscn` es Classic Court (320 × 180); `src/scenes/levels/sky_towers.tscn` es Sky Towers (480 × 270).
- `src/managers/level_manager.gd` carga mapas desde el catálogo y aplica bounds, spawns y ajustes.
- `src/scenes/levels/arena_camera.gd` sigue la acción y limita la vista a los bounds seleccionados.
- `src/resources/arena_data.gd` describe una arena; `src/resources/arena_catalog.tres` define el orden de selección.
- `assets/sprites/arena/arena_tileset.tres` usa `foreground_tilesets.png` con celdas de 16 × 16 px, colisión sólida en la capa 1 y plataformas de una vía en la capa 4.
- Las miniaturas `classic_preview.svg` y `sky_towers_preview.svg` se muestran en el panel de selección.

## Mapas disponibles

| Arena | Tamaño | Tema | Características |
|---|---:|---|---|
| Classic Court | 320 × 180 | Stone | Piso puntuable y dos plataformas de una vía. |
| Sky Towers | 480 × 270 | Sky Stone | Piso puntuable, tres plataformas elevadas y límites ampliados. |

El menú obtiene sus opciones, dimensiones, tema y miniatura de `ArenaData`; al registrar otra escena, aparece sin añadir código de selección por mapa.

## Crear y registrar un mapa

1. Crea una escena `Node2D` en `src/scenes/levels/` para la geometría del mapa. Añade `TileMapLayer` y asígnale `arena_tileset.tres`.
2. Pinta suelo sólido con tiles que tengan colisión en la capa 1 y plataformas atravesables con tiles de la capa 4. Los jugadores ya pueden bajar con Abajo + Salto.
3. Marca únicamente el TileMapLayer del suelo que termina la ronda con el grupo `scoring_ground`. Las plataformas de tránsito no deben pertenecer a ese grupo.
4. Añade los límites laterales y el techo como cuerpos de colisión de la escena. El `playable_bounds` del recurso debe describir el área completa que la cámara y las entidades pueden ocupar.
5. Crea un recurso de tipo `ArenaData` y establece `id` único, nombre, descripción, tema, clasificación de tamaño, jugadores recomendados, escena del mapa, bounds y spawns. Asigna una textura importada para la miniatura; si falta, la selección muestra una tarjeta neutral.
6. Añade el recurso al array `arenas` de `src/resources/arena_catalog.tres`. El orden del array es el orden del menú; no hace falta modificar `PlayerCountMenu`.
7. Ejecuta el proyecto y comprueba el encuadre, spawns, colisiones, plataformas de una vía y puntuación. Mantén multiplicadores en `1.0` salvo que el mapa necesite un ajuste probado.

## Convenciones

- El piso puntuable es una superficie distinta de las plataformas elevadas. El globo solo resuelve una ronda al tocar algo del grupo `scoring_ground`.
- Usa el origen superior izquierdo para bounds en coordenadas de mundo. Los spawns y límites se expresan en los mismos píxeles del mundo.
- Las arenas no deben incluir jugadores, globo, HUD ni gestores; esos nodos pertenecen a la escena persistente `arena.tscn`.
- Para añadir mecánicas a tiles en el futuro, conserva el comportamiento neutral de los tiles sin propiedades de juego.

Más información: [Partida](match.md) · [Globo](balloon.md) · [Interfaz](ui.md).
