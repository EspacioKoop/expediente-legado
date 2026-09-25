# Playtest humano del sueño · #299

Este pase convierte el último gate abierto de #299/#281 en una comprobación humana
reproducible. No sustituye CI: mide si una persona nueva entiende el progreso
0/2 → 1/2 → 2/2 y completa la primera noche sin conocer la implementación.

## Preparación

1. Usar una build identificable por SHA y anotar plataforma.
2. Empezar desde una partida donde pueda alcanzarse una noche limpia.
3. El participante no debe conocer el layout ni qué acciones cuentan.
4. No explicar objetivos, símbolos, gato, anomalías ni rutas antes del pase.
5. Mantener HUD, accesibilidad y controles normales de la build.
6. Cronometrar desde que el jugador obtiene control dentro del sueño.

Registrar el pase con:

```bash
python3 scripts/registrar_playtest_299.py \
  --salida docs/playtests/playtest-299.md
```

## Gate

El pase queda listo para valorar cierre de #299 si se cumplen todos estos puntos:

- el participante identifica una primera acción válida en menos de 60 s sin ayuda;
- el estado inicial 0/2 se percibe como progreso pendiente, no como decoración;
- al completar el primer objetivo se percibe un cambio claro a 1/2;
- el gato/referencia ambiental orienta hacia contenido pendiente sin señalar una salida física;
- reentrar o repetir el primer objetivo no incrementa de nuevo el progreso;
- un segundo objetivo válido provoca 2/2 y transición automática;
- la transición ocurre una sola vez y no deja softlock;
- si aparece una ruta opcional fallable, abandonarla no bloquea mientras queden dos objetivos válidos;
- el temporizador, si interviene, se entiende como salida alternativa y no como ruta normal;
- tras guardar/cerrar/reabrir, el estado posterior al sueño permanece coherente.

## Observación

El facilitador debe registrar lo que hace el participante y lo que verbaliza, sin
interpretar por él qué "debería haber entendido". Si falla el gate, anotar el
primer punto observable de confusión: qué vio, qué intentó, qué esperaba y qué
ocurrió.

No cerrar #299 sólo porque CI/export sea verde. El criterio pendiente es humano.

Refs #9 #281 #299 #301 #308 #313 #467 #629 #981 #1208.

— Odiseo (GPT-5.6 Sol)
