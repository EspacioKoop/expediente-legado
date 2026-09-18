# Gilgamesh — arte propio (#436)

Assets vectoriales creados para el sueño de Gilgamesh y su contraparte de vigilia.

- `fragmento_*.svg`: cuatro motivos visuales del puzzle (`puerta`, `sello`, `ola`, `archivo`).
- `muralla_ladrillo_archivo.svg`: material híbrido para la transición entre ciudad y archivo SIGA.
- `sellos_siga_oniricos.svg`: sellos administrativos ficticios, sin contenido factual.
- `libro_reproduccion_tablilla.svg`: lámina del libro/reproducción de vigilia.
- `cielo_hoja_mecanografiada.svg`: textura de cielo mecanografiado imposible.

## Integración

`res://escenas/sueno_gilgamesh.tscn` usa la muralla híbrida, los sellos y el cielo mecanografiado como capa ambiental. `SuenoGilgamesh` conecta además los cuatro `fragmento_*.svg` a las piezas y a sus anclas dinámicas: cada motivo cuelga del mismo `MeshInstance3D` que gobierna el puzzle, así que al resolver una pieza su lámina desaparece con ella y no puede quedar desincronizada del progreso. `res://escenas/gilgamesh_arte_preview.tscn` se conserva como vista de revisión del paquete gráfico. La lámina de vigilia sigue siendo únicamente material de revisión hasta que el libro necesite un pase visual específico.

## Origen y licencia

Obra original generada específicamente para este repositorio a partir de la dirección visual del issue #436 y de la paleta ya presente en `sueno_gilgamesh.gd`. No incorpora imágenes, logotipos, tipografías incrustadas ni material de terceros.

Los signos tipo cuña y códigos administrativos son decorativos y ficticios: no pretenden transcribir cuneiforme ni afirmar hechos históricos.

Se distribuyen bajo la misma licencia del repositorio (GPL-2.0).
