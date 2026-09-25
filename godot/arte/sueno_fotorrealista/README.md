# Kit 3D onírico de microdetalle PBR (#87)

Primer lote autónomo de props para sueños. La intención no es aumentar polígonos por
sí mismos, sino conservar siluetas reconocibles y obtener volumen por iluminación,
rugosidad, metal, humedad, suciedad y emisión.

## Piezas

- archivador_humedo.tscn: archivador metálico de cuatro cajones con vetas húmedas;
- crt_condensacion.tscn: televisor CRT sin marca, con cristal húmedo y condensación;
- fluorescente_oxidado.tscn: luminaria oxidada con tubo emisivo y luz local barata;
- silla_reflejo.tscn: silla doméstica/oficina con un segundo volumen imposible que
  funciona como reflejo desfasado.

Cada escena declara metadata/origen_reconocible para mantener el contrato de #87:
el sueño deforma una familia ya vista o manipulada, no fabrica una fuente narrativa
nueva.

## Material común

material_microdetalle.gdshader es un spatial shader PBR sin texturas binarias.
Introduce variación procedural de albedo y roughness, suciedad de baja frecuencia,
vetas húmedas, metalicidad y emisión. Esto permite un acabado más físico con un
presupuesto geométrico pequeño y mantiene el lote revisable directamente en Git.

No contiene logos, marcas reales, texto diegético ni hechos de expedientes.

## Integración

Este corte no modifica SuenoUtileria, dia.tscn ni controladores compartidos porque
esas rutas tienen reservas activas. Las cuatro escenas quedan listas para
instanciarse como PackedScene en un corte posterior de #87 una vez exista una
reserva libre para la integración.

Al integrarlas:
1. elegir la escena por el ID ya registrado en ObjetosOniricos;
2. no superar el máximo actual de anomalías por sala;
3. conservar objeto_origen/documento_origen cuando corresponda;
4. aplicar la deformación espacial desde el controller, no duplicar lógica aquí;
5. validar desde cámara jugable y con reduccion_movimiento.

## Coste

Las piezas usan únicamente BoxMesh, CylinderMesh, un OmniLight3D barato en la
luminaria y un shader común. No añaden GLB, PNG, normal maps ni nuevas dependencias
de LFS.
