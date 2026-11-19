# Design

## Context

Ver `proposal.md` para la motivación y `specs/cpu-ai-bridge/spec.md` para el contrato. Hoy `CPUController` combina la FSM y las intenciones locales; `PlayerController` consume esas intenciones, pero excluye abajo y agarre para bots. `PlayerMovementConstants` es la fuente de movimiento. `LevelManager` instancia arenas desde `ArenaCatalog`; el catálogo actual contiene cuatro arenas, con `TileMapLayer`, colisiones de escena y límites auxiliares. `MatchManager` ya emite eventos de ronda, falta descendente, set y partida. Las pruebas existentes son scripts `SceneTree` ejecutables en headless.

## Goals / Non-Goals

**Goals:**
- Integrar un cerebro remoto sin bloquear el ciclo físico ni modificar el movimiento humano.
- Permitir episodios controlados por pasos y exportar geometría de la escena activa, no aproximaciones visuales.
- Preservar el comportamiento local existente como implementación de respaldo.

**Non-Goals:**
- Crear el proyecto de entrenamiento Python, un modelo de IA o nuevas reglas de competición.
- Garantizar resultados bit a bit idénticos entre versiones de Godot, plataformas o configuraciones físicas distintas.

## Decisions

1. **Contrato de cerebro y fallback.** Extraer las decisiones actuales a `LocalBrain` detrás de un contrato `CPUBrain`; `CPUController` selecciona la implementación activa y `PlayerController` consume una única estructura de intenciones. `RemoteBrain` adapta el protocolo a ese contrato. Cada petición lleva un número de secuencia; una respuesta vencida o de otra sesión se descarta. El cliente no bloquea la física: ante ausencia de respuesta en el plazo configurado se usan las intenciones locales. Esta separación conserva la física y evita acoplar Python al movimiento interno.

2. **Transporte local y encuadre.** Usar TCP limitado a loopback, con mensajes JSON UTF-8 delimitados por salto de línea. Cada mensaje incluye `type` y un identificador de sesión; las acciones y observaciones incluyen secuencia. Se elige TCP frente a WebSocket porque el caso de uso es un único cliente local y no necesita HTTP ni framing adicional. El servidor acepta una conexión de entrenamiento a la vez; valida mensajes y devuelve errores explícitos. Las operaciones de control son `reset`, `step`, `set_speed`, `get_level_geometry`, `load_nav_graph` y `close`.

3. **Semántica de paso.** `step(n)` ejecuta hasta `n` intercambios observación/acción, cada uno seguido de exactamente un tick físico fijo; se detiene antes si termina el episodio. El servidor procesa cada acción con el número de secuencia esperado y devuelve estado/eventos al completar el lote. En juego normal la física no espera a Python: cada tick sin respuesta usa `LocalBrain`. Así, `n` facilita lotes reproducibles sin cambiar la semántica de una decisión por tick.

4. **Velocidad sin alterar el paso físico.** Mantener el producto `Engine.time_scale / Engine.physics_ticks_per_second` igual al intervalo físico base al cambiar la velocidad, escalando ambos valores desde una tasa base guardada y restaurándolos al cerrar el entorno. Validar con el delta observado en cada tick para evitar que la aceleración cambie el salto o las colisiones. La velocidad efectiva seguirá limitada por el rendimiento de la máquina.

5. **Reinicio determinista.** El modo de simulación usa un generador de números aleatorios propio inicializado desde la semilla para saque, CPU y episodio; el reinicio también fija arena, marcador y estado físico. La garantía de repetibilidad se limita a la misma versión de Godot, configuración, nivel y secuencia de acciones, pues el motor no ofrece determinismo entre plataformas.

6. **Escena headless y terminales.** Componer una escena de simulación con la arena y entidades existentes, sin menús, y un controlador de prueba seleccionable para CPU contra CPU o CPU contra jugador scripteado. Un adaptador de episodios escucha las señales actuales de `MatchManager` y publica resultados con una razón normalizada (contacto con suelo, falta, repetición por golpe descendente, set o partida); no reimplementa la puntuación.

7. **Exportación y sondeo físico.** Recorrer el `ArenaData` y el mapa instanciado: exportar `playable_bounds`, spawns, límites auxiliares, formas de colisión, polígonos de `TileMapLayer` y propiedades de unidireccionalidad de `TileSet`. Leer valores de `PlayerMovementConstants` en tiempo de ejecución, nunca mantener una copia del balance en el exportador. Ejecutar sondeos en un contexto aislado con la misma escena de jugador y geometría para que el movimiento use `PlayerController` y su física reales sin alterar marcador, globo ni partida activa.

8. **Grafo ponderado y seguimiento.** Usar un recurso `NavGraph` basado en `AStar2D`, con conexiones dirigidas según el JSON y metadatos de acción por arista. Sobrescribir el cálculo de costo de AStar2D para respetar el costo de cada arista; mantener acción y destino en un índice aparte para reconstruir la ruta. Un seguidor de ruta compartido convierte la arista actual (`WALK`, `JUMP`, `DASH`, `DROP` o `WALL_JUMP`) en intenciones consumibles por un `CPUBrain`. El grafo activo queda asociado al id de `ArenaData`; las dimensiones y coordenadas se interpretan en espacio de mundo.

9. **Overlay y contrato versionado.** Usar un overlay `CanvasItem` activable solo para depuración, que dibuja el grafo y la ruta sin cambiar colisiones. Documentar en `docs/` un protocolo JSON versionado con ejemplos completos para conexión, control, observación, acción, geometría, grafo y errores, además de un cliente mínimo Python basado en biblioteca estándar.

## Risks / Trade-offs

- [La latencia o desconexión del cliente puede producir decisiones locales durante una jugada] → La física no espera respuestas, se validan secuencias y se activa fallback con timeout explícito.
- [Aumentar demasiado la tasa de física puede saturar CPU] → Validar la velocidad solicitada, mantener el paso fijo y exponer el rendimiento real sin saltarse ticks.
- [La geometría exportada puede divergir si se omiten colisiones de TileSet o límites generados] → Extraer de nodos y recursos físicos instanciados y probar arenas con plataformas unidireccionales.
- [Un sondeo podría afectar el estado de la partida] → Ejecutarlo en una instancia aislada y comprobar que el estado de episodio no cambia.
- [Los grafos externos pueden tener ids, costos o aristas inválidos] → Validar versión, referencias, coordenadas y costos antes de sustituir el grafo activo; conservar el grafo anterior si la carga falla.
- [La repetibilidad puede diferir en otras versiones o plataformas] → Registrar versión/configuración junto a cada ejecución y acotar explícitamente la garantía.

## Migration Plan

1. Introducir el contrato de cerebro y adaptar el CPU actual como opción por defecto; comprobar que las pruebas de CPU y PvP no cambian.
2. Añadir puente y escena de simulación optativos. Sin argumentos de ejecución, la escena principal conserva su configuración actual.
3. Añadir exportación, sondeo, carga de grafos y overlay; validar cada arena del catálogo.
4. Documentar protocolo y ejemplos, y ejecutar las pruebas headless de repetibilidad, desconexión y navegación.

No se requiere migración de partidas guardadas ni de recursos de arena. Para revertir, se desactiva el lanzador/servidor y se mantiene `LocalBrain` como implementación seleccionada.
