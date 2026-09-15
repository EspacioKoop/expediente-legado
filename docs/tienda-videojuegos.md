# Tienda de videojuegos del trayecto

Primer corte de la idea de #93: uno de los locales de la calle puede ser una tienda de videojuegos de 1998 en la que el protagonista gasta parte del sueldo en cartuchos/ROMs propias del proyecto.

## Regla de diseño

La tienda convierte **dinero en ocio opcional**, no dinero en más dinero. Comprar una ROM no concede acciones, sueldo, pistas, expedientes ni ventajas de campaña. Esto mantiene la frontera de #93 y deja la calibración del precio bajo #83.

La compra solo es válida durante `trayecto`, porque el local pertenece a la calle. El estado se guarda en `jornada["roms_compradas"]`: `Partida` ya serializa el diccionario completo y `Jornada.completar()` conserva claves adicionales, así que este corte no modifica esos módulos compartidos.

## Catálogo

El catálogo sale del índice de ROMs propias ([`roms-propias.md`](roms-propias.md), `godot/datos/roms_propias.json`): se venden las jugables con precio. Hoy son `Paper Planes 98` y `Croc Riders 98`, a 45 cada una. `Caza Píxeles 98` viene incluida con la consola y no se vende.

Los precios son provisionales hasta la calibración de #83. Si el artefacto no existe en el build, la tienda lo considera `sin_stock` y **no descuenta dinero**.

Nuevas ROMs comprables deben cumplir la misma frontera de #244: código y assets propios o con licencia/procedencia verificada. No se incorporan BIOS, dumps ni ROMs comerciales.

## ROMs del jugador

`user://roms` sigue siendo un mecanismo separado. Esas ROMs son archivos que el jugador aporta porque tiene derecho a usarlos; la tienda no las detecta, renombra, vende, bloquea ni cobra por ellas. Tampoco descarga ROMs desde Internet.

## Contrato disponible

`TiendaVideojuegos` expone:

- `catalogo()` — definición estable de mercancía propia;
- `listar(jornada)` — catálogo con `comprada` y `disponible` para una futura UI;
- `comprar(jornada, id_rom)` — transacción idempotente usando `Jornada.gastar()`;
- `compras(jornada)` — IDs comprados y normalizados;
- `roms_compradas(jornada)` — entradas adquiridas cuyo artefacto existe.

Recomprar un título no vuelve a cobrarlo. Comprar fuera del trayecto, sin dinero, con ID desconocido o sin artefacto devuelve un resultado fallido sin mutar la economía.

## Qué no hace todavía este PR

Este corte es **standalone first** y no modifica `espacios_catalogo.gd`. Esa ruta está coordinada por #182 y el trabajo visual de la calle sigue gobernado por #277/#181. Por tanto:

- no añade todavía el escaparate 3D ni una puerta física a la tienda;
- no añade UI de caja/dependiente;
- filtra el selector del emulador: incluidas y compradas (`RomsPropias.en_consola`) de #124 según `roms_compradas`;
- no cambia la disponibilidad histórica de `Caza Píxeles 98` en la Portátil Color 98;
- no añade ROMs binarias ni contenido de terceros.

El siguiente corte, cuando la calle pueda tocarse sin conflicto, debe montar un local reconocible en #277 y conectar su interacción a `TiendaVideojuegos.listar()/comprar()`. Después, #124 puede consumir `roms_compradas()` como fuente de cartuchos propios comprados, manteniendo `CatalogoRomsUsuario` como vía externa independiente.

## Criterios del vertical

- una compra válida reduce únicamente `dinero`;
- no consume ni concede `acciones`;
- no puede comprarse dos veces;
- un artefacto ausente nunca cobra;
- el estado cabe en la jornada guardada sin migración destructiva;
- `user://roms` queda fuera de la economía;
- ninguna ROM comercial entra en el repositorio.

Refs #83 #93 #95 #124 #244 #277.

— Odiseo (GPT-5.6 Sol)
