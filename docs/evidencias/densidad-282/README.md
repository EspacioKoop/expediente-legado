# Evidencia de densidad 3D · #282

Este gate convierte el pendiente visual de #282 en una revisión reproducible. El
workflow **Evidencia densidad 282** arranca el recorrido real de `dia.tscn` y
produce cuatro capturas **sin HUD** —oficina, calle, casa y sueño— con la cámara
del jugador a 1280×720 y FOV 70. Cada fase fija rumbo e inclinación de QA para
que el resultado no dependa de la orientación heredada de la fase anterior.

Junto a las PNG se publica un `manifest.json` con dos familias de señales:

- la auditoría declarativa de `Densidad3D`: bultos con modelo, bultos que siguen
  siendo proxy y ratio modelado;
- el árbol 3D realmente montado: número de `MeshInstance3D`, cajas, superficies
  planas, `ArrayMesh`, otras primitivas, lotes `MultiMesh` e interactuables.

Estas cifras son **diagnóstico, no una puntuación artística**. Una `BoxMesh`
puede ser la forma correcta para una caja, un cajón o un muro; del mismo modo,
una malla importada puede seguir teniendo mala silueta o estar mal colocada.
El gate evita dos errores: discutir #282 sin mirar el mismo build y sustituir
proxies por cantidad sin comprobar qué ve realmente el jugador.

## Qué revisar sin HUD

- **Oficina:** puesto SIGA, almacenamiento, compañeros y utilería deben formar un
  archivo habitado; los elementos cercanos no deben parecer volúmenes de prueba.
- **Calle:** fachadas, escaparate, farolas, portales, ventanas y profundidad deben
  construir un exterior, no un pasillo con decoración.
- **Casa:** descanso, estar, cocina, almacenamiento y objetos del gato deben leer
  como una vivienda completa y con escala coherente.
- **Sueño:** arquitectura, figuras y objetos relevantes deben tener silueta propia
  o deformar objetos reconocibles de vigilia; no volver a un corredor de bloques.

La automatización comprueba que existen cuatro frames distintos y que el
manifiesto es internamente coherente. **No sustituye la revisión humana** exigida
por #282/#398/#400: el cierre sigue necesitando mirar las capturas o jugar el
recorrido y registrar qué proxy, objeto o composición concreta falla si la
densidad todavía no es suficiente.
