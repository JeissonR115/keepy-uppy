# OpenSpec Proposal — Configuración de controles locales

Lee este documento junto con `KEEPY_UPPY_OPENSPEC_BRIEF.md`.

## Objetivo

Implementar controles independientes para dos jugadores locales y un menú que permita personalizar las teclas desde el juego.

## 1. Controles predeterminados

### Jugador 1

| Acción          | Tecla |
| --------------- | ----- |
| Mover izquierda | A     |
| Mover derecha   | D     |
| Mover arriba    | W     |
| Mover abajo     | S     |
| Saltar          | F     |
| Dash            | G     |
| Acelerar        | H     |

### Jugador 2

| Acción          | Tecla            |
| --------------- | ---------------- |
| Mover izquierda | Flecha izquierda |
| Mover derecha   | Flecha derecha   |
| Mover arriba    | Flecha arriba    |
| Mover abajo     | Flecha abajo     |
| Saltar          | 1                |
| Dash            | 2                |
| Acelerar        | 3                |

Para 1, 2 y 3 utilizar inicialmente las teclas numéricas de la fila superior del teclado.

## 2. Menú de configuración

Crear una pantalla donde cada jugador pueda configurar individualmente sus controles.

Requisitos:

- Mostrar las acciones y sus teclas actuales.
- Permitir seleccionar una acción para reasignarla.
- Entrar en modo de captura de teclado.
- Mostrar un mensaje mientras se espera una nueva tecla.
- Permitir cancelar la reasignación.
- Guardar la configuración para próximas ejecuciones.
- Incluir un botón para restaurar los controles predeterminados.
- Diferenciar visualmente los controles de ambos jugadores.

## 3. Validación de teclas

No permitir asignar:

- Teclas F1 a F12.
- Escape.
- Teclas modificadoras individuales: Shift, Ctrl, Alt y Meta.
- Teclas reservadas por el sistema operativo.
- Combinaciones que puedan activar atajos del sistema.
- Teclas que ya estén asignadas a otra acción.

Si una tecla no es válida, mostrar un mensaje explicando el motivo.

No intentar interceptar ni bloquear atajos protegidos por el sistema operativo.

Centralizar las reglas de validación para facilitar su mantenimiento.

## 4. Acción acelerar

Crear las acciones:

- `player_1_accelerate`: H.
- `player_2_accelerate`: 3.

La funcionalidad de acelerar todavía debe definirse.

Proponer un impulso temporal de velocidad que tenga:

- Duración configurable.
- Intensidad configurable.
- Tiempo de enfriamiento.
- Velocidad máxima.

No confundir esta habilidad con la aceleración normal del movimiento horizontal.

Presentar la propuesta antes de implementarla.

## 5. Arquitectura

- Utilizar Godot Input Map.
- Separar la lectura de entrada de la lógica de movimiento.
- Evitar duplicar código entre jugadores.
- Mantener independiente la interfaz de configuración.
- Guardar las preferencias mediante un sistema local de Godot.
- Permitir que ambos jugadores utilicen el mismo teclado simultáneamente.

## 6. Criterios de aceptación

1. P1 utiliza WASD y F/G/H.
2. P2 utiliza flechas y 1/2/3.
3. Ambos jugadores pueden recibir entradas simultáneamente.
4. El menú permite reasignar las acciones.
5. Las teclas prohibidas no se guardan.
6. No se permiten asignaciones duplicadas.
7. Cancelar una captura conserva la tecla anterior.
8. Restaurar controles devuelve los valores originales.
9. Las preferencias persisten al reiniciar el juego.
10. Si la configuración está dañada o no existe, se utilizan los valores predeterminados.

## 7. Instrucciones para OpenSpec

1. Leer `KEEPY_UPPY_OPENSPEC_BRIEF.md` y este documento.
2. Inspeccionar el proyecto y las especificaciones existentes.
3. Crear una propuesta OpenSpec independiente.
4. Evitar duplicar requisitos existentes.
5. Generar `proposal.md`, `specs/`, `design.md` y `tasks.md`.
6. Documentar la captura de teclas, persistencia, validaciones y compatibilidad.
7. Dejar explícita la decisión pendiente sobre acelerar.
8. No implementar código hasta recibir aprobación.
9. Implementar posteriormente por tareas pequeñas y verificables.

**Primera tarea: generar y validar únicamente los documentos OpenSpec. No implementar código todavía.**
