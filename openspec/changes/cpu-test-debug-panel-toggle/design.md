# Design

## Context

El panel `CPUDebugPanel` y su botón viven en una `CanvasLayer` del árbol principal, mientras que `NavGraphOverlay` dibuja el grafo, rutas, objetivo, trayectoria e indicador CPU bajo la arena. `CPUTestDebugController` también recibe controles de depuración. Son nodos separados y deben compartir el mismo ciclo de vida de Test CPU. Véase [proposal.md](./proposal.md) para la motivación y [specs/cpu-test-debug-ui/spec.md](./specs/cpu-test-debug-ui/spec.md) para el contrato.

## Goals / Non-Goals

**Goals:**

- Mantener juntos el panel y el botón de alternancia bajo el ciclo de vida de Test CPU.
- Poder ocultar solo las opciones, dejando accesible el botón que las vuelve a mostrar.
- Retirar o desactivar toda la UI visual y los controles de depuración antes de reanudar el menú o un modo normal.
- Asegurar que una partida normal no cree ni herede esta interfaz.

**Non-Goals:**

- Cambiar la telemetría CPU, las capas de visualización, las teclas rápidas ni el comportamiento de pausa y cámara lenta.
- Añadir un panel global de depuración o persistir la preferencia de visibilidad entre partidas.

## Decisions

1. **Separar el panel de opciones del control de alternancia.** Mantener el botón fuera del `PanelContainer` ocultable. El botón cambia solo la visibilidad del panel, sin añadir dependencias con el HUD global.
2. **Tratar panel, overlay e input como una sesión de depuración.** Aunque estén bajo padres distintos, el controlador del modo es dueño de su activación. Al salir, primero deshabilitar la entrada de depuración y las actualizaciones de telemetría, ocultar/limpiar el overlay y ocultar el panel y el botón; después liberar los nodos. Esto evita que un frame o una actualización tardía vuelva a mostrar elementos al abrir el menú normal.
3. **Crear la sesión solo al iniciar Test CPU.** El menú normal y las partidas estándar no deben instanciar ni retener el panel, el botón, el overlay o el controlador. Reiniciar el modo de prueba crea una sesión nueva con los valores iniciales.
4. **Verificar salida completa y aislamiento.** Extender los tests headless para comprobar la ausencia del panel, botón, overlay e input de depuración al salir y durante partidas normales, además de conservar las pruebas de alternancia y estado de simulación.

## Risks / Trade-offs

- [El panel y los gráficos tienen padres distintos y podrían quedar desincronizados] → hacer que el cierre de sesión desactive y limpie ambos antes de volver al flujo normal.
- [Una actualización tardía de CPU podría volver a dibujar el overlay] → desconectar las señales y deshabilitar la entrada antes de limpiar los elementos visuales.
- [Los controles compactos compiten por espacio en la vista] → usar el espacio adyacente al panel existente sin cambiar su contenido ni mover el HUD global.

## Migration Plan

No hay migración de datos ni cambios de configuración. Implementar la alternancia y reforzar las comprobaciones de ciclo de vida; rollback consiste en retirar el botón y restaurar el panel siempre visible, manteniendo el contrato de Test CPU existente.
