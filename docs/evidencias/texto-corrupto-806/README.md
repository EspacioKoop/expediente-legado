# Evidencia visual · texto corrupto narrativo #806

Este gate cubre el criterio visual pendiente de #806 sin añadir estado de QA al
juego ni versionar PNG binarios.

El workflow **Evidencia texto corrupto 806** renderiza dos superficies reales
que ya consumen el efecto narrativo integrado:

- `documento-os98.png`: `ExploradorSiga` real con su
  `RichTextLabel` `VisorDocumento`, mostrado en un estado de contaminación
  alta;
- `rotulo-3d.png`: `ArchivadorInteractivo3D` real con el
  `Label3D` `DestinoArchivado`, usando el mismo contrato de contaminación.

El artifact incluye también `manifest.json` con el texto fuente, el texto
visual resultante, la superficie concreta y SHA-256 de cada PNG. El runner falla
si alguna de las dos superficies no se renderiza o si el efecto no llega a
alterar visualmente el texto.

## Revisión humana

El workflow demuestra que el efecto puede renderizarse de extremo a extremo,
pero no decide si el resultado artístico es bueno. Para cerrar #806 hay que
abrir **ambas** imágenes del mismo artifact y registrar una revisión humana:

1. **Documento OS98:** la corrupción debe percibirse como intencionada y todavía
   permitir reconocer que existe un documento debajo del ruido narrativo.
2. **Rótulo 3D:** el efecto debe leerse sobre una superficie del mundo y no como
   un error de fuente o clipping.
3. **Coherencia:** ambas capturas deben compartir vocabulario visual
   (repeticiones, sustituciones/intercalado) y sentirse parte de la misma
   contaminación.
4. **Legibilidad:** la degradación no debe sugerir que información crítica queda
   inaccesible; la política de reducción de movimiento/contenido crítico está
   cubierta además por las regresiones runtime de #1339, #1341 y #1346.

Formato sugerido para el comentario de cierre:

```text
Validación visual #806
- Documento OS98: PASS/FAIL — motivo breve
- Rótulo 3D: PASS/FAIL — motivo breve
- Coherencia entre superficies: PASS/FAIL — motivo breve
```

Un artifact verde prepara esa revisión; no autoaprueba ni cierra el issue.
