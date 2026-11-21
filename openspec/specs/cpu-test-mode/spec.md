# cpu-test-mode Specification

## Purpose
Proporciona un modo local de prueba para observar a una CPU que navega de forma autónoma por las arenas, explica sus decisiones y permite inspeccionar o controlar el avance de la simulación.

## Requirements

### Requirement: Autonomous CPU navigation
In Test CPU mode, the CPU SHALL autonomously select and follow a reachable navigation-graph route toward an interception target without Python or externally supplied route commands.

#### Scenario: Pursue a predicted interception
- **WHEN** la CPU tiene el turno, hay un grafo válido y el predictor encuentra una intercepción
- **THEN** selecciona un destino alcanzable próximo a esa posición, sigue la ruta correspondiente y actualiza el destino cuando la intercepción pase a otro nodo objetivo

#### Scenario: No reachable target or no graph
- **WHEN** no existe un grafo válido o ningún nodo con ruta desde la posición actual ofrece un destino razonable
- **THEN** la partida continúa sin error fatal y la CPU usa el comportamiento local de respaldo

#### Scenario: CPU turn FSM
- **WHEN** la CPU decide en un tick del modo de prueba
- **THEN** expone uno de los estados SERVE, POSITION, HIT o AVOID y ejecuta la acción correspondiente al saque, navegación, contacto o evasión

#### Scenario: Respect turn and downward-hit rules
- **WHEN** el turno esperado pertenece al rival o una acción pudiera contactar el globo con impulso descendente
- **THEN** la CPU no golpea fuera de turno ni ejecuta el golpe descendente

#### Scenario: Deterministic test behavior
- **WHEN** la CPU juega en Test CPU mode con el mismo estado inicial
- **THEN** la selección de destino no añade errores de predicción ni decisiones de obstrucción aleatorias

### Requirement: Bundled arena navigation graphs
Test CPU mode SHALL load a versioned navigation graph for the selected arena from the game project when one is available.

#### Scenario: Graph matches selected arena
- **WHEN** se inicia una arena cuyo archivo de grafo existe y es válido
- **THEN** el modo carga el grafo correspondiente a esa arena y la CPU puede usarlo para navegar

#### Scenario: Graph is missing or invalid
- **WHEN** el archivo de grafo de la arena falta o no supera la validación
- **THEN** el modo conserva la partida y activa el comportamiento CPU de respaldo

### Requirement: Per-tick CPU decision telemetry
Test CPU mode SHALL expose a UI-independent decision snapshot for each CPU update containing the decision state, concise reason, target position, current node, active route, current edge, intent, and last route-change reason.

#### Scenario: Decision snapshot updates
- **WHEN** la CPU procesa un tick
- **THEN** la telemetría refleja el estado, motivo, objetivo, nodo, ruta, arista e intenciones de esa decisión

#### Scenario: Route changes
- **WHEN** la CPU selecciona o recalcula una ruta
- **THEN** la telemetría registra la razón del cambio y el nuevo recorrido

### Requirement: CPU debugging visualization
Test CPU mode SHALL provide independently toggleable graph, active-route, previous-route, target, and predicted-balloon-trajectory layers, plus live decision status and reason.

#### Scenario: Toggle visualization layers
- **WHEN** el usuario alterna una capa de depuración
- **THEN** solo la capa seleccionada cambia de visibilidad y la simulación continúa

#### Scenario: Inspect live decision
- **WHEN** la CPU cambia de estado, objetivo o intención
- **THEN** el panel y la etiqueta sobre la CPU muestran el estado y motivo actuales

### Requirement: Simulation controls in Test CPU mode
Test CPU mode SHALL provide controls to pause, advance exactly one physics tick, and run in slow motion.

#### Scenario: Pause and single-step
- **WHEN** el usuario pausa y solicita avanzar un tick
- **THEN** la simulación ejecuta exactamente un tick de física y vuelve a quedar pausada

#### Scenario: Slow motion
- **WHEN** el usuario activa cámara lenta
- **THEN** el modo avanza la simulación a una escala temporal reducida y permite volver a velocidad normal

### Requirement: Test CPU menu flow isolation
The main menu SHALL offer a Test CPU flow that selects an arena from the current catalog, starts a player-versus-CPU match with debugging visualization active, and returns to the main menu without changing normal match behavior.

#### Scenario: Start Test CPU match
- **WHEN** el usuario elige Test CPU, selecciona una arena y confirma
- **THEN** se inicia una partida jugador contra CPU en esa arena y se activa su depuración visual

#### Scenario: Return to menu
- **WHEN** el usuario sale del modo Test CPU
- **THEN** vuelve al menú principal y la siguiente partida normal inicia sin overlay ni comportamiento autónomo exclusivo del modo de prueba

#### Scenario: Existing modes remain unchanged
- **WHEN** el usuario elige el modo normal de uno o dos jugadores
- **THEN** se conservan sus reglas, navegación de menú y presentación vigentes sin panel ni overlay de Test CPU
