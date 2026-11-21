# Tasks

## 1. Alternancia del panel

- [x] 1.1 Añadir al panel CPU un botón de alternancia fuera del contenedor de opciones, con estado/etiqueta que indique mostrar u ocultar; verificar con `tests/test_cpu_test_controls.gd` que puede ocultarse y mostrarse y el botón sigue accesible.
- [x] 1.2 Comprobar que alternar la visibilidad no cambia el estado de pausa, la escala temporal ni las opciones de capas; verificarlo con el test headless de controles CPU.

## 2. Aislamiento del modo de prueba

- [x] 2.1 Asegurar que la sesión de depuración solo se activa durante Test CPU y que todas las rutas de salida desactivan y retiran el panel, el botón, el overlay y sus entradas; verificarlo con `tests/test_cpu_test_mode_menu.gd`.
- [x] 2.2 Verificar que las partidas normales de uno y dos jugadores no muestran ni responden al panel, botón, gráficos/indicadores o controles de Test CPU con `tests/test_cpu_test_mode_menu.gd`.
