# Design

## Context

Actualmente `arena.tscn` contiene actores, gestor de partida, cámara, piso y límites fijos en una sola escena de 320 × 180. `PlayerController` y `MatchManager` dependen de referencias relativas entre actores hermanos; `MatchManager` mantiene los spawns como exports. `BalloonController` ya distingue el grupo `scoring_ground`, mientras el jugador ya implementa plataformas de una vía y caída con Abajo + Salto. El archivo del tileset existe, pero debe inspeccionarse su grilla real al importarlo. La documentación de niveles menciona gestores y mapas que no están presentes en el árbol actual.

## Goals / Non-Goals

**Goals:**
- Mantener estable la raíz de partida y sus actores, sustituyendo solo la geometría activa del mapa.
- Hacer que los mapas nuevos se registren mediante datos y escenas, no ramificaciones nuevas en menú o gestores.
- Aplicar bounds y spawns del mapa antes de reiniciar partida y configurar cámara.
- Usar colisiones de TileSet y clasificación explícita de superficies puntuables.

**Non-Goals:**
- Añadir trampolines, picos, arena lenta, viento u otras mecánicas de peligro.
- Cambiar reglas de servicio, control de jugadores, formato de guardado o dependencias externas.
- Fijar multiplicadores físicos para mapas todavía no diseñados.

## Decisions

1. **Recursos de arena tipados más catálogo explícito.** `ArenaData` guardará id, presentación, escena de geometría, bounds, spawns y ajustes opcionales. Un recurso catálogo ordenado referenciará las arenas. Esto mantiene el descubrimiento determinista y compatible con Godot sin depender de escaneo de archivos en runtime; registrar un mapa será agregar su recurso al catálogo.

2. **Raíz de partida estable con `MapRoot` reemplazable.** Jugadores, globo, `MatchManager`, HUD y cámara permanecerán en la escena persistente. El gestor de arena instanciará la escena de mapa bajo un nodo dedicado, aplicará spawns a `MatchManager` y actualizará límites de cámara antes de reiniciar. Se elige esto frente a reemplazar la escena completa porque los controladores actuales buscan hermanos por rutas relativas.

3. **TileSet como autoría de geometría y colisión.** Importar `foreground_tilesets.png` y comprobar su celda/padding visual antes de fijar el tamaño de atlas. Definir física separada para sólido y una vía, alineada con las capas existentes; no codificar el tamaño supuesto de celda del documento fuente. Las plataformas conservan la interacción existente de abajo hacia arriba y caída del jugador.

4. **Marcado explícito de piso puntuable.** Los pisos que finalizan la ronda pertenecerán al grupo `scoring_ground`; plataformas de tránsito no lo harán. Esto aprovecha la señal existente de `BalloonController` y evita que cualquier contacto de tile puntúe. No se delega esta semántica a la apariencia visual del tile.

5. **Vista previa por textura con fallback.** `ArenaData` permitirá una textura miniatura asignada por arena. La UI usará una tarjeta neutral cuando falte, en lugar de instanciar el mapa dentro de un `SubViewport`; esta opción reduce el acoplamiento y costo en el menú, dejando abierta una vista dinámica si más adelante se necesita.

6. **Ajustes físicos neutrales y optativos.** Los datos podrán exponer multiplicadores compatibles con los controladores existentes, con valor neutro por defecto. No se introducirá acumulación de momentum nueva ni escalado automático de física por tamaño, ya que podría alterar el balance de la arena actual sin datos de diseño. Estos efectos se calibrarán al crear arenas que los requieran.

## Risks / Trade-offs

- [El atlas puede tener celdas irregulares o márgenes] → Inspeccionar dimensiones y regiones antes de configurar TileSet; validar el primer mapa visualmente dentro del editor.
- [La geometría puntuable puede perder su etiqueta durante la migración] → Mantener una superficie de puntuación explícita y comprobar el contacto del globo después de separar mapa y raíz.
- [Cambiar límites puede alterar cámara en la arena clásica] → Registrar bounds equivalentes a 320 × 180 y comprobar encuadre inicial y spawns antes de añadir mapas grandes.
- [El catálogo explícito requiere editar un archivo al añadir un mapa] → Centralizar el registro en un recurso único y documentar el flujo de creación de arena.

## Migration Plan

1. Crear los recursos tipados y el mapa clásico de referencia; mantener el flujo actual jugable mientras se conecta la raíz persistente.
2. Sustituir la geometría embebida por instancia bajo `MapRoot`, copiando su apariencia, colisiones y puntuación.
3. Conectar catálogo, selector, preview, bounds, spawns y cámara; migrar la escena clásica al catálogo.
4. Confirmar en Godot que el juego inicia, se puede elegir el mapa y la partida conserva el comportamiento existente. Si la migración falla, volver temporalmente a la escena clásica fija mientras se corrige el mapa nuevo.

## Open Questions

- El spritesheet debe inspeccionarse para confirmar el tamaño de celda y el padding, pero ese dato no cambia la arquitectura ni el contrato funcional.
