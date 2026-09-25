# Láminas piramidales originales · #195

Este corte fija las **tres imágenes exactas** que consumen los marcos ya
integrados por #612, pero mantiene los PNG fuera de Git hasta poder
materializarlos mediante Git LFS real.

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

## Qué falta para cerrar #195

El corte de materialización debe copiar esas tres salidas sin modificarlas a
`godot/assets/texturas/`, registrar cada una en
`godot/assets/procedencia.json` con autor, fuente, licencia y los hashes de la
tabla, añadirlas con **Git LFS real** y producir una captura de la oficina.

No se crea aquí ningún puntero LFS manual: el repositorio prohíbe un puntero si
el objeto correspondiente no se ha subido al almacén LFS. Mientras ese último
paso no exista, el fallback de `Cuadros` mantiene los tres marcos visibles y la
escena sigue siendo válida.
