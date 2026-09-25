# Playtest humano de comprensión y ritmo (#395)

Este protocolo cubre el último gate que no puede resolver CI ni una captura: comprobar con **una persona nueva** que entrada/oficina, oficina → trayecto y casa → sueño se entienden sin contexto del código y que ritmo, continuidad y sincronía audiovisual no introducen un problema reproducible.

La evidencia técnica previa está en `docs/validacion-cinematica-395.md`. Este pase no vuelve a validar implementación, export o equivalencia de estado: observa comprensión y ritmo desde el punto de vista de un jugador nuevo.

## Regla principal: no cebar respuestas

Antes de jugar, no explicar qué debe entender la persona ni mencionar las respuestas esperadas. Solo indicar controles básicos si los necesita para avanzar. Las preguntas se hacen **después** de cada secuencia, antes de explicar nada sobre ella.

Se recomienda usar un alias o identificador anónimo para el participante y no registrar datos personales innecesarios.

## Build

Usar una export real que contenga los cambios ya integrados de #395. Registrar el `build_sha` de `BUILD-INFO.txt` y la plataforma usada. Si se usa un save como atajo para casa → sueño, anotar el atajo y no modificar ejecutable/PCK ni el estado durante la reproducción de la secuencia.

## Pase A · entrada / oficina

1. Arrancar con **Nueva partida**.
2. No pulsar skip deliberadamente durante la secuencia.
3. Al recuperar control, preguntar sin pistas:
   - «¿Dónde crees que estás?»
   - «¿Quién eres o qué papel tienes aquí?»
   - «¿Qué crees que se espera que hagas ahora?»
4. Registrar las respuestas literalmente.
5. Solo después, el facilitador marca si cada una de las tres ideas esenciales quedó comprendida.

No exigir que el jugador repita nombres internos (`auditor01`, SIGA-98, A-7) palabra por palabra. El criterio es comprensión funcional: **archivo/oficina**, **rol de auditor/trabajador que revisa expedientes** y **expectativa de empezar a revisar/investigar el trabajo asignado**.

## Pase B · oficina → trayecto

1. Completar la jornada hasta abandonar la oficina por ascensor, sin saltar la secuencia.
2. Al recuperar control en trayecto, preguntar sin pistas:
   - «¿De dónde vienes y a dónde crees que te está llevando esta transición?»
3. Registrar la respuesta literalmente.
4. El facilitador marca si se comprendió la continuidad **archivo/oficina → ascensor/salida → trayecto/calle**.
5. Registrar además si cierre, bajada y apertura del ascensor se perciben sincronizados con sus acentos físicos. Este check no exige reconocer sonidos concretos: solo detectar desfase o contradicción entre acción visible y audio.

## Pase C · casa → sueño

1. Llegar a casa por el recorrido normal o mediante un save de QA documentado.
2. Interactuar con la cama y observar la transición completa.
3. Al entrar en sueño, preguntar sin pistas:
   - «¿Qué acción acaba de provocar este cambio de espacio?»
4. Registrar la respuesta literalmente.
5. El facilitador marca si la relación **cama/dormir → sueño** quedó comprendida.

## Ritmo

Después de cada secuencia preguntar:

> «¿Se sintió bien de ritmo, demasiado rápida, demasiado larga o confusa?»

Registrar la opción y cualquier comentario literal. No convertir automáticamente una preferencia aislada en bug. Si aparece un problema claro, intentar reproducirlo en una segunda pasada o con otra persona y anotar qué momento concreto falla.

## Criterio de salida para #395

El gate queda listo para valorar cierre cuando:

- la persona no conocía previamente el proyecto ni las respuestas esperadas;
- entiende las tres ideas esenciales de entrada/oficina sin ayuda;
- entiende la continuidad oficina → trayecto sin depender de un rótulo explicativo;
- entiende que dormir en la cama provoca la transición al sueño;
- no queda documentado un problema reproducible de ritmo, encuadre, continuidad, confusión o sincronía audiovisual que requiera otro cambio.

Una opinión estética («yo lo haría más corto/largo») no equivale por sí sola a un fallo reproducible. Sí lo es, por ejemplo, que el texto no pueda leerse a tiempo, que se confunda el lugar, que se pierda la relación cama→sueño o que la secuencia parezca haberse roto.

## Registro asistido

Puede generarse un informe Markdown homogéneo con:

```bash
python3 scripts/registrar_playtest_395.py
```

El script guarda respuestas literales, checks del facilitador, build/plataforma y un resumen del gate. No analiza semánticamente las respuestas ni sustituye el juicio humano.

## Qué adjuntar al issue

Para cerrar el gate basta con enlazar un registro que contenga:

- build SHA y plataforma;
- confirmación de que el tester era nuevo;
- respuestas literales a las cinco preguntas de comprensión;
- valoración de ritmo de las tres secuencias;
- valoración de sincronía audiovisual de oficina → trayecto;
- checks del facilitador;
- cualquier incidencia reproducible y sus pasos.

No hace falta otra reimplementación si el pase cumple estos puntos.

Refs #177 #395 #410 #428 #590 #646 #856 #858 #1073 #1074 #1293

— Odiseo (GPT-5.6 Sol)
