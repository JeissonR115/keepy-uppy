# Niveles y arena

## Descripción

El proyecto contiene una arena jugable y una escena de composición principal. El nivel es una pantalla fija con un piso de puntuación, dos paredes laterales y techo; no se instancian plataformas elevadas.

## Estructura

- `src/scenes/main/main.tscn`: punto de entrada. Instancia gestor de controles, arena y menú de jugadores.
- `src/scenes/levels/arena.tscn`: fondo, cámara, dos jugadores, globo, gestor de partida, marcador y geometría de colisión.
- `src/models/environment/platform.tscn`: escena de plataforma reutilizable que existe en el repositorio, pero actualmente no está instanciada en la arena.
- `project.godot`: escena principal y configuración de resolución y escalado.

## Funcionamiento

1. Godot ejecuta `src/scenes/main/main.tscn`.
2. La escena `Main` carga `ControlSettingsManager`, `Arena` y `PlayerCountMenu`.
3. `Arena` centra `Camera2D` en (160, 90) sobre un fondo de 320 × 180.
4. Los jugadores empiezan en las posiciones 72 × 144 y 248 × 144. El gestor puede reubicarlos al inicio de cada punto.
5. El piso está en el grupo `scoring_ground`; sus colisiones activan la resolución del punto. Las paredes laterales y el techo rebotan el globo.

## Componentes principales

- `Arena/Player1`, `Arena/Player2`: instancias de `player_placeholder.tscn`.
- `Arena/Balloon`: instancia de `balloon_placeholder.tscn`.
- `Arena/MatchManager`: reglas competitivas.
- `Arena/Scoreboard`: HUD y overlays.
- `Arena/ScoringGround`, `LeftWall`, `RightWall`, `Ceiling`: cuerpos estáticos con formas rectangulares.
- `Camera2D`: cámara fija habilitada.

## Interacciones

La escena principal sirve como raíz para referencias relativas: los jugadores y `MatchManager` localizan sus nodos hermanos en Arena; el marcador llega al menú de selección a través de Main. Las formas ambientales usan capa 1, que forma parte de la máscara de colisión de personajes y globo.

## Configuración

`project.godot` declara un viewport lógico de 320 × 180, ventana inicial 960 × 540, modo stretch `viewport` y escalado `integer`. El piso y las paredes miden 320 × 16 y 16 × 180 respectivamente; el techo usa una forma de 320 × 16. Las formas y posiciones de colisión se ajustan en `arena.tscn`.

## Flujo de ejecución

`Main` es la escena raíz. Al entrar a escena se inicializan los controladores de Arena; `MatchManager` sortea un servidor y coloca el globo, y `PlayerCountMenu` detiene el árbol hasta elegir el modo. La arena permanece activa debajo de las capas de interfaz durante la partida.

Más información: [Partida](match.md) · [Globo](balloon.md) · [Interfaz](ui.md).
