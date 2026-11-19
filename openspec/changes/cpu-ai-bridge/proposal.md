# Proposal

## Why

El bot actual produce intenciones dentro de `CPUController`, lo que impide conectar un agente Python y probarlo de forma reproducible contra la física y las reglas reales del juego. Hace falta un límite intercambiable entre cerebro y movimiento, junto con un entorno headless y una representación de navegación por nivel, antes de desarrollar o entrenar la IA externa.

## What Changes

- Definir el contrato de intenciones `CPUBrain` y separar la implementación local de respaldo (`LocalBrain`) de la remota (`RemoteBrain`).
- Añadir un puente local Godot–Python con protocolo JSON de observación, acción y control, timeout y fallback seguro al cerebro local.
- Proporcionar una ejecución de simulación headless, acelerable, reiniciable por semilla y nivel, con episodios y resultados observables.
- Exportar geometría y constantes de movimiento por arena, permitir sondeos de movimiento real y cargar/graficar en Godot un `NavGraph` por nivel.
- Documentar el protocolo y los formatos de geometría/grafo en `docs/`.
- Mantener intactos el control jugador contra jugador y las reglas competitivas existentes.

## Capabilities

### New Capabilities
- `cpu-ai-bridge`: Interfaz de cerebro, comunicación remota, simulación reproducible y navegación basada en geometría de arena.

### Modified Capabilities

## Impact

- Código afectado: `src/models/player/` (controlador, cerebros y navegación), `src/managers/` y escenas de nivel/arena para simulación y señales de episodio.
- Pruebas: ampliar las pruebas headless de CPU, movimiento, partida y arena; añadir cobertura del protocolo, reinicio y carga de grafos.
- Documentación: añadir el contrato JSON a `docs/`.
- Integración: cliente Python externo mediante socket local; sin dependencias externas en Godot y sin incluir entrenamiento ni un modelo de IA en este cambio.
