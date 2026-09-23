# Evidencia visual del hogar · #227

Este gate convierte la validacion visual pendiente de #227 en un conjunto
reproducible del mismo build que se esta revisando. No modifica la vivienda,
el pack ni el gameplay: abre la escena real dia.tscn, entra en casa,
usa la camara jugable a 1920x1080 / FOV 70, oculta el HUD y captura cuatro zonas.

## Artifact

El workflow **Evidencia hogar 227** publica:

- entrada.png: aparador y lampara del recibidor;
- estar.png: sofa CC0, mesa baja y mueble de TV;
- dormitorio.png: armario wardrobe_01 junto al recorrido hacia la cama;
- cocina_comedor.png: mesa, tres sillas y los electrodomesticos seleccionados;
- manifest.json: las 15 instancias domesticas que materializan los 13 GLB del
  lote, su zona y los encuadres cuyo frustum contiene el centro de cada objeto.

Las tres sillas reutilizan chair_01; el sofa reutiliza 2_seat_sofa_01 sobre
SofaCasa/VisualHogar. Por eso el inventario visual tiene 15 instancias aunque el
lote contenga 13 modelos distintos.

La comprobacion de frustum usa la camara real para demostrar que cada encuadre
apunta a su zona. No intenta inferir oclusion ni calidad visual: que un centro
este dentro del frustum no prueba por si solo que el objeto este bien compuesto.

## Revision humana

Para cada PNG registrar **pass/fail** y, si falla, el objeto concreto:

1. **Escala:** muebles y electrodomesticos guardan proporciones plausibles entre
   si, con el jugador y con puertas/encimeras.
2. **Clipping:** no hay interpenetraciones visibles con paredes, suelo,
   mobiliario adyacente ni piezas funcionales ya existentes.
3. **Legibilidad:** entrada, estar, dormitorio y cocina-comedor se reconocen como
   zonas domesticas distintas sin depender del HUD.

El manifest sirve para detectar regresiones de montaje y cobertura de camara,
pero el workflow tiene veredicto_automatico=false. **No cierra #227** por si
solo: el cierre sigue requiriendo revisar visualmente estas cuatro capturas y el
armario domestico deformado del vertical casa->sueno de #967 en una Alpha
representativa.
