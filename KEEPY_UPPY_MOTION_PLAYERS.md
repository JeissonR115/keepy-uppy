# Guía de implementación: movimiento del jugador (estilo Celeste, multijugador)

Instrucciones para la IA que implemente el sistema. Seguir el orden indicado y cumplir los criterios de aceptación del final.

## 1. Objetivo

Implementar el movimiento de Madeline (Celeste) en un jugador 2D con estas **tres diferencias**:

1. **Capa en lugar de cabello:** el personaje lleva una **capa** (_cape_) simulada que se genera al aparecer, cuelga de dos puntos de agarre en el personaje y se mueve con él (sección 10).
2. **Color de la capa = color del jugador** (juego multijugador). No se usan rojo/azul/rosa de Celeste.
3. **Indicador de dash por saturación de la capa:**
   - Dash disponible: color del jugador **vivo** (saturado y brillante).
   - Al usar el dash: la capa pasa a color **apagado** (mismo tono, menos saturación y brillo).
   - Permanece apagado hasta **tocar el suelo**, momento en que el dash se recarga y el color vuelve a vivo.

Todo lo demás (física, curvas, tolerancias) debe replicar Celeste.

## 2. Supuestos (ajustar si el proyecto difiere)

- Motor: **Godot 4**, jugador como `CharacterBody2D`, GDScript.
- Un solo dash por defecto (sin cristales de recarga; opcional más adelante).
- Los jugadores **no colisionan entre sí**.
- Cada jugador controla su propio personaje (autoridad del cliente dueño).
- Unidades: píxeles y segundos; eje Y positivo hacia abajo; simulación en `_physics_process` a **60 Hz** (`Project Settings > Physics > Ticks per Second = 60`).
- Si la escala del juego difiere de 320x180 con tiles de 8 px, **escalar todas las constantes de distancia y velocidad proporcionalmente**.

## 3. Entradas (Input Map)

| Acción                        | Uso                                            |
| ----------------------------- | ---------------------------------------------- |
| `left`, `right`, `up`, `down` | Movimiento y dirección de dash (8 direcciones) |
| `jump`                        | Salto (mantener = salto más alto)              |
| `dash`                        | Dash                                           |
| `grab`                        | Agarrar pared (mantener)                       |

## 4. Constantes

Crear un archivo `player_constants.gd` (o un `Resource`) con estos valores, sin números mágicos en el resto del código.

```gdscript
# Horizontal
const MAX_RUN := 90.0
const RUN_ACCEL := 1000.0
const RUN_REDUCE := 400.0
const AIR_MULT := 0.65

# Vertical
const GRAVITY := 900.0
const MAX_FALL := 160.0
const FAST_MAX_FALL := 240.0
const FAST_MAX_ACCEL := 300.0
const HALF_GRAV_THRESHOLD := 40.0

# Salto
const JUMP_SPEED := -105.0
const JUMP_H_BOOST := 40.0
const VAR_JUMP_TIME := 0.2
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.08
const CEILING_CORNER_CORRECTION := 4   # px

# Dash
const DASH_SPEED := 240.0
const DASH_TIME := 0.15
const DASH_FREEZE := 0.05
const DASH_COOLDOWN := 0.2
const DASH_REFILL_COOLDOWN := 0.1
const END_DASH_SPEED := 160.0
const END_DASH_UP_MULT := 0.75
const DASH_CORNER_CORRECTION := 4      # px

# Super / Hyper / Ultra
const SUPER_JUMP_H := 260.0
const DUCK_SUPER_X_MULT := 1.25
const DUCK_SUPER_Y_MULT := 0.5
const ULTRA_MULT := 1.2

# Pared
const WALL_CHECK_DIST := 3             # px, wall jump
const WALL_JUMP_H := 130.0
const WALL_JUMP_FORCE_TIME := 0.16
const SUPER_WALL_JUMP_SPEED := -160.0
const SUPER_WALL_JUMP_H := 170.0
const SUPER_WALL_JUMP_VAR_TIME := 0.25
const SUPER_WALL_JUMP_FORCE_TIME := 0.2
const WALL_SLIDE_START := 20.0
const WALL_SLIDE_TIME := 1.2

# Agarre y escalada
const CLIMB_CHECK_DIST := 2            # px
const CLIMB_MAX_STAMINA := 110.0
const CLIMB_UP_COST := 45.5            # por segundo
const CLIMB_STILL_COST := 10.0         # por segundo
const CLIMB_JUMP_COST := 27.5
const CLIMB_UP_SPEED := -45.0
const CLIMB_DOWN_SPEED := 80.0
const CLIMB_TIRED_THRESHOLD := 20.0
```

