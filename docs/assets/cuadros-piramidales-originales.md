# Láminas piramidales originales · #195

Tres imágenes exactas cuelgan en los marcos de la oficina integrados por #612.
Viven en `godot/assets/texturas/` como objetos Git LFS y son la salida del
renderizador sin retoques.

Las composiciones son originales del proyecto y no copian iconografía de
terceros. Se publican como **CC0-1.0**. Las fuentes versionadas son tres recetas
JSON y un renderizador Python sin dependencias externas.

| receta | salida runtime | motivo | sha256 del PNG reproducible |
| --- | --- | --- | --- |
| `piramide-01.json` | `cuadro-piramide-01.png` | horizonte con tres pirámides | `f409296951511243d8754eaead458ee01c5cac4767e7cc7f37d21aaad9f8d53e` |
| `piramide-02.json` | `cuadro-piramide-02.png` | sección monumental sobre retícula | `c7ab003f17daeb22032b4a40b510487a02257d0985cc1bb00fa298e4c86e187f` |
| `piramide-03.json` | `cuadro-piramide-03.png` | pirámide nocturna y triángulo celeste | `e35897cee9344eda22661feec1c85c482f5c1ec5fcb06bd629110e729f54da44` |

## Render reproducible

Desde la raíz:

```bash
python3 scripts/generar_cuadros_piramidales.py
python3 scripts/test_cuadros_piramidales_originales.py
```

La salida se escribe por defecto en `build/cuadros_piramidales/`, nunca dentro
de `godot/assets/`. El PNG se codifica con bloques DEFLATE almacenados en vez
de depender del nivel o versión de compresión de zlib; por eso el SHA-256 del
fichero es estable y puede registrarse antes de promover el binario.

## Materialización

Los tres PNG de `godot/assets/texturas/` son copia byte a byte de la salida del
generador. Cada uno tiene ficha en `godot/assets/procedencia.json` con
`origen: generado_por_script`, su receta y el generador. Si se cambia una
receta, hay que volver a generar, copiar y actualizar a la vez la tabla, la
receta y la ficha. `test_cuadros_piramidales_originales.py` falla si el PNG
versionado se aparta del render catalogado o si queda un puntero LFS sin
objeto.

`godot/pruebas/pruebas_cuadros_oficina_195.gd` monta los marcos y comprueba que
cada lámina carga su textura. Si falta un fichero, el fallback de `Cuadros`
mantiene el marco con relleno neutro y la escena sigue siendo válida.
