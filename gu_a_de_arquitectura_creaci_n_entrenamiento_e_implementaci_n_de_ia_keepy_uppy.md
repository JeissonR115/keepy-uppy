# Guía de Arquitectura: Creación, Entrenamiento e Implementación de IA para *Keepy Uppy*

Este documento resume el flujo técnico completo para diseñar, entrenar (en PC local o gratis en la nube con Google Colab) e integrar un bot competitivo en **Godot 4** con movilidad estilo *Celeste* y reglas tácticas por turnos.

## 1. Arquitectura General (Enfoque Híbrido)

Entrenar una red neuronal desde cero leyendo píxeles tarda semanas y suele fallar en juegos de plataformas con físicas complejas. La arquitectura óptima divide el problema en **dos sistemas desacoplados**:

1. **Cerebro Táctico (Entrenado en Python):** Una red neuronal ligera o árbol de políticas que recibe datos numéricos exactos (posiciones, velocidades, estado de turnos) y decide los *inputs* virtuales (`izquierda`, `derecha`, `salto`, `dash`).

2. **Cuerpo y Físicas (Ejecutado en Godot 4):** El archivo entrenado se exporta en formato estándar (`.onnx` o `.json`) y se carga en `cpu_controller.gd`, ejecutando exactamente las mismas físicas que un jugador humano.

## 2. Fase 1: Diseño del Entorno de Simulación (Python / Gymnasium)

Para entrenar rápido sin esperar a que rendericen los gráficos de Godot (60 FPS), creamos una simulación matemática pura en Python usando **Gymnasium** (puede correr a +5,000 FPS sin ventana gráfica).

### 2.1 Espacio de Observación (Inputs de la IA)

En cada paso de simulación, la IA recibe un vector normalizado con \~16 valores numéricos:

* **Estado propio:** Posición $(x, y)$, velocidad $(v_x, v_y)$, `can_dash` (0 o 1), `is_on_floor` (0 o 1).

* **Estado del balón:** Posición relativa al bot $(\Delta x, \Delta y)$, velocidad $(v_{bx}, v_{by})$ y punto estimado de caída.

* **Estado del rival:** Posición relativa al bot $(\Delta x_r, \Delta y_r)$ y velocidad.

* **Regla de turno:** `is_my_turn` (`1.0` si me toca golpear el balón, `-1.0` si es turno del rival).

* **Sensores de entorno (Raycasts):** 4 a 8 distancias hacia las plataformas o muros más cercanos.

### 2.2 Espacio de Acciones (Outputs de la IA)

La IA devuelve las acciones discretas o continuas que alimentarán al controlador:

* Movimiento horizontal: `[-1 (Izquierda), 0 (Quieto), 1 (Derecha)]`

* Salto: `[0, 1]`

* Dash: `[0, 1]` + Dirección del dash (8 direcciones).

### 2.3 Sistema de Recompensas (*Reward Shaping*)

El éxito del entrenamiento depende de premiar y castigar correctamente las reglas del juego:

| Evento / Situación | Recompensa | Propósito | 
| ----- | ----- | ----- | 
| **Tocar el balón en MI turno** | `+5.0` | Objetivo principal ofensivo. | 
| **Acercarse al punto de caída en MI turno** | `+0.05 / frame` | Guía al bot hacia la trayectoria del globo. | 
| **Anotar un punto (el balón cae en turno rival)** | `+15.0` | Victoria de ronda. | 
| **Tocar el balón en turno RIVAL (Falta)** | `-10.0` | Enseña a esquivar cuando no es su turno. | 
| **Interponerse entre rival y balón (turno rival)** | `+0.03 / frame` | Fomenta bloquear o estorbar al oponente. | 
| **Dejar caer el balón en MI turno** | `-15.0` | Penalización por perder el punto. | 

## 3. Fase 2: Entrenamiento del Modelo

### Herramientas Recomendadas

* **Librería de RL:** `Stable-Baselines3` (Algoritmo **PPO** - *Proximal Policy Optimization*) o `NEAT-Python` (algoritmos genéticos).

* **Aceleración:** **Google Colab** (ofrece GPU T4 gratuita en el navegador; acelera el entrenamiento entre 10x y 20x respecto a una CPU de laptop estándar).

### Flujo de Entrenamiento (Self-Play)

1. **Etapa 1 (Solo contra la gravedad):** El bot entrena solo en la arena aprendiendo a moverse, saltar, usar el *dash* y mantener el globo en el aire sin que toque el suelo.

2. **Etapa 2 (Self-Play Competitivo):** Se enfrentan dos copias de la misma IA siguiendo las reglas de turnos. Una aprende a atacar y la otra aprende simultáneamente a esquivar y estorbar.

3. **Exportación:** Al alcanzar una tasa de éxito estable (ej. 500,000 a 1,000,000 de pasos, \~15–30 min en Google Colab), se exportan los pesos del modelo a un archivo `bot_brain.onnx` o `bot_weights.json`.

## 4. Fase 3: Implementación en Godot 4

Una vez descargado el archivo entrenado, la integración dentro de tu proyecto (`src/models/player/`) sigue tu regla de modularidad (< 400 líneas por archivo):

### Estructura de Archivos en Godot

1. **`res://assets/ai/bot_weights.json` (o `.onnx`):** Archivo con los pesos entrenados de la red neuronal.

2. **`src/models/player/ai_inference.gd` (\~120 líneas):**

   * Carga el archivo JSON con los pesos de las capas densas (*Linear + ReLU/Tanh*).

   * Realiza la multiplicación de matrices en GDScript puro (toma menos de `0.1 ms` por frame, sin necesidad de plugins externos pesados).

3. **`src/models/player/cpu_sensor.gd` (\~100 líneas):**

   * Recolecta las posiciones del jugador, rival, balón y estado del turno (`MatchManager`).

   * Normaliza los datos en el mismo formato usado durante el entrenamiento en Python.

4. **`src/models/player/cpu_controller.gd` (\~130 líneas):**

   * Llama a `cpu_sensor.gd` -> pasa los datos a `ai_inference.gd` -> recibe las acciones (`move_dir`, `jump`, `dash`) y las inyecta en `player_controller.gd`.

## 5. Checklist de Ejecución Paso a Paso

* \[ \] **Paso 1:** Escribir el entorno simulado en Python (`keepy_uppy_env.py`) replicando las constantes de gravedad, salto y *dash* de `player_movement_constants.gd`.

* \[ \] **Paso 2:** Subir el script a un notebook de **Google Colab** e instalar `stable-baselines3[extra]` y `gymnasium`.

* \[ \] **Paso 3:** Ejecutar el entrenamiento con *Self-Play* y validar que el agente respete los turnos y use el *dash* para rescates.

* \[ \] **Paso 4:** Exportar los pesos de la red neuronal a un archivo `.json` ligero.

* \[ \] **Paso 5:** Implementar `cpu_sensor.gd` y `ai_inference.gd` en Godot 4 y conectarlos a `cpu_controller.gd`.

* \[ \] **Paso 6:** Ejecutar las pruebas unitarias (`tests/test_cpu_controller.gd`) y ajustar dificultad añadiendo un pequeño retardo de reacción (*reaction delay*) según el nivel seleccionado.