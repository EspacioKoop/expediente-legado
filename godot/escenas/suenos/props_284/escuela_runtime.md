# Escuela onírica runtime (#284)

La vertical escolar reutiliza `crucero` como planta física y no cambia la selección nocturna. El contenido de #87 se construye primero y `SuenoEscuela` transforma únicamente su presentación.

## Extrañeza

- espacial: puertas y números de aula se reordenan con cada timbre;
- sonora: timbre fuera de horario y voces procedurales de un aula vacía;
- objeto: pupitres que cambian de orientación, dibujo mutante y reloj de tres agujas;
- interacción: el dibujo del pupitre devuelve una frase ya conocida, nunca una pista nueva.

## Arte y procedencia

La escena no usa el School Classrooms Asset Pack de #223. Pasillos, paredes y techo se generan desde la misma `planta` física y los props principales son mallas originales diffables del proyecto (`pupitre_escolar_psx.obj`, `taquillas_escolares_psx.obj`). #223 permanece como trabajo independiente para una eventual importación CC0 mediante Git LFS y registro de hash/procedencia.

## Física

`SuenoEscuela3D` no crea `StaticBody3D` ni `CollisionShape3D`: oculta solo las mallas visibles de la geometría base y la sustituye por una presentación escolar alineada con `Planta.celdas()`/`Planta.contorno()`.
