# Playtest humano de oficina / archivo (#126)

Este protocolo cubre el último gate de #126 que no puede resolver CI ni una captura: comprobar con **una persona nueva** que la planta 4 se reconoce como una oficina/archivo habitado y funcional y que su recorrido no se siente como una sala técnica o una escena bloqueada.

La evidencia estática reproducible ya la genera #995. Este pase evalúa únicamente lectura espacial y recorrido desde el punto de vista de un jugador.

## Regla principal: no explicar el resultado esperado

Antes de jugar, no decir «esto es un archivo», no enumerar las zonas y no señalar la salida. Solo explicar controles básicos si hacen falta.

Usar un alias anónimo para el participante y no registrar datos personales innecesarios.

## Build

Usar una export real del mismo commit que la evidencia visual revisada. No reutilizar
capturas antiguas de #995 después de cambios de presentación: desde aquel gate entraron,
entre otros, Forward+ con sombras/SSAO/SSIL (#1121) y el lote administrativo Styloo
materializado (#1216).

Antes del pase:

1. ejecutar o descargar el artifact `SIGA-98-oficina-visual-gate-126-<sha>`;
2. revisar sus dos PNG y su `README.md`;
3. confirmar que el `commit SHA` del artifact coincide con `BUILD-INFO.txt` de la build;
4. confirmar en el manifest si Styloo está activo y qué renderer se usó.

Registrar:

- `build_sha` de `BUILD-INFO.txt`;
- SHA del artifact visual revisado;
- plataforma;
- si el participante conocía previamente el proyecto.

Un participante que ya conozca el layout puede aportar feedback, pero no sirve como gate de reconocimiento espontáneo.

## Pase

1. Entrar en la planta 4 con HUD/rótulos ignorados para la evaluación.
2. Dejar al participante observar y recorrer libremente durante al menos un minuto.
3. Pedirle que llegue, sin señalar rutas:
   - a un puesto de trabajo;
   - a la zona de archivo/almacenamiento;
   - a la zona de café/pausa;
   - a la salida.
4. Tras el recorrido, preguntar sin pistas:
   - «¿Qué tipo de lugar dirías que es?»
   - «¿Qué zonas o funciones distintas has reconocido?»
   - «¿Hubo algún momento en que no supieras por dónde pasar o qué era una puerta/salida?»
   - «¿Algo te hizo pensar que era una sala técnica, una demo o un escenario sin uso real?»
5. Registrar las respuestas literalmente antes de comentarlas.

## Checks del facilitador

Después de guardar las respuestas, marcar únicamente observaciones comprobables:

- reconoce espontáneamente **oficina/archivo** o una descripción funcional equivalente;
- distingue al menos trabajo + archivo/almacenamiento + pausa;
- encuentra la salida sin ayuda;
- puede recorrer puestos ↔ archivo ↔ café ↔ salida sin atasco o bloqueo relevante;
- no describe el conjunto como sala técnica/demo/greybox por un defecto reproducible.

No exigir vocabulario interno como «zona de clasificación», «planta 4» o nombres de assets.

## Criterio de salida para #126

El gate queda listo para valorar cierre cuando:

- el artifact visual revisado y la build del playtest corresponden al mismo SHA;
- el participante no conocía previamente el layout;
- reconoce el lugar como oficina/archivo funcional sin depender de HUD;
- identifica varias zonas con función;
- encuentra la salida y completa el recorrido sin ayuda;
- no queda una incidencia reproducible de navegación/lectura espacial;
- no reaparece la lectura de «sala técnica», «demo» o «greybox» por un defecto concreto.

Una preferencia estética aislada no bloquea el cierre. Sí lo bloquea, por ejemplo, una puerta que no se reconoce, un pasillo impracticable, mobiliario que fuerza rodeos absurdos o una composición que sigue pareciendo un laboratorio de pruebas.

## Registro asistido

```bash
python3 scripts/registrar_playtest_126.py
```

El script conserva respuestas literales y resume solo los checks introducidos por el facilitador. No interpreta semánticamente las respuestas ni sustituye el juicio humano.

## Qué adjuntar al issue

- build SHA, SHA del artifact visual y plataforma;
- manifest del gate visual del mismo commit;
- alias del participante;
- confirmación de conocimiento previo;
- cuatro respuestas literales;
- checks del facilitador;
- incidencia reproducible, si existe;
- observaciones opcionales.

Refs #126 #398 #400 #994 #995.

— Odiseo (GPT-5.6 Sol)
