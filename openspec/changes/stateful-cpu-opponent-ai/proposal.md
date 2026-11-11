# Proposal

## Why

El bot actual está integrado en `PlayerController` y solo toma decisiones cuando le corresponde tocar el globo; el resto del tiempo se queda quieto. Una CPU con estados explícitos, predicción configurable y conducta defensiva/ofensiva hará que las partidas de un jugador sean más completas sin alterar las reglas competitivas ni el movimiento compartido.

## What Changes

- Añadir una capacidad de oponente CPU local basada en FSM y heurísticas deterministas, sin aprendizaje automático ni dependencias externas.
- Separar las decisiones de la CPU del controlador físico del jugador y convertirlas en intenciones de movimiento, salto y dash que consumen las físicas existentes.
- Definir conductas distintas para el turno de la CPU y el turno rival: interceptar el globo cuando le corresponde, y priorizar evitar contactos inválidos antes de decidir si obstaculiza al rival.
- Exponer los parámetros de reacción, error de predicción, agresividad y umbral de dash, además de límites necesarios para predecir la trayectoria.
- Mantener la validación de contactos y faltas en `MatchManager`; la CPU no podrá eludir turnos ni alterar la resolución del punto.
- Hacer deterministas las decisiones y el error de predicción bajo el mismo estado inicial, conciliando el requisito de repetibilidad con la imperfección configurable.

## Capabilities

### New Capabilities
- `cpu-opponent`: decisiones y dificultad configurables para el oponente CPU en los turnos propios y rivales.

### Modified Capabilities
- Ninguna. Las reglas de movimiento, contacto, turnos y puntuación existentes no cambian; la CPU las utiliza.

## Impact

- Código afectado: `src/models/player/player_controller.gd`, el nuevo controlador de CPU en `src/models/player/`, y la integración con `MatchManager` y `BalloonController`.
- Pruebas: ampliar las pruebas de interacción del jugador y añadir cobertura para estados, predicción, parámetros, determinismo y prevención de contactos fuera de turno.
- Documentación: actualizar `docs/modules/player.md` para describir la arquitectura y configuración de la CPU.
- No se requieren cambios a los controles humanos, las reglas de puntuación, la física del globo ni dependencias del proyecto.
