# Tasks

## 1. Redacción de la guía arquitectónica

- [ ] 1.1 Inspeccionar clases, escenas y recursos de jugador, globo, partida, niveles, UI y CPU; redactar las secciones de visión, arquitectura, módulos, física y estados en `docs/technical/architecture.md`, enlazando rutas existentes y comprobando cada valor contra código o pruebas.
- [ ] 1.2 Contrastar el puente con `docs/cpu-ai-bridge.md` y resumirlo sin duplicar su contrato; verificar que la guía enlace la fuente de verdad y cubra geometría, sondeos, esquema de grafo y determinismo.
- [ ] 1.3 Leer el código, documentación, configuración y pruebas de `../keepy-uppy-ai` sin escribir allí; documentar arquitectura, generación de grafos, entorno, comandos y límites V1, marcando como pendiente cualquier afirmación no confirmada.
- [ ] 1.4 Documentar tecnologías, alternativas, decisiones tipo ADR, estrategia y listado de pruebas, requisitos, instalación, controles, modos, comandos de ejecución y deuda técnica; comprobar nombres/rutas/comandos contra el árbol y configuración existentes.
- [ ] 1.5 Añadir diagramas Mermaid de contexto, componentes, flujo de turno, estados de partida y ciclo headless; verificar que cada nodo y transición corresponda a escenas, señales y código existente.

## 2. Integración y revisión documental

- [ ] 2.1 Añadir en `docs/README.md` un enlace a `docs/technical/architecture.md` y comprobar que el destino existe y las referencias a módulos y puente no duplican su contenido.
- [ ] 2.2 Revisar todos los enlaces, nombres de clases, comandos, parámetros, cifras y afirmaciones frente al código, configuración y pruebas; ejecutar los comandos de validación documental `openspec validate technical-documentation` y `git diff --check` y corregir cualquier error.