Función base: `move_toward(valor, objetivo, paso)` equivale al `Approach` de Celeste. Casi todas las curvas se construyen con ella.

## 5. Estado del jugador

Máquina de estados mínima: `NORMAL`, `DASH`, `CLIMB`. Variables:

```gdscript
var state := State.NORMAL
var facing := 1
var ducking := false

# Timers (se decrementan cada tick)
var coyote := 0.0
var jump_buffer := 0.0
var var_jump_timer := 0.0
var var_jump_speed := 0.0
var force_move_x := 0          # input horizontal forzado tras wall jump
var force_move_timer := 0.0
var wall_slide_timer := WALL_SLIDE_TIME

# Dash
var dash_available := true
var dash_dir := Vector2.ZERO
var dash_timer := 0.0
var dash_cooldown := 0.0
var dash_refill_cooldown := 0.0

# Agarre
var stamina := CLIMB_MAX_STAMINA
```

## 6. Orden de actualización por tick

1. Leer input y actualizar timers (`coyote`, `jump_buffer`, `dash_cooldown`, etc.).
2. Recargar dash y stamina si corresponde (sección 8).
3. Ejecutar la lógica del estado actual (`NORMAL`, `DASH` o `CLIMB`).
4. Aplicar `move_and_slide()` con corner correction.
5. Detectar transiciones (aterrizaje, golpe de techo, pared).
6. Actualizar la capa (secciones 9 y 10) y sincronizar red (sección 11).

## 7. Mecánicas a implementar

### 7.1 Movimiento horizontal (estado NORMAL)

```gdscript
var mult := 1.0 if is_on_floor() else AIR_MULT
if absf(velocity.x) > MAX_RUN and signf(velocity.x) == move_x:
    velocity.x = move_toward(velocity.x, MAX_RUN * move_x, RUN_REDUCE * mult * delta)
else:
    velocity.x = move_toward(velocity.x, MAX_RUN * move_x, RUN_ACCEL * mult * delta)
```

**Regla crítica:** el exceso de velocidad (sobre `MAX_RUN`) decae lento solo si el input sigue en la misma dirección. Sin input o con input contrario se aplica la aceleración rápida y la velocidad se pierde casi de inmediato. No añadir fricción extra.

Durante `force_move_timer > 0`, usar `force_move_x` en lugar del input.

### 7.2 Gravedad

```gdscript
if not is_on_floor():
    var g_mult := 1.0
    if absf(velocity.y) <= HALF_GRAV_THRESHOLD and Input.is_action_pressed("jump"):
        g_mult = 0.5
    var max_fall := MAX_FALL
    if Input.is_action_pressed("down") and velocity.y >= MAX_FALL:
        max_fall = FAST_MAX_FALL
    velocity.y = move_toward(velocity.y, max_fall, GRAVITY * g_mult * delta)
```

No aplicar gravedad durante el estado `DASH`.

### 7.3 Salto, coyote time y buffer

```gdscript
if jump_buffer > 0.0 and coyote > 0.0:
    jump_buffer = 0.0
    coyote = 0.0
    velocity.x += JUMP_H_BOOST * move_x
    velocity.y = JUMP_SPEED
    var_jump_timer = VAR_JUMP_TIME
    var_jump_speed = velocity.y

if var_jump_timer > 0.0:
    if Input.is_action_pressed("jump"):
        velocity.y = minf(velocity.y, var_jump_speed)
    else:
        var_jump_timer = 0.0
    var_jump_timer -= delta
```

