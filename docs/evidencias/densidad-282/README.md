# Evidencia de densidad 3D · #282

Este gate convierte el pendiente visual de #282 en una revisión reproducible. El
workflow **Evidencia densidad 282** arranca el recorrido real de `dia.tscn` y
produce **12 capturas sin HUD**: oficina, calle, casa y sueño, cada una desde el
spawn jugable en tres direcciones reproducibles —frente, izquierda y derecha—,
con cámara del jugador a 1280×720 y FOV 70.

La ampliación a tres direcciones evita que un único encuadre convierta en falso
negativo un proxy, una superficie vacía o una composición pobre que quede justo
fuera de cámara. No mueve al jugador a puntos artificiales: las tres vistas
comparten el mismo spawn y solo cambia el rumbo de cámara.

El workflow usa el renderer declarado por el proyecto, actualmente **Forward+**.
No fuerza `gl_compatibility`: desde #1243 hay diferencias visuales relevantes
de iluminación y sombras que solo deben juzgarse sobre el renderer canónico del
juego.

El runner fija además `TranslationServer.set_locale("es")` antes de montar
`dia.tscn`. El artifact de #1281 dejó al descubierto esta omisión: la vista
lateral de calle mostraba `CALLE_ROTULO_RECLAMACIONES` y
`CALLE_ROTULO_TURNO` en vez de sus rótulos reales. Eso era un defecto del
capturador aislado, no evidencia válida para juzgar el juego. El gate falla ahora
si cualquier `Label3D` de `CalleIdentidad` sigue empezando por `CALLE_`.

Junto a las PNG se publica un `manifest.json` con dos familias de señales:

- la auditoría declarativa de `Densidad3D`: bultos con modelo, bultos que siguen
  siendo proxy y ratio modelado;
- el árbol 3D realmente montado: número de `MeshInstance3D`, cajas, superficies
  planas, `ArrayMesh`, otras primitivas, lotes `MultiMesh` e interactuables.

El manifiesto registra también el locale efectivo. Cada caso incluye sus tres
vistas, rumbo e inclinación y SHA-256 de cada PNG. La vista frontal se conserva también en los campos
históricos `captura`/`sha256` para no romper consumidores anteriores.

Estas cifras son **diagnóstico, no una puntuación artística**. Una `BoxMesh`
puede ser la forma correcta para una caja, un cajón o un muro; del mismo modo,
una malla importada puede seguir teniendo mala silueta o estar mal colocada.
El gate evita tres errores: discutir #282 sin mirar el mismo build, sustituir
proxies por cantidad sin comprobar qué ve realmente el jugador y dar por buena
una fase porque un único encuadre casual no enseñaba su punto débil.

## Qué revisar sin HUD

- **Oficina:** puesto SIGA, almacenamiento, compañeros y utilería deben formar un
  archivo habitado; los elementos cercanos no deben parecer volúmenes de prueba.
  Revisar especialmente si mobiliario y figuras conservan volumen bajo la
  iluminación Forward+.
- **Calle:** fachadas, escaparates, comercios, farolas, portales, ventanas y
  profundidad deben construir un exterior, no un pasillo con decoración.
- **Casa:** descanso, estar, cocina, almacenamiento y objetos del gato deben leer
  como una vivienda completa y con escala coherente.
- **Sueño:** arquitectura, figuras y objetos relevantes deben tener silueta propia
  o deformar objetos reconocibles de vigilia; no volver a un corredor de bloques
  ni a planos/láminas de debug.

La automatización comprueba que existen las doce vistas, que las tres imágenes de
cada fase son distintas y que el manifiesto es internamente coherente.
**No sustituye la revisión humana** exigida por #282/#398/#400: el cierre sigue
necesitando mirar las capturas o jugar el recorrido y registrar qué proxy,
objeto o composición concreta falla si la densidad todavía no es suficiente.
