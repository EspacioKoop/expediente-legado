# SIGA-98 · Alpha P0 + novedades · 2026-09-15

Esta build es el siguiente corte de playtesting humano después de la alpha post-playtest del 13 de septiembre (#394). Su objetivo principal es comprobar si el saneamiento P0 ya integrado convierte el recorrido completo en una experiencia legible y controlable, y de paso probar varias novedades recientes sin convertirlas en requisitos del recorrido.

**Baseline de gameplay:** `main` en `0b828dd7a3d0061801b90f8cf94119d8e5277580` (tras #510).

El SHA exacto del paquete se incluye además en `BUILD-INFO.txt` dentro de cada ZIP. Esta alpha no es una release comercial, no publica automáticamente en itch.io y no cierra por sí sola ningún gate que requiera validación humana.

## Qué mejora respecto a la alpha anterior

### Control, HUD y lectura del recorrido

- Cámara y locomoción 3D revisadas: ratón y stick derecho, sensibilidad e inversión Y persistentes, deadzone, aceleración/frenado y captura de cursor (#405 / #396).
- HUD y diálogo comparten una jerarquía única; fuera del archivo se ha reducido el HUD permanente (#406 / #453).
- Los prompts muestran el último dispositivo usado y la fase enseña una tarjeta breve al entrar en archivo, trayecto, casa o sueño (#498).
- La entrada y la transición casa → sueño usan ya secuencias 3D sobre espacios reales (#410 / #428).

### Espacios, materiales y personajes

- Oficina con materiales administrativos más reconocibles y un lote CC0 de escritorios, archivadores, monitores, teléfonos, sillas, teclados y lámparas (#412 / #499).
- Casa con composición doméstica más clara, materiales propios, cama/cuenco reconocibles y almacenamiento físico conectado al inventario (#420 / #427 / #465 / #510).
- Trayecto con cielo, profundidad urbana, fachadas materializadas y nuevo mobiliario vial CC0 sin bloquear el corredor jugable (#429 / #449 / #507).
- El escaparate de seis televisores muestra medias lunas estáticas ligeras en lugar de exigir seis streams de vídeo (#505).
- Los compañeros tienen perfiles faciales deterministas adicionales y movimiento ambiental mínimo; sigue siendo un gate visual humano, no una afirmación de acabado final (#445 / #502 / #275 / #134).

### SIGA e investigación

- El asistente-gato de SIGA recibe contexto real del visor: exploración, descubrimiento, combinaciones fallidas/repetidas, expediente listo y expediente cerrado, sin resolver el caso por el jugador (#508).
- El Bingo SIGA mantiene una tarjeta diaria determinista, decisión explícita y snapshot al cerrar jornada; sigue sin recompensas sistémicas ni bloqueo del juego principal (#151 / #488).
- Continúan disponibles relaciones manuales, marcadores, metadatos, anexos, archivado 3D y contexto de careo de la alpha anterior.

### Vida cotidiana e inventario

- Objetos recogibles 3D pueden entrar en el inventario sin límite artificial de capacidad (#97 / #485).
- La cómoda de casa permite guardar, sacar y consultar contenido usando el contrato de inventario; cerrada bloquea esas operaciones (#510).
- Los trabajillos nocturnos quedan reflejados en el resumen de vida, sin convertirlos en premio/castigo moral ni alterar por sí solos la clasificación final (#94 / #506).
- Existe una ruta jugable de escaleras desde la planta 4 como alternativa al ascensor; el fichaje/guardado ocurre antes de elegir ruta (#135 / #490).

### Portátil y extras opcionales

- La Portátil Color 98 tiene sonidos físicos procedurales de cartucho, encendido y botones, desactivables de forma independiente (#245 / #483).
- SameBoy/Core ya se compila dentro de la GDExtension como preparación técnica, pero **el runtime activo sigue siendo Peanut-GB** y no se anuncia compatibilidad CGB completa todavía (#456 / #500).
- La tienda de videojuegos tiene un primer contrato de compra de ROMs propias durante `trayecto`, sin descargar ni distribuir ROMs comerciales (#93 / #494).
- Se han añadido contratos y verticales standalone de sueños/anomalías (Aquiles, Duat, catálogo de anomalías, grabación onírica). Son material de prueba aislada o futura integración; no deben confundirse con contenido garantizado en el recorrido nocturno principal (#438 / #441 / #149 / #454).

## Recorrido principal recomendado

1. Empezar con **Nueva partida** y comprobar si se entiende el archivo, el puesto 4-B y la primera acción sin consola ni contexto previo.
2. Probar cámara con ratón; si hay mando, repetir con stick derecho. Cambiar de dispositivo y comprobar que el prompt se actualiza sin duplicarse.
3. Abrir SIGA, investigar varios folios, usar relaciones/marcadores/metadatos/anexos y observar si el gato reacciona al contexto sin dar la solución.
4. Completar firma/careo y comprobar que el contexto descubierto llega a la conversación de forma comprensible.
5. Salir del archivo y probar **Ascensor** y, en otra pasada, **Escaleras**. Confirmar que ambas rutas llegan al mismo `trayecto` sin duplicar fichaje ni nómina.
6. Recorrer la calle sin HUD como referencia visual: cielo, fondo urbano, fachadas, mobiliario vial y escaparate deben leerse como exterior.
7. En casa, probar objetos interactivos, recoger algún objeto y usar la cómoda abierta/cerrada para guardar/sacar contenido.
8. Dormir y completar la primera noche por objetivos. Comprobar que casa → sueño se entiende y que terminar/saltar la transición lleva al mismo estado.
9. Despertar, avanzar alquiler/impago cuando corresponda, cerrar el juego y usar **Continuar** desde varios puntos para validar persistencia real.
10. Usar **Parte de incidencias** ante cualquier bloqueo o regresión, incluyendo el SHA de `BUILD-INFO.txt`.

## Pruebas focales de las novedades

Estas comprobaciones son útiles, pero un fallo del recorrido principal tiene prioridad:

- **Prompts/fase (#498):** alternar teclado↔mando y entrar/salir de las cuatro fases; no debe quedar una tarjeta o prompt permanente encima de diálogo/modal.
- **Oficina CC0 / rostros (#499/#502):** mirar desde frente, 3/4 y perfil; detectar escala incoherente, materiales rotos, UV extrañas o caras superpuestas.
- **Calle (#505/#507):** verificar que conos/barrera/tapas no bloquean el corredor y que las medias lunas no introducen tirones visibles.
- **Bingo SIGA (#151):** aceptar/descartar/ignorar, recargar el mismo día y comprobar que la tarjeta no cambia ni concede recompensas.
- **Inventario/cómoda (#97):** recoger → guardar → cerrar → intentar sacar → abrir → sacar, sin duplicados ni pérdida de objetos.
- **Escaleras (#135):** comparar resultado lógico con ascensor y comprobar que cerrar durante la transición no duplica estado al continuar.
- **Portátil (#245/#456):** sonidos físicos on/off; Caza Píxeles 98 debe seguir funcionando. No reportar CGB-only como regresión del runtime actual: aún no está activado SameBoy como núcleo de ejecución.

## Gates humanos que esta alpha debe resolver

- #271 — Nueva partida / Continuar y persistencia real tras cerrar/reabrir.
- #272 — onboarding comprensible sin conocimiento del proyecto.
- #273 / #396 / #113 — tacto de movimiento, cámara, foco, remapeo y mando físico.
- #397 / #276 — HUD, prompts y conversación sin solapes durante el recorrido real.
- #398 / #399 — oficina, calle, casa y sueño reconocibles sin depender del HUD.
- #275 / #134 / #282 / #400 — rostros, presencia de personajes, densidad y reactividad desde cámara jugable.
- #395 / #280 — entrada y casa → sueño visibles, legibles, saltables y equivalentes en una export real.
- #281 — primera noche comprensible y completable por objetivos.
- #286 — SIGA se percibe como investigación ligera y no como lectura → decisión inmediata.
- #287 — el ritmo de la decisión política permite posponer/madurar sin bloquear el flujo.
- #119 — ambiente de oficina audible y equilibrado cuando corresponda.

## Límites conocidos y exclusiones

- CI/Alpha automáticas validan importación, pruebas, lint, smoke y export; **no equivalen** a playthrough humano, validación visual, mezcla de audio ni prueba con mando físico.
- El PR #503 (vertical jugable de Gilgamesh) estaba abierto al cortar este baseline y **no forma parte de esta alpha**.
- SameBoy está en la cadena de build, no como runtime activo: la emulación incluida sigue usando Peanut-GB y no promete CGB-only.
- Varios sueños/anomalías recientes son verticales standalone o contratos todavía sin wiring completo al selector/recorrido principal.
- La URL externa del Parte de incidencias puede quedar vacía si el empaquetado no define `SIGA98_FEEDBACK_URL`; el texto sigue pudiéndose copiar/guardar localmente.
- Esta rama de alpha no cambia gameplay: empaqueta el estado existente de `main`, documenta qué probar y añade metadatos de identificación del paquete.

## Qué reportar primero

Prioridad P0: bloqueo del recorrido, pérdida/duplicación de estado, cámara o controles que impidan jugar, HUD que oculte interacción/diálogo, transiciones que no aparezcan o dejen un estado distinto, primera noche incomprensible y espacios que sigan pareciendo greybox desde cámara de juego.

Después: regresiones visuales concretas, colisiones de props, escala/materiales/UV, comportamiento del gato/Bingo, inventario/cómoda, escaleras y extras de portátil.

Refs #9 #181 #394 #498 #499 #502 #505 #507 #508 #510.

— Odiseo (GPT-5.6 Sol)
