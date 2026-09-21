# Comercio de barrio del trayecto

Primer corte ejecutable de #676. El objetivo es fijar la frontera de datos y economía de tres superficies comerciales sin abrir todavía nuevos interiores ni competir con trabajo visual activo en la calle o la casa.

## Superficies

El contrato `ComercioBarrio` expone tres superficies diferenciadas:

- **Quiosco Avenida**: prensa/publicaciones pequeñas. El catálogo incluye una revista ficticia, un periódico local y, desde #93, un paquete de cigarrillos como consumo recurrente.
- **Bit 98**: adapta la tienda de videojuegos ya implementada por #93 mediante `TiendaVideojuegos`; no replica catálogo, stock ni reglas de ROMs.
- **El Trastero**: segunda mano para pequeños objetos domésticos. El primer catálogo incluye una lámpara y un marco usados.

La base de datos nació sin exigir interiores 3D. La implementación actual ya materializa Electrodomésticos y Bit 98 como microinteriores accesibles dentro de `trayecto`, sin crear una fase ni una economía nuevas.

## Economía

Toda compra normal pasa por `Jornada.gastar()`, por lo que reutiliza la economía de #83/#93. No añade crédito, deuda, puntos, moneda secundaria ni acciones extra. La compra solo es válida en fase `trayecto`.

Las compras de objetos se registran en `jornada["comercio_barrio_compras"]` y son idempotentes: volver a comprar el mismo objeto no vuelve a cobrar. La superficie de videojuegos mantiene su persistencia especializada en `TiendaVideojuegos`.

El paquete de cigarrillos es la excepción deliberada: cuesta **8**, se marca `repetible`, se consume en el acto y puede volver a comprarse. No entra en inventario, no concede acciones, no aumenta ingresos y no activa contenido cultural u onírico. Su única consecuencia es gastar parte del mismo saldo que compite con comida propia, comida del gato, café, alquiler e imprevistos.

### Reventa e inventario — #61 / #97

`ComercioBarrio.vender()` conecta por primera vez la venta de `Inventario` con el saldo real de `Jornada`, sin introducir otra economía:

- solo **El Trastero** admite reventa;
- solo se vende durante `trayecto`;
- la tienda solo puede vender un objeto presente en `carried`;
- un objeto guardado en `home_storage` debe sacarse físicamente en casa antes de llevarlo a la tienda;
- `Inventario.vender()` sigue siendo la autoridad sobre vendibilidad y precio;
- si el objeto es onírico, la venta falla y el saldo no cambia, aunque el objeto traiga un precio erróneo;
- vender no concede acciones, no altera expedientes cerrados y no toca el histórico de compras.

Esto convierte “vender cosas para llegar a fin de mes” en una costura real entre casa, inventario y economía sin permitir vender a distancia ni monetizar el sueño.

## Inventario y casa

Los objetos se materializan mediante el contrato de `Inventario` de #97:

- publicaciones del quiosco quedan en `carried`;
- objetos voluminosos/decorativos de segunda mano usan `Inventario.recoger()` y después `Inventario.guardar_en_casa()` para quedar en `home_storage`.

Esto da a #96 una fuente de verdad real para representar una compra doméstica. No se crea un booleano estético paralelo ni se toca `casa_utileria.gd` en este corte.

La reventa respeta la misma frontera: fuera de casa solo existe lo que se lleva encima. Para vender una lámpara o un marco guardado, primero debe pasar `home_storage → carried` mediante el almacenamiento doméstico ya integrado.

## Cultura y sueños

La revista ficticia `Umbral — nº 17` declara metadatos compatibles con #442 (`id_semilla` + `fuente`) a través de `fuente_cultural()`.

**Comprar no activa ninguna semilla onírica.** El consumidor debe activar #442 únicamente después de una interacción deliberada posterior, por ejemplo abrir/leer contenido suficiente de la publicación. Así se mantiene la regla de #442: gastar dinero no equivale a haber prestado atención a una fuente cultural.

La reventa tampoco abre una ruta económica desde el sueño: cualquier objeto con `origen == "sueno"` permanece bloqueado por el contrato central de `Inventario`. El siguiente corte de #97 puede permitir sacar recompensas físicas del sueño sin convertirlas en dinero o acciones.

La conexión de páginas hojeables pertenece a #674 y queda fuera de este corte.

## Compatibilidad con la tienda de videojuegos

