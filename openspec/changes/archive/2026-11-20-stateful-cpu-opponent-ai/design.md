# Design

## Context

Ver `proposal.md` para la motivación y `specs/cpu-opponent/spec.md` para el contrato de comportamiento. Hoy `PlayerController` contiene la lógica del bot en funciones de entrada: solo la activa cuando `bot_enabled`, la partida está activa y `expected_balloon_player == self`. `MatchManager` ya expone el jugador esperado y resuelve contactos y faltas. `BalloonController` es un `RigidBody2D` con velocidad lineal, gravedad, resistencia, límites de velocidad y rebotes configurables. Ambos personajes ya comparten movimiento, salto, dash y colisiones.

## Goals / Non-Goals

**Goals:**
- Separar la elección de acciones de CPU de la simulación física compartida del jugador.
- Resolver la contradicción entre imperfección aleatoria y repetibilidad mediante aleatoriedad pseudoaleatoria con semilla de partida explícita y flujo local de CPU.
- Mantener los turnos, la aplicación de contactos y las faltas bajo las reglas actuales.
- Hacer que el predictor falle de forma acotada cuando la trayectoria futura deje de ser confiable.

**Non-Goals:**
- Cambiar las reglas del partido, la puntuación, la prioridad, las físicas del globo o los controles humanos.
- Añadir dificultad por Machine Learning, servicios externos, multijugador en línea o nuevas habilidades de movimiento.
- Garantizar una predicción exacta después de colisiones no observadas o interacciones futuras con jugadores.

## Decisions

### Controlador de CPU desacoplado del movimiento

Introducir un nodo hijo `CPUController` en la escena del jugador, con lógica en `src/models/player/cpu_controller.gd`, como responsable de estado, predicción y selección de intención. Mantener `PlayerController` como autoridad de movimiento: recibe las intenciones tipadas de dirección horizontal, salto y dash y las pasa por los mismos límites, cooldowns y acciones usados por el jugador. El componente solo produce decisiones cuando `bot_enabled` está activo.

Alternativa considerada: conservar heurísticas dentro de `PlayerController`. Se descarta porque mezcla estrategia con física y hace difícil probar la máquina de estados y los parámetros sin ejecutar la lógica completa de movimiento. No se propone simular un segundo personaje ni inyectar eventos globales de `Input`.

### Máquina de estados derivada del estado autoritativo

Usar estados de CPU `INACTIVE`, `CPU_TURNO_PROPIO` y `CPU_TURNO_RIVAL`. Derivar cambios de turno de `MatchManager.expected_balloon_player` y de `match_state`; no duplicar turnos en una segunda fuente de verdad. Al entrar en un estado, reiniciar los temporizadores y la decisión de agresividad que correspondan. En el turno propio, perseguir el punto de intercepción; en el turno rival, comprobar primero la amenaza y evadirla; solo si el área es segura se permite posicionarse entre el humano y el globo.

Alternativa considerada: representar la FSM dentro de `MatchManager`. Se descarta porque la elección de movimiento es responsabilidad del actor CPU; el gestor conserva únicamente el estado competitivo y valida todos los contactos, incluso si un movimiento de evasión causa accidentalmente una falta.

### Predicción física determinista y acotada

Predecir el siguiente cruce de la altura de contacto a partir de posición y velocidad del `RigidBody2D`, gravedad del proyecto y parámetros de resistencia y límites del globo. Avanzar en pasos del tick de física (60 Hz) para aplicar de forma reproducible la integración conocida, hasta un horizonte configurable. Tratar paredes y techo solo cuando su geometría y respuesta estén definidas; detener la predicción ante suelo, una colisión observada, datos no finitos o un resultado fuera del horizonte. Si la predicción termina sin intercepción confiable, usar una posición de recuperación limitada a la arena en vez de continuar una persecución indefinida.

Las predicciones de giro libre no pueden conocer futuras colisiones con personajes o escenario. Por eso se recalculan a partir del estado real y el dash se decide por tiempo/distancia de alcance comparados con las capacidades compartidas del jugador, no por una ruta inventada que atraviese obstáculos.

