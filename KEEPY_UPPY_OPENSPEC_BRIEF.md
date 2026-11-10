# Keepy Uppy — Project Brief for OpenSpec (SDD)

> Este documento es la fuente inicial de requisitos del videojuego. Entrégalo a tu asistente de programación junto con el repositorio y pídele que genere los artefactos OpenSpec antes de escribir código.
>
> Estado: definición inicial. Las decisiones no especificadas deben proponerse en `design.md` y quedar pendientes de aprobación; no inventar reglas de juego como si ya estuvieran acordadas.

## 1. Objetivo

Desarrollar **Keepy Uppy**, un videojuego 2D de competencia local para dos jugadores, creado con **Godot 4.x y GDScript**, con estética pixel art inspirada en los juegos de 16 bits.

Los dos jugadores intentan mantener un globo en el aire. El movimiento debe ser expresivo, preciso y divertido, con una sensación de control inspirada en la movilidad de *Celeste*, sin copiar personajes, niveles, arte ni contenido de ese juego.

El alcance inicial es un prototipo jugable local para dos personas en un mismo equipo. No implementar multijugador en línea.

## 2. Pilares de diseño

1. **Movimiento satisfactorio:** aceleración, desaceleración, salto variable, Coyote Time, Jump Buffer, control aéreo y dash.
2. **Globo legible y rescatable:** física ligera, impulsos claros y oportunidades para salvarlo usando el dash.
3. **Competencia entre jugadores:** empujones y obstrucciones con reglas de prioridad fáciles de entender.
4. **Lectura visual:** pixel art nítido, efectos visibles y feedback claro de los contactos.
5. **Arquitectura mantenible:** escenas y scripts pequeños, responsabilidades separadas y valores configurables.

## 3. Plataforma y restricciones técnicas

- Motor: Godot 4.x estable.
- Lenguaje: GDScript.
- Juego: 2D.
- Modo: multijugador local para exactamente dos jugadores en la primera versión.
- Sin servicios online, cuentas, servidores ni matchmaking.
- Usar `CharacterBody2D` para los personajes.
- Evaluar `RigidBody2D` para el globo; documentar la decisión y sus consecuencias en `design.md`.
- Usar Input Map para todas las acciones.
- No depender de plugins externos salvo que exista una razón documentada y se apruebe.
- Mantener el proyecto ejecutable al terminar cada incremento.
- No escribir todo el juego en un único script.

## 4. Mecánicas de los jugadores

Cada jugador debe disponer de:

- Movimiento horizontal con aceleración y desaceleración configurables.
- Salto con altura variable.
- Coyote Time.
- Jump Buffer.
- Control aéreo.
- Dash de ocho direcciones.
- Estados y animaciones para idle, correr, subir, caer y dash.
- Colisiones con el escenario y con el otro jugador.

Los parámetros de movimiento deben estar expuestos mediante `@export` o centralizados en recursos/configuración apropiados. Evitar números mágicos.

### Controles iniciales

Jugador 1:
- `player_1_left`: A
- `player_1_right`: D
- `player_1_jump`: Space
- `player_1_dash`: Shift

Jugador 2:
- `player_2_left`: Left
- `player_2_right`: Right
- `player_2_jump`: Enter
- `player_2_dash`: Right Ctrl

Los controles deben poder cambiarse desde Input Map sin modificar la lógica de movimiento.

## 5. Globo

El globo es el objetivo central de la partida. Debe:

- Permanecer sujeto a una física ligera y configurable.
- Recibir impulsos de los contactos válidos de los jugadores.
- Rebotar y perder velocidad de forma controlada.
- Interactuar con el escenario y detectar cuando toca el suelo.
- Tener una animación visual sutil de flotación.
- Proporcionar feedback visual y sonoro cuando recibe un golpe, si los assets de audio están disponibles.

La física debe ser predecible para el jugador, aunque visualmente se sienta ligera. Separar la detección del contacto de la aplicación del impulso para facilitar pruebas y balance.

## 6. Dash y estela de rescate

Al ejecutar un dash, el jugador genera una zona de interacción temporal asociada a su trayectoria (no solo un efecto visual).

Requisitos:
- La zona activa durante un intervalo configurable.
- Detecta el globo de forma consistente.
- Si el globo entra en contacto, aplica un impulso que tenga en cuenta la dirección del dash.
- El efecto debe poder rescatar el globo antes de que toque el suelo.
- Evitar múltiples golpes involuntarios durante una sola activación, salvo que el diseño lo permita explícitamente.
- La estela visual debe poder existir independientemente de la zona de colisión.
- La zona de rescate debe tener una forma y duración documentadas en `design.md`.

