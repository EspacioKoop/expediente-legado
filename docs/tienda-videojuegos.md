# Tienda de videojuegos del trayecto

La idea de #93 convierte uno de los locales de la calle en una tienda de videojuegos de 1998 en la que el protagonista gasta parte del sueldo en cartuchos/ROMs propias del proyecto. #800 separa ahora la propiedad de esos cartuchos de la jornada: lo comprado queda en la biblioteca permanente del perfil y puede abrirse también desde el menú principal.

## Regla de diseño

La tienda convierte **dinero en ocio opcional**, no dinero en más dinero. Comprar una ROM no concede acciones, sueldo, pistas, expedientes ni ventajas de campaña. Esto mantiene la frontera de #93 y deja la calibración del precio bajo #83.

La compra solo puede realizarse durante `trayecto`, porque el local pertenece a la calle. Sin embargo, la propiedad del cartucho vive en `user://perfil_roms.json`, fuera de `Partida` y `Jornada`: empezar una partida nueva no borra la biblioteca. `PerfilRoms` usa escritura atómica y conserva una única lista normalizada de IDs.

Los guardados anteriores a #800 pueden contener `jornada["roms_compradas"]`. Esa clave se trata únicamente como fuente de migración: al arrancar el menú o consultar la tienda/consola durante una jornada antigua, sus IDs se copian de forma idempotente a `PerfilRoms`. El `partida.json` legado no se reescribe para migrarlo y el menú no llama a `Partida.cargar()`, evitando alterar un guardado corrupto antes de que el jugador pulse Continuar.

## Catálogo

El catálogo sale del índice de ROMs propias ([`roms-propias.md`](roms-propias.md), `godot/datos/roms_propias.json`): se venden las jugables con precio. Hoy son `Paper Planes 98` y `Croc Riders 98`, a 45 cada una. `Caza Píxeles 98` viene incluida con la consola y no se vende.

Los precios son provisionales hasta la calibración de #83. Si el artefacto no existe en el build, la tienda lo considera `sin_stock` y **no descuenta dinero**. Si el perfil permanente no puede escribirse después del cobro, la operación devuelve el dinero para no dejar una compra fantasma.

Nuevas ROMs comprables deben cumplir la misma frontera de #244: código y assets propios o con licencia/procedencia verificada. No se incorporan BIOS, dumps ni ROMs comerciales.

## ROMs del jugador

`user://roms` sigue siendo un mecanismo separado. Esas ROMs son archivos que el jugador aporta porque tiene derecho a usarlos; la tienda no las detecta, renombra, vende, bloquea ni cobra por ellas. Tampoco descarga ROMs desde Internet.

## Contrato disponible

`TiendaVideojuegos` conserva sus firmas para no obligar a la calle ni a `ComercioBarrio` a conocer el nuevo almacenamiento:

- `catalogo()` — definición estable de mercancía propia;
- `listar(jornada)` — catálogo con `comprada` y `disponible`;
- `comprar(jornada, id_rom)` — transacción idempotente usando `Jornada.gastar()` y `PerfilRoms.registrar()`;
- `compras(jornada)` — IDs permanentes normalizados; la jornada solo sirve como posible fuente de migración;
- `roms_compradas(jornada)` — entradas adquiridas cuyo artefacto existe.

Recomprar un título no vuelve a cobrarlo. Comprar fuera del trayecto, sin dinero, con ID desconocido o sin artefacto devuelve un resultado fallido sin mutar la economía.


## Manual de servicio de Bit 98

Completar el catálogo **disponible en la build** desbloquea de forma permanente el manual de servicio de Bit 98. El desbloqueo reutiliza `PerfilRoms`: no introduce otra moneda, otra partida ni un fichero de progreso paralelo.

En una build publicada, la tecla **º** abre entonces una consola limitada con `ayuda`, `clima`, `desatascar`, `portatil`, `diagnostico` y `limpiar`. Es deliberadamente distinta de la consola QA: no contiene comandos para cambiar día, dinero, pistas, gato, fase ni sala del sueño. Esos comandos siguen viviendo exclusivamente bajo `debug/**` y no entran en los presets públicos.

La condición usa solo cartuchos presentes en la build. Un título temporalmente sin artefacto no hace imposible conseguir el manual. Una futura misión puede conceder el mismo acceso como ruta alternativa sin ampliar los permisos de esta consola.

## Portátil Color 98

La consola doméstica de #124 y la nueva entrada **Portátil Color 98** del menú principal consumen la misma biblioteca de `PerfilRoms`. Ambas muestran las ROMs incluidas mediante `RomsPropias.en_consola`, las compradas permanentemente y, por la vía independiente de `CatalogoRomsUsuario`, las aportadas por el jugador.

El emulador sigue aislado del estado de campaña: recibe la lista de compras al abrirse y no sabe de dinero, jornadas ni guardados. El menú reutiliza `EmuladorPortatilAudioApp`, por lo que controles, SRAM, presentación y audio son los mismos que desde la consola 3D.

## Atrezzo de escaparate

**Yggdrasil's Egg** aparece en el interior de Bit 98 como caja de videojuego ficticio de 1998. Es únicamente dressing visual: no figura en `RomsPropias`, `TiendaVideojuegos.catalogo()` ni `roms_propias.json`, no tiene ROM binaria, precio, stock, compra ni desbloqueo. Esta separación permite usarlo como eco diegético de #653 sin convertir el escaparate en otra superficie de activación.

## Alcance y dependencias

La implementación sigue sin comercializar archivos externos y no modifica `espacios_catalogo.gd`. La geometría de la calle continúa gobernada por #277/#181; #800 solo cambia la autoridad de persistencia y añade la entrada de inicio.

- filtra el selector del emulador: incluidas y compradas (`RomsPropias.en_consola`) de #124 según la biblioteca permanente;
- no cambia la disponibilidad histórica de `Caza Píxeles 98` en la Portátil Color 98;
- no añade ROMs binarias ni contenido de terceros;
- no mezcla `user://roms` con la economía;
- no borra la clave antigua del guardado después de migrarla.

## Criterios del vertical

- una compra válida reduce únicamente `dinero`;
- no consume ni concede `acciones`;
- no puede comprarse dos veces;
- un artefacto ausente nunca cobra;
- las compras sobreviven a días, reasignaciones y partidas nuevas;
- las compras de partidas antiguas se migran de forma no destructiva;
- la biblioteca es accesible desde el menú principal;
- `user://roms` queda fuera de la economía;
- ninguna ROM comercial entra en el repositorio.

Refs #83 #93 #95 #124 #244 #277 #800.

— Odiseo (GPT-5.6 Sol)
