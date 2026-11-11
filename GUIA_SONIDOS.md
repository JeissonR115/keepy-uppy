# Guía de sonidos: formato, generación en 16 bits y asignación a acciones

Se usa junto con `sound_presets.json` (fuente de verdad de todos los efectos) y `GUIA_IMPLEMENTACION_MOVIMIENTO.md` (movimiento del jugador).

## 1. Prompt para la IA

Pegar este prompt a la IA que implemente el audio, adjuntando `GUIA_SONIDOS.md` y `sound_presets.json`.

```
Eres ingeniero de audio y gameplay en Godot 4 (GDScript). Adjunto GUIA_SONIDOS.md y
sound_presets.json. El JSON contiene 15 presets de sintetizadores de efectos de sonido
(Bfxr, Mixr, Signlr, Footsteppr, Squishr, Choirr, Jinglr, Boomr) agrupados en 11 eventos
de un juego multijugador de globos con movimiento estilo Celeste.

Tareas, en orden:
1. Copia sound_presets.json a res://audio/sound_presets.json sin modificar ningun preset.
2. Genera los WAV en 16 bits segun la seccion 2 y el campo "render" de cada evento
   (variantes, jitter de parametros y tiers). Total esperado: 29 archivos, rutas en "files".
   Si NO puedes ejecutar el motor exacto de cada sintetizador, no lo imites ni inventes que
   lo hiciste: crea WAV silenciosos de 0.1 s con el nombre exacto como placeholder, lista
   cada archivo pendiente en res://audio/PENDIENTES.md (evento, preset, parametros del
   render) y avisame para exportarlos desde la herramienta.
3. Implementa el autoload AudioManager (seccion 6) que lee el manifiesto.
4. Conecta cada evento a su accion en el juego segun la tabla de la seccion 5.
5. Implementa la sincronizacion multijugador de la seccion 7.
6. No asignes sonidos a acciones que no esten en la tabla. Si una accion no tiene sonido,
   dejala sin sonido y listala al final.
7. Verifica los criterios de aceptacion de la seccion 8 y reporta cuales cumples.
```

## 2. Formato de salida del audio (16 bits)

| Propiedad | Valor |
|---|---|
| Contenedor | WAV |
| Codificación | PCM entero con signo, **16 bits**, little-endian (`pcm_s16le`) |
| Frecuencia de muestreo | 44100 Hz |
| Canales | Mono (la posición se logra con `AudioStreamPlayer2D`) |
| Normalización | Pico a -1 dBFS, sin recorte |
| Final | Recortar silencio final mayor a 50 ms y aplicar fade-out de 5 ms (evita clics) |
| Loop | Desactivado (importación de Godot: `loop_mode = Disabled`) |
| Nombres | `snake_case` en minúsculas |

16 bits es la **profundidad de salida**. El estilo retro lo definen los presets (por ejemplo `bitCrush`), que se respetan tal cual.

## 3. Estructura de archivos

```
res://audio/
  sound_presets.json                # copia del manifiesto
  PENDIENTES.md                     # solo si faltan WAV por exportar
  sfx/
	jump/jump_01.wav
	laugh_p1/laugh_p1_01.wav ... _03.wav
	laugh_p2/laugh_p2_01.wav ... _03.wav
	dash/dash_01.wav
	footstep/footstep_01.wav ... _04.wav
	balloon_touch/balloon_touch_soft_01.wav ... _hard_04.wav
	balloon_explode/balloon_explode_01.wav
	set_new_p1/set_new_p1_01.wav
	set_new_p2/set_new_p2_01.wav
	match_start/match_start_01.wav
	menu_select/menu_select_01.wav
tools/
  render_sfx.py                     # opcional: renderiza el manifiesto a WAV
```

Convención de nombre: `<evento>[_<tier>]_<nn>.wav`, con índice de dos dígitos desde `01`.

## 4. Formato de guardado (`sound_presets.json`)

Un solo JSON con la configuración de salida y un diccionario `events`. **Cada preset es el JSON exacto del sintetizador** (`synth_type`, `version`, `file_name`, `params`); no se edita ni se reformatea. En los presets Mixr y Jinglr, `sources` y `phrase` son cadenas JSON dentro de la cadena: se guardan tal cual.

Estructura de un evento:

```json
{
  "label": "Salto",
  "trigger": "Cuándo suena",
  "mode": "single | random_variant | intensity",
  "presets": [ { "synth_type": "Bfxr", "version": "1.0.4", "file_name": "Jump10", "params": { } } ],
  "files": ["res://audio/sfx/jump/jump_01.wav"],
  "tiers": [ { "name": "soft", "max_intensity": 0.33 } ],
  "playback": {
	"bus": "SFX",
	"volume_db": -4,
	"volume_db_by_intensity": [-12, -2],
	"pitch_jitter": 0.04,
	"positional": true,
	"max_distance": 800
  },
  "render": { "variants": 1 }
}
```

| Campo | Significado |
|---|---|
| `mode` | `single`: un archivo. `random_variant`: elige uno al azar de `files`. `intensity`: `files` es un diccionario por tier y se elige el tier según `intensity` (0 a 1) |
| `presets` | Presets originales del evento. En `random_variant` con varios presets, un WAV por preset en el mismo orden |
| `files` | Rutas de salida. Lista, o diccionario `tier -> lista` en modo `intensity` |
| `tiers` | Umbrales de intensidad (solo modo `intensity`) |
| `playback.volume_db_by_intensity` | `[db con intensidad 0, db con intensidad 1]`, interpolado linealmente |
| `playback.pitch_jitter` | Variación aleatoria de `pitch_scale` de ±valor en cada reproducción |
| `render` | Instrucciones para generar los WAV (variantes, jitter de parámetros, tiers) |

Para agregar un sonido nuevo: añadir el evento al manifiesto, renderizar sus WAV según `render` y conectarlo en el código con `AudioManager.play(...)`. No hace falta modificar `AudioManager`.

## 5. Asignación: evento, preset y acción del juego

| Evento | Preset (sintetizador) | Cuándo suena | WAV |
|---|---|---|---|
| `jump` | Jump10 (Bfxr) | Inicio de salto y wall jump. Opcional: super, hyper y wall bounce con `pitch_offset` +0.15 | 1 |
| `laugh_p1` | CyberBird9, CyberBird8, CyberBird7 (Mixr) | El jugador 1 anota un punto y se ríe con una risa al azar de las suyas | 3 |
| `laugh_p2` | DistressBurst, DistressBurst9, DistressBurst14 (Signlr) | El jugador 2 anota un punto y se ríe con una risa al azar de las suyas | 3 |
| `dash` | Random6 (Mixr) | Al iniciar el impulso del dash | 1 |
| `footstep` | Random2 (Footsteppr) | Cada 14 px recorridos corriendo en suelo | 4 |
| `balloon_touch` | BubblePop2 (Squishr) | Un jugador toca el globo; más duro y fuerte con más velocidad | 12 |
| `balloon_explode` | Boom (Bfxr) | El globo explota | 1 |
| `set_new_p1` | VictoryChord (Choirr) | El jugador 1 gana el set: suena su música de ganador | 1 |
| `set_new_p2` | FairyChoir3 (Choirr) | El jugador 2 gana el set: suena su música de ganador | 1 |
| `match_start` | Warning2 (Jinglr) | Inicio del partido | 1 |
| `menu_select` | WaterDrop9 (Squishr) | Selección en el menú | 1 |

Total: **29 WAV**.

### 5.1 Acciones sin sonido asignado

Aterrizaje, escalada, agarre de pared, recarga de dash, muerte y respawn **no tienen sonido** por ahora. No inventar ni reutilizar presets para ellas.

### 5.2 Variación del toque de globo

El motor de juego no ejecuta los sintetizadores en tiempo real, así que la variación se **pre-renderiza**: 3 tiers de intensidad x 4 variantes aleatorias = 12 WAV.

Para cada tier se parte del preset `BubblePop2` y se sobrescriben estos parámetros:

| Tier | masterVolume | pressure | stretch | wetness | duration |
|---|---|---|---|---|---|
| `soft` (hasta 0.33) | 0.35 | 0.35 | 0.20 | 0.90 | 0.20 |
| `medium` (hasta 0.66) | 0.50 | 0.60 | 0.15 | 0.84 | 0.18 |
| `hard` (hasta 1.00) | 0.70 | 0.90 | 0.08 | 0.70 | 0.14 |

Cada variante usa una `seed` nueva aleatoria y suma un desplazamiento aleatorio uniforme de ±valor a estos parámetros: `viscosity` 0.10, `stretch` 0.05, `wetness` 0.08, `bubbleSize` 0.08, `duration` 0.03, `pressure` 0.05. Todos los parámetros se limitan al rango 0 a 1 y `duration` mínimo 0.05.