- `coyote` se reinicia a `COYOTE_TIME` mientras `is_on_floor()`; si no, decrece.
- `jump_buffer` se pone en `JUMP_BUFFER` al presionar `jump` y decrece.
- **Corner correction:** si al subir se golpea el techo con solape menor o igual a 4 px en horizontal, desplazar al jugador lateralmente para rodear la esquina en lugar de detenerlo.
- Si se golpea el techo, cancelar `var_jump_timer` (tras una pequeña gracia de 0.05 s).

### 7.4 Dash

**Inicio** (en `NORMAL` o `CLIMB`): `dash` presionado, `dash_available == true` y `dash_cooldown <= 0`.

1. `dash_available = false` **de inmediato** (esto dispara la capa apagada, sección 9).
2. `dash_cooldown = DASH_COOLDOWN`, `dash_refill_cooldown = DASH_REFILL_COOLDOWN`.
3. Congelar al jugador `DASH_FREEZE` s (freeze frame; solo ese jugador, no pausar el árbol completo porque es multijugador). Durante el freeze, permitir actualizar la dirección con el input.
4. Dirección: `Input.get_vector(left, right, up, down)` normalizado; si es cero, usar `Vector2(facing, 0)`.
5. Estado `DASH`, `dash_timer = DASH_TIME`.

**Durante el dash:** `velocity = dash_dir * DASH_SPEED`, sin gravedad. Corner correction de 4 px al chocar esquinas.

**Fin del dash** (por tiempo): `velocity = dash_dir * END_DASH_SPEED`; si `velocity.y < 0`, `velocity.y *= END_DASH_UP_MULT`. Volver a `NORMAL`.

**Dash hacia abajo en suelo:** activa `ducking = true` (hitbox reducida), necesario para el hyper.

### 7.5 Super, Hyper, Ultra y Wall bounce

Todas se evalúan **dentro del estado DASH**:

| Técnica         | Condición                                                                    | Efecto                                                                                                                                                                                      |
| --------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ultra**       | Tocar suelo durante un dash diagonal hacia abajo                             | `velocity.x *= ULTRA_MULT`, `velocity.y = 0`, `ducking = true`; el dash continúa por el tiempo restante                                                                                     |
| **Super jump**  | En suelo, `jump` presionado, `dash_dir.y == 0` (horizontal)                  | `velocity.x = SUPER_JUMP_H * facing`, `velocity.y = JUMP_SPEED`; terminar dash                                                                                                              |
| **Hyper jump**  | En suelo, `jump` presionado, `ducking == true` (dash diagonal abajo)         | Igual que super, luego `velocity.x *= DUCK_SUPER_X_MULT` (resultado 325) y `velocity.y *= DUCK_SUPER_Y_MULT`; `ducking = false`; terminar dash                                              |
| **Wall bounce** | `jump` presionado, `dash_dir == (0, -1)`, pared a menos de `WALL_CHECK_DIST` | `velocity.y = SUPER_WALL_JUMP_SPEED`, `velocity.x = SUPER_WALL_JUMP_H` alejándose de la pared; `var_jump_timer = SUPER_WALL_JUMP_VAR_TIME`; `force_move_timer = SUPER_WALL_JUMP_FORCE_TIME` |

Tras estas técnicas el exceso de velocidad se conserva con la regla de 7.1. Para permitir encadenar, **usar siempre el buffer de salto** al aterrizar.

### 7.6 Pared: deslizamiento y salto

- **Wall slide:** en el aire, cayendo (`velocity.y > 0`) y empujando hacia la pared: limitar la velocidad de caída a `WALL_SLIDE_START` y aumentarla linealmente hasta `MAX_FALL` en `WALL_SLIDE_TIME` s.
- **Wall jump:** `jump` con pared a menos de `WALL_CHECK_DIST` (no requiere estar agarrado):
  - `velocity.x = WALL_JUMP_H * dirección_opuesta_a_la_pared`, `velocity.y = JUMP_SPEED`.
  - `force_move_x = dirección_opuesta`, `force_move_timer = WALL_JUMP_FORCE_TIME`.
  - Activar salto variable igual que en 7.3.

