# School Classrooms Asset Pack — contrato de integración (#223)

Fuente canónica: **styloo — School Classrooms Asset Pack**  
Página: https://styloo.itch.io/classroom-asset-pack  
Licencia publicada por el autor: **Creative Commons Zero v1.0 Universal (CC0-1.0)**.

La página pública de Styloo declara sus assets como CC0. El ZIP aportado para este corte incluye `read me .txt`, pero ese **README interno no declara la licencia**: solo contiene notas técnicas de importación. Por tanto, la página del autor sigue siendo la fuente de licencia que debe quedar registrada en procedencia.

## Auditoría del ZIP real aportado

Se auditó `StylooClassroomAssetPack GLTF & FBX.zip`, no una lista inferida desde la web:

- **409 entradas**;
- SHA-256 del contenedor: `f9dd508d353783be22577331a6ece9700120319e4399b583b82ad6a7d23d0954`;
- bloques presentes: `principal office`, `computer`, `classroom`, `ArtRoom`, `catferia`, `chemestry lab`, `toilet` y `walls`;
- hay GLB y FBX individuales, además de `demoscene` que quedan explícitamente fuera;
- el README recomienda GLB/GLTF porque conserva mejor los materiales y avisa de que FBX puede requerir reconectar/ajustar metallic, roughness y alpha.

Los nombres, tamaños, SHA-256 y medidas auditadas de cada candidato viven en `docs/assets/school-classrooms-styloo.manifest.json`. Así #223 deja de depender de nombres aproximados o de volver a inspeccionar el ZIP manualmente.

## Primer lote: seis piezas administrativas

No importar el pack completo ni ninguna demo scene. El lote `administrativo` conserva el alcance pequeño del primer corte, ahora con rutas exactas:

| ID | Miembro exacto dentro del ZIP | Tamaño | Complejidad auditada |
| --- | --- | ---: | ---: |
| `desk` | `principal office/GLTF/PRINCIPALOFFICEdesk.glb` | 139.060 B | 3.738 vértices / 3.452 caras |
| `principal_chair` | `principal office/GLTF/PRINCIPALOFFICEprincipalchair.glb` | 298.200 B | 7.429 / 8.800 |
| `shelf` | `principal office/GLTF/PRINCIPALOFFICEshelf.glb` | 279.404 B | 7.546 / 5.412 |
| `telephone` | `principal office/GLTF/PRINCIPALOFFICEtelephone.glb` | 862.604 B | 22.588 / 21.362 |
| `old_pc` | `computer/GLTF/COMPUTERpcold.glb` | 62.848 B | 1.504 / 1.026 |
| `printer` | `computer/GLTF/COMPUTERprinter.glb` | 132.296 B | 3.411 / 2.420 |

El teléfono es de disco y la familia informática `old` usa silueta de torre/CRT, por lo que son candidatos visualmente coherentes con 1998. Esto sigue siendo una **preselección**: la lectura definitiva de materiales, escala y encaje artístico se hace dentro de Godot, no a partir del nombre del fichero.

### Contexto informático opcional

Un PC de 1998 no se lee bien si solo aparece la torre. El manifiesto separa un lote `contexto_informatico_1998` con `COMPUTERscreenold.glb`, `COMPUTERkeyboard.glb` y `COMPUTERmouse.glb`. No se añaden por defecto al staging para que el PR binario pueda seguir siendo pequeño.

Se mantienen fuera `COMPUTERpc.glb`, `COMPUTERscreen.glb`, `COMPUTERrouter.glb` y las memorias USB: no hacen falta para este corte y son temporalmente más ambiguos.

## Corte escolar posterior ligado a #284

El lote `escuela_sueno` fija dos piezas separadas del lote administrativo:

- `classroom/GLTF/locker.glb`;
- `classroom/GLTF/blackboardbig.glb`.

Sirven para reforzar la identidad escolar de #284, pero #284 debe **componer la escena escolar propia** en Godot con geometría, iluminación, sonido e interacciones propias. No se reutilizará `classroom_demoscene` ni ninguna otra escena completa del pack; #284 ya tiene lógica y composición propias y estos assets solo pueden sustituir o enriquecer presentación concreta.

## Hallazgos de escala y coste

La auditoría geométrica confirma que **no hay que asumir importación 1:1**. Los extents crudos obtenidos del GLB son, entre otros:

- `desk`: `5.302 × 2.248 × 2.367`;
- `principal_chair`: `1.267 × 2.163 × 1.164`;
- `shelf`: `4.808 × 3.838 × 1.165`.

Si se interpretan como metros, son demasiado grandes para mobiliario normal. No se fija un factor global porque las proporciones auditadas tampoco justifican aplicar uno a ciegas. Cada pieza debe medirse en Godot contra personaje, puertas, techo y mobiliario ya integrado.

También hay props pequeños con bastante geometría: `telephone` tiene **22.588 vértices**, `old_monitor` 12.064 y `keyboard` 14.953. Para el acabado PSX conviene evitar duplicarlos masivamente. Si se usan como fondo repetido, el siguiente corte debería evaluar simplificación/LOD o reservarlos para primeros planos.

## Preparación reproducible sin tocar runtime

El script `scripts/preparar_school_classrooms_styloo.py` valida el ZIP por SHA-256 y, después, cada GLB permitido por tamaño y hash. Solo escribe en staging; nunca escribe directamente en `godot/assets` ni fabrica punteros LFS.

Validación del lote administrativo:

```bash
python3 scripts/preparar_school_classrooms_styloo.py \
  "/ruta/StylooClassroomAssetPack GLTF & FBX.zip" \
  --dry-run
```

Preparar además el conjunto mínimo de PC de 1998:

```bash
python3 scripts/preparar_school_classrooms_styloo.py \
  "/ruta/StylooClassroomAssetPack GLTF & FBX.zip" \
  --lote administrativo \
  --lote contexto_informatico_1998
```

La salida por defecto es `dist/.cache/styloo-classrooms/` e incluye `styloo-classrooms-staging.json` con fichas de procedencia sugeridas. Si el ZIP fue reempaquetado pero conserva exactamente los GLB auditados, `--aceptar-reempaquetado` permite validar por fichero en vez de confiar en el hash del contenedor.

## Integración real: procedencia y Git LFS

Cuando se haga el PR binario, cada fichero que entre bajo `godot/assets/` debe tener una entrada propia en `godot/assets/procedencia.json` con ruta, título, autor `styloo`, licencia `CC0-1.0`, la URL de fuente y el SHA-256 del GLB exacto.

Los `.glb`/`.fbx` y texturas binarias deben entrar mediante **Git LFS real** conforme a `.gitattributes`. El staging no sustituye ese paso. No se debe crear un puntero LFS si no se puede subir también el objeto al almacén LFS.

Antes de integrar cada pieza:

- validar escala desde cámara jugable;
- revisar materiales y backface culling según las notas del README;
- comprobar coherencia con 1998;
- decidir si la complejidad geométrica encaja con el rol del prop;
- usar overrides/materiales del proyecto antes que modificar destructivamente el GLB fuente;
- ejecutar importación Godot, suite, recorrido, arranque y pruebas Python;
- validar visualmente clipping y legibilidad.

#223 permanece abierto hasta que el lote administrativo aprobado se incorpore con Git LFS + procedencia real y pase validación visual en Godot. Este corte elimina la incertidumbre sobre qué hay en el ZIP y cómo preparar exactamente esos binarios, pero no finge que ya estén integrados.

Refs #216 #223 #284 #399

— Odiseo (GPT-5.6 Sol)