## 7. Interacción y prioridad entre jugadores

Los jugadores pueden empujarse y estorbarse. El juego debe mantener una variable de prioridad que identifique qué jugador tiene la ventaja en la siguiente disputa por el globo.

Reglas iniciales:
- La prioridad cambia cuando un jugador realiza un contacto válido con el globo.
- El jugador con prioridad puede desplazar al rival con mayor fuerza.
- El jugador sin prioridad conserva movilidad y puede estorbar, pero sus empujones son más débiles.
- El dash del jugador con prioridad debe tener mayor capacidad de desplazamiento contra el oponente.
- La fuerza, duración, enfriamiento y condiciones deben ser configurables.
- El feedback visual debe comunicar claramente quién tiene prioridad.

**Decisión pendiente:** especificar qué sucede al inicio de una ronda, cuando el globo toca el suelo, en contactos simultáneos y cuando un dash y un golpe normal ocurren en el mismo instante. Proponer reglas en `design.md`; no asumirlas silenciosamente.

## 8. Puntuación y ciclo de ronda

El juego debe detectar cuando el globo toca el suelo y registrar el resultado de la ronda.

La asignación de puntos aún debe definirse. En la propuesta, documentar alternativas sencillas y recomendar una regla consistente con el objetivo competitivo. No implementar una regla ambigua sin explicarla.

Preparar:
- Marcador para ambos jugadores.
- Reinicio de ronda.
- Estado de partida.
- Condición de victoria configurable.

## 9. Dirección visual y audio

- Pixel art de apariencia 16 bits.
- Resolución interna y escala entera recomendadas en `design.md`.
- Filtro de textura apropiado para mantener píxeles nítidos.
- Cámara 2D.
- Escenario con plataformas.
- Animaciones legibles y efectos de partículas.
- Estela de dash y feedback de impacto.
- Interfaz minimalista con marcador.
- Música y efectos de sonido opcionales en el prototipo inicial.

No generar ni descargar assets automáticamente. El propietario del proyecto creará los recursos manualmente con los nombres exactos definidos por el asistente.

Mientras no existan assets, utilizar placeholders (formas geométricas, colores o sprites temporales) para que el juego pueda ejecutarse y probarse.

## 10. Estructura objetivo del repositorio

Usar esta estructura como punto de partida. Ajustarla solo si existe una razón técnica explicada en `design.md`.

```text
KeepyUppy/
├── assets/
│   ├── sprites/
│   │   ├── players/
│   │   ├── balloon/
│   │   ├── environment/
│   │   ├── effects/
│   │   └── ui/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   └── backgrounds/
├── src/
│   ├── models/
│   │   ├── player/
│   │   ├── balloon/
│   │   ├── environment/
│   │   └── effects/
│   ├── scenes/
│   │   ├── main/
│   │   ├── levels/
│   │   └── ui/
│   ├── managers/
│   ├── utils/
│   └── globals/
├── openspec/
│   ├── config.yaml
│   ├── specs/
│   └── changes/
├── project.godot
└── README.md
```

### Responsabilidades sugeridas

- `src/models/player/`: escena del jugador y componentes de movimiento, dash e interacción.
- `src/models/balloon/`: escena, física y detección de contactos del globo.
- `src/models/environment/`: plataformas y elementos físicos del escenario.
- `src/models/effects/`: estelas, partículas y feedback visual.
- `src/scenes/`: composición de escenas principales, niveles y UI.
- `src/managers/`: coordinación de partida, jugadores, globo y puntuación.
- `src/utils/`: utilidades reutilizables sin estado global.
- `src/globals/`: scripts Autoload estrictamente necesarios. Usar extensión `.gd`; no inventar una extensión `.gdt`.

Evitar que los managers concentren toda la lógica. Las entidades deben conservar sus comportamientos locales y comunicarse mediante señales cuando sea adecuado.

## 11. Contrato de assets

Antes de implementar una escena que dependa de recursos gráficos, entregar una tabla o manifiesto con:

- Ruta relativa exacta.
- Nombre de archivo exacto.
- Tipo de recurso.
- Dimensiones recomendadas.
- Cantidad de frames y distribución de spritesheet, si aplica.
- Animaciones que contiene.
- Uso dentro del juego.

Ejemplo inicial de nombres (se pueden ajustar antes de aprobar el manifiesto):

```text
assets/sprites/players/
├── player_1_idle.png
├── player_1_run.png
├── player_1_jump.png
├── player_1_fall.png
├── player_1_dash.png
├── player_2_idle.png
├── player_2_run.png
├── player_2_jump.png
├── player_2_fall.png
└── player_2_dash.png

assets/sprites/balloon/
└── balloon.png

assets/sprites/environment/
├── platform.png
└── ground.png

assets/sprites/effects/
└── dash_trail.png
```

