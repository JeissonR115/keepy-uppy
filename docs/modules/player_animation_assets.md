# Manifiesto de animaciones del jugador

Los fotogramas son PNG RGBA de 32 × 32 píxeles. Cada secuencia usa `f0.png` hasta `fN.png` en orden numérico. Los GIF indicados junto a cada carpeta son vistas previas y no se cargan durante el juego.

## Cuerpo

Ruta base: `res://assets/sprites/Animations/player/`. Tipo de recurso en juego: animación de `SpriteFrames` reproducida por `AnimatedSprite2D`.

| Secuencia | Fotogramas | Uso visual |
|---|---:|---|
| `idle` | 66 | Quieto en el suelo |
| `runSlow` | 12 | Movimiento en suelo a menor velocidad |
| `runFast` | 12 | Movimiento en suelo a mayor velocidad |
| `flip` | 8 | Inicio del salto |
| `fall` | 8 | Caída normal |
| `fallFast` | 2 | Caída rápida existente |
| `fallPose` | 11 | Inventariado y disponible; no conectado porque la pose no coincide claramente con un estado actual |
| `dangling` | 10 | Ascenso neutral |
| `dash` | 4 | Dash |
| `wallslide` | 1 | Deslizamiento por pared |
| `climbPull` | 4 | Escalada hacia arriba |
| `climbPush` | 4 | Escalada hacia abajo |
| `climbup` | 6 | Transición de salida por arriba |

## Efectos

Ruta base: `res://assets/sprites/Animations/player_sweat/`. Tipo de recurso en juego: una segunda animación `SpriteFrames` en una capa visual sin colisión.

| Secuencia | Fotogramas | Uso visual |
|---|---:|---|
| `jump` | 4 | Inicio de salto, una vez por transición |
| `climb` | 2 | Entrada a la escalada |
| `climbLoop` | 6 | Mientras continúa la escalada |
| `danger` | 6 | Evento existente de jugador golpeado; el último fotograma es transparente y termina el efecto |
| `still` | 6 | Acento secundario en reposo, si resulta legible en juego |
| `idle` | 1 | Excluido: `f0.png` es completamente transparente |

El arte de jugador 2 reutiliza estos mismos recursos con modulación naranja aplicada al dibujado. La selección de clips se deriva de los estados existentes; este manifiesto no introduce estados de juego nuevos.

## Perfiles visuales

`player_visual_profile_p1.tres` y `player_visual_profile_p2.tres` configuran por separado las secuencias de cuerpo y efectos, los tintes, el tinte de rastros, los anclajes y los nombres de clip para cada estado visual. Ambos perfiles apuntan a los `SpriteFrames` que ya estaban en el proyecto; P2 conserva el matiz naranja existente. Ambos jugadores tienen pelo pixelado. Los mapas de animación son editables por perfil, aunque actualmente asignan los mismos clips a los estados compartidos. La cápsula, capas físicas y `DashRescueArea` siguen fuera del perfil y del subárbol visual.

`PlayerHair` crea dos trazos de seis puntos, anclados independientemente del cuerpo. El seguimiento amortiguado reacciona a velocidad, facing y dash; `reset_for_round()` restablece puntos y anclajes. El dibujo usa posiciones enteras, líneas de 2 px, filtro nearest y antialias desactivado. No crea cuerpos, áreas ni señales físicas.

## Rastros de dash

`PlayerDashAfterimage` captura el fotograma visible del personaje seis veces durante el dash. Cada copia conserva facing, offset y escala, recibe el tinte de su perfil y desvanece su alfa en 0.18 s. Incluye un `Area2D` que detecta el globo sin bloquear cuerpos. El área principal permite un rescate y el conjunto de copias permite uno adicional como máximo por dash.

## Fuente y autorización

Las carpetas de cuerpo y efectos ya estaban en el proyecto antes de esta reimplementación; el manifiesto del repositorio no registra su creador ni una licencia de redistribución aplicable. El README de [yusufkaanocak/Celeste-Movement](https://github.com/yusufkaanocak/Celeste-Movement) atribuye sus sprites a Nate Kling para Mix and Jam. La licencia MIT del repositorio no establece por sí sola permiso para redistribuir esas imágenes. Por eso se adapta el comportamiento, pero no se copia ni importa ese paquete de arte. Los perfiles y rastros reutilizan los `SpriteFrames` locales sin afirmar derechos sobre los PNG. La atribución/licencia y la decisión están documentadas en [reference-celeste-demo-comparison.md](../reference-celeste-demo-comparison.md).

La calidad de importación, dimensiones y clips se comprueban en `tests/test_visual_assets.gd`; los estados en `tests/test_visual_feedback.gd`; el pelo en `tests/test_player_hair.gd`; y los seis rastros/rescate en `tests/test_player_dash_afterimages.gd`.