En juego se calcula `intensity = clamp(impact_speed / BALLOON_REF_SPEED, 0, 1)`. `BALLOON_REF_SPEED` es una constante a ajustar (valor inicial 240 px/s, igual a la velocidad del dash). Con `intensity` se elige el tier, una variante al azar, el volumen entre -12 y -2 dB y un `pitch_scale` aleatorio de ±5%.

### 5.3 Variación de los pasos

Se renderizan 4 variantes del preset `Random2` sumando un desplazamiento aleatorio de ±valor a `heel` 0.05, `roll` 0.03, `ball` 0.05 y `swiftness` 0.03. En juego: variante al azar, `pitch_scale` de ±6% y volumen entre -14 y -8 dB según `|vx| / MAX_RUN`.

## 6. Implementación en Godot 4

### 6.1 Autoload `AudioManager`

Registrar en `Project Settings > Autoload` con el nombre `AudioManager`. Crear los buses `SFX` y `UI` en el Audio Bus Layout.

```gdscript
extends Node

const MANIFEST_PATH := "res://audio/sound_presets.json"

var _events: Dictionary = {}
var _streams: Dictionary = {}   # id -> Array de streams, o Dictionary tier -> Array
var _last: Dictionary = {}      # id -> último índice reproducido (evita repetir seguido)
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	var f := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	_events = JSON.parse_string(f.get_as_text())["events"]
	for id in _events:
		var ev: Dictionary = _events[id]
		if ev["mode"] == "intensity":
			var by_tier := {}
			for tier in ev["files"]:
				by_tier[tier] = _load_list(ev["files"][tier])
			_streams[id] = by_tier
		else:
			_streams[id] = _load_list(ev["files"])

func _load_list(paths: Array) -> Array:
	var out := []
	for p in paths:
		if ResourceLoader.exists(p):
			out.append(load(p))
	return out

func _pick(id: String, intensity: float) -> Dictionary:
	if not _events.has(id):
		return {}
	var ev: Dictionary = _events[id]
	var pb: Dictionary = ev["playback"]
	var list: Array
	if ev["mode"] == "intensity":
		var tier := "hard"
		for t in ev["tiers"]:
			if intensity <= t["max_intensity"]:
				tier = t["name"]
				break
		list = _streams[id].get(tier, [])
	else:
		list = _streams[id]
	if list.is_empty():
		return {}
	var idx := _rng.randi() % list.size()
	if list.size() > 1 and _last.get(id, -1) == idx:
		idx = (idx + 1 + _rng.randi() % (list.size() - 1)) % list.size()
	_last[id] = idx
	var vr: Array = pb.get("volume_db_by_intensity", [pb["volume_db"], pb["volume_db"]])
	return {
		"stream": list[idx],
		"bus": pb["bus"],
		"volume_db": lerpf(vr[0], vr[1], clampf(intensity, 0.0, 1.0)),
		"pitch": 1.0 + _rng.randf_range(-pb["pitch_jitter"], pb["pitch_jitter"]),
		"max_distance": pb.get("max_distance", 800.0),
	}

## Sonido no posicional (menú, risas, set, inicio de partido).
func play(id: String, intensity := 0.0, pitch_offset := 0.0) -> void:
	var s := _pick(id, intensity)
	if s.is_empty():
		return
	var p := AudioStreamPlayer.new()
	p.stream = s["stream"]
	p.bus = s["bus"]
	p.volume_db = s["volume_db"]
	p.pitch_scale = s["pitch"] + pitch_offset
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

## Sonido que decide solo si es posicional según el manifiesto (para RPC).
func play_event(id: String, pos := Vector2.ZERO, intensity := 0.0) -> void:
	if _events.has(id) and _events[id]["playback"]["positional"]:
		play_at(id, pos, intensity)
	else:
		play(id, intensity)

## Sonido posicional (salto, dash, pasos, globo).
func play_at(id: String, pos: Vector2, intensity := 0.0, pitch_offset := 0.0) -> void:
	var s := _pick(id, intensity)
	if s.is_empty():
		return
	var p := AudioStreamPlayer2D.new()
	p.stream = s["stream"]
	p.bus = s["bus"]
	p.volume_db = s["volume_db"]
	p.pitch_scale = s["pitch"] + pitch_offset
	p.max_distance = s["max_distance"]
	get_tree().current_scene.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()
```

Si algún WAV falta, el evento simplemente no suena (no genera error).

### 6.2 Conexión con el jugador (`player.gd`)

