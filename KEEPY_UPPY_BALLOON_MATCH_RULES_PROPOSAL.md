# OpenSpec Proposal — Globo, físicas y sistema competitivo

Lee este documento junto con `KEEPY_UPPY_OPENSPEC_BRIEF.md`.

## 1. Objetivo

Definir e implementar las reglas competitivas de Keepy Uppy:

- Física del globo.
- Contactos de los jugadores.
- Sistema de prioridad.
- Inicio de cada punto.
- Puntuación.
- Sets y victoria del partido.

## 2. Formato de partida

El juego funciona mediante sets.

Reglas:

- Cada set se juega a 5 puntos.
- El primer jugador que consiga 5 puntos gana el set.
- El primer jugador que consiga 3 sets gana el partido.
- Al comenzar un nuevo set, los puntos de ambos jugadores vuelven a cero.
- Los sets ganados se conservan durante toda la partida.

No se exige diferencia de dos puntos. Si el marcador está 4-4, el siguiente punto determina el ganador del set.

## 3. Inicio del partido y tirada de moneda

Al comenzar un partido nuevo:

1. Realizar una tirada de moneda aleatoria.
2. Asignar el primer inicio a P1 o P2.
3. Mostrar visualmente el resultado.
4. Preparar el globo y los jugadores.
5. Comenzar el primer punto.

La moneda solamente se utiliza al iniciar un partido nuevo.

### Inicio de los siguientes puntos

El jugador que gana el punto anterior comienza el siguiente.

Esta regla también se aplica al iniciar un nuevo set.

No realizar otra tirada de moneda entre sets.

## 4. Regla para ganar un punto

El punto termina cuando el globo toca el suelo.

Regla propuesta:

- Registrar qué jugador realizó el último contacto válido con el globo.
- Si el globo toca el suelo, gana el punto el jugador contrario al último que lo tocó.
- El ganador comienza el siguiente punto.

Ejemplo:

Si P1 fue el último jugador en tocar el globo y este cae al suelo, P2 gana el punto y comienza el siguiente.

**Decisiones pendientes:**

- Qué sucede si el globo cae sin haber sido tocado.
- Cómo resolver contactos simultáneos.
- Cómo resolver situaciones donde no se puede determinar el último contacto.

Proponer soluciones deterministas antes de implementar.

## 5. Física del globo

El globo debe sentirse ligero y flotante, no como una pelota pesada.

Debe tener:

- Gravedad o flotación configurable.
- Velocidad vertical máxima.
- Velocidad horizontal máxima.
- Resistencia al movimiento horizontal.
- Rebotes.
- Impulsos variables.
- Colisiones con jugadores.
- Colisiones con escenario.
- Detección del contacto con el suelo.
- Animación de flotación.

### Parámetros configurables

Todos los valores físicos deben poder modificarse sin reescribir el código.

Proponer valores iniciales para:

- Gravedad.
- Resistencia horizontal.
- Velocidad máxima.
- Fuerza de rebote.
- Fuerza mínima y máxima de impacto.
- Intervalo mínimo entre contactos.
- Tamaño de las zonas de colisión.

Evaluar si conviene utilizar `RigidBody2D` o implementar parte del movimiento mediante código.

Documentar la decisión técnica y sus consecuencias.

## 6. Contactos con el globo

Cada contacto válido debe:

1. Identificar al jugador.
2. Registrar quién realizó el contacto.
3. Aplicar un impulso al globo.
4. Considerar la dirección y velocidad del contacto.
5. Actualizar la prioridad.
6. Generar feedback visual y sonoro cuando existan los assets.

Diferenciar:

- Contacto normal.
- Contacto mediante dash.
- Contacto mediante la estela de dash.

Evitar que una misma colisión genere múltiples golpes involuntarios.

## 7. Sistema de prioridad

La prioridad representa qué jugador tiene ventaja en las interacciones físicas.

Reglas:

- Al comenzar un punto, tiene prioridad quien lo inicia.
- Cuando el otro jugador realiza un contacto válido con el globo, la prioridad cambia.
- El jugador con prioridad puede empujar al rival con mayor fuerza.
- El jugador sin prioridad puede seguir moviéndose y obstaculizando, pero sus empujones son más débiles.
- El dash del jugador con prioridad debe tener mayor capacidad de desplazamiento.
- La prioridad debe comunicarse visualmente.

