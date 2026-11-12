# Design

## Context

Consulta `proposal.md` para el alcance y las capacidades modificadas; las reglas observables completas están en `specs/player-control/spec.md` y `specs/pixel-art-presentation/spec.md`.

El proyecto corre Godot 4.7. `arena.tscn` instancia dos copias de `player_placeholder.tscn`, con la misma escena/controlador y distintos `input_prefix`; el CPU transforma decisiones en intención de movimiento y usa ese controlador. `PlayerController` (394 líneas) es propietario de `_physics_process()` y `move_and_slide()`, y delega técnicas en módulos de salto, dash, escalada y superficies. `PlayerMovementConstants` centraliza los parámetros actuales. La escena mantiene una cápsula de radio 5 px, altura 23 px y centro Y 0.5, separada del sprite 32×32 px; P1/P2 comparten ahora `SpriteFrames` de cuerpo y efectos, con tinte naranja para P2. Una capa cape se simula con Verlet y no colisiona.

Los cambios abiertos `celeste-reference-movement-and-tileset-fidelity` y `player-sprite-animation-visuals` se deben conciliar con el trabajo ya existente en `animated-player-sprites-and-player-two-tint` antes de aplicar esta propuesta. El comparativo del repo B identifica su rama Godot 4.1 y controlador/resource, máquina de estados, corner correction, hair como rastro de posiciones, efectos de dash y dependencias. Allí se observó una pausa bloqueante de 30 ms y no hay TileSet/TileMap; esos detalles no se portan literalmente. El código visible de `player/player.gd` del repo A hereda de `KinematicBody2D` y usa `move_and_slide(velocity, Vector2.UP)`, `yield`, contadores de frames para coyote/buffer y acciones Input globales: es API de Godot 3, incompatible con el `CharacterBody2D`/Input Map del proyecto 4.7. El script declara `ACCELERATION=3000`, `MAX_SPEED=18000`, `GRAVITY=2100`, `LIMIT_SPEED_Y=1200`, salto `36000` con mínimo `12000`, coyote de 6 frames, buffer de 10 frames, wall jump `18000`, dash `36000` y duración aproximada de 0.25 s; muchas velocidades se multiplican por `delta`, así que esos valores no se pueden trasladar como unidades px/s. La lógica también contiene jump cut, movimiento horizontal acelerado, caída con fricción aérea, wall slide/grab, dash direccional, recarga en piso, animaciones y trail. El repo A publica una licencia MIT para el repositorio y atribuye sus sprites a Nate Kling; la licencia de código no resuelve derechos del arte. Fijar el commit exacto/versión declarada y revisar escenas/recursos restantes en la auditoría, sin volver a inferir o copiar sus API. No trasladar dependencias de plugins ni escenas completas de las referencias.

## Goals / Non-Goals

**Goals:**

- Reutilizar un único executor físico para P1/P2/CPU y una configuración de movimiento compartida, con módulos pequeños para responsabilidades que ya cruzan el límite de 400 líneas.
- Medir brechas frente a ambos repositorios antes de modificar parámetros. Mantener unidades de proyecto en píxeles/segundo y temporizadores en segundos; adaptar cada fórmula a Godot 4.7 en vez de copiar API o código de otra versión.
- Mantener hitbox y colisiones de cuerpo fuera de la jerarquía visual, orientaciones visuales específicas y una simulación cosmética separada para el cabello de P2.
- Entregar un inventario de migración conservador: cambios concretos, archivos nuevos solo cuando hagan falta y eliminaciones probadas por búsquedas de referencias.

**Non-Goals:**

- Reemplazar `MatchManager`, `BalloonController`, CPU, controles remapeables, mapas, TileSet ni reglas de superficie.
- Copiar texturas, scripts, plugins, nombres de clases o escenas completas de las referencias.
- Convertir el cabello en collider o cambiar el tamaño de hitbox para encajar con el arte.
- Mantener simultáneamente un controlador legado y otro nuevo después de la migración.

## Decisions

### Mantener CharacterBody2D como autoridad y separar intención, simulación y presentación

`PlayerInputReader` (incluida la intención generada por CPU) permanece como entrada. Un `PlayerController` compacto orquesta la simulación y hace la única llamada a `move_and_slide()`. Conservar inicialmente `player_jump_techniques.gd`, `player_dash_techniques.gd`, `player_climb_techniques.gd` y `player_surface_techniques.gd`, pero cambiar o dividir cada uno solo cuando la comparación identifique un defecto o el archivo exceda el límite. Mantener los estados `NORMAL`, `DASH`, `CLIMB` o subdividirlos si las transiciones medidas requieren estados explícitos; no añadir una máquina de estados de propósito general solo por similitud con el demo.

