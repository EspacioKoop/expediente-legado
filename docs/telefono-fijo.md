# Teléfono fijo doméstico (#671)

## Propósito

El teléfono es una superficie opcional de vida doméstica en 1998. No crea una agenda, reputación social, misión paralela ni reloj real. Todo su estado vive dentro de `Jornada.telefono_fijo` y se guarda con la partida normal.

## Flujo

Al entrar en fase `casa`, `TelefonoFijo.preparar_casa()` evalúa un catálogo declarativo. Como máximo queda una llamada entrante activa. El piloto ámbar del aparato y un efecto corto anuncian la llamada; el contenido hablado siempre existe también como transcript textual.

El jugador puede:

- descolgar y atender la llamada;
- dejarla explícitamente al contestador;
- ignorarla por completo: al abandonar `casa`, el controller la deriva al contestador antes de guardar;
- escuchar el siguiente mensaje nuevo;
- descolgar sin llamada entrante para obtener línea y llamar solo a contactos declarados;
- colgar el auricular.

No hay temporizador de segundos. Una llamada ignorada no bloquea el ciclo y su contenido queda en la cinta.

## Estado persistente

`jornada.telefono_fijo` conserva únicamente:

- `procesadas`: IDs de llamadas entrantes ya resueltas;
- `mensajes`: cinta del contestador, con día, hora narrativa, remitente, texto y flag `escuchado`;
- `historial`: eventos mínimos de llamadas atendidas, contestador y salientes;
- `llamada_activa`: ID pendiente durante la visita a casa;
- `dia_preparado`: evita duplicar llamadas al reconstruir la escena;
- `descolgado`: estado físico del auricular.

Las horas (`18:42`, `20:11`, etc.) son metadatos narrativos fijos. No se consulta la hora del sistema ni se programa contenido contra reloj real.

## Catálogo inicial

El primer corte incluye seis llamadas entrantes con condiciones diferentes:

1. compañero del archivo, día 1;
2. número equivocado por calendario periódico;
3. recordatorio de administración ligado al vencimiento de alquiler ya existente;
4. llamada comercial periódica;
5. compañera del archivo condicionada a haber cerrado al menos un expediente;
6. prueba de centralita condicionada a calendario y dos cierres.

Además hay tres números salientes ficticios y explícitamente permitidos: centralita SIGA, Ultramarinos La Esquina y Videoclub Mirador. Cualquier ID no declarado se rechaza.

## Presentación y accesibilidad

`TelefonoFijoInteractivo3D` construye carcasa, auricular, teclado y dos pilotos con primitivas del motor. Es `Interactuable3D`, por lo que usa la acción semántica común en vez de teclas hardcodeadas.

`TelefonoFijoPanel` es una ventana modal transitoria con transcript, botones enfocables, `cancelar`/`ui_cancel` y fallback A/B de mando. El contenido narrativo no depende del audio.

## Límites del corte

- No se revelan hechos de expedientes ni se generan pistas.
- No hay llamadas entrantes de duración real ni castigo por no contestar.
- No se añade economía: el recordatorio del alquiler solo observa el estado ya gestionado por `Jornada`.
- Los contactos salientes son ficticios y cerrados; no existe marcado libre.
- El modelo 3D es procedural/provisional y puede sustituirse por asset definitivo sin cambiar el contrato.
- La validación humana final de colocación, legibilidad, volumen y navegación con teclado/mando sigue correspondiendo al gate de playtest.

Refs #671 #669 #133 #400 #125 #98 #181.

— Odiseo (GPT-5.6 Sol)
