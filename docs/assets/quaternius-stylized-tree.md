# Quaternius Stylized Tree Pack — primer corte (#219)

Fuente oficial: **Quaternius — Stylized Tree Pack**
Página: https://quaternius.com/packs/stylizedtree.html
Descarga: carpeta de Google Drive enlazada desde esa página
(`1GlrFUFcNj6KIuc4-QpVEiRcXVUzSClP2`).

## Licencia: CC0-1.0

En #219 se señaló una posible ambigüedad: Quaternius publica ahora una licencia
general, **QAL v1.0** (actualizada el 28/08/2026), que prohíbe redistribuir los
assets "como asset independiente". Se resolvió así, con comprobación del
**16/09/2026**:

1. La ficha del pack declara **License: CC0** y enlaza a
   `creativecommons.org/publicdomain/zero/1.0/`.
2. La propia distribución de descarga incluye un `License.txt` del autor que
   dice literalmente: *"License: CC0 1.0 Universal (CC0 1.0) Public Domain
   Dedication"*.
3. CC0 es una dedicación irrevocable al dominio público: una licencia general
   posterior no puede retirarla sobre copias publicadas bajo CC0. La QAL,
   además, establece que rige la versión vigente cuando se obtuvieron los assets.
4. Es coherente con los packs de Quaternius ya integrados en el repositorio
   (#217 Modular Train, #218 Ultimate Buildings, #229 Ultimate Nature).

Si Quaternius cambiase la ficha o el `License.txt` de este pack, los ficheros ya
versionados siguen cubiertos por la dedicación CC0 con la que se descargaron.

## Selección

La distribución trae 45 modelos (familias `Birch`, `DeadBirch`, `DeadTree`,
`Pine`, `Tree`) en FBX/OBJ/Blend. Entran tres OBJ con su MTL, sin texturas:

| Rol | Fichero | Caras | Por qué |
| --- | --- | --- | --- |
| frondoso de patio | `Tree_1.obj` | 388 | copa ancha y pocas caras |
| pino de periferia | `Pine_2.obj` | 301 | silueta vertical distinta |
| árbol desnudo | `DeadTree_5.obj` | 409 | invierno urbano; rompe la repetición de copas |

Descartados: los abedules (tronco blanco y hojas amarillas, demasiado
protagonistas de noche) y `Tree_3` (1002 caras sin ganar silueta).

## Adaptación SIGA-98

- Las texturas del pack (hojas de caricatura) **no se versionan**. Cada
  superficie recibe el shader PSX común con un color apagado según el material
  del MTL (`Bark`, `Tree_Leaves`, `Pine_Leaves`): se lee la masa, no la hoja.
- Sin sombras propias, `visibility_range_end = 60`, sin colisión, navegación ni
  interacción.

## Montaje

`godot/guion/dia_arboles_cc0_app.gd`, solo en la fase `trayecto`: 6 instancias
de los 3 modelos (≤ 12 superficies). Las fachadas de la calle miden ~10 m y
están a |x| ≈ 5,5 m, así que:

- un árbol a escala real no se ve, y uno pegado a la fachada atraviesa el muro
  con la copa (comprobado en captura);
- se usan ejemplares de patio de 12-16 m a |x| ≥ 10,5 m, o detrás de los
  edificios que cierran el eje (|z| ≥ 20), para que solo asome la silueta sobre
  los tejados.

Validación visual: la captura del trayecto con `pruebas/capturar.gd` muestra una
copa oscura sobre la línea de tejados del lado oeste, sin tocar el primer plano.

Procedencia y SHA-256 de cada OBJ/MTL en `godot/assets/procedencia.json`.
Pruebas: `scripts/test_arboles_cc0.py`.

Refs #216 #219
