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
