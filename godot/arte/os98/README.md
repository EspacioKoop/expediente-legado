# OS98 · pack visual

Assets originales del falso escritorio corporativo de 1998 de **Expediente Legado**.

## Producción

- `wallpaper.svg`: fondo vivo del escritorio, escalable y sin texto horneado.
- `system_mark.svg`: marca pixel-art usada por el shell.
- `iconos_32.svg` / `iconos_16.svg`: atlas principal (`siga`, `equipo`, `documentos`, `red`, `papelera`, `ayuda`).
- `cursores_32.svg`: cursores `normal`, `ayuda`, `ocupado`, `seleccionar`, `texto` y `no-disponible`.
- `iconos_utilidades_32.svg`: correo, configuración, impresora, notas, calendario, buscar, ejecutar y apagar.
- `bandeja_16.svg`: volumen, red, correo, sincronización y alertas.
- `texturas_ui.svg`: muestras de panel, papel, rejilla, borde de ventana y barra de título.

Los atlas de utilidades y bandeja son **recursos preparados**, no accesos del escritorio: solo deben mostrarse cuando exista una función real asociada. El shell actual usa SIGA-98, Ayuda, la marca, el wallpaper y el cursor normal.

## Web 1998 / navegador (#537)

- `navegador_controles_16.svg`: atlas 10×16 con atrás, adelante, recargar, parar, inicio, historial, favoritos, buscar, enlace y error.
- `web_destinos_32.svg`: atlas 10×32 para portal institucional, directorio/buscador, deportes, meteo, tecnología, ocio, clasificados, página personal, intranet y error.
- `prensa_cabeceras_98.svg`: cuatro cabeceras ficticias de 468×60 (`La Plaza`, `Diario Central`, `El Horizonte`, `Gaceta Mercantil`) pensadas para recibir titulares y encuadres editoriales desde datos, no desde la imagen.
- `web_badges_88x31.svg`: ocho micro-badges de época para 800×600, sin marcos, web local, en obras, mirror, intranet, archivo y actualizado.

Los SVG web se entregan como atlas con grupos identificados y tamaños regulares para que Godot pueda recortarlos por región sin duplicar ficheros. Las cabeceras no codifican una etiqueta ideológica: la lectura política debe seguir naciendo del tratamiento editorial definido por #537.

## Dirección visual

La segunda pasada parte del asset sheet aprobado en la sesión de diseño: estética de estación corporativa de 1998, iconografía pixel-art legible, azules petróleo/acero, crema y acentos de color limitados. Los SVG de producción reinterpretan esa lámina como geometría propia y versionable; no copian iconos ni marcas de Windows/Microsoft.

El PNG de referencia no se versiona: `.gitattributes` exige Git LFS para PNG nuevos y no se crea un puntero LFS sin poder subir también el objeto. Por eso los recursos integrables se trasladaron a SVG.
