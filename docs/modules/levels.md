# Niveles y arena

## Descripción

El proyecto contiene una arena clásica y dos niveles grandes seleccionables. Sky Towers mide 640 × 360 y Ancient Ruins mide 800 × 450; ambos tienen paredes, piso y plataformas unidireccionales.

## Estructura

- `src/scenes/main/main.tscn`: punto de entrada. Instancia gestor de controles, arena y menú de jugadores.
- `src/scenes/levels/arena.tscn`: fondo, cámara, dos jugadores, globo, gestor de partida, marcador y geometría de colisión.
- `src/scenes/levels/sky_towers.tscn` y `ancient_ruins.tscn`: niveles alternativos con plataformas elevadas.
- `src/managers/level_manager.gd`: carga el nivel elegido, actualiza spawns y configura límites de cámara.
- `src/scenes/levels/arena_camera.gd`: cámara compartida que sigue a ambos jugadores y al globo.
- `project.godot`: escena principal y configuración de resolución y escalado.

## Funcionamiento

1. Godot ejecuta `src/scenes/main/main.tscn`.
2. La escena `Main` carga `ControlSettingsManager`, `Arena` y `PlayerCountMenu`.
3. Al elegir uno o dos jugadores, aparece el selector de nivel con Classic Court, Sky Towers y Ancient Ruins.
4. `LevelManager` conserva el escenario clásico en los nodos de Arena o instancia el nivel alternativo elegido. La cámara compartida acompaña a jugadores y globo dentro de los límites activos.
5. El piso y las plataformas están en el grupo `scoring_ground`; el contacto del globo con cualquiera de esas superficies resuelve el punto. Las plataformas alternativas usan la capa de colisión 4 y solo se atraviesan de abajo hacia arriba.
6. Los jugadores pueden bajar a través de una plataforma con Abajo + Salto; el globo también colisiona y puntúa al tocarla.

## Componentes principales

- `Arena/Player1`, `Arena/Player2`: instancias de `player_placeholder.tscn`.
- `Arena/Balloon`: instancia de `balloon_placeholder.tscn`.
- `Arena/MatchManager`: reglas competitivas.
- `Arena/Scoreboard`: HUD y overlays.
- `Arena/ScoringGround`, `LeftWall`, `RightWall`, `Ceiling`: límites clásicos estáticos.
- `Arena/LevelManager`: selección y configuración del escenario.
- `Camera2D`: cámara de seguimiento compartido con límites configurables.

## Interacciones

La escena principal sirve como raíz para referencias relativas: los jugadores y `MatchManager` localizan sus nodos hermanos en Arena; el marcador llega al menú de selección a través de Main. Las formas de suelo y paredes usan capa 1; las plataformas unidireccionales usan capa 4. La máscara de los jugadores y el globo incluye ambas capas.

## Configuración

`project.godot` declara un viewport lógico de 320 × 180 y una ventana inicial de 960 × 540. Los niveles grandes amplían el área de mundo y la cámara sigue la acción. El piso, paredes, techo y plataformas se definen en sus escenas `.tscn`.

## Flujo de ejecución

`Main` es la escena raíz. Al entrar a escena se inicializan los controladores de Arena; `MatchManager` sortea un servidor y coloca el globo, y `PlayerCountMenu` detiene el árbol hasta que se elijan el modo y el escenario. La arena permanece activa debajo de las capas de interfaz durante la partida.

Más información: [Partida](match.md) · [Globo](balloon.md) · [Interfaz](ui.md).
