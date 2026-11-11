# OpenSpec Proposal — Sistema de IA y Lógica de la CPU

Lee este documento junto con `KEEPY_UPPY_OPENSPEC_BRIEF.md` y el documento de **Físicas y Sistema Competitivo**.

## 1. Objetivo

Definir la arquitectura lógica, parámetros configurables y comportamientos de la CPU basados en **IA clásica (Máquinas de Estados Finitos y Heurísticas)**, evitando modelos complejos de Machine Learning y garantizando un rendimiento óptimo, determinismo y control absoluto de la dificultad.

---

## 2. Decisiones Técnicas y Arquitectura

Para controlar a la CPU de forma fluida y predecible, se utilizará una **Máquina de Estados Finitos (FSM)** integrada en un nodo `cpu_controller.gd`.

### Principios de diseño:

- **Ausencia de Redes Neuronales:** La CPU tomará decisiones mediante cálculos vectoriales, proyecciones de trayectorias físicas y ponderación de prioridades por fotograma.
- **Configuración por Parámetros:** Todos los umbrales (tiempo de reacción, margen de error, velocidad de persecución) serán variables exportadas (`@export`) para permitir balanceo rápido desde el editor.
- **Simetría con el Jugador:** La CPU interactúa con las mismas físicas de movimiento, saltos y dashes que un jugador real, respetando las reglas de turno y prioridad.

---

## 3. Estados de la Máquina de Estados de la CPU (FSM)

La CPU evaluará su comportamiento dividiéndolo en dos estados principales según las reglas del turno y la posición del globo:

### Estado A: `CPU_TURNO_PROPIO` (Defensa y Devolución)

Se activa cuando el globo se dirige al campo de la CPU o le corresponde realizar el contacto válido para evitar perder el punto.

1. **Predicción de Trayectoria:**

- Calcula el punto de intersección $(x, y)$ donde el globo tocará la altura de golpeo de la CPU utilizando las ecuaciones de movimiento parametrizadas del globo.

2. **Movimiento hacia el Objetivo:**

- Mueve al personaje de la CPU hacia la coordenada calculada a velocidad máxima.

3. **Margen de Imperfección Humana:**

- Se introduce un vector de error aleatorio (`error_offset`) proporcional al nivel de dificultad para evitar que la CPU sea infalible.

4. **Decisión de Dash:**

- Si la distancia al punto de impacto es crítica y el tiempo de llegada es menor al umbral de reacción, activa la habilidad de _dash_.

### Estado B: `CPU_TURNO_RIVAL` (Supervivencia y Estorbo)

Se activa cuando es el turno del jugador humano de golpear el globo.

1. **Esquive de Emergencia (Alta Prioridad):**

- Si el globo o el jugador rival vienen en trayectoria de colisión directa hacia la posición actual de la CPU, esta se desplaza lateralmente a una zona segura para evitar un **doble toque (falta)**.

2. **Estorbo Táctico (Estratégico):**

- Si la CPU está a salvo del globo, cambia su objetivo para posicionarse en el camino más directo entre el jugador rival y la ubicación actual del globo, obstaculizando su paso físico mediante empujones.

---

## 4. Parámetros Configurables de Dificultad

El script `cpu_controller.gd` expondrá las siguientes variables para calibrar la IA:

- `reaction_time` (float): Retraso en segundos antes de que la CPU empiece a reaccionar al cambio de dirección del globo.
- `prediction_error_margin` (float): Desviación máxima en píxeles aplicada al punto de destino calculado.
- `aggression_level` (float): Probabilidad de que la CPU intente estorbar al rival en lugar de quedarse en zona neutral.
- `dash_threshold_distance` (float): Distancia mínima a la que la CPU decide gastar su _dash_ para alcanzar el globo.

---

## 5. Criterios de Aceptación

1. La CPU calcula correctamente la trayectoria del globo sin utilizar modelos de IA externa.
2. La CPU prioriza la devolución del globo cuando es su turno (`CPU_TURNO_PROPIO`).
3. La CPU evita tocar el globo de forma inválida (doble toque) cuando es el turno del rival (`CPU_TURNO_RIVAL`).
4. El nivel de dificultad es completamente ajustable modificando los parámetros exportados de reacción y error.
5. El comportamiento de la CPU es determinista bajo las mismas condiciones de partida.
