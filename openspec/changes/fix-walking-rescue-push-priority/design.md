# Design

## Context

`MatchManager._on_player_bumped` descarta el empuje normal de Player 2 y selecciona fuerza de empuje con `priority_player`; las colisiones se reportan desde ambos controladores al pasar por colisiones de movimiento. `expected_balloon_player` ya representa el turno para rescatar. Ver `proposal.md` y el delta de `balloon-interaction` para el comportamiento esperado.

## Goals / Non-Goals

**Goals:**
- Procesar empujes al caminar y al hacer dash desde cualquiera de los dos jugadores.
- Escoger la fuerza comparando al jugador que inicia el empujón con `expected_balloon_player`.
- Evitar aplicar el efecto más de una vez por pareja de jugadores en el mismo tick.

**Non-Goals:**
- Cambiar la regla que registra los toques al globo ni su prioridad de resolución.
- Cambiar velocidades o temporizadores del dash.
- Dar al jugador que recibe el empujón la fuerza del jugador que lo inicia.

## Decisions

- Eliminar los filtros asimétricos por número de jugador para las colisiones normales, preservando únicamente las excepciones específicas del modo CPU que sean necesarias para su comportamiento. Esto corrige que Player 2 nunca active empujes al caminar.
- Elegir la fuerza según `player == expected_balloon_player`, tanto si `while_dashing` es verdadero como falso. Mantener valores configurables por separado para empuje normal/ventaja y dash normal/ventaja. `priority_player` seguirá gobernando solamente la resolución de disputas de contacto.
- Deduplicar por pareja de participantes durante el frame/tick de física, de forma que dos señales de la misma colisión no acumulen empuje. Liberar esa deduplicación al cambiar el tick para permitir colisiones nuevas.
- Conservar dirección de empuje y tope de velocidad actuales para reducir el cambio al origen de la selección de fuerza y a la simetría de entrada.

## Risks / Trade-offs

- [Eliminar filtros puede cambiar el comportamiento del oponente CPU] → Preservar y revisar condicionales que limiten empujes de CPU, verificando los dos lados del modo humano contra CPU.
- [Deduplicar durante el tick podría ignorar una segunda colisión intencional en el mismo instante] → Deduplicar solo la misma pareja en el mismo tick y comprobar que el siguiente tick permite un nuevo empuje.
- [La ventaja puede resultar muy fuerte también al caminar] → Reutilizar los parámetros exportados actuales para que la fuerza pueda balancearse sin alterar la regla de asignación.

## Migration Plan

Sin migración de datos. La reversión consiste en restaurar los filtros previos y la selección de fuerza, manteniendo los parámetros de balance ya existentes.
