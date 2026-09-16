# Props 3D — sueños #284

Starter pack de **assets 3D originales del proyecto** para las cuatro familias de sueño de #284. Son escenas `.tscn` listas para instanciar en Godot 4. No incorporan mallas, texturas ni audio de terceros.

## Contenido

- `cabana_nieve.tscn`: cabaña de montaña reutilizable; el pase de #284 sustituye el cuerpo de primitivas por la malla original `cabana_nieve_psx.obj`, mantiene nieve, ventanas cálidas y luz interior.
- `cabana_nieve_psx.obj`: malla low-poly original y diffable con planta irregular, tejado a dos aguas, chimenea y porche; evita que la arquitectura final de montaña se lea como bloques genéricos.
- `pupitre_escolar.tscn`: pupitre escolar completo con tablero, faldón y estructura metálica.
- `taquillas_escolares.tscn`: módulo de tres taquillas con puertas, respiraderos y tiradores.
- `reloj_escolar_anomalo.tscn`: reloj mural con doble juego de agujas para mutaciones del sueño.
- `archivador_desierto.tscn`: archivador metálico de cuatro cajones con tiradores.
- `cabina_telefono_desierto.tscn`: cabina telefónica aislada con bastidor, techo, teléfono y auricular.
- `muro_torre_castillo.tscn`: portada medieval basada en la malla original `muro_arco_castillo_psx.obj`, con arco de dovelas, contrafuertes, torres octogonales troncocónicas y cubiertas apuntadas.
- `muro_arco_castillo_psx.obj`: malla low-poly original y diffable que sustituye la fachada de primitivas del primer starter pack; no usa `BoxMesh`/`CylinderMesh` como arquitectura visible.
- `escalera_anular_castillo.tscn`: versión reutilizable de la escalera imposible basada en la malla original `escalera_anular_castillo_psx.obj`.
- `escalera_anular_castillo_psx.obj`: escalera anular low-poly original; asciende alrededor de un núcleo octogonal y, sin cambiar de sentido, empieza a descender en los últimos peldaños.
- `estandarte_anular.tscn`: estandarte rojo con emblema anular 3D separado.
- `patio_castillo_onirico.tscn`: composición lista para pase visual con tres portadas, escalera imposible, dos estandartes y una iluminación de patio contenida.

## Uso

Cada fichero es una pieza independiente. Puede instanciarse directamente o abrirse y copiar sus nodos a una escena mayor. Los materiales siguen siendo editables para que el pase final pueda introducir texturas, desgaste o paleta específica sin rehacer la geometría.

`patio_castillo_onirico.tscn` sirve como corte de arte reconocible para integrar o validar el sueño de castillo: concentra arquitectura propia y la anomalía espacial en una sola escena sin modificar el runtime estabilizado del sueño.

La montaña se compone en runtime desde `SuenoMontana3D`: la familia CONVERGENTE conserva la única colisión, mientras la presentación añade cima nevada, laderas, mar de nubes, huellas anticipadas, documento congelado y la cabaña de este directorio.

El feedback de playtest de `c2b4b714` descarta que la arquitectura final del sueño se lea como asset genérico estilo "Minecraft". Por eso tanto el castillo como la cabaña de montaña pasan a siluetas originales antes de usarse como presentación final.

## Procedencia

Contenido original creado específicamente para `EspacioKoop/expediente-legado`; no deriva de packs externos. Por eso vive fuera de `godot/assets/`, cuyo registro `procedencia.json` está reservado al material de terceros.

Refs #284 #87 #279 #296
