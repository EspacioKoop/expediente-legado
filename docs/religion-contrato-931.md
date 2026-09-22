# Contrato transversal de religión · #931

Este corte convierte `ReligionEventos` en la fuente de verdad común para hechos religiosos y culturales observables. El objetivo no es asignar una identidad religiosa al protagonista, sino conservar qué ocurrió, cómo se supo y qué declaraciones explícitas existen.

## Canales

El registro persistido en `Partida` mantiene cuatro colecciones independientes:

- **exposición**: algo fue visto, leído, escuchado o experimentado;
- **práctica**: hubo participación en una práctica o actividad concreta;
- **convicción declarada**: solo existe cuando una declaración explícita la crea;
- **vínculo**: relación observable con una persona, comunidad o institución.

No hay conversión automática entre canales. Completar una ROM cultural sigue siendo exposición; participar en una actividad del mundo sigue siendo práctica; ninguna de las dos crea convicción.

## Evento común

Cada hecho conserva, como mínimo, `id`, `canal`, `fuente`, `procedencia`, `contexto`, `jornada`, `vuelta`, etiquetas y metadatos de conocimiento público cuando sean aplicables. `tradicion` es metadato documental, no una clase de personaje.

La procedencia distingue, por ejemplo, un handshake de ROM de una interacción física. El id es único entre todos los canales, de modo que el mismo hecho no puede reaparecer accidentalmente como exposición y convicción.

## Convicción sin barra de fe

El canal de convicción admite declaraciones explícitas de:

- afirmación;
- duda;
- no adscripción;
- cambio.

`ultima_declaracion()` ofrece una vista derivada para consumidores que necesiten el estado declarado más reciente, pero no destruye el historial ni crea un `religion=X` global. No existe puntuación de fe o religiosidad.

## Vínculos y conocimiento

Los vínculos pueden declarar un `actor` observable. `vinculos_por_actor()` agrupa solo los hechos realmente asociados a ese actor; no crea reputación religiosa global ni copia automáticamente información a otros NPC.

## Persistencia y reset

| Operación | Exposición | Práctica | Convicción declarada | Vínculo |
| --- | --- | --- | --- | --- |
| Cambio de escena/fase | conserva | conserva | conserva | conserva |
| Nueva jornada | conserva | conserva | conserva | conserva |
| Reasignación/nueva vuelta | conserva | conserva | conserva | conserva |
| Guardar/cargar Partida | persiste | persiste | persiste | persiste |
| Nueva partida | reinicia | reinicia | reinicia | reinicia |

La razón es que los cuatro canales son hechos históricos de una partida. La jornada y la vuelta quedan dentro de cada evento para que un consumidor pueda filtrar contexto sin borrar el pasado.

Las partidas anteriores a #931 migran de forma aditiva: al no contener la clave `religion`, `Partida.nueva()` aporta un registro vacío durante la fusión.

## Verticales

- Las ROMs JALI 98, VITRAL 98 y SARNATH 98 dejan de depender de un registro efímero del controller y escriben en `partida.estado`.
- El vertical de mundo de #934 conserva su API standalone, pero etiqueta jornada, vuelta y procedencia en el mismo contrato; puede recibir directamente el registro de `Partida`.
- Conflicto (#936) continúa consumiendo únicamente práctica/convicción cuando una regla contextual lo exige. Exposición y vínculo no se convierten en compromisos.

## Regresión

`pruebas_religion_contrato_931.gd` cubre separación de canales, duda/no adscripción/cambio, vínculos por actor, persistencia real en disco, conservación tras reasignación, reset de nueva partida y rechazo de duplicados o conversiones implícitas. `scripts/test_religion_contrato_931.py` fija además el wiring de Partida y ROMs.
