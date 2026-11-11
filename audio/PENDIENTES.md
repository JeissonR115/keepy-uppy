# Exportaciones de sonido pendientes

No se encontró un exportador de los sintetizadores Bfxr, Mixr, Signlr, Footsteppr, Squishr, Choirr, Jinglr o Boomr en el entorno de implementación. Los 29 archivos enumerados aquí son placeholders WAV silenciosos de 0.1 s, PCM s16le, mono y 44,100 Hz; no son exportaciones audibles ni emulaciones.

Exportar desde la herramienta exacta usando los presets originales de `sound_presets.json`, la salida WAV PCM de 16 bits/44,100 Hz/mono y los parámetros `render` indicados. Mantener exactamente las rutas listadas.

| Evento | Preset(s) | Render pendiente |
|---|---|---|
| `jump` | Bfxr `Jump10` | Una variante, parámetros originales sin cambios. |
| `laugh_p1` | Mixr `CyberBird9`, `CyberBird8`, `CyberBird7` | Un WAV por preset en ese orden, parámetros originales sin cambios. |
| `laugh_p2` | Signlr `DistressBurst`, `DistressBurst9`, `DistressBurst14` | Un WAV por preset en ese orden, parámetros originales sin cambios. |
| `dash` | Mixr `Random6` | Una variante, parámetros originales sin cambios. |
| `footstep` | Footsteppr `Random2` | Cuatro variantes; jitter independiente uniforme: `heel` ±0.05, `roll` ±0.03, `ball` ±0.05, `swiftness` ±0.03. |
| `balloon_touch` | Squishr `BubblePop2` | Cuatro variantes por tier. `soft`: `masterVolume` 0.35, `pressure` 0.35, `stretch` 0.20, `wetness` 0.90, `duration` 0.20. `medium`: 0.50, 0.60, 0.15, 0.84, 0.18. `hard`: 0.70, 0.90, 0.08, 0.70, 0.14. Seed nueva por variante; jitter independiente uniforme: `viscosity` ±0.10, `stretch` ±0.05, `wetness` ±0.08, `bubbleSize` ±0.08, `duration` ±0.03, `pressure` ±0.05. Limitar los parámetros a 0..1 y `duration` a mínimo 0.05. |
| `balloon_explode` | Bfxr `Boom` | Una variante, parámetros originales sin cambios. |
| `set_new_p1` | Choirr `VictoryChord` | Una variante, parámetros originales sin cambios. |
| `set_new_p2` | Choirr `FairyChoir3` | Una variante, parámetros originales sin cambios. |
| `match_start` | Jinglr `Warning2` | Una variante, parámetros originales sin cambios. |
| `menu_select` | Squishr `WaterDrop9` | Una variante, parámetros originales sin cambios. |

## Archivos placeholder

- `sfx/jump/jump_01.wav`
- `sfx/laugh_p1/laugh_p1_01.wav`, `laugh_p1_02.wav`, `laugh_p1_03.wav`
- `sfx/laugh_p2/laugh_p2_01.wav`, `laugh_p2_02.wav`, `laugh_p2_03.wav`
- `sfx/dash/dash_01.wav`
- `sfx/footstep/footstep_01.wav` a `footstep_04.wav`
- `sfx/balloon_touch/balloon_touch_soft_01.wav` a `balloon_touch_soft_04.wav`
- `sfx/balloon_touch/balloon_touch_medium_01.wav` a `balloon_touch_medium_04.wav`
- `sfx/balloon_touch/balloon_touch_hard_01.wav` a `balloon_touch_hard_04.wav`
- `sfx/balloon_explode/balloon_explode_01.wav`
- `sfx/set_new_p1/set_new_p1_01.wav`
- `sfx/set_new_p2/set_new_p2_01.wav`
- `sfx/match_start/match_start_01.wav`
- `sfx/menu_select/menu_select_01.wav`

Al sustituir placeholders, verificar que los archivos generados no sean silenciosos y que conserven formato y rutas. Los nombres de preset y los parámetros de render de arriba son referencia; `sound_presets.json` sigue siendo la fuente de verdad.
