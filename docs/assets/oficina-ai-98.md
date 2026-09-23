# Props fotorealistas de oficina 1998

Este lote añade seis recortes 2D generados específicamente para *Expediente Legado* el
24 de septiembre de 2026. Se eligieron después de revisar los props ya presentes en el
repositorio para no duplicar el monitor, teléfono, teclado, impresora, mobiliario ni la
utilería procedural existente.

## Contenido

- `fax_98.webp`: fax de sobremesa con papel y auricular.
- `escaner_98.webp`: escáner plano A4 de carcasa beige.
- `fotocopiadora_98.webp`: fotocopiadora autónoma de oficina.
- `dispensador_agua_98.webp`: dispensador con garrafa.
- `grapadora_98.webp`: grapadora metálica usada.
- `perforadora_98.webp`: perforadora pesada de dos agujeros.

Los ficheros viven en `godot/assets/texturas/oficina_ai_98/`.

## Origen y uso

Las imágenes proceden de una generación original con OpenAI ImageGen para este proyecto,
no de un pack descargado de terceros. Los términos aplicables de OpenAI asignan al usuario,
entre OpenAI y el usuario y en la medida permitida por la ley, los derechos de la salida
generada. La ficha exacta y el SHA-256 de cada WebP están en
`godot/assets/procedencia.json`.

Los recortes están limitados a un máximo de 256 px por lado y conservan canal alfa. Están
pensados para dressing lejano, billboards, interfaces, referencias de modelado o prototipos;
no son mallas 3D ni materiales PBR.

## Limitaciones visuales

La generación contiene rotulación sintética y, en algunos objetos, marcas que recuerdan o
reproducen marcas comerciales reales. No deben tratarse como identidad comercial aprobada.
Antes de usar un prop en primer plano o en una build pública conviene retirar/reemplazar esa
rotulación y revisar el recorte. También puede quedar algún píxel del fondo de estudio en
bordes complejos.

El lote no modifica todavía ninguna escena: entra como biblioteca utilizable para evitar
acoplar una decisión de colocación a la incorporación de los recursos.