```gdscript
const STEP_DISTANCE := 14.0
var _step_dist := 0.0

# Al ejecutar el salto (7.3) y el wall jump (7.6):
AudioManager.play_at("jump", global_position)

# Al iniciar el impulso del dash (7.4), tras el freeze:
AudioManager.play_at("dash", global_position)

func _update_footsteps(delta: float) -> void:
	if is_on_floor() and state == State.NORMAL and not ducking and absf(velocity.x) > 10.0:
		_step_dist += absf(velocity.x) * delta
		if _step_dist >= STEP_DISTANCE:
			_step_dist = 0.0
			AudioManager.play_at("footstep", global_position, clampf(absf(velocity.x) / MAX_RUN, 0.0, 1.0))
	else:
		_step_dist = 0.0
```

Llamar `_update_footsteps(delta)` en `_physics_process`, después de `move_and_slide()`.

### 6.3 Conexión con el globo y el partido

```gdscript
const BALLOON_REF_SPEED := 240.0   # ajustar a la velocidad máxima real del globo

func on_balloon_touched(pos: Vector2, impact_speed: float) -> void:
	var i := clampf(impact_speed / BALLOON_REF_SPEED, 0.0, 1.0)
	AudioManager.play_at("balloon_touch", pos, i)

func on_balloon_exploded(pos: Vector2) -> void:
	AudioManager.play_at("balloon_explode", pos)

func on_match_started() -> void:
	AudioManager.play("match_start")

func on_point_scored(scorer_index: int) -> void:   # scorer_index: 1 o 2
	AudioManager.play("laugh_p%d" % scorer_index)   # risa al azar del que anota

func on_set_won(winner_index: int) -> void:        # winner_index: 1 o 2
	AudioManager.play("set_new_p%d" % winner_index) # música del ganador del set

func on_menu_option_selected() -> void:
	AudioManager.play("menu_select")
```

## 7. Multijugador

- Cada jugador tiene `player_index` (1 o 2), asignado al unirse y replicado junto con `player_color`.
- Los eventos de gameplay discretos (`balloon_touch`, `balloon_explode`, `match_start`, `set_new_pN`, `laugh_pN`) los dispara la **autoridad** (quien posee el globo o el estado del partido); `N` es el índice del jugador que anota (risa) o gana el set (música) y se reproducen en **todos** los clientes mediante RPC:

```gdscript
@rpc("authority", "call_local", "reliable")
func net_sfx(id: String, pos: Vector2, intensity: float) -> void:
	AudioManager.play_event(id, pos, intensity)
```

- `jump` y `dash` del jugador local se reproducen de inmediato (sin esperar red) y se envían a los demás con un RPC `unreliable` desde el cliente dueño.
- `footstep` de jugadores remotos se calcula **localmente** con el mismo acumulador de distancia, a partir de su movimiento interpolado.
- `menu_select` es local y nunca se replica.
- La variación aleatoria no necesita estar sincronizada: es solo cosmética.
- Con más de 2 jugadores, usar `((player_index - 1) % 2) + 1` para elegir entre las versiones `p1` y `p2`.

## 8. Criterios de aceptación

1. Existen los 29 WAV con la ruta y nombre de `files`, en **PCM 16 bits, 44100 Hz, mono**; si faltan, `PENDIENTES.md` los lista.
2. `sound_presets.json` conserva los 15 presets sin modificaciones.
3. Cada evento de la tabla 5 suena en su acción y ninguna acción no listada tiene sonido.
4. `balloon_touch` suena más fuerte y duro a mayor velocidad de impacto y nunca se repite exactamente igual en golpes consecutivos.
5. `footstep` alterna variantes y su volumen depende de la velocidad.
6. Los eventos con varias variantes (`laugh_p1`, `laugh_p2`, `footstep`, `balloon_touch`) eligen al azar sin repetir la misma dos veces seguidas.
7. En multijugador todos los clientes oyen los eventos de gameplay una sola vez y los eventos del menú solo en el local.
8. Las ráfagas de sonido (muchos toques seguidos) no provocan cortes ni errores (cada reproducción usa su propio reproductor).
9. Los volúmenes están balanceados entre sí; ajustar `volume_db` en el manifiesto, nunca en los WAV.

## 9. Pendientes y suposiciones a confirmar

- **Punto que cierra el set:** la risa del que anota suena en cada punto y, si ese punto gana el set, también suena la música del ganador al mismo tiempo. Si se solapan mal, retrasar `on_set_won` unos 0.8 s.
- **Rocket1:** se quitó del manifiesto; la explosión del globo usa solo `Boom`.
- **`BALLOON_REF_SPEED`, `STEP_DISTANCE` y `max_distance`:** valores iniciales a ajustar con el juego real.