### 7.7 Agarre y escalada (estado CLIMB)

- Entrar: `grab` mantenido, pared a menos de `CLIMB_CHECK_DIST`, `stamina > 0`.
- Salir: soltar `grab`, quedarse sin stamina o perder la pared.
- Velocidad vertical: subir `CLIMB_UP_SPEED`, bajar `CLIMB_DOWN_SPEED`, quieto 0.
- Consumo por segundo: subir `CLIMB_UP_COST`, quieto `CLIMB_STILL_COST`. Saltar desde el agarre consume `CLIMB_JUMP_COST`.
- Con `stamina < CLIMB_TIRED_THRESHOLD`, el personaje parpadea (feedback visual).
- Sin gravedad mientras se agarra.

## 8. Recarga de dash y stamina

Ejecutar cada tick, fuera del estado `DASH`:

```gdscript
dash_refill_cooldown -= delta
if is_on_floor():
    stamina = CLIMB_MAX_STAMINA
    if not dash_available and dash_refill_cooldown <= 0.0:
        dash_available = true     # dispara capa viva
```

**El dash solo se recarga al tocar el suelo** (no al tocar pared ni en el aire). `dash_refill_cooldown` evita recargar en el mismo tick en que se inició un dash desde el suelo.

## 9. Capa: color y estados visuales

### 9.1 Datos

- `player_color: Color`: color base asignado al jugador (lo define el lobby o el servidor; único por jugador).
- El color mostrado se **deriva** de `player_color` y `dash_available`. No sincronizar el color calculado, solo sus entradas.

### 9.2 Cálculo

```gdscript
const CAPE_DULL_SATURATION_MULT := 0.35
const CAPE_DULL_VALUE_MULT := 0.6
const CAPE_VIVID_SATURATION_MIN := 0.9
const CAPE_VIVID_VALUE_MIN := 1.0

func get_cape_color() -> Color:
    var c := player_color
    if dash_available:
        # Viva: mismo tono, saturación y brillo altos
        return Color.from_hsv(c.h, maxf(c.s, CAPE_VIVID_SATURATION_MIN), CAPE_VIVID_VALUE_MIN)
    # Apagada: mismo tono, saturación y brillo reducidos
    return Color.from_hsv(c.h, c.s * CAPE_DULL_SATURATION_MULT, c.v * CAPE_DULL_VALUE_MULT)
```

### 9.3 Comportamiento

| Evento                                    | Capa                                                                           |
| ----------------------------------------- | ------------------------------------------------------------------------------ |
| Jugador con dash disponible               | Viva                                                                           |
| Inicio de dash (`dash_available = false`) | Cambia a apagada **de inmediato** y se mantiene así durante y después del dash |
| Jugador en el aire o en pared sin dash    | Apagada (no hay recarga por pared)                                             |
| Toca el suelo y `dash_available = true`   | Vuelve a viva; opcional: destello breve de 0.1 s                               |

- "Apagada" significa **menos saturación y brillo, no transparencia**: la capa sigue siendo visible y del mismo tono.
- Los valores de `CAPE_*` deben ser constantes fáciles de ajustar.
- Mantener ambos estados distinguibles entre jugadores incluso con colores similares (verificar con la paleta final).
- El color se aplica al polígono de la capa y su contorno (sección 10.6). Aplicar `get_cape_color()` cada tick.

## 10. Capa: generación, puntos de agarre y simulación

La capa **reemplaza el cabello de Celeste** (en inglés: _cape_). Es una tela simulada que se crea al aparecer el jugador, cuelga de **dos puntos de agarre** en el personaje y se mueve con él. Es **puramente cosmética**: no colisiona con el mundo ni afecta la jugabilidad.

### 10.1 Concepto

