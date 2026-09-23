# Literatura · diálogos, autores y movimientos (#1180)

Este corte añade el primer productor conversacional del contrato de #1176 sin
crear una identidad cultural paralela.

## Contrato

El catálogo `godot/datos/literatura_dialogos.json` describe el NPC mediador,
la obra, el movimiento literario como contexto y las ramas de conversación.
Elegir una rama registra únicamente un evento en el canal `insight`, con:

- fuente concreta del NPC;
- jornada;
- obra;
- diálogo y rama observados;
- movimiento usado como contexto;
- consecuencia visible declarada por la rama.

Las dos ramas del prototipo convergen en `apariencia_y_eleccion`. El id del
evento depende del diálogo y del insight, no de la rama: volver a hablar o
probar la otra formulación no duplica el hecho.

## Primer diálogo

La mediadora de biblioteca comenta *La vida es sueño*. El jugador puede
enfocar la conversación desde la elección bajo incertidumbre o desde la
representación. Las respuestas son distintas y cada rama declara una
consecuencia visible en la ficha de lectura, pero ninguna respuesta se traduce
en afiliación, reputación, ideología, arquetipo ni atributo de personalidad.

## Consumidores

El mismo evento alimenta dos consumidores separados:

1. `LiteraturaDialogoReentrada` produce una variante para una conversación
   posterior con el NPC.
2. `LiteraturaMovimientoContexto` expone contexto del movimiento para una
   superficie externa, conservando la procedencia del insight.

Ambos consultan hechos registrados; ninguno mantiene una barra cultural.

## Cobertura

`godot/pruebas/pruebas_literatura_dialogo_1180.gd` comprueba dos ramas,
consecuencia visible, procedencia, idempotencia, dos consumidores del mismo
insight y ausencia de conversión de exposición en identidad.

`scripts/test_literatura_dialogo_1180.py` entra en el descubrimiento normal de
tests Python y ejecuta además la prueba headless de Godot.

## Siguiente corte

El contrato ya es ejecutable, pero este PR no monta todavía una UI de elección
en `Dia`: el diálogo diegético actual muestra una línea resuelta y no ofrece
botones de rama. El siguiente paso debe adaptar una superficie de elección
reutilizable al NPC físico sin duplicar `DialogoDiegetico`, y hacer visible en
el recorrido real la consecuencia declarada aquí.

Refs #1175 #1176 #1180.
