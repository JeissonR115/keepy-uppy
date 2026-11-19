# Design

## Context

El catálogo actual ya guarda escenas, vista previa, bounds y posiciones iniciales mediante `ArenaData`; el gestor carga el primer elemento registrado si aún no se seleccionó un nivel. Hay dos arenas con vistas previas propias. El globo ya rebota en nodos del grupo `trampoline`, y los jugadores tienen lógica para impulsarse al colisionar con ese grupo. `MatchManager` centraliza el último toque y la resolución de puntos. Ver `proposal.md` y los deltas para el comportamiento requerido.

La creación de mapas depende del cambio pendiente `map-selection-tileset-arena-system`, que aporta el catálogo y selector. Ese cambio debe estar aplicado antes de integrar este contenido.

## Goals / Non-Goals

**Goals:**
- Añadir una arena principal por defecto de 320 × 180, con piso visible y sin plataformas, y una arena secundaria que presente los elementos interactivos.
- Reutilizar `ArenaData` para bounds seguros, posiciones iniciales y miniaturas fieles al mapa.
- Mantener las interacciones de trampolín y balón en controladores separados, con escenas reutilizables para pinchos y ventiladores.
- Resolver el contacto con pinchos como un solo cierre de ronda, acreditando el punto al rival del último jugador que hizo un toque válido.
- Evitar contactos adicionales del jugador durante la misma activación de dash después del primer toque válido, sin desactivar colisiones compartidas.

**Non-Goals:**
- Hacer que los ventiladores afecten a los jugadores.
- Cambiar las reglas de puntuación por contacto con el suelo o por toque bajo.
- Reemplazar el catálogo, selector o flujo de menú existentes.

## Decisions

- Registrar ambos niveles en el catálogo existente y ubicar la arena compacta primero o marcarla explícitamente como predeterminada, manteniendo compatibilidad con el selector. La geometría jugable visible de la arena compacta contiene solo el piso; las paredes y el techo de seguridad son invisibles.
- Añadir un margen seguro configurable al dato de cada arena y derivar de él límites de cámara/colisión con espacio suficiente para la silueta de los jugadores, el radio del globo y elementos interactivos. Esto evita ajustes por nombre de mapa y conserva dimensiones distintas entre arenas.
- Actualizar las miniaturas SVG existentes y añadir las dos nuevas en el directorio de previews actual. Mantenerlas como texturas estáticas de catálogo, de acuerdo con el flujo existente; no instanciar las escenas del mapa dentro de un SubViewport.
- Reutilizar la lógica del grupo `trampoline` para los jugadores y el globo, verificando que las nuevas superficies usan colisión desde arriba y conservan la velocidad horizontal del jugador.
- Implementar pinchos como una superficie hazard que notifica una sola vez por ronda. `MatchManager` usa `round_has_valid_contact` y `last_valid_toucher` para decidir si el punto corresponde a su rival; si no hubo toque válido, utiliza la regla actual de rondas sin toque. La transición normal de ronda impide premios duplicados.
- Implementar ventiladores como regiones que aplican fuerza continua solo al globo, usando parámetros editables para dirección, potencia y alcance. No incluir los jugadores en la máscara de interacción.
- Mantener el bloqueo de contacto de dash por activación y jugador, no desactivar la `PlayerContactArea` compartida ni la colisión física del jugador. Al terminar el dash, rearmar el contacto para permitir una interacción posterior incluso si el globo quedó cerca.

## Risks / Trade-offs

- [Los límites invisibles pueden reducir demasiado el espacio de una arena compacta] → Calcular el margen con las dimensiones reales de colisión y comprobar el encuadre 320 × 180.
- [Un evento de pinchos podría competir con el contacto de piso en el mismo frame] → Resolver y marcar primero el evento que cierre la ronda; ignorar posteriores eventos de puntuación de esa ronda.
- [El empuje repetido del ventilador puede acelerar demasiado el globo] → Limitar la fuerza y la velocidad resultante con parámetros configurables y validar distintas intensidades.
- [La geometría de los mapas puede quedar desactualizada respecto a una miniatura] → Incluir la actualización de cada miniatura en la tarea del mapa que modifica.
- [El cambio depende de un catálogo aún sujeto a otro cambio OpenSpec] → Aplicarlo después de `map-selection-tileset-arena-system` y comprobar los recursos efectivos del catálogo antes de registrar mapas.

## Migration Plan

No requiere migración de partidas guardadas. Aplicar primero el sistema de catálogo y selección pendiente; después registrar los nuevos mapas, margen seguro y vistas previas, añadir las escenas de interacción y conectar eventos de hazards con la resolución de ronda. Si un nuevo mapa o hazard rompe el inicio de la partida, conservar las arenas anteriores en el catálogo y desactivar la nueva entrada hasta corregir su escena.