- Rejilla de **2 columnas x N filas** de puntos (columna A y columna B). La fila 0 está anclada al personaje; las demás filas cuelgan libres.
- Simulación **Verlet** (posición actual y anterior por punto) con restricciones de distancia. Sin físicas del motor.
- La forma se dibuja como un polígono que conecta la columna A de arriba abajo y la columna B de abajo arriba.
- Se genera por código a partir de constantes: no requiere arte de la capa (solo color).

### 10.2 Puntos de agarre (anclajes)

Dos `Marker2D` hijos del jugador, definidos en la espalda del sprite para `facing = +1` (derecha). Con `facing = -1` se espeja la coordenada X.

| Punto     | Posición (px, desde el origen del jugador) | Función                                 |
| --------- | ------------------------------------------ | --------------------------------------- |
| `AnchorA` | (0, -8)                                    | Cuello, lado frontal de la capa         |
| `AnchorB` | (-3, -6)                                   | Hombro/espalda, lado trasero de la capa |

- Los valores son un punto de partida: **ajustarlos al tamaño real del sprite**.
- La distancia entre anclajes define el ancho superior de la capa.
- Ajustes por estado: al agacharse o hacer dash hacia abajo en suelo, bajar ambos anclajes unos 3 px en Y; al escalar, mantener los anclajes del lado opuesto a la pared (usar `facing`).
- Si el sprite tiene animaciones con balanceo (idle, correr), se pueden animar las posiciones de los marcadores.

### 10.3 Estructura de nodos

```
Player (CharacterBody2D)
  AnimatedSprite2D
  CapeAnchors (Node2D)
    AnchorA (Marker2D)
    AnchorB (Marker2D)
  Cape (Node2D, script cape.gd, top_level = true)
    Polygon2D        # relleno, z_index = -1 (detrás del sprite)
    Line2D           # contorno cerrado, mismo z_index
```

`top_level = true` es obligatorio: la capa se simula en **coordenadas globales** para que quede atrás al mover al jugador en lugar de pegarse a su transformación.

### 10.4 Parámetros

```gdscript
const CAPE_ROWS := 6              # filas por columna
const CAPE_SEGMENT := 2.5         # px entre filas (largo total aprox. 12.5 px)
const CAPE_TAPER := 0.6           # ancho de la última fila respecto al ancho en los anclajes
const CAPE_GRAVITY := 250.0       # px/s², caída suave
const CAPE_DAMPING := 0.90        # por tick; evita oscilaciones
const CAPE_WIND_GAIN := 3.0       # 1/s; empuje opuesto a la velocidad del jugador
const CAPE_ITERATIONS := 4        # pasadas de restricciones por tick
const CAPE_RESET_DISTANCE := 48.0 # px; si el anclaje se aleja más, reiniciar (teletransporte, respawn)
```

- `CAPE_WIND_GAIN` hace que la capa se extienda hacia atrás según la velocidad: a 90 px/s forma aprox. 45 grados y en dash queda casi horizontal. Parado, solo actúa la gravedad y la capa cuelga.
- Si el sprite usa otra escala, escalar `CAPE_SEGMENT`, los anclajes y `CAPE_RESET_DISTANCE` proporcionalmente.

### 10.5 Algoritmo por tick

Ejecutar **después de `move_and_slide()`**, una vez por tick de física, para cada jugador (local y remotos):

1. Calcular la posición global de `AnchorA` y `AnchorB` (con espejo por `facing` y desplazamiento por agachado).
2. Si la capa aún no se inicializó o el anclaje está a más de `CAPE_RESET_DISTANCE` del punto de la fila 0: colocar todos los puntos sobre los anclajes (sin velocidad).
3. **Integrar (Verlet)** las filas 1 a N-1 de ambas columnas:
   `p_nuevo = p + (p - p_anterior) * DAMPING + aceleración * delta²`, con `aceleración = (0, CAPE_GRAVITY) - velocidad_jugador * CAPE_WIND_GAIN`.
