# Props PBR reutilizables — #435

Segunda capa del paquete visual de mitologías oníricas. A diferencia del muestrario de materiales de #1414, estas piezas ya tienen **volumen 3D procedural** y usan los PBR propios del proyecto.

## Piezas

- `tablilla_uruk()`: tablilla rota con marcas abstractas; útil en #436.
- `archivador_onirico()`: archivador oxidado con cajones abiertos y papel; útil en #437 y cruces SIGA/sueño.
- `panoplia_aquiles()`: escudo, greba y marca del talón; útil en #438.
- `busto_hidra()`: cinco cuellos/cabezas con escama PBR y detalles de bronce; útil en #439.
- `compuerta_ryu()`: mecanismo de jade/metal/bronce; útil en #440.
- `balanza_duat()`: balanza monumental reutilizable; útil en #441.
- `legajo_siga()`: paquete de documentos atado/sellado para hibridaciones burocráticas de cualquiera de las familias.

## Contrato

Los props no:
- registran semillas;
- seleccionan familias;
- resuelven puzzles;
- leen input;
- crean HUD;
- revelan hechos de expedientes.

Son escenografía reutilizable. El gameplay sigue viviendo en los verticales existentes.

## Rendimiento

Se construyen con `BoxMesh`, `CylinderMesh` y `SphereMesh`, con segmentación moderada. Los materiales se duplican de los `.tres` PBR de #1414 para evitar mutaciones globales.
