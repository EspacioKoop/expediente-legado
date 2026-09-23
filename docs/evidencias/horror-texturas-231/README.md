# Evidencia A/B · Horror Texture Pack en sueños (#231)

Capturas del corte que materializa por Git LFS el lote 128×128 que
`HorrorTexturas` ya consume. No sustituyen el pase humano de #398: solo muestran
qué cambia en pantalla cuando el lote está instalado.

## Cómo se hicieron

- GPU real (`DISPLAY=:0`, Forward+, Vulkan, Intel ADL-N), no xvfb.
- Mismo montaje, cámara y luz que `godot/pruebas/capturar_sueno_284.gd`
  (1280×720, FOV 70°, cámara a 1,65 m, sin HUD).
- Tras los adaptadores de identidad se llamó a `HorrorTexturas.aplicar(espacio,
  forma, nivel)`, como hace `dia_sueno_app.gd`. En cada comparativa, de
  izquierda a derecha: **sin pack**, **nivel 1** (solo muro) y **nivel 3** (muro,
  suelo y manchas).

## Qué se ve

| Comparativa | Perfil | Lectura |
| --- | --- | --- |
| `comparativa-castillo.png` | `castillo`: Brick 11 / Stone 07 | la muralla lisa pasa a ladrillo desgastado; a nivel 3 también cambia el patio |
| `comparativa-escuela.png` | `escuela`: Wall 09 / Floor 12 | las paredes planas ganan manchas de humedad verdosas |
| `comparativa-desierto.png` | `desierto`: Wall 05 / Stone 13 | **sin cambio visible** |

## Límite detectado

En **desierto** y **montaña**, exteriores, el perfil se aplica
(`horror_perfil`, `textura_muro` y `textura_suelo` quedan fijados en el
espacio), pero la presentación 3D de #284 tapa la envolvente sobre la que se
pintan, así que no llega a la pantalla. Es un hueco del runtime, no del lote. Se
anota para #231/#398 en lugar de corregirlo en este corte, que no toca
`horror_texturas.gd` ni la generación de sueños.

Con un solo cartel en la sala, el castillo solo recibe una mancha y a esta
distancia apenas se distingue. Las manchas siguen ancladas a carteles de #87 y
ninguna es Stain 01–05.
