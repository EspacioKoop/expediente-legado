# Props 3D — sueños #284

Starter pack de **assets 3D originales del proyecto** para las cuatro familias de sueño de #284. Son escenas `.tscn` listas para instanciar en Godot 4 y están construidas únicamente con primitivas/materiales del motor: no incorporan mallas, texturas ni audio de terceros.

## Contenido

- `cabana_nieve.tscn`: cabaña reconocible con tejado nevado, chimenea, puerta, ventanas cálidas, porche y carámbanos.
- `pupitre_escolar.tscn`: pupitre escolar completo con tablero, faldón y estructura metálica.
- `taquillas_escolares.tscn`: módulo de tres taquillas con puertas, respiraderos y tiradores.
- `reloj_escolar_anomalo.tscn`: reloj mural con doble juego de agujas para mutaciones del sueño.
- `archivador_desierto.tscn`: archivador metálico de cuatro cajones con tiradores.
- `cabina_telefono_desierto.tscn`: cabina telefónica aislada con bastidor, techo, teléfono y auricular.
- `muro_torre_castillo.tscn`: módulo de muralla con torre circular, almenas y puerta de madera.
- `escalera_anular_castillo.tscn`: escalera modular que puede montarse para invertir altura o cerrar bucles.
- `estandarte_anular.tscn`: estandarte rojo con emblema anular 3D separado.

## Uso

Cada fichero es una escena independiente. Puede instanciarse directamente o abrirse y copiar sus nodos a una escena mayor. Los materiales son deliberadamente sencillos y editables para que el pase final pueda sustituirlos por materiales coherentes con la dirección artística sin rehacer la geometría.

Los assets están pensados como base jugable, no como sustituto del pase final de arte. La escena final de #284 sigue teniendo que evitar el aspecto de greybox y cumplir la regla de extrañeza del issue.

## Procedencia

Contenido original creado específicamente para `EspacioKoop/expediente-legado`; no deriva de packs externos. Por eso vive fuera de `godot/assets/`, cuyo registro `procedencia.json` está reservado al material de terceros.

Refs #284 #87 #279 #296
