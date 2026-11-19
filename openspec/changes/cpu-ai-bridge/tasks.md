# Tasks

## 1. Interfaz de cerebro y compatibilidad

- [x] 1.1 Definir el contrato tipado `CPUBrain` y extraer las decisiones actuales de `CPUController` a `LocalBrain`; verificar con las pruebas de CPU que estados, intenciones y aleatoriedad sembrada conservan el comportamiento actual.
- [x] 1.2 Hacer que `CPUController` delegue al cerebro seleccionado y que `PlayerController` consuma abajo y agarre del mismo conjunto de intenciones; verificar saltos, drop-through, escalada, dash y las pruebas de jugador contra jugador.

## 2. Puente TCP y cerebro remoto

- [x] 2.1 Implementar servidor TCP de loopback con mensajes JSON delimitados por línea, sesión y secuencia, validación de comandos/acciones y errores explícitos; verificar conexión local, mensajes malformados, campos inválidos y secuencias obsoletas con pruebas automatizadas.
- [x] 2.2 Implementar `RemoteBrain` asíncrono con timeout, descarte de respuestas tardías y fallback a `LocalBrain`; verificar desconexión y timeout sin detener la física ni cambiar el movimiento PvP.
- [x] 2.3 Documentar en `docs/` el ciclo de conexión y los formatos de control, observación y acción, e incluir un cliente Python mínimo de biblioteca estándar; verificar que el ejemplo pueda conectar, reiniciar, intercambiar una acción/observación y cerrar.

## 3. Simulación headless y episodios

- [x] 3.1 Crear la escena sin menús y el lanzador con argumentos de puerto, nivel, velocidad y semilla, además de modos CPU contra CPU y CPU contra jugador scripteado; verificar ambas configuraciones con una ejecución headless.
- [x] 3.2 Implementar `reset(seed, level)`, `step(n)` y `set_speed` con RNG de episodio y paso físico invariable; verificar mediante pruebas que dos ejecuciones con la misma semilla/acciones coinciden y que variar velocidad no cambia el delta físico.
- [ ] 3.3 Publicar eventos terminales con tipo, motivo, jugador, marcador y ganador a partir del ciclo real de `MatchManager`; verificar punto, falta, repetición por golpe descendente, set y partida con pruebas de episodio.
- [ ] 3.4 Documentar en `docs/` los argumentos del lanzador, límites de repetibilidad y ejemplos de ejecución de episodios; verificar que los comandos documentados arrancan en headless.

## 4. Geometría y sondeo de movimiento

- [ ] 4.1 Exportar por id de arena límites, spawns, límites auxiliares, colisiones y polígonos de TileMap/TileSet, incluidas superficies unidireccionales, y leer constantes de `PlayerMovementConstants`; verificar geometría y constantes de todas las arenas del catálogo con pruebas.
- [ ] 4.2 Implementar sondeos aislados de salto y dash usando la escena de jugador y física reales; verificar posición de aterrizaje y que el marcador, el globo y la partida activa no cambian.
- [ ] 4.3 Documentar el esquema JSON de geometría y sondeo en `docs/`; verificar el ejemplo contra la exportación de una arena con plataformas unidireccionales.

## 5. Grafo y navegación

- [ ] 5.1 Implementar carga y validación del grafo versionado por nivel en `NavGraph` sobre `AStar2D`, respetando direccionalidad, costos y acciones por arista; verificar rutas ponderadas, referencias inválidas y conservación del grafo activo si falla una carga.
- [ ] 5.2 Añadir el seguidor que traduce aristas a intenciones `CPUBrain` y el overlay de nodos, aristas y ruta; verificar recorrido CPU entre nodos con WALK, JUMP, DASH, DROP y WALL_JUMP, y cambio correcto entre arenas.
- [ ] 5.3 Documentar en `docs/` el esquema JSON del grafo y un ejemplo con costos y acciones; verificar su carga y representación en el overlay.

## 6. Verificación integrada

- [ ] 6.1 Ejecutar una prueba end-to-end con cliente Python: resetear, intercambiar acciones/observaciones, consultar geometría, cargar y recorrer un grafo, finalizar episodios y cerrar; verificar repetibilidad con semilla y fallback tras desconexión.
