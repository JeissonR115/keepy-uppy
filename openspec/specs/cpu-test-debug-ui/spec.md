# cpu-test-debug-ui Specification

## Purpose
Define el ciclo de vida de la interfaz de depuración de Test CPU y cómo el usuario controla su visibilidad sin afectar la simulación.

## Requirements

### Requirement: Test CPU debug UI is mode-scoped
The debug panel, its visibility control, CPU/navigation indicators, and debug controls SHALL be visible or responsive only during an active Test CPU session.

#### Scenario: Start a Test CPU match
- **WHEN** el usuario inicia una partida en modo Test CPU
- **THEN** están disponibles el panel, el botón de alternancia y los indicadores visuales de depuración de Test CPU

#### Scenario: Exit Test CPU mode
- **WHEN** el usuario sale de Test CPU y vuelve al menú o continúa a un modo normal
- **THEN** desaparecen el panel, el botón, los gráficos de navegación y los indicadores CPU, y los controles de depuración dejan de responder

#### Scenario: Start an ordinary match after Test CPU
- **WHEN** el usuario inicia una partida normal de uno o dos jugadores después de salir de Test CPU
- **THEN** no se muestran ni responden elementos de depuración exclusivos de Test CPU y el menú y la partida normales siguen funcionando

### Requirement: User can toggle the Test CPU debug panel
While Test CPU mode is active, the user SHALL be able to show or hide the debug options panel without ending the test or changing simulation state.

#### Scenario: Hide debug options
- **WHEN** el usuario activa el botón de alternancia mientras el panel está visible
- **THEN** el panel de opciones se oculta y el botón sigue disponible para volver a mostrarlo

#### Scenario: Show debug options
- **WHEN** el usuario activa el botón de alternancia mientras el panel está oculto
- **THEN** el panel de opciones vuelve a mostrarse con sus controles de pausa, paso, cámara lenta y capas

#### Scenario: Toggle while simulation is running
- **WHEN** el usuario oculta o muestra el panel durante una prueba
- **THEN** la simulación conserva su estado de pausa, escala temporal y opciones de capas
