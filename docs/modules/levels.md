# Arenas y TileSet

## Estructura actual

- `src/scenes/main/main.tscn` mantiene la raíz de la partida y abre la selección inicial.
- `src/scenes/levels/arena.tscn` contiene jugadores, globo, cámara, marcador y gestores persistentes.
- `src/scenes/levels/arena_classic.tscn` es Classic Court (320 × 180); `src/scenes/levels/sky_towers.tscn` es Sky Towers (480 × 270).
- `src/managers/level_manager.gd` recibe `ArenaCatalog`, selecciona `ArenaData` tipado, carga mapas y aplica bounds, spawns y ajustes.
- `src/scenes/ui/menus/player_count_menu.gd` consume las mismas entradas `ArenaData` para construir dinámicamente nombre, descripción, clasificación y vista previa.
- `src/scenes/levels/arena_camera.gd` sigue la acción y limita la vista a los bounds seleccionados.
- `src/resources/arena_data.gd` describe una arena; `src/resources/arena_catalog.tres` define el orden de selección.
- `assets/sprites/arena/arena_tileset.tres` usa una cuadrícula de 8 × 8 px. El atlas de cemento comienza en `(2, 2)` y cubre `6 × 15` celdas con colisión sólida en la capa 1; el atlas de plataformas comienza en `(10, 2)`, cubre `6 × 15` celdas y usa la capa unidireccional 4. El trampolín mantiene su recurso de 16 × 16 px y colisiona por la capa 2. Las celdas anteriores de 16 px se representan con cuatro celdas de 8 px para conservar las dimensiones de las arenas.
- Las miniaturas `classic_preview.svg` y `sky_towers_preview.svg` se muestran en el panel de selección.

## Mapas disponibles

| Arena | Tamaño | Tema | Características |
|---|---:|---|---|
| Classic Court | 320 × 180 | Stone | Piso puntuable, plataformas de una vía, trampolín y muros escalables. |
| Sky Towers | 480 × 270 | Sky Stone | Piso puntuable, plataformas elevadas, trampolín, muros escalables y límites ampliados. |

El menú obtiene sus opciones, dimensiones, tema y miniatura de `ArenaData`; al registrar otra escena, aparece sin añadir código de selección por mapa.

## Crear y registrar un mapa

1. Crea una escena `Node2D` en `src/scenes/levels/` para la geometría del mapa. Añade `TileMapLayer` y asígnale `arena_tileset.tres`.
2. Pinta el suelo puntuable con colisión sólida de la capa 1 y marca su `TileMapLayer` con `scoring_ground`. El globo solo puntúa al tocar esa superficie desde arriba; golpearla de lado, como si fuera un muro, no termina la ronda. Se informa como máximo un contacto puntuable por ronda.
3. Pinta plataformas de paso usando los tiles de una vía de la capa 4 y marca su `TileMapLayer` con `one_way_platform`. Los jugadores pueden saltar hacia arriba y bajar con Abajo + Salto; el globo ignora esta capa y la atraviesa.
4. Usa el atlas adicional `trampoline_tile.svg` para pintar una capa con colisión de la capa 2 y grupo `trampoline`. El globo rebota hacia arriba sin puntuar y los jugadores reciben un impulso al aterrizar.
5. Pinta muros con tiles sólidos de la capa 1 en una capa separada llamada, por ejemplo, `ClimbableWallTiles`, y añádele el grupo `climbable_wall`. Los jugadores trepan al mantener su acción de agarre; los límites ordinarios no son escalables.
6. Añade los límites laterales y el techo como cuerpos de colisión de la escena. El `playable_bounds` del recurso debe describir el área completa que la cámara y las entidades pueden ocupar.
7. Crea un recurso de tipo `ArenaData` y establece `id` único, nombre, descripción, tema, clasificación de tamaño, jugadores recomendados, escena del mapa, bounds y spawns. Asigna una textura importada para la miniatura; si falta, la selección muestra una tarjeta neutral.
8. Añade el recurso al array `arenas` de `src/resources/arena_catalog.tres`. El orden del array es el orden del menú; no hace falta modificar `PlayerCountMenu`.
9. Ejecuta el proyecto y comprueba el encuadre, spawns, colisiones, plataformas de una vía, trampolín, muros escalables y puntuación. Mantén multiplicadores en `1.0` salvo que el mapa necesite un ajuste probado.

## Convenciones

- Solo un contacto desde arriba con un cuerpo del grupo `scoring_ground` detona el globo y resuelve una ronda. Plataformas `one_way_platform`, trampolines y muros ordinarios no deben pertenecer a ese grupo.
- Mantén cada rol en su propio `TileMapLayer`: `scoring_ground`, `one_way_platform`, `trampoline` o `climbable_wall`. Los tiles sólidos sin esos roles bloquean sin conceder puntos.
- Usa el origen superior izquierdo para bounds en coordenadas de mundo. Los spawns y límites se expresan en los mismos píxeles del mundo.
- Las arenas no deben incluir jugadores, globo, HUD ni gestores; esos nodos pertenecen a la escena persistente `arena.tscn`.
- Para añadir mecánicas a tiles en el futuro, conserva el comportamiento neutral de los tiles sin propiedades de juego.

Más información: [Partida](match.md) · [Globo](balloon.md) · [Interfaz](ui.md).