Alternativa considerada: extrapolar solo una parábola analítica. Se descarta como estrategia única porque el globo también tiene amortiguación, límites y rebotes; el avance fijo aprovecha las reglas conocidas y mantiene un límite superior claro de trabajo por tick.

### Reacción, imperfección y agresividad repetibles

Exponer `reaction_time`, `prediction_error_margin`, `aggression_level` y `dash_threshold_distance` en el controlador de CPU; añadir un horizonte máximo acotado si no existe uno apropiado. Restringir los valores a dominios válidos. Aplicar `reaction_time` al iniciar una respuesta o cambiar de manera relevante el objetivo, no a cada actualización física. Mantener un generador pseudoaleatorio local cuya semilla se derive del estado/semilla de partida y del actor, y consumir sus valores solo en transiciones definidas de la FSM. El offset se elige una vez por decisión de interceptación dentro del margen, no se vuelve a sortear cada frame. La agresividad se evalúa al entrar en la fase rival y se conserva hasta que cambie el contexto.

Esto conserva variación entre semillas sin depender del estado global aleatorio del juego ni permitir oscilación por fotograma. Con la misma semilla, configuración y secuencia física, las decisiones son repetibles. Si la partida no expone una semilla estable, la integración deberá proveerla sin cambiar el sorteo competitivo existente.

Alternativa considerada: usar `randf()` global por frame. Se descarta porque interfiere con otros usos aleatorios, dificulta las pruebas y contradice la repetibilidad.

### Interacción con reglas y escenas existentes

Mantener `bot_enabled` como activación existente del modo de un jugador. Añadir el nodo al `player_placeholder.tscn` común; el jugador humano no lo activa y el CPU conserva su configuración en la misma escena. No alterar `BalloonController` o `MatchManager` salvo para leer estado/semilla si hace falta. La selección de un dash debe pasar por disponibilidad, dirección y cooldown existentes. El contacto fuera de turno seguirá siendo una falta mediante el gestor.

Actualizar `docs/modules/player.md` y extender pruebas de interacción para estados, predicción con límites, intención de dash, evasión y reproducibilidad. Agregar pruebas deterministas del predictor con estados iniciales controlados; no depender de una partida completa aleatoria para probar cálculo geométrico.

## Risks / Trade-offs

- [La integración del globo con el motor y sus colisiones puede desviarse del predictor] → Recalcular desde el estado físico real cada tick, limitar el horizonte y cancelar la predicción al detectar una colisión o condición no soportada.
- [Una evasión no puede impedir siempre que el globo contacte al CPU] → No falsificar ni filtrar contactos; dejar que `MatchManager` resuelva el evento según las reglas vigentes.
- [Una agresividad alta puede sentirse injusta o impedir la lectura del juego] → Mantenerla configurable, usar una decisión estable por fase y validar valores extremos en pruebas.
- [La extracción puede cambiar inadvertidamente el comportamiento del bot actual] → Mantener las físicas y condiciones de activación existentes, añadir casos de regresión para el movimiento actual hacia el globo y revisar por separado el nuevo comportamiento rival.
- [Si no se expone una semilla de partida, repetir una partida completa podría no repetir el bot] → Definir una semilla explícita para el controlador y probar el generador local independientemente del sorteo de servidor.

## Migration Plan

1. Añadir y probar el controlador de CPU y sus decisiones sin quitar la ruta actual del bot.
2. Conectar las intenciones al movimiento compartido y activar los estados de turno.
3. Migrar las decisiones existentes al nuevo componente, conservar `bot_enabled` y validar pruebas de regresión.
4. Documentar la configuración y eliminar la lógica duplicada anterior una vez que las pruebas del bot pasen.

Rollback: retirar el componente y restaurar la lectura de las decisiones bot por `PlayerController`; no hay migración de datos ni cambios de formato persistente.
