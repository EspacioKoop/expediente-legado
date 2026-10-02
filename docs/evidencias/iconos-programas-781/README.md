# Evidencia visual · iconos propios de programas OS98 #781

Este gate prepara la revisión visual exigida por #781 sin modificar el runtime
del escritorio ni autoaprobar el criterio artístico.

El workflow **Evidencia iconos programas 781** monta `EscritorioSigaVisual` real
a **1920×1080** y registra las siete identidades ya integradas:

- Explorador;
- Web98;
- Archivo de programas;
- Correo interno;
- Bloc de notas;
- Calculadora;
- Catálogo de anomalías.

Genera dos capturas:

- `iconos-programas-32.png`: escritorio con los siete lanzadores y su atlas
  específico de 32 px;
- `iconos-programas-16.png`: menú de programas abierto y una ventana real de
  Correo, para cubrir el atlas de 16 px en menú, barra de tareas y barra de
  título.

También publica `manifest.json` con resolución, identidades, superficies y el
marcador `veredicto_automatico=false`. El runner falla si falta cualquiera de
las siete identidades, si las celdas del atlas no corresponden al orden
canónico o si alguna captura no se puede renderizar.

## Revisión humana

El artifact verde no decide si los iconos son suficientemente claros. Antes de
valorar el cierre de #781 hay que abrir ambas capturas y registrar una revisión
humana:

1. **32 px / escritorio:** las siete aplicaciones deben distinguirse de un
   vistazo y no parecer variaciones del mismo icono.
2. **16 px / menú y ventana:** cada símbolo debe conservar identidad sin ruido,
   recortes ni formas ambiguas.
3. **Consistencia:** la versión de 16 px debe leerse como la misma aplicación
   que la de 32 px, sin depender de texto.
4. **Composición 1080p:** los iconos no deben dominar el escritorio ni perderse
   contra el wallpaper y el chrome del OS98.

Formato sugerido para el comentario de validación:

```text
Validación visual #781
- Atlas 32 px: PASS/FAIL — motivo breve
- Atlas 16 px: PASS/FAIL — motivo breve
- Consistencia entre tamaños: PASS/FAIL — motivo breve
- Lectura general a 1920×1080: PASS/FAIL — motivo breve
```

Refs #534 #781 #827 #1149.
