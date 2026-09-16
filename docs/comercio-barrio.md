# Comercio de barrio del trayecto

Primer corte ejecutable de #676. El objetivo es fijar la frontera de datos y economía de tres superficies comerciales sin abrir todavía nuevos interiores ni competir con trabajo visual activo en la calle o la casa.

## Superficies

El contrato `ComercioBarrio` expone tres superficies diferenciadas:

- **Quiosco Avenida**: prensa/publicaciones pequeñas. El primer catálogo incluye una revista ficticia y un periódico local.
- **Bit 98**: adapta la tienda de videojuegos ya implementada por #93 mediante `TiendaVideojuegos`; no replica catálogo, stock ni reglas de ROMs.
- **El Trastero**: segunda mano para pequeños objetos domésticos. El primer catálogo incluye una lámpara y un marco usados.

Este corte no necesita interiores 3D: la futura integración puede resolverse desde escaparate/mostrador en el trayecto.

## Economía

Toda compra normal pasa por `Jornada.gastar()`, por lo que reutiliza la economía de #83/#93. No añade crédito, deuda, puntos, moneda secundaria ni acciones extra. La compra solo es válida en fase `trayecto`.

Las compras del comercio se registran en `jornada["comercio_barrio_compras"]` y son idempotentes: volver a comprar el mismo objeto no vuelve a cobrar. La superficie de videojuegos mantiene su persistencia especializada en `TiendaVideojuegos`.

## Inventario y casa

Los objetos se materializan mediante el contrato de `Inventario` de #97:

- publicaciones del quiosco quedan en `carried`;
- objetos voluminosos/decorativos de segunda mano usan `Inventario.recoger()` y después `Inventario.guardar_en_casa()` para quedar en `home_storage`.

Esto da a #96 una fuente de verdad real para representar una compra doméstica más adelante. No se crea un booleano estético paralelo ni se toca `casa_utileria.gd` en este corte.

## Cultura y sueños

La revista ficticia `Umbral — nº 17` declara metadatos compatibles con #442 (`id_semilla` + `fuente`) a través de `fuente_cultural()`.

**Comprar no activa ninguna semilla onírica.** El consumidor debe activar #442 únicamente después de una interacción deliberada posterior, por ejemplo abrir/leer contenido suficiente de la publicación. Así se mantiene la regla de #442: gastar dinero no equivale a haber prestado atención a una fuente cultural.

La conexión de páginas hojeables pertenece a #674 y queda fuera de este corte.

## Compatibilidad con la tienda de videojuegos

`ComercioBarrio` delega `listar()` y `comprar()` en `TiendaVideojuegos` para `videojuegos`. No inspecciona ni comercializa `user://roms`, no descarga contenido y no introduce una segunda lista de ROMs. La procedencia/licencia sigue gobernada por #244 y el contrato ya existente de #93/#124.

## Límites deliberados

Este PR es **standalone first** y no modifica:

- `godot/guion/calle_identidad.gd` — la materialización del quiosco/segunda mano debe coordinarse después con el trabajo visual de calle;
- `godot/guion/casa_utileria.gd` — #96 ya tiene su propio contrato ambiental y materialización;
- `godot/datos/textos.csv` — evitamos reservar un fichero compartido hasta que exista una UI física concreta;
- escenas, geometría o interiores 3D;
- precios/calibración global fuera de los importes pequeños del primer catálogo.

## Siguiente corte

Cuando las reservas visuales lo permitan:

1. montar fachadas reconocibles de quiosco y segunda mano en la calle;
2. añadir una superficie de interacción accesible por teclado/mando que consuma `listar()/comprar()`;
3. hacer que la lámpara/marco de `home_storage` tenga representación visible mediante #96;
4. conectar la revista a una interacción hojeable de #674 y solo entonces activar #442.

Con eso #676 podrá cubrir tres superficies reales sin convertir la calle en un mundo abierto comercial.

Refs #83 #93 #96 #97 #124 #244 #442 #674 #676.

— Odiseo (GPT-5.6 Sol)
