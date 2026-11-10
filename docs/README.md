# Documentación técnica — Keepy Uppy

Keepy Uppy es un juego local de dos jugadores en el que los jugadores mantienen un globo en el aire y compiten por turnos. Se puede jugar contra otra persona o contra un bot sencillo controlado por el segundo jugador.

## Tecnologías y ejecución

- **Motor:** Godot Engine 4.7, según `config/features` en [`project.godot`](../project.godot).
- **Lenguaje:** GDScript tipado.
- **Escenas:** formato `.tscn` de Godot.
- **Resolución lógica:** 320 × 180; la ventana tiene un tamaño inicial de 960 × 540 y usa escalado entero.
- **Ejecución:** abrir el proyecto en Godot y ejecutar `src/scenes/main/main.tscn`, configurada como escena principal.

El juego usa nodos de física 2D (`CharacterBody2D`, `RigidBody2D`, `StaticBody2D` y `Area2D`). La presentación actual usa geometría dibujada en escenas y no depende de paquetes externos de arte.

## Contexto y objetivo

Cada toque válido cambia el turno al rival. El globo queda suspendido junto al jugador que saca hasta su primer toque. En una jugada normal, el último jugador que tocó el globo anota cuando este toca el piso. Tocar fuera del turno provoca una falta. Un golpe que envía el globo hacia abajo repite el saque; dos faltas descendentes consecutivas del mismo jugador le descuentan un punto. La partida se organiza en sets.

## Arquitectura

La escena principal crea el gestor de controles, la arena y el menú para seleccionar uno o dos jugadores. Dentro de la arena, `MatchManager` coordina el estado competitivo y conecta los contactos físicos del globo con las reglas de turnos y puntuación. Los controladores de jugador y globo gestionan movimiento y física; la interfaz escucha sus señales para mostrar marcador, turno y menús.

```text
Main
├── ControlSettingsManager
├── Arena
│   ├── Player1 / Player2
│   ├── Balloon
│   ├── MatchManager
│   ├── Scoreboard
│   └── suelo, paredes y techo
└── PlayerCountMenu
```

## Carpetas principales

| Ruta | Contenido |
|---|---|
| `src/managers/` | Reglas de partida y almacenamiento/configuración de controles. |
| `src/models/` | Controladores y escenas reutilizables de jugador, globo y entorno. |
| `src/scenes/main/` | Composición de la escena de entrada. |
| `src/scenes/levels/` | Escena de arena. |
| `src/scenes/ui/` | Marcador, pausa, selección de jugadores y configuración de teclas. |
| `tests/` | Pruebas automatizadas de lógica, escenas e interacción. |
| `openspec/` | Propuestas, especificaciones y cambios de OpenSpec. |

## Módulos

- [Controles y asignaciones](modules/controls.md): Input Map, lectura de entradas, validación y persistencia de teclas.
- [Jugador y bot](modules/player.md): movimiento, salto, dash, empujes, presentación y lógica del bot.
- [Globo y física](modules/balloon.md): contactos, impulsos, gravedad, límites de velocidad y efecto al tocar el suelo.
- [Partida y puntuación](modules/match.md): saque, turnos, faltas, puntos, sets y señales de coordinación.
- [Niveles y arena](modules/levels.md): escena principal, composición de la arena y colisiones ambientales.
- [Interfaz](modules/ui.md): navegación de menús, marcador, pausa, configuración y pantalla de ganador.

## Dependencias entre módulos

| Módulo | Depende de | Provee a |
|---|---|---|
| Controles | `PlayerActionCatalog`, Input Map y `user://controls.cfg` | Jugadores, botones de menú y navegador de menús. |
| Jugador | Controles, globo y `MatchManager` | Movimiento, contactos de dash y señal de empujón. |
| Globo | Jugadores y escena de arena | Señales de contacto y del suelo; velocidad e impulsos físicos. |
| Partida | Jugadores y globo | Estado de turno, puntuación y señales para el HUD. |
| Niveles | Escenas de jugador, globo, partida e interfaz | Composición instanciada por `Main`. |
| Interfaz | Partida, controles y catálogo de acciones | Entrada para los menús y presentación del estado de juego. |

## Pruebas existentes

Los scripts de [`tests/`](../tests/) se ejecutan individualmente con Godot en modo headless. Cubren movimiento, dash, física y contactos del globo, saques, turnos, puntuación, controles y menús. El código de pruebas se mantiene separado del runtime.
