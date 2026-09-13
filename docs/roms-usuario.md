# ROMs aportadas por el jugador

La portátil de #124 reserva una carpeta local para que cada jugador pueda añadir, de forma opcional, ROMs que tenga derecho a usar.

## Carpeta

SIGA-98 usa:

```text
user://roms
```

`user://` es la carpeta de datos de usuario que Godot asigna a la aplicación. El código expone también la ruta absoluta mediante `CatalogoRomsUsuario.ruta_absoluta()` para que una futura interfaz pueda mostrarla o abrirla sin hardcodear rutas de Windows, Linux o macOS.

La carpeta se crea vacía al encender/interactuar con la portátil por primera vez. El juego funciona igual si permanece vacía.

## Qué se detecta

Solo ficheros directos con extensión:

- `.gb`
- `.gbc`

No se recorren subcarpetas ni se aceptan ZIP/7z. Para evitar entradas accidentales o absurdamente grandes, el catálogo solo lista ficheros de entre 32 KiB y 8 MiB. En este corte solo se consulta nombre, ruta y tamaño; la ROM no se carga entera en memoria.

## Responsabilidad y procedencia

SIGA-98 **no descarga ROMs**, no incluye ROMs comerciales ni ofrece enlaces para obtenerlas. La carpeta existe únicamente para contenido aportado por el propio jugador.

Cada persona debe usar únicamente ROMs que tenga derecho a usar conforme a su legislación y a la licencia del propio software. El proyecto no intenta determinar la procedencia jurídica de un fichero local y no convierte el hecho de encontrarlo en autorización para redistribuirlo.

Las ROMs propias del proyecto, como `Caza Píxeles 98`, siguen otro flujo: viven como código fuente en el repositorio y se compilan de forma reproducible en CI.

## Estado actual

Este vertical descubre ROMs y deja preparado el contrato de integración, pero **todavía no ejecuta** ROMs del usuario. El núcleo de emulación de #124 debe implementarse y validarse aparte antes de que la portátil pueda arrancar cualquiera de estas entradas.

Cuando exista el emulador, deberá mantener estos límites:

- ninguna ROM externa modifica el estado de campaña por sí misma;
- salir de la portátil siempre debe ser posible;
- no se ejecutan procesos externos ni scripts auxiliares de una ROM;
- un fichero incompatible o corrupto falla de forma controlada;
- el juego principal funciona aunque la carpeta no exista, esté vacía o contenga ficheros no compatibles.
