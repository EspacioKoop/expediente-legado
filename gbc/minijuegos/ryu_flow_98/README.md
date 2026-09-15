# RYU_FLOW

Micro-ROM propia para la **Portátil Color 98**, vinculada al vertical Ryū de #440.
Su id canónico en el catálogo del proyecto es `ryu_flow_98`. Se mantiene como
código fuente RGBDS y el `.gbc` se genera en build/CI; no se versiona ninguna
ROM binaria.

## Bucle jugable

`RYU_FLOW` es un micro-puzzle de cauce deliberadamente pequeño:

- izquierda/derecha selecciona una de tres compuertas;
- `A` alterna su desvío arriba/abajo;
- la guía inferior muestra la continuidad esperada del cauce;
- el cartucho arranca con las tres compuertas incorrectas (`101`);
- la solución es determinista (`010`) y **las tres compuertas deben haber sido
  manipuladas** antes de aceptar el final;
- al completar el cauce, el ryū aparece siguiendo el flujo resuelto.

No hay RNG, puntuación, economía, pistas ni recompensa del juego principal.
Arrancar la ROM y cerrarla inmediatamente no constituye una interacción válida.

## Contrato de finalización para #442

Al completar de verdad el puzzle se escribe `0xA5` en la dirección WRAM fija
`$C100` (`wRyuFlowCompletado`). Al iniciar o reiniciar una partida el byte vuelve
a `0x00`.

Este byte es **solo un punto de integración futuro**: este corte no modifica
Godot para registrar `semilla_onirica_ryu` ni conecta #440 al selector nocturno.
La futura integración de #442 debe observar la finalización del micro-objetivo,
no el mero arranque de la ROM.

## Build

Requiere RGBDS (misma versión fijada por `.github/workflows/gbc-fixtures.yml`):

```bash
make -C gbc/minijuegos/ryu_flow_98 clean test
```

Salida local: `gbc/minijuegos/ryu_flow_98/build/ryu_flow_98.gbc` (efímera).

La cabecera usa flag CGB `0x80` para conservar compatibilidad dual-mode y el
catálogo actual de la Portátil Color 98.

## Arte y licencia

Tiles, tipografía bitmap y silueta del ryū son originales y están definidos en
`main.asm`. No hay assets ni código de terceros. Se distribuyen bajo la licencia
vigente del repositorio.

La referencia visual del cartucho está en `docs/visuales/ryu-flow/` y no se
copia dentro de la ROM.

Refs #440 #442 #124 #181.