4. Repetir `CAPE_ITERATIONS` veces:
   - Fijar la fila 0 a los anclajes.
   - **Restricción de largo:** cada punto con el de la fila siguiente a distancia `CAPE_SEGMENT` (columna A y columna B).
   - **Restricción de ancho:** entre el punto de A y el de B de cada fila, con ancho `ancho_anclajes * lerp(1.0, CAPE_TAPER, fila / (N-1))`.
5. Reconstruir el polígono y el contorno con los puntos **redondeados a píxel entero** (estética pixel art).
6. Aplicar `get_cape_color()` al relleno; el contorno usa ese color oscurecido (por ejemplo `darkened(0.4)`).

No simular mientras el jugador está en freeze frame del dash (la capa también se detiene).

### 10.6 Implementación de referencia (`cape.gd`)

```gdscript
extends Node2D
class_name Cape

const ROWS := 6
const SEGMENT := 2.5
const TAPER := 0.6
const GRAVITY := 250.0
const DAMPING := 0.90
const WIND_GAIN := 3.0
const ITERATIONS := 4
const RESET_DISTANCE := 48.0

@onready var polygon: Polygon2D = $Polygon2D
@onready var outline: Line2D = $Line2D

var p := PackedVector2Array()   # posición actual; índice = columna * ROWS + fila
var q := PackedVector2Array()   # posición anterior
var initialized := false

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	p.resize(ROWS * 2)
	q.resize(ROWS * 2)
	outline.closed = true

func simulate(delta: float, a: Vector2, b: Vector2, vel: Vector2, color: Color) -> void:
	var anchors := [a, b]
	if not initialized or p[0].distance_to(a) > RESET_DISTANCE:
		for c in 2:
			for r in ROWS:
				p[c * ROWS + r] = anchors[c]
				q[c * ROWS + r] = anchors[c]
		initialized = true

	var accel := Vector2(0.0, GRAVITY) - vel * WIND_GAIN
	for c in 2:
		for r in range(1, ROWS):
			var i := c * ROWS + r
			var cur := p[i]
			p[i] = cur + (cur - q[i]) * DAMPING + accel * delta * delta
			q[i] = cur

	var w0 := a.distance_to(b)
	for _it in ITERATIONS:
		for c in 2:
			p[c * ROWS] = anchors[c]
			for r in range(ROWS - 1):
				_link(c * ROWS + r, c * ROWS + r + 1, SEGMENT, r == 0)
		for r in range(1, ROWS):
			var w := w0 * lerpf(1.0, TAPER, float(r) / (ROWS - 1))
			_link(r, ROWS + r, w, false)

	var poly := PackedVector2Array()
	for r in ROWS:
		poly.append(p[r].round())
	for r in range(ROWS - 1, -1, -1):
		poly.append(p[ROWS + r].round())
	polygon.polygon = poly
	polygon.color = color
	outline.points = poly
	outline.default_color = color.darkened(0.4)

func _link(i: int, j: int, rest: float, pin_i: bool) -> void:
	var d := p[j] - p[i]
	var l := d.length()
	if l < 0.0001:
		return
	var corr := d * ((l - rest) / l)
	if pin_i:
		p[j] -= corr
	else:
		p[i] += corr * 0.5
		p[j] -= corr * 0.5
```

### 10.7 Integración en `player.gd`

```gdscript
const ANCHOR_A := Vector2(0, -8)
const ANCHOR_B := Vector2(-3, -6)
const CAPE_DUCK_OFFSET := 3.0

@onready var cape: Cape = $Cape

func _update_cape(delta: float) -> void:
	var duck_y := CAPE_DUCK_OFFSET if ducking else 0.0
	var a := global_position + Vector2(ANCHOR_A.x * facing, ANCHOR_A.y + duck_y)
	var b := global_position + Vector2(ANCHOR_B.x * facing, ANCHOR_B.y + duck_y)
	cape.simulate(delta, a, b, velocity, get_cape_color())
```

Llamar `_update_cape(delta)` al final de `_physics_process`, tras `move_and_slide()`. Los jugadores remotos llaman la misma función con su posición interpolada y la `velocity` replicada.

### 10.8 Casos especiales

