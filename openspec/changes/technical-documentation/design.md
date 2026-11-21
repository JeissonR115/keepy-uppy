# Design

## Context

El repositorio ya mantiene una guía general en `docs/README.md`, referencias por módulo bajo `docs/modules/` y el contrato detallado del puente en `docs/cpu-ai-bridge.md`. El runtime está organizado en gestores, modelos, escenas y recursos (`src/managers/`, `src/models/`, `src/scenes/`, `src/resources/`); hay pruebas headless en `tests/`. El proyecto Python hermano contiene sus propias guías de generación de grafos y entorno (`../keepy-uppy-ai/docs/`). Ver `proposal.md` para la motivación y el alcance.

## Goals / Non-Goals

**Goals:**

- Crear una guía de arquitectura única en español, verificable contra archivos y pruebas existentes.
- Trazar cada explicación de componentes, parámetros, comandos y cobertura a sus rutas concretas.
- Ofrecer diagramas Mermaid para contexto, componentes, turno, estados de partida y simulación headless.
- Señalar límites de evidencia como pendientes de verificar y evitar presentar inferencias como hechos.

**Non-Goals:**

- Cambiar comportamiento, pruebas, dependencias, protocolo o configuración de ejecución.
- Copiar el detalle del protocolo o de los módulos ya documentados.
- Editar el proyecto hermano; documentarlo únicamente desde evidencia leíble.

## Decisions

1. **Usar `docs/technical/architecture.md` como índice narrativo principal.** Agrupará las doce áreas de aceptación y enlazará anexos solo si una tabla o el registro ADR requiere más espacio. Esto mantiene una ruta de lectura única; se descarta dispersar la guía en doce documentos independientes.
2. **Mantener las fuentes de detalle actuales.** La sección del puente describirá límites y flujo en pocas líneas y enlazará `docs/cpu-ai-bridge.md`; la sección de módulos remitirá a las páginas bajo `docs/modules/`. Esto evita que el contrato TCP y la documentación de clases diverjan por duplicación.
3. **Usar documentación de comportamiento solo como evidencia.** Las afirmaciones sobre turnos, física, estados y determinismo deben contrastarse con implementación y pruebas (`src/managers/match_manager.gd`, `src/models/balloon/balloon_controller.gd`, `src/models/player/`, `tests/`). Si solo una parte está cubierta, describir esa cobertura, sin convertirla en cobertura total.
4. **Documentar el sistema IA Python como integración independiente.** Usar `../keepy-uppy-ai/README.md`, `docs/graph-generation.md`, `docs/training-environment.md`, `pyproject.toml`, `src/keepy_ai/` y `tests/` como evidencia. Conservar explícitas las limitaciones confirmadas: no hay aristas `WALL_JUMP` en V1, `step()` tiene latencia de un tick y la recompensa vale `0.0` provisionalmente.
5. **Tratar tecnologías y ADR como decisiones documentadas con evidencia.** Para cada tecnología, indicar dónde aparece, su función observable y una alternativa razonable no adoptada; identificar esa alternativa como comparación documental y no como decisión histórica si no existe evidencia de que se evaluó en su momento.
6. **Registrar el alcance solo documental con `skip_specs: true`.** No se alteran requisitos de comportamiento, por lo que no corresponde inventar una capacidad de runtime para satisfacer el esquema de specs.

## Risks / Trade-offs

- [Rutas, comandos o valores pueden quedar obsoletos] → incluir referencias directas y revisar cada una contra el árbol actual antes de cerrar la documentación.
- [Los diagramas pueden sugerir un orden distinto al runtime real] → derivarlos de señales, callbacks y bucles encontrados en código; distinguir pasos síncronos de diferidos.
- [El proyecto hermano puede evolucionar por separado] → señalar sus rutas como referencia externa y evitar copiar contratos detallados que tienen fuente de verdad en el repositorio principal.
- [La lista de pruebas puede interpretarse como garantía de cobertura completa] → vincular pruebas por área e indicar explícitamente que los scripts existentes son la cobertura observada, no una medición exhaustiva.

## Migration Plan

No aplica migración de runtime. Añadir el documento y sus anexos, incorporar un enlace en `docs/README.md`, revisar enlaces/rutas/comandos/diagramas y verificar el cambio documental con `openspec validate` y `git diff --check`.
