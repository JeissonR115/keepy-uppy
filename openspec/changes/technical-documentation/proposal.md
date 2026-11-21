# Proposal

## Why

La documentación actual está repartida entre una guía técnica, páginas de módulos y la referencia del puente, por lo que no ofrece una vista arquitectónica única ni una explicación verificable de la integración con el proyecto de IA. Hace falta un entregable en español que ayude a evaluar y mantener el juego sin duplicar las referencias detalladas existentes.

## What Changes

- Añadir `docs/technical/architecture.md` con las doce áreas solicitadas, diagramas Mermaid, tablas y referencias a rutas concretas del repositorio.
- Añadir anexos técnicos cuando el detalle de tecnologías, decisiones, pruebas o ejecución no quepa con claridad en el documento principal.
- Enlazar la nueva guía desde `docs/README.md`, conservando `docs/cpu-ai-bridge.md` y `docs/modules/` como fuentes detalladas para sus temas.
- Documentar el proyecto `../keepy-uppy-ai` mediante inspección de solo lectura y marcar explícitamente cualquier dato que no pueda confirmarse.
- Limitar el cambio a documentación; no alterar código, pruebas, protocolo ni el repositorio hermano.

## Capabilities

### New Capabilities

Ninguna. El cambio añade documentación y no introduce comportamiento del sistema.

### Modified Capabilities

Ninguna. No cambian requisitos de comportamiento existentes.

## Impact

- Documentación: `docs/technical/` y `docs/README.md`.
- Referencias a código Godot en `src/`, pruebas en `tests/`, configuración y comandos del proyecto.
- Referencias de solo lectura al proyecto hermano `../keepy-uppy-ai`.
- No se modifican APIs, dependencias de ejecución ni el protocolo Godot–Python.