`ComercioBarrio` delega `listar()` y `comprar()` en `TiendaVideojuegos` para `videojuegos`. No inspecciona ni comercializa `user://roms`, no descarga contenido y no introduce una segunda lista de ROMs. La procedencia/licencia sigue gobernada por #244 y el contrato ya existente de #93/#124.

## Límites deliberados

Este PR es **standalone first** y no modifica:

- `godot/guion/calle_identidad.gd` — la materialización del quiosco/segunda mano debe coordinarse después con el trabajo visual de calle;
- `godot/guion/casa_utileria.gd` — #96 ya tiene su propio contrato ambiental y materialización;
- `godot/datos/textos.csv` — evitamos reservar un fichero compartido hasta que exista una UI física concreta;
- escenas, geometría o interiores 3D;
- precios/calibración global fuera de los importes pequeños del primer catálogo;
- la UI de inventario: sigue siendo de consulta y no vende a distancia.

## Quiosco Avenida y El Trastero físicos — 2026-09-21

El segundo corte físico completa la presencia en calle de las otras dos
superficies del contrato:

- **Quiosco Avenida** se materializa como puesto de fachada, con señalética
  propia y los cuatro productos que devuelve `ComercioBarrio.listar("quiosco")`.
  Las tres publicaciones reutilizan `PublicacionFisica3D`; el paquete de
  consumo sigue sin marca ficticia adicional ni utilidad mecánica.
- **El Trastero** expone la lámpara y el marco de segunda mano devueltos por el
  catálogo real. Comprar la lámpara sigue pasando por `ComercioBarrio.comprar`
  y termina en `Inventario.HOME_STORAGE`, por lo que #96 puede materializarla
  después en casa.

La capa `ComercioBarrio3D` no contiene precios ni una copia del catálogo:
deriva nombres, importes y estado comprado desde `ComercioBarrio`. Tampoco
activa #442 al pagar una publicación; la activación cultural continúa exigiendo
lectura/interacción posterior.

## Reventa física en El Trastero — 2026-09-21

La reventa deja de ser solo una función de dominio. `ComercioBarrio3D`
materializa una **bandeja de reventa** dentro de El Trastero usando exclusivamente
los objetos presentes en `Inventario.CARRIED` que estén marcados como vendibles.

Cada objeto de la bandeja:

- muestra nombre e importe procedentes del propio objeto de inventario;
- llama a `ComercioBarrio.vender(..., "segunda_mano", item_id)`;
- desaparece de la bandeja cuando la venta se confirma;
- actualiza el mismo saldo de `Jornada`;
- conserva a `Inventario.vender()` como autoridad final sobre bloqueos, incluido
  el veto a objetos de origen onírico.

`HOME_STORAGE` no se consulta para construir la bandeja. Un objeto guardado en
casa debe sacarse primero y viajar en `carried`; por tanto no aparece una venta
a distancia disfrazada de interfaz de tienda.

## Bit 98: identidad visual integrada — 2026-09-21

Bit 98 ya no depende solo de cajas coloreadas para leerse como tienda. La capa
`Bit98Dressing` añade rótulo exterior/interior, cartelería de novedades y segunda
mano y un expositor físico que **reutiliza** las portadas ya versionadas de
`caza_pixeles_98`, `paper_planes_98` y `croc_riders_98`.

Los SVG de `godot/arte/bit98/` son originales del proyecto y no introducen
marcas reales ni títulos nuevos en `RomsPropias`. Esta capa es estrictamente
visual: no conoce precios, inventario, compras, desbloqueos ni semillas oníricas.

## Siguiente corte

Con las tres superficies ya físicas y la reventa operable, quedan mejoras de
segunda capa sin necesidad de abrir más interiores:

1. completar el feedback diegético de compra/reventa con vendedor fuera de campo o
   pequeñas variaciones de estado, sin diálogo obligatorio;
2. comprobar en playtest que la bandeja de reventa sigue siendo legible con varios
   objetos `carried` y no invade el paso;
3. hacer que la lámpara/marco de `home_storage` tenga representación visible mediante #96;
4. conectar la revista a una interacción hojeable de #674 y solo entonces activar #442;
5. completar #97 con una recompensa onírica física que pueda salir del sueño pero no venderse ni conceder acciones.

Así #676 cubre ya compra y venta sobre superficies reales sin convertir la calle
en un mundo abierto comercial, y #61 dispone de una costura económica directa
entre trayecto, casa e inventario.

Refs #61 #83 #93 #96 #97 #124 #244 #442 #674 #676.

— Odiseo (GPT-5.6 Sol)
