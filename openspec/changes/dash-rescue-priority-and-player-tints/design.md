# Design

## Context

`MatchManager` ya mantiene `expected_balloon_player` para el turno del globo y `priority_player` para resolver interferencias; el empuje del dash consulta actualmente solo el segundo. `PlayerController` tiene un `PriorityIndicator` visible con la prioridad de contacto, mientras que el perfil visual aplica tintes independientes y el perfil de Player 2 hoy usa tonos cálidos. Ver `proposal.md` para la motivación y los deltas de especificación para el comportamiento requerido.

## Goals / Non-Goals

**Goals:**
- Consultar el jugador esperado para seleccionar la fuerza de dash de rescate.
- Comunicar turno de rescate y prioridad de contacto con señales visuales inequívocas.
- Centralizar la diferencia cromática en los perfiles visuales existentes.

**Non-Goals:**
- Cambiar el crédito del último toque, el conteo de puntos, o la política de desempate de contactos simultáneos.
- Modificar velocidad, duración o enfriamiento del dash.
- Rediseñar las animaciones o el HUD completo.

## Decisions

- Mantener `expected_balloon_player` como fuente de verdad para el rescatista; usarlo para decidir qué fuerza de empuje aplica un dash. No reutilizar `priority_player`, ya que representa el orden de resolución del contacto y puede pertenecer al jugador opuesto.
- Separar visualmente el indicador de rescate del indicador existente de prioridad de contacto. El triángulo se ubica sobre el jugador esperado y se actualiza en los mismos eventos que cambian el turno; el indicador existente puede seguir comunicando la prioridad de contacto. Esto evita reasignar dos conceptos diferentes a la misma señal.
- Configurar el tinte azul mediante los recursos de perfil ya consumidos por `PlayerPresentationController`; seleccionar tonos con intensidad creciente de P1 a P2 y revisar el contraste sobre las animaciones existentes. Alternativa descartada: colorear nodos por código en la escena, porque duplicaría configuración y haría menos directo ajustar cada perfil.

## Risks / Trade-offs

- [Dos indicadores cercanos pueden solaparse durante el juego] → Colocar el triángulo por encima de la silueta y conservar el indicador de contacto en su ubicación/forma actual; comprobar legibilidad con ambos visibles.
- [Un tinte intenso puede ocultar detalles del arte] → Ajustar los valores en los perfiles, aplicando azul más fuerte al segundo jugador sin perder contraste de silueta y animación.
- [El turno de rescate puede cambiar en transiciones de punto o saque] → Actualizar el indicador desde el mismo flujo que emite el cambio de turno y limpiar su estado al reiniciar una ronda.

## Migration Plan

No requiere migración de datos. Ajustar lógica y presentación en una actualización del juego; si la legibilidad cromática no es satisfactoria, restaurar los tintes anteriores mediante los recursos de perfil y conservar la lógica de turno separada.