Alternativa descartada: introducir el controlador de PixelPerfect2D del repo B o una segunda escena por jugador. Su API, plugin y cableado raw-input no se alinean con el ejecutor compartido, CPU ni contratos de colisión de balón. Alternativa descartada: reescritura total sin medir; invalidaría numerosas conductas existentes (ultra/super, rescate de dash, escalada/stamina) sin evidencia de que sean huecos.

### Calibrar de forma trazable, no importar constantes de otra escala

Crear una tabla de referencia en la documentación técnica con cada mecanismo, fórmula/estado observado, parámetro local, cambio propuesto y verificación. Medir usando una escena de ensayo reproducible en Godot 4.7 y pasos físicos controlados; comparar distancia/tiempo, altura máxima y transiciones para aceleración, frenado, salto, caída, dash y wall interaction. Los datos ya observados incluyen coyote de 0.1 s en el repo B frente a 0.1 s local, jump buffer de 0.1 s frente a 0.08 s local, margen seguro de pared 3 px y corrección de esquina 4 px en el repo B. El repo A mide coyote/buffer en frames y mezcla constantes multiplicadas por delta; comparar primero a una frecuencia fija y derivar tiempos, nunca copiar los valores crudos. Tratar las métricas como punto de comparación, no como decisiones automáticas.

Las direcciones diagonales del dash se normalizan antes de asignar velocidad. Cada duración/cooldown usa `delta` de física y no bloqueos de hilo ni contadores de frame. La política de dash frente a pared/suelo/techo queda explícita y se valida con la cápsula, sin tocar geometría de escenario para resolver errores del controlador.

Alternativa descartada: reproducir un movimiento “fiel” mediante números crudos de otra demo. Las escalas de viewport, tick rate, unidad de velocidad y fricción pueden diferir; la paridad debe decidirse por trazas observables.

### Compartir controlador y colisiones, configurar apariencia por perfil

Agregar un recurso/dato de perfil visual por jugador o recursos exportados en la escena común para seleccionar SpriteFrames, mapeo de animación, tinte y anclajes; el prefijo P1/P2 solo elige perfil y acciones, nunca constantes físicas. Cuerpo, efecto visual, pelo y cape son nodos visuales; cápsula, máscara/capa, área de rescate y contacto de jugador permanecen como componentes físicos separados. Mantener `MatchManager` y señales existentes como única autoridad de impacto válido.

P1 usa frames del repo A solo cuando se acredite licencia/permiso del arte de Nate Kling para redistribución y derivación. P2 usa frames de Madeline solo con autorización aplicable de EXOK/dueño; el README del demo no constituye por sí solo permiso para este proyecto. Si no se obtiene evidencia, usar el arte local autorizado o sprites originales entregados para cada perfil y registrar la proveniencia. No se copiarán código/arte de terceros en el proceso de propuesta.

Alternativa descartada: duplicar controlador/escena completa para obtener apariencias diferentes; duplicaría correcciones y permitiría que P1/P2 diverjan físicamente.

### Cabello como simulación cosmética acotada

Añadir un `PlayerHair` como escena/componente adjunto solo al perfil P2, con puntos de segmento anclados a marcadores del sprite. Actualizarlo en física o en una interpolación acotada que consuma la velocidad/estado ya calculados; usar inercia amortiguada y restricciones de longitud entre segmentos, limitar delta y reinicializar anclajes tras reset/teleport. No ejecutar simulación si el jugador está eliminado o no está en el árbol. No usar `Area2D`, `CollisionObject2D` ni señales del cabello. La política visual de dash se basa en la dirección/impulso del controlador.

Alternativa descartada: copiar `Hair.gd` del repo B, que guarda historial de posiciones y ajusta puntos a una `Line2D`, porque requiere adaptar pivotes/animaciones y la forma del personaje; implementar un componente pequeño con parámetros del proyecto conserva su lógica y testabilidad. Alternativa descartada: conservar cape de P2 debajo del cabello como duplicación visual; decidir su uso por perfil al integrar, dejando cape para P1 si la apariencia elegida lo requiere.

### Inventario de migración por riesgo y validación

**Archivos previstos para modificar:** `src/models/player/player_controller.gd`, `player_movement_constants.gd`, módulos de técnicas que tengan brechas demostradas, `player_input_reader.gd` solo si se requieren acciones nuevas, `player_presentation_controller.gd`, `player_placeholder.tscn`, `src/scenes/levels/arena.tscn`, y `docs/modules/player.md` más documentación de inventario de animación. `src/managers/match_manager.gd`, `src/models/balloon/balloon_controller.gd`, `cpu_controller.gd`, predictor, nivel/cámara, menús y TileSets se mantienen compatibles; solo se modifican si una nueva propiedad de perfil hace necesario un enlace y se añade prueba de contrato.