Diferenciar claramente:

**Ganador del punto:** determina quién recibe el punto y quién inicia el siguiente.

**Jugador con prioridad:** determina quién tiene ventaja durante las interacciones físicas del punto actual.

La fuerza de empuje, los multiplicadores, la duración y los límites deben ser configurables.

Evitar que los empujones saquen a los jugadores del escenario.

## 8. Ciclo de partido

Implementar una máquina de estados para controlar el partido.

Estados sugeridos:

- `MATCH_START`
- `COIN_TOSS`
- `POINT_START`
- `POINT_ACTIVE`
- `POINT_RESULT`
- `SET_RESULT`
- `MATCH_RESULT`

Flujo:

1. Iniciar partido.
2. Realizar tirada de moneda.
3. Asignar quién inicia.
4. Preparar jugadores y globo.
5. Comenzar el punto.
6. Detectar cuando el globo toca el suelo.
7. Determinar el ganador.
8. Actualizar los puntos.
9. Comprobar si alguien llegó a 5 puntos.
10. Si ganó el set, actualizar el marcador de sets.
11. Comprobar si alguien llegó a 3 sets.
12. Si no terminó el partido, preparar el siguiente punto.

Evitar que una misma caída del globo registre más de un punto.

## 9. Interfaz

Mostrar:

- Puntuación actual de P1 y P2.
- Sets ganados por ambos jugadores.
- Quién inicia el siguiente punto.
- Quién tiene prioridad.
- Resultado de la tirada de moneda.
- Mensaje al ganar un punto.
- Mensaje al ganar un set.
- Mensaje al ganar el partido.

La interfaz debe mantener la estética pixel art de 16 bits.

No debe tapar a los jugadores ni al globo.

## 10. Arquitectura sugerida

Separar responsabilidades:

- `balloon.gd`: físicas y movimiento del globo.
- Componente de contacto: detección y registro de golpes.
- `game_manager.gd`: ciclo general del partido.
- `score_manager.gd`: puntos, sets y ganador.
- `turn_manager.gd`: inicio de puntos y prioridad.
- `player_collision.gd`: interacciones físicas entre jugadores.

La interfaz debe escuchar señales de los sistemas correspondientes.

Utilizar señales para eventos como:

- `balloon_touched`
- `balloon_hit_ground`
- `point_awarded`
- `set_won`
- `match_won`
- `priority_changed`

Adaptar los nombres a la arquitectura existente y evitar managers duplicados.

## 11. Criterios de aceptación

1. Un partido nuevo realiza una única tirada de moneda.
2. El ganador de cada punto inicia el siguiente.
3. El globo determina correctamente cuándo termina un punto.
4. Una caída solamente registra un punto.
5. La prioridad inicial corresponde al jugador que comienza.
6. La prioridad cambia cuando el rival toca válidamente el globo.
7. La prioridad modifica las fuerzas de empuje.
8. Los contactos normales y los de dash generan respuestas diferentes.
9. El primero que alcanza 5 puntos gana el set.
10. El primero que gana 3 sets gana el partido.
11. Los puntos se reinician entre sets.
12. Los sets se conservan durante el partido.
13. La interfaz refleja correctamente todos los estados.
14. Las físicas pueden ajustarse desde la configuración del proyecto.

## 12. Instrucciones para OpenSpec

1. Leer `KEEPY_UPPY_OPENSPEC_BRIEF.md` y este documento.
2. Inspeccionar las especificaciones y el código existente.
3. Crear una propuesta OpenSpec nueva e independiente.
4. Evitar duplicar funcionalidades ya especificadas.
5. Generar `proposal.md`, `specs/`, `design.md` y `tasks.md`.
6. Utilizar escenarios Given/When/Then para los requisitos comprobables.
7. Documentar las físicas, contactos, prioridad y máquina de estados.
8. Dejar explícita la regla de atribución del punto como propuesta pendiente de aprobación.
9. No implementar código hasta recibir aprobación.
10. Implementar posteriormente por fases y validar cada regla.

**Primera tarea: generar y validar únicamente los documentos OpenSpec. No implementar código todavía.**
