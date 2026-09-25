# Evidencia visual de Traffic Road Assets · #225

Este gate convierte la validacion visual pendiente de #225 en un conjunto
reproducible del mismo build que se esta revisando. No modifica el lote ni el
gameplay: abre la escena real `dia.tscn`, entra en `trayecto`, usa la camara
jugable a 1280x720 / FOV 75, oculta el HUD y captura cuatro vistas.

## Artifact

El workflow **Evidencia trafico vial 225** publica:

- `barrera_conos.png`: conjunto de barrera y dos conos desde el eje jugable;
- `tapa_sur.png`: detalle de la tapa situada al sur del recorrido;
- `tapa_norte.png`: detalle de la tapa situada al norte;
- `paso_central.png`: lectura longitudinal del corredor principal;
- `manifest.json`: las cinco instancias CC0, sus AABB visuales en metros,
  cobertura por frustum, posicion en pantalla por vista y SHA-256 de cada PNG.

La cobertura de frustum demuestra que el encuadre apunta a las piezas que debe
mostrar. No intenta inferir oclusion ni calidad artistica.

## Revision humana

Para cada PNG registrar **pass/fail** y, si falla, la pieza concreta:

1. **Epoca:** conos, barrera y tapas no introducen una silueta, acabado o color
   que se lea como claramente posterior a 1998 o impropio del entorno.
2. **Escala:** la barrera (1,10 m), los conos (0,65 m) y las tapas (0,70 m de
   diametro) guardan proporciones plausibles con el jugador, asfalto y bordes.
3. **Clipping:** las tapas no presentan z-fighting; barrera y conos no se
   interpenetran entre si ni con geometria urbana de forma visible.
4. **Legibilidad:** el lote se entiende como dressing secundario, no como
   objetivo interactivo, y el paso central sigue siendo visualmente claro.
5. **Conjunto:** la calle conserva su identidad y profundidad; estas cinco
   piezas no forman un bloque reconocible del pack ni dominan la composicion.

El manifiesto y el workflow detectan regresiones objetivas de montaje y
encuadre, pero tienen `veredicto_automatico=false`. **No cierra #225** por si
solo: el cierre sigue requiriendo revision humana de estas capturas (o una Alpha
representativa) y puede registrarse tambien en el gate transversal #398.
