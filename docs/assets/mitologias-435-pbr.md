# Materiales PBR originales para mitologías oníricas (#435)

Paquete de superficies creado dentro del proyecto para vestir los verticales 3D de #435 sin incorporar scans, fotografías, logos ni diseños de terceros.

## Contenido

| Material | Uso principal | Uso secundario |
| --- | --- | --- |
| `arcilla_uruk` | Gilgamesh: tablillas, muros, fragmentos | Duat: pesos terrosos |
| `metal_archivo_oxidado` | Minotauro: archivadores/pasillos | Hidra: burocracia regenerativa |
| `bronce_votivo` | Aquiles: figura, herrajes | Duat: balanza y cadenas |
| `escama_hidra` | Hidra: presencia/cabezas | mezclas oníricas orgánicas |
| `jade_ryu_humedo` | Ryū: cuerpo/ornamento húmedo | arquitectura suspendida |
| `caliza_duat` | Duat: pirámides, basas, arquitectura | Gilgamesh: piedra monumental |
| `papel_archivo_envejecido` | formularios, tiras, sellos, documentación | todas las familias híbridas con SIGA |

Cada material tiene albedo, normal y roughness a 512×512 en SVG tileable, más un `.tres` listo para `StandardMaterial3D`. La escena `preview_materiales.tscn` sirve como muestrario rápido en Godot.

## Dirección visual

El objetivo es lectura **PBR/fotorealista a escala de material**, no convertir el sueño en un diorama histórico. Las superficies conservan desgaste, variación de rugosidad y microrelieve, pero siguen siendo compatibles con geometría procedural de bajo coste y con la dirección SIGA-98.

No se introducen hechos históricos ni iconografía de adaptaciones modernas concretas: son superficies genéricas propias para arcilla, metal pintado, bronce, escama, jade, caliza y papel.

## Procedencia y licencia

- Autoría: material original generado específicamente para este repositorio.
- Fuentes externas: ninguna.
- Dependencias externas: ninguna.
- Licencia: MIT, como el código/textos/datos propios del repositorio según `LICENSE`.
- No requiere entrada en `godot/assets/procedencia.json` porque no es material de terceros.

## Integración recomendada

No sustituir lógica de los verticales. Aplicar los `.tres` como `material_override` a las geometrías existentes:

- #436 Gilgamesh: `arcilla_uruk` + `papel_archivo_envejecido`.
- #437 Minotauro: `metal_archivo_oxidado` + `papel_archivo_envejecido`.
- #438 Aquiles: `bronce_votivo`.
- #439 Hidra: `escama_hidra` + `metal_archivo_oxidado`.
- #440 Ryū: `jade_ryu_humedo` y metal en compuertas/pasarelas.
- #441 Duat: `caliza_duat` + `bronce_votivo`.

Los mapas están diseñados para repetirse. Ajustar `uv1_scale` en cada material antes de duplicar geometría o crear variantes paralelas.
