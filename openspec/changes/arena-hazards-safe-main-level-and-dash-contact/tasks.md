# Tasks

## 1. Contenido de niveles y márgenes seguros

- [x] 1.1 Confirmar que `map-selection-tileset-arena-system` ya implementa el catálogo y selector; verificar en código que la escena principal carga el primer mapa válido del catálogo.
- [x] 1.2 Añadir el margen seguro configurable a los datos de arena y aplicarlo a límites de cámara y colisión; verificar por revisión geométrica que los footprints de jugadores y globo permanecen dentro de la vista en arenas de 320 × 180 y 480 × 270.
- [x] 1.3 Crear y registrar dos arenas nuevas: la principal de 320 × 180 con solo piso visible y límites invisibles, y una escena secundaria basada en la geometría existente; verificar en catálogo que la principal es predeterminada y ambas aparecen en la lista de selección.

## 2. Interacciones de trampolín y hazards

- [x] 2.1 Verificar e integrar trampolines reutilizables para jugadores y globo; comprobar rebote vertical configurado, velocidad horizontal del jugador preservada y un solo contacto por aterrizaje.
- [x] 2.2 Crear la escena reusable de pinchos y conectar su evento al cierre de ronda; verificar explosión del globo, punto al rival del último jugador que lo tocó, fallback sin toque y una única puntuación.
- [x] 2.3 Crear ventiladores con dirección, potencia y alcance configurables que apliquen fuerza solo al globo; verificar que el globo cambia trayectoria dentro del flujo y los jugadores mantienen su velocidad.
- [x] 2.4 Añadir trampolines, pinchos y ventiladores a la arena secundaria y actualizar las miniaturas de todas las arenas para reflejar su geometría final; verificar visualmente cada vista previa contra su mapa.

## 3. Contacto del globo durante el dash

- [x] 3.1 Bloquear nuevos contactos del mismo jugador solo después del primer toque válido durante una activación de dash y restaurarlos al terminarla; verificar que otro jugador sigue pudiendo tocar el globo y que un dash sin toque no bloquea contactos.

## 4. Integración de juego

- [ ] 4.1 Ejecutar partidas en los dos niveles nuevos y verificar selección por defecto, límites seguros, miniaturas, rebote en trampolines, puntuación por pinchos, corriente de ventiladores y contacto único del dash hasta completar una ronda.

## Workflow follow-up

- Aplicar y archivar `map-selection-tileset-arena-system` antes de integrar este cambio, ya que proporciona el catálogo y selector de arenas requeridos.