No cambiar los nombres después de que el propietario haya creado los archivos, salvo que se solicite y se actualicen todas las referencias. Los placeholders no deben requerir archivos externos.

## 12. Arquitectura y calidad

- Una escena y un script principal por entidad cuando corresponda.
- Composición antes que herencia profunda.
- Señales para eventos entre sistemas.
- Tipado estático siempre que sea práctico.
- `class_name` solo cuando mejore la claridad o reutilización.
- `@export` para parámetros de balance.
- Autoload solo para estado o servicios realmente globales.
- Nombres de clases, métodos, variables y archivos en inglés.
- Comentarios breves y útiles.
- Evitar dependencias circulares y rutas de nodos frágiles.
- No duplicar la autoridad de estado entre managers.
- Añadir pruebas manuales reproducibles y, cuando sea viable, pruebas automatizadas para lógica aislable.

## 13. Fases de implementación

Organizar el trabajo en cambios OpenSpec pequeños y verificables. No implementar todas las fases en una sola operación.

1. **Project foundation:** estructura, configuración de Godot, escena principal temporal y placeholders.
2. **Player controller:** dos jugadores, movimiento, salto variable, Coyote Time, Jump Buffer y dash.
3. **Balloon physics:** física del globo, contactos, impulsos y detección de suelo.
4. **Dash rescue:** zona temporal de rescate y estela visual.
5. **Player interaction:** empujones, prioridad y balance de fuerzas.
6. **Round and score:** rondas, marcador, reinicio y condición de victoria.
7. **Level and presentation:** escenario, UI, animaciones, partículas y audio.
8. **Polish and verification:** balance, corrección de errores y pruebas de partida completa.

Cada fase debe terminar con un proyecto ejecutable y una lista de pruebas manuales. No avanzar a la siguiente fase si existen errores bloqueantes o criterios de aceptación sin cumplir.

## 14. Criterios de aceptación iniciales

El prototipo se considera funcional cuando:

- Godot abre el proyecto sin errores de importación.
- La escena principal se ejecuta sin assets definitivos.
- Dos jugadores pueden moverse simultáneamente con sus controles independientes.
- El salto variable, Coyote Time y Jump Buffer funcionan de forma comprobable.
- El dash responde a las ocho direcciones.
- El globo puede recibir impulsos de ambos jugadores.
- La zona de dash puede rescatar el globo.
- La prioridad cambia según la regla acordada y modifica la fuerza de interacción.
- El contacto del globo con el suelo se detecta de forma fiable.
- El marcador y el reinicio de ronda funcionan según las reglas aprobadas.

## 15. Instrucciones para OpenSpec y el agente

Lee este documento completo antes de proponer cambios.

1. Inspecciona el repositorio y detecta si ya existe un proyecto Godot o código que deba preservarse.
2. No sobrescribas ni elimines archivos existentes sin explicar el motivo y solicitar aprobación.
3. Crea una propuesta OpenSpec para la fundación y el prototipo jugable de Keepy Uppy.
4. Genera los artefactos de planificación requeridos por el esquema `spec-driven`: `proposal.md`, especificaciones delta bajo `specs/`, `design.md` y `tasks.md`.
5. Divide requisitos por capacidades (por ejemplo: player-controller, balloon-physics, dash-rescue, player-interaction, round-scoring y local-input) cuando eso facilite el mantenimiento.
6. En `proposal.md`, explica objetivo, alcance, motivación y fuera de alcance.
7. En los archivos de especificación, escribe requisitos comprobables con escenarios Given/When/Then o el formato requerido por OpenSpec.
8. En `design.md`, documenta escenas, nodos, scripts, señales, físicas, estados, input, decisiones pendientes, riesgos y estructura de assets.
9. En `tasks.md`, crea tareas pequeñas, ordenadas y verificables, vinculadas a los requisitos.
10. Incluye explícitamente las decisiones pendientes sobre puntuación, prioridad inicial, contactos simultáneos y parámetros físicos.
11. No escribas código de implementación hasta que el propietario revise y apruebe los artefactos de planificación.
12. Después de la aprobación, implementa una fase a la vez. Al modificar un archivo existente, entrega su contenido completo y conserva los cambios no relacionados.
13. Al finalizar cada fase, ejecuta las comprobaciones disponibles, revisa errores de Godot y resume archivos creados/modificados, pruebas realizadas y pendientes.

**Primera tarea:** crear y validar únicamente la planificación OpenSpec del proyecto. No implementar todavía el videojuego.
