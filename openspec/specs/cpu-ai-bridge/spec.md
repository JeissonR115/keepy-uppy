# cpu-ai-bridge Specification

## Purpose
Permite conectar cerebros de CPU locales o remotos al movimiento existente y ejecutar partidas headless reproducibles con observación, geometría y navegación de cada arena.

## Requirements

### Requirement: Intercambio de cerebros de CPU
El bot SHALL obtener del cerebro activo las intenciones horizontal, salto, dash, dirección del dash, abajo y agarre, y SHALL aplicar esas intenciones mediante el movimiento normal del jugador.

#### Scenario: Usar el cerebro local
- **WHEN** una partida activa usa el cerebro local
- **THEN** la CPU conserva su comportamiento local y sus acciones pasan por la misma interfaz de intenciones

#### Scenario: Usar intenciones remotas
- **WHEN** el cerebro remoto entrega una acción válida
- **THEN** la CPU aplica todas sus intenciones, incluidas abajo y agarre, sin bloquearlas por ser un bot

#### Scenario: Mantener el control local
- **WHEN** dos jugadores humanos juegan sin un cerebro de CPU activo
- **THEN** sus controles y movimiento conservan el comportamiento actual

### Requirement: Protocolo de observación y acción
El puente SHALL intercambiar mensajes JSON por paso, con una observación suficiente para decidir y una acción que contenga todas las intenciones de CPU.

#### Scenario: Recibir una observación
- **WHEN** el cliente Python solicita el siguiente paso de decisión
- **THEN** recibe posiciones y velocidades de ambos jugadores y del globo, `waiting_for_first_touch`, turno esperado, `on_floor`, contacto con pared, cooldown y disponibilidad del dash, estamina, marcador y nivel actual

#### Scenario: Entregar una acción
- **WHEN** Python responde a una observación
- **THEN** la acción incluye intención horizontal, salto, dash, dirección del dash, abajo y agarre, y se aplica al paso correspondiente

#### Scenario: Mensaje inválido
- **WHEN** el puente recibe JSON malformado, un tipo desconocido o campos requeridos inválidos
- **THEN** responde con un error identificable y no aplica una acción parcial

### Requirement: Control del entorno por cliente
El puente SHALL permitir reiniciar una partida con semilla y nivel, avanzar pasos de física, cambiar la velocidad de simulación, consultar la geometría, cargar un grafo de navegación y cerrar la sesión.

#### Scenario: Reiniciar una partida
- **WHEN** el cliente envía `reset` con semilla y nivel válidos
- **THEN** el entorno reinicia la partida en ese nivel y devuelve la primera observación

#### Scenario: Avanzar la simulación
- **WHEN** el cliente envía `step(n)` con un número positivo de pasos
- **THEN** el entorno avanza hasta `n` pasos de física o hasta terminar el episodio y devuelve la observación resultante

#### Scenario: Consultar y cargar datos de nivel
- **WHEN** el cliente solicita geometría o envía un grafo para el nivel activo
- **THEN** Godot devuelve la geometría o confirma la carga del grafo para ese nivel

#### Scenario: Cerrar la sesión
- **WHEN** el cliente envía `close`
- **THEN** el puente deja de aceptar comandos de esa sesión y libera sus recursos

### Requirement: Fallback ante pérdida del puente
La CPU SHALL cambiar al cerebro local cuando el cliente remoto se desconecte o exceda el timeout, sin detener ni corromper la partida.

#### Scenario: Python se desconecta
- **WHEN** el socket remoto se cierra durante una partida
- **THEN** la siguiente decisión de CPU proviene del cerebro local y la partida continúa

#### Scenario: Python excede el timeout
- **WHEN** el cerebro remoto no responde dentro del límite configurado
- **THEN** Godot registra el fallo, descarta esa respuesta tardía y continúa con el cerebro local

### Requirement: Simulación reproducible de episodios
El entorno SHALL ejecutar sin menús con paso de física fijo y velocidad configurable, y SHALL reiniciar partidas por semilla y nivel.

#### Scenario: Repetir un episodio
- **WHEN** se ejecutan dos episodios con la misma semilla, nivel, configuración y secuencia de acciones
- **THEN** producen los mismos eventos y resultados bajo la misma versión y configuración de Godot

#### Scenario: Cambiar velocidad
- **WHEN** el cliente cambia la velocidad de simulación
- **THEN** aumenta o reduce el avance de la simulación sin cambiar la duración de un paso de física

#### Scenario: Ejecutar una batería headless
- **WHEN** el lanzador recibe puerto, nivel, velocidad y semilla
- **THEN** inicia el entorno sin menús y permite ejecutar episodios CPU contra CPU o contra un jugador scripteado

### Requirement: Resultados de episodio observables
El entorno SHALL señalar el fin de cada episodio e identificar el resultado y su motivo, incluidos punto anotado, falta y set terminado.

#### Scenario: Termina un punto o una falta
- **WHEN** la partida resuelve un punto o una falta
- **THEN** el cliente recibe un evento terminal con el tipo, el jugador afectado y el motivo de la resolución

#### Scenario: Termina un set o una partida
- **WHEN** se alcanza la condición de fin de set o partida
- **THEN** el cliente recibe el evento correspondiente con marcador y ganador

### Requirement: Geometría y sondeo físico por arena
El entorno SHALL exportar por nivel los límites, spawns, colisiones y plataformas —incluidas las unidireccionales— junto con las constantes de movimiento vigentes.

#### Scenario: Descargar geometría
- **WHEN** Python consulta la geometría de una arena válida del catálogo
- **THEN** recibe sus límites, spawns, superficies sólidas y unidireccionales y constantes leídas de la fuente de movimiento del juego

#### Scenario: Sondear movimiento real
- **WHEN** Python solicita probar un salto o dash desde una posición y dirección
- **THEN** Godot simula la acción con la física y geometría reales y devuelve el resultado del movimiento, incluido dónde aterriza

#### Scenario: Consultar niveles de distinto tamaño
- **WHEN** se consulta más de una arena del catálogo
- **THEN** cada exportación conserva sus propios límites, geometría y spawns sin asumir un tamaño global

### Requirement: Grafo de navegación por nivel
Godot SHALL cargar un grafo JSON con nodos, aristas dirigidas o bidireccionales, acción y costo, y SHALL exponer rutas mediante AStar2D.

#### Scenario: Cargar y dibujar un grafo
- **WHEN** Python entrega un grafo válido para el nivel activo
- **THEN** Godot lo carga, puede dibujar nodos y aristas en el overlay y permite mostrar la ruta activa

#### Scenario: Recorrer una ruta
- **WHEN** la CPU recibe un destino alcanzable en un grafo cargado
- **THEN** el cerebro activo sigue la ruta y emite la acción asociada a cada arista

#### Scenario: Cambiar de nivel
- **WHEN** se selecciona otra arena
- **THEN** se usa únicamente el grafo asociado a esa arena y sus dimensiones

### Requirement: Documentación del protocolo
El proyecto SHALL documentar en `docs/` los formatos JSON de observación, acción, control, geometría y grafo, incluidos errores y ciclo de conexión.

#### Scenario: Implementar un cliente mínimo
- **WHEN** un desarrollador consulta la documentación
- **THEN** puede conectar un cliente Python, reiniciar, intercambiar acciones y observaciones, consultar geometría y cerrar la sesión sin inferir campos no documentados