- **Cambio de dirección (`facing`):** los anclajes saltan de lado pero los puntos conservan su posición global; las restricciones los arrastran. No teletransportar la capa.
- **Respawn o teletransporte:** forzar reinicio (`initialized = false`) para evitar estiramientos.
- **Dash:** el `WIND_GAIN` extiende la capa casi horizontal por la velocidad alta; no se necesita lógica adicional.
- **Estabilidad:** si algún punto da valores no finitos, reiniciar la capa.
- **Orden de dibujo:** la capa va **detrás del sprite** del personaje.

## 11. Multijugador

Modelo asumido: **cada cliente tiene autoridad sobre su propio jugador** (mejor sensación de control) y replica el estado a los demás.

- Usar `MultiplayerSynchronizer` con estas propiedades replicadas: `global_position`, `velocity`, `facing`, `state`, `ducking`, `dash_available`, `player_color`.
- Los jugadores remotos **no ejecutan la lógica de movimiento**: interpolan posición y velocidad recibidas y solo ejecutan la visual (capa, animaciones, partículas).
- Consecuencia importante: `dash_available` se replica, por lo que todos ven la capa apagada/viva de cada jugador de forma coherente.
- **La simulación de la capa no se replica:** cada cliente simula localmente la capa de todos los jugadores (remotos incluidos) a partir de posición, velocidad, `facing` y `ducking`. Es cosmética, así que pequeñas diferencias entre clientes son aceptables.
- La capa se instancia al aparecer cada jugador (local o remoto) y se libera junto con él.
- El freeze frame del dash se aplica **solo al jugador local** (no pausar el juego global).
- `player_color` se asigna una vez al unirse y no cambia durante la partida.
- Si más adelante se requiere servidor autoritativo, mover la simulación al servidor y mantener el mismo conjunto de constantes.

## 12. Estructura de archivos sugerida

```
player/
  player.tscn
  player.gd              # máquina de estados y orquestación
  player_constants.gd    # sección 4
  cape.tscn              # Cape + Polygon2D + Line2D (sección 10.3)
  cape.gd                # simulación de la capa (sección 10.6)
```

## 13. Criterios de aceptación

Verificar cada punto antes de dar la tarea por terminada:

1. Arranque y frenado sin input: menos de 0.1 s en suelo.
2. Toque corto de `jump` produce salto bajo; mantener produce salto completo de unos 28 px.
3. Saltar hasta 0.1 s después de salir de un borde funciona (coyote).
4. `jump` presionado hasta 0.08 s antes de aterrizar se ejecuta al tocar suelo (buffer).
5. El dash recorre aprox. 36 px y no se puede repetir hasta tocar suelo.
6. Tras un hyper, mantener la dirección conserva la velocidad (325 px/s decae lento); soltarla la pierde casi de inmediato.
7. Wall bounce, wall jump, wall slide y escalada funcionan con las cifras de stamina indicadas (subir dura aprox. 2.4 s; quieto aprox. 11 s).
8. Corner correction de 4 px en techo y dash.
9. **Color de la capa:** viva con dash disponible; apagada al instante de usar el dash; vuelve a viva solo al tocar el suelo.
10. **Capa, forma y movimiento:**
    - Parado, cuelga con gravedad suave; corriendo, se extiende hacia atrás según la velocidad; en dash queda casi horizontal.
    - Siempre unida a los dos puntos de agarre; la longitud no se estira visiblemente (menos de 15%).
    - Cambiar de dirección o reaparecer no produce teletransportes ni deformaciones extremas.
    - Dibujada detrás del sprite y con coordenadas redondeadas a píxel.
11. **Multijugador:** cada jugador conserva su propio color; los demás clientes ven la capa apagada/viva correcta y animada con el movimiento; el freeze del dash no afecta a otros jugadores.

## 14. Fuera de alcance (por ahora)

- Cristales de recarga de dash.
- Colisión entre jugadores.
- Colisión de la capa con el mundo y desgarro de tela.
- Predicción y reconciliación de red.
- Opciones de accesibilidad (dashes infinitos, velocidad de juego).
