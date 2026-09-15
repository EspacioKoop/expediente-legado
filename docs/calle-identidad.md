# Identidad de la calle (#277, #398)

El trayecto tiene que decir dónde se está y a qué sitios se puede ir, sin necesitar un mapa. Antes (`docs/capturas/calle-identidad-antes.png`) era un pasillo de bloques beige: el spawn daba la espalda al vacío, el portal de casa era un marco suelto, las luces flotaban sin poste y el escaparate enseñaba tres televisores tras un cristal opaco.

## Recorrido

Se sale del **edificio del Archivo General** (a la espalda del spawn, `z = -17.3`) y se anda hacia el **bloque de viviendas del portal 7** (`z = 16.3`), que cierra la calle de frente.

| Acera | Sitio | Qué lo identifica | Trámite |
|---|---|---|---|
| izquierda, junto a la oficina | **Ventanilla de Reclamaciones** | placa azul, puerta de cristal, turno en rojo, postes de cola | `Usar` abre el Coliseo (#43) encima del día |
| izquierda, centro | **Electrodomésticos** | rótulo rojo, cristal translúcido, **dos hileras de cuatro televisores** con la misma emisión | — |
| derecha, sur | **Videojuegos** | rótulo magenta y cian con neón, escaparate de cartuchos | `Usar` compra el siguiente cartucho del catálogo (#93) |
| derecha, norte | **Alquileres · Administración de fincas** | frente verde, ventanilla con repisa | el día de vencimiento, la salida de pago (#85) está delante de su repisa |

Además:

- **Farolas:** las tres luces cuelgan de cables entre fachadas; donde no hay fachada, recoge el cable un poste.
- **Fachadas:** tienen de 8 a 11 m de altura, llegan hasta los dos edificios de los extremos y tienen ventanas en las plantas altas, algunas encendidas.
- **Fondo:** los edificios del skyline encienden ventanas en la cara que da a la calle, así que el horizonte deja de ser un recorte negro.
- **Cielo:** noche urbana estática, con luna menguante sobre el bloque de casa (visible desde el spawn), pocas estrellas y el resplandor anaranjado de las farolas de sodio en el horizonte.

## Decisiones

- `CalleIdentidad` es presentación sobre la planta de `dia_calle_app`. Las reglas siguen donde estaban: `TiendaVideojuegos.comprar`, `Jornada`/`AlquilerDuelo` y `ventanilla_app`.
- **El Coliseo usa la misma `Partida` del día** (`partida_externa`). Antes de abrirlo se guarda lo pendiente y, al salir, se vuelve a andar. Dos copias del estado guardando por separado se habrían pisado la racha o la jornada.
- La ventanilla de alquiler deja de ser un par de cajas en la calzada, que además chocaban con el contenedor de #222. Ahora es la administración de fincas, y su salida de pago está en la acera, delante de la repisa.
- El contenedor y sus bolsas (#222) pasan a la acera izquierda, y los aparatos de aire suben por encima de los rótulos.
- Las tres pieles de revoco de `CalleMateriales` apuntaban a bultos antiguos en `x = ±2.59` y aparecían como tablones marrones en mitad de la calzada. Ahora cubren las fachadas reales.
- Los rótulos son `Label3D` con claves `CALLE_*` en `textos.csv`, en la letra monoespaciada del SIGA.
- Sin assets nuevos: geometría procedural con el shader PSX común, texturas procedurales (`revoco_urbano`, `metal_pintado`, `madera_domestica`) y superficies emisivas para ventanas y cristales. Solo hay una luz nueva, el neón de la tienda de videojuegos.

## Pruebas

`godot/pruebas/pruebas_calle_identidad.gd` (desde `scripts/test_calle_identidad.py`) monta el trayecto real y comprueba:

- los ocho sitios existen;
- la oficina queda detrás del spawn y el portal está en la fachada de casa;
- hay 8 televisores en 2 hileras de 4, detrás de un cristal translúcido y con emisión compartida;
- los rótulos están traducidos y cada luz tiene su cable;
- la compra funciona: cobra una vez con existencias y, sin ellas, ni compra ni cobra;
- el Coliseo se abre con la misma partida, bloquea el paso y se cierra volviendo a la calle;
- la calle solo se monta en la fase de trayecto.

Capturas: `docs/capturas/calle-identidad-*.png`.