**Archivos candidatos a crear:** un perfil visual (`src/models/player/player_visual_profile.gd` o recursos `.tres`), `player_hair.gd` y `player_hair.tscn`, además de pruebas focalizadas para cabello, perfil independiente y transiciones no cubiertas. Un módulo de estado solo si descomponer transiciones permite que el controlador permanezca por debajo de 400 líneas. La ubicación/nombre final debe seguir las convenciones del árbol existente.

**Eliminaciones condicionadas:** retirar polígono placeholder, recursos de animación o cape únicamente si siguen presentes y una búsqueda global demuestra que no se referencian; no borrar `player_dash_techniques.gd`, `player_climb_techniques.gd`, `player_surface_techniques.gd`, rescue area, CPU o assets simplemente por la palabra “reimplementación”. Archivos .uid e importados se eliminan junto con su fuente solo con Godot y referencias confirmadas. `arena.tscn` conserva nodos `Player1`/`Player2` y sus interfaces consumidas.

### Control de regresión y preparación de pruebas

Extender las pruebas actuales en vez de sustituirlas: conservar verificaciones de movimiento, salto, dash, rescate, colisiones, escalada, superficies, cape, CPU, turnos, puntuación y partido completo. Añadir pruebas deterministas con física fijada para paridad P1/P2, límites de velocidad, altura comparativa de salto, ventanas de buffer/coyote en borde temporal, dash diagonal normalizado y contacto de cápsula en suelo/pared/techo/esquina. Revisar a la vez el contexto de balloon y CPU para detectar cambios temporales de golpe/intercepción. Pruebas visuales validan selección de frames y pelo, sin pedir igualdad de píxeles entre artes diferentes. Ejecutar el verificador de 400 líneas al final y asegurar escenas importadas en modo offline.

## Risks / Trade-offs

- [El movimiento de referencia difiere en escala, tick o API] → Registrar versión exacta y comparar trazas en el proyecto 4.7; adaptar fórmulas y no copiar código.
- [Cambios de velocidad o dash alteran contactos, puntuación o predicción del CPU] → Congelar geometría y reglas; correr las pruebas de partido/CPU junto con cada hito físico.
- [No se dispone de derechos suficientes para los dos sets de sprites] → Tratar la comprobación de derechos como bloqueo de incorporación del arte y usar recursos autorizados/originales hasta resolverlo.
- [Simulación de cabello causa jitter o costo excesivo] → Acotar segmentos/iteraciones, usar delta limitado, reinicializar tras teletransporte y medir en una arena con ambos jugadores activos.
- [Controlador o archivos exceden 400 líneas] → Dividir por responsabilidad observable y comprobar con `scripts/check_source_line_limits.sh`; no crear abstracciones sin prueba de mantenibilidad.
- [Cambios OpenSpec en curso pisan los mismos archivos] → Revisar diferencias y marcar una sola secuencia de aplicación antes de comenzar; no aplicar tareas duplicadas ni sobrescribir trabajo local existente.

## Migration Plan

1. Antes de código, inspeccionar archivos concretos y revisiones actuales de los dos repositorios; fijar su commit, versión Godot, entry points de movimiento, hitbox y licencia de cada recurso. Actualizar el documento comparativo con P1 y P2 y una matriz brecha/prueba.
2. Decidir y registrar la fuente visual autorizada; crear perfiles de recursos mientras el comportamiento siga compartido. Si falta autorización, aplicar perfiles originales/propietarios compatibles con las mismas dimensiones de anclaje.
3. Añadir o ajustar pruebas de caracterización sobre el controlador actual para capturar comportamiento y reglas; guardar valores base observables de hitbox, match, balón y CPU.
4. Implementar estados y físicas en etapas: movimiento horizontal y gravedad; salto/forgiveness; wall slide/jump; dash/superficies. Cada etapa adapta pruebas y conserva `move_and_slide()` como autoridad única.
5. Separar perfiles de P1/P2, mapear animaciones a señales/estados reales, añadir pelo P2 cosmético y verificar reinicio de ronda, ambos jugadores simultáneos y CPU.
6. Migrar escenas/integraciones, borrar solo recursos probados obsoletos, actualizar documentación, ejecutar regresión y límite de líneas.

**Rollback:** revertir por grupo de archivos/hito manteniendo las rutas `Player1` y `Player2`, las firmas de reset y señales de contacto. No cambiar capa/máscara de arena. Si un cambio de perfil visual falla, se puede restaurar el visual compartido sin revertir la capa física; si una regla física rompe turnos/contactos, revertir el último hito físico antes de continuar.

## Open Questions

Ninguna para los contratos o la arquitectura. La incorporación de sprites específicos está condicionada a evidencias de licencia/permiso descritas arriba; la auditoría de fuente y selección de recurso con derechos se resuelve como tarea obligatoria antes de importar archivos, no como decisión implícita.
