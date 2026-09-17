# Props 3D — sueños #284

Starter pack de **assets 3D originales del proyecto** para las cuatro familias de sueño de #284. Son escenas `.tscn` listas para instanciar en Godot 4. No incorporan mallas, texturas ni audio de terceros.

## Contenido

- `cabana_nieve.tscn`: cabaña de montaña reutilizable; el pase de #284 sustituye el cuerpo de primitivas por la malla original `cabana_nieve_psx.obj`, mantiene nieve, ventanas cálidas y luz interior.
- `cabana_nieve_psx.obj`: malla low-poly original y diffable con planta irregular, tejado a dos aguas, chimenea y porche; evita que la arquitectura final de montaña se lea como bloques genéricos.
- `pupitre_escolar.tscn`: pupitre escolar basado en la malla original `pupitre_escolar_psx.obj`.
- `pupitre_escolar_psx.obj`: malla original y diffable del pupitre usado por la pesadilla escolar; sustituye el montaje visible de `BoxMesh`/`CylinderMesh`.
- `taquillas_escolares.tscn`: módulo de tres taquillas basado en la malla original `taquillas_escolares_psx.obj`.
- `taquillas_escolares_psx.obj`: malla original y diffable del bloque de taquillas escolares.
- `reloj_escolar_anomalo.tscn`: reloj mural con doble juego de agujas para mutaciones del sueño.
- `archivador_desierto.tscn`: archivador metálico de cuatro cajones basado en la malla original `archivador_desierto_psx.obj`; conserva tiradores reutilizables, pero elimina el cuerpo construido con `BoxMesh`.
- `archivador_desierto_psx.obj`: malla original y diffable del archivador aislado del desierto.
- `cabina_telefono_desierto.tscn`: cabina telefónica aislada basada en `cabina_telefono_desierto_psx.obj`, con dial, auricular y panel translúcido sin estructura de cajas genéricas.
- `cabina_telefono_desierto_psx.obj`: malla original y diffable para la silueta principal de la cabina, incluido bastidor, pedestal, teléfono y cubierta a dos aguas.
- `muro_torre_castillo.tscn`: portada medieval basada en la malla original `muro_arco_castillo_psx.obj`, con arco de dovelas, contrafuertes, torres octogonales troncocónicas y cubiertas apuntadas.
- `muro_arco_castillo_psx.obj`: malla low-poly original y diffable que sustituye la fachada de primitivas del primer starter pack; no usa `BoxMesh`/`CylinderMesh` como arquitectura visible.
- `escalera_anular_castillo.tscn`: versión reutilizable de la escalera imposible basada en la malla original `escalera_anular_castillo_psx.obj`.
- `escalera_anular_castillo_psx.obj`: escalera anular low-poly original; asciende alrededor de un núcleo octogonal y, sin cambiar de sentido, empieza a descender en los últimos peldaños.
- `estandarte_anular.tscn`: estandarte rojo con emblema anular 3D separado.
- `patio_castillo_onirico.tscn`: composición base con tres portadas, escalera imposible, dos estandartes y una iluminación de patio contenida.
- `galeria_scriptorium_castillo.tscn`: ala de archivo/scriptorium compuesta con las mismas portadas y escalera; concentra el códice conocido sin añadir narrativa nueva.
- `torre_capilla_castillo.tscn`: lectura vertical imposible que apila umbrales y dos escaleras a distinta altura sin crear una segunda navegación.
- `claustro_reflejado_castillo.tscn`: claustro de arcadas repetidas con una portada elevada, dos escaleras enfrentadas y un estandarte invertido; funciona como ala de transición sin añadir colisión propia.

## Uso

Cada fichero es una pieza independiente. Puede instanciarse directamente o abrirse y copiar sus nodos a una escena mayor. Los materiales siguen siendo editables para que el pase final pueda introducir texturas, desgaste o paleta específica sin rehacer la geometría.

El castillo dispone ahora de cuatro composiciones sobre el mismo lenguaje arquitectónico: patio, scriptorium, torre/capilla y claustro reflejado. `SuenoCastillo` selecciona la lectura y una mutación secundaria de forma determinista; `SuenoCastillo3D` puede desfazar, contraer/estirar o girar la composición sin tocar la física ANULAR. Así una misma ala puede reaparecer con pequeñas contradicciones espaciales, en vez de funcionar como un preset fijo. Tras #587 y #755, esta vertical cubre la necesidad que motivó #296; PSX Going Medieval y Fantasy Props MegaKit quedan como **reserva opcional**, no como dependencia ni deuda de importación.

La montaña se compone en runtime desde `SuenoMontana3D`: la familia CONVERGENTE conserva la única colisión, mientras la presentación añade cima nevada, laderas, mar de nubes, huellas anticipadas, documento congelado y la cabaña de este directorio.

El desierto se compone en runtime desde `SuenoDesierto3D`: `SuenoDesierto` sustituye la planta histórica de `peine` por el contorno caminable de la familia FRAGMENTADA antes de que `Espacio3D` construya la sala. La presentación mantiene esa única física y añade arena, dunas lejanas, huellas geométricas, sombra sin objeto, papel semienterrado, cabina, archivador y una estructura de horizonte que conserva distancia aparente. El sonido es procedural: viento con ecos de oficina, tono telefónico y una zona local donde ambos desaparecen.

La escuela se compone en runtime desde `SuenoEscuela3D`: reutiliza la planta `crucero` como dos pasillos escolares cruzados y conserva esa física invisible. La presentación se reconstruye con linóleo, zócalo verde, paredes crema, fluorescentes, puertas numeradas, pupitres, taquillas, pizarra y reloj. Con cada timbre procedural se reordenan las puertas/números y los pupitres pasan a mirar hacia la pared opuesta; una tercera aguja gira a contratiempo y las voces procedurales vienen de un aula vacía. El dibujo del pupitre interactivo reutiliza una frase ya conocida por #87.

#223 sigue siendo el corte independiente para una futura importación del School Classrooms Asset Pack mediante Git LFS + ficha de procedencia/hash. La vertical escolar de #284 **no depende** de ese pack ni incorpora binarios externos.

El feedback de playtest de `c2b4b714` descarta que la arquitectura final del sueño se lea como asset genérico estilo "Minecraft". Por eso castillo, montaña, desierto y escuela pasan a presentación propia antes de usarse como acabado final.

## Procedencia

Contenido original creado específicamente para `EspacioKoop/expediente-legado`; no deriva de packs externos. Por eso vive fuera de `godot/assets/`, cuyo registro `procedencia.json` está reservado al material de terceros.

Refs #284 #87 #223 #279 #296 #947
