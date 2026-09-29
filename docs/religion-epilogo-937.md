# Religión: epílogo factual por vida (#937)

ReligionTrayectoria consume exclusivamente las instantáneas archivadas por
ReligionEventos al cerrar una vida laboral. No mantiene un segundo registro y
no reinterpreta exposición, práctica, declaración o vínculo como una identidad
global del personaje.

## Contrato

El final base ya viene resuelto por su sistema dueño. La capa religiosa **no
bloquea** ni sustituye ese final base: adjunta como máximo tres módulos
descriptivos:

1. **declaraciones**: hechos del canal de convicción declarada;
2. **prácticas y exposiciones**: conserva ambos canales como hechos distintos
   dentro del mismo módulo;
3. **vínculos**: hechos asociados a personas, comunidades o instituciones cuando
   el evento registró un actor.

Cada módulo contiene los hechos originales reducidos del snapshot y marca
requiere_citar_hechos = true. Cualquier presentación posterior debe citar esos
hechos y su procedencia antes de redactar una síntesis narrativa.

## Ausencia, duda y contradicción

sin declaración significa exactamente que no hay hechos en el canal de
convicción. No se convierte en no adscripción, ateísmo ni otra etiqueta.

Duda, no adscripción, afirmación y cambio solo aparecen cuando fueron
declaraciones explícitas registradas por ReligionEventos. Si existen
declaraciones contradictorias o un cambio posterior, se conservan como hechos
separados y ordenados por jornada/id; no se escoge una como ganadora.

## Límites

Este corte no añade puntuaciones, ranking, recompensas, logros ni contenido de
tradiciones. Tampoco decide qué final principal ocurre. Su única salida es una
capa descriptiva reproducible que permite a una UI o escena de cierre mencionar
personas, lugares, fuentes y acciones que realmente sucedieron durante esa vida.


## Presentación integrada en el cierre

`FinalPolitico.resumen()` consume la misma fotografía factual de la vida actual
mediante `ReligionEventos.resumen_trayectoria()` y entrega el resultado al panel
de cierre. El panel muestra hasta cuatro hechos concretos antes de cualquier
lectura global: canal, contexto y fuente/actor o declaración explícita. Si hay
más, solo indica cuántos quedan archivados; no escoge una identidad dominante.

Confirmar el cierre sella la trayectoria con motivo `final_narrativo` usando
`ReligionEventos.archivar_trayectoria()`. La operación es idempotente por
`vuelta`, por lo que recargar o confirmar de nuevo no duplica el historial.

La presentación no escribe eventos, no cambia el final político, no concede
logros religiosos y no convierte exposición o práctica en convicción.
