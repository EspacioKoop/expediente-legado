# Chill Vibes Art Jam 4 — contrato de integración (#220)

Fuente canónica: **psychic_magpie — Common game assets [Chill Vibes Art Jam 4]**  
Página: https://psychic-magpie.itch.io/chill-vibes-art-jam-4  
Licencia publicada por el autor: **Creative Commons Zero v1.0 Universal (CC0-1.0)**.

## La descarga real es bastante mayor que la ficha pública

La página de itch todavía enumera solo un palé, imágenes `TNT`/`?` y humo. El `.7z` aportado para este corte es una revisión posterior del pack y contiene bastante más material. Se auditó el archivo real, no una lista inferida desde la web:

- archivo: `Common game assets [Chill Vibes Art Jam 4].7z`;
- SHA-256: `fdeadea99cf98bac3c77787ae85b5befb3a0df5de084177387896fb32a3bdf82`;
- **79 ficheros**;
- **28 GLB** y 15 familias 3D;
- además: 15 `.blend`, 19 PNG, 16 SVG y `README.txt`;
- el README interno documenta modelos, UV, blendshapes y piezas articuladas, pero **no declara la licencia**; la fuente de licencia sigue siendo la página pública del autor.

Las familias 3D presentes son: barrel, button, CCTV camera, cinder block, concrete barrier, crate, crowbar, flashlight, lever, radio, shipping container, shipping pallet, street light, tire y traffic cone.

El manifiesto `docs/assets/chill-vibes-art-jam-4.manifest.json` fija rutas, tamaño, SHA-256, extents y complejidad de una pieza representativa de cada familia para no tener que redescubrir el contenido del pack.

## Primer corte: dressing de servicio realmente pasivo

El lote `dressing_servicio` mantiene #220 pequeño y evita llenar la escena con objetos que prometen interacción:

| ID | Pieza | Tamaño | Triángulos | Extents crudos |
| --- | --- | ---: | ---: | --- |
| `pallet` | shipping pallet | 42.800 B | 616 | 0,80 × 0,144 × 1,20 |
| `crate` | crate | 17.876 B | 188 | 1,00 × 1,00 × 1,00 |
| `barrel` | barrel solid color | 63.488 B | 558 | 0,60 × 0,876 × 0,60 |
| `cinder_block` | cinder block | 19.028 B | 276 | 0,406 × 0,203 × 0,203 |
| `concrete_barrier` | concrete barrier | 7.364 B | 84 | 1,00 × 0,813 × 0,610 |
| `traffic_cone` | traffic cone | 28.400 B | 384 | 0,491 × 0,750 × 0,491 |

Los seis GLB usan sobre todo materiales simples sin texturas externas. Son buenos candidatos para adaptar paleta/material mediante overrides SIGA-98 sin modificar destructivamente la fuente.

La intención no es colocar los seis de golpe. En una escena concreta conviene empezar con **palé + caja + una tercera pieza funcionalmente justificada**, variar orientación/escala de forma moderada y medir si mejoran la lectura del lugar. Duplicar props hasta “llenar” no satisface #400.

## Segundo nivel: infraestructura, no relleno genérico

`infraestructura_servicio` conserva piezas útiles pero más dependientes del lugar:

- **CCTV**: dos nodos y cámara articulable; encaja en archivo/servicio si su posición explica vigilancia o circulación.
- **shipping container**: 4.234 triángulos y 6,20 m de largo; mejor para exterior/carga que para pasillo interior.
- **street light**: 5,0 m de alto; pertenece a calle, patio o acceso, no a almacén interior.
- **tire**: usa imagen embebida para el relieve; solo tiene sentido en garaje, mantenimiento o exterior concreto.

Este lote no se añade al staging por defecto.

## Tercer nivel: piezas que deberían responder al jugador

`interactivos_potenciales` separa radio, palanca, botón, linterna y palanca de uña/crowbar del dressing muerto. Son visualmente reutilizables, pero su forma hace esperar una función.

El propio GLB ya conserva información aprovechable:

- `radio`: 3 nodos y 18 morph targets; el README indica aguja/antena y diales manipulables;
- `lever`: 2 nodos; la palanca puede rotarse independientemente;
- `button`: 2 morph targets para el pulsador;
- `flashlight`: 6 morph targets y una imagen embebida;
- `crowbar`: geométricamente barato, pero semánticamente fuerte.

No deben entrar en #220 como decoración silenciosa. Si se usan, conviene enlazarlos con una interacción o sistema dueño del comportamiento y relacionar el issue correspondiente.

## Qué queda fuera de este corte

- `TNT` y `?`: demasiado semánticos o poco diegéticos para dressing genérico.
- warning labels: útiles para una zona técnica concreta, pero deben decidirse por escena para evitar señalética gratuita o lectura de peligro falsa.
- smoke: VFX; no pertenece a este PR de props.
- variantes de caja, barril, neumático y contenedor: el manifiesto escoge una sola representante para evitar importar combinaciones por inercia.
- `.blend`: no hacen falta para runtime si el GLB funciona; además están cubiertos por LFS y pesan bastante más.

## Preparación reproducible sin tocar runtime

`preparar_chill_vibes_cc0.py` trabaja sobre el directorio extraído y valida cada GLB por tamaño + SHA-256. Opcionalmente también valida el `.7z` original. Solo escribe staging en `dist/.cache`; no toca `godot/assets`, procedencia ni runtime.

Ejemplo:

```bash
7z x "Common game assets [Chill Vibes Art Jam 4].7z" -o/tmp/chill-vibes
python3 scripts/preparar_chill_vibes_cc0.py \
  /tmp/chill-vibes \
  --archivo "Common game assets [Chill Vibes Art Jam 4].7z" \
  --dry-run
```

Preparar el lote pasivo:

```bash
python3 scripts/preparar_chill_vibes_cc0.py /tmp/chill-vibes
```

Para revisar también infraestructura de servicio:

```bash
python3 scripts/preparar_chill_vibes_cc0.py /tmp/chill-vibes \
  --lote dressing_servicio \
  --lote infraestructura_servicio
```


## Materialización local con Git LFS real

Tras #1039, el paso binario queda automatizado por `scripts/materializar_chill_vibes_cc0.py`. El comando es deliberadamente conservador: por defecto hace *dry-run*; con `--aplicar` exige un checkout Git real, instala LFS solo en ese checkout, comprueba `filter=lfs` para cada destino, rechaza rutas con cambios locales/staged y no hace commit, push ni merge.

Dry-run del lote pasivo:

```bash
python3 scripts/materializar_chill_vibes_cc0.py /tmp/chill-vibes --repo .
```

Materialización real, después de revisar el plan:

```bash
python3 scripts/materializar_chill_vibes_cc0.py /tmp/chill-vibes \
  --archivo "Common game assets [Chill Vibes Art Jam 4].7z" \
  --repo . \
  --aplicar
```

La operación:

- copia únicamente los GLB del allowlist a `godot/assets/modelos/chill_vibes/`;
- vuelve a verificar el SHA-256 después de copiar;
- fusiona las fichas en `godot/assets/procedencia.json` sin duplicar rutas;
- conserva `archivo_origen` y `paquete_sha256`;
- ejecuta `git add` solo sobre los GLB elegidos y procedencia;
- lee cada blob desde el índice y exige el puntero LFS canónico con el mismo OID SHA-256 y tamaño;
- ante un fallo posterior a la escritura, intenta retirar el staging y restaurar los ficheros afectados.

Esto **no autoriza por sí solo a importar el lote completo**: la selección final sigue ligada a una escena concreta y al gate de #181.


## Integración real cuando una escena lo justifique

#181 sigue priorizando validar el saneamiento P0 antes de expandir decoración opcional. Por eso este corte **audita y prepara**, pero no versiona todavía GLB ni cambia escenas.

Cuando una zona real de carga/servicio necesite estas piezas:

1. escoger 2–3 assets como máximo para el primer pase;
2. validar escala y lectura desde cámara jugable;
3. aplicar materiales/overrides coherentes con #399 y el tratamiento PSX existente;
4. copiar únicamente los GLB elegidos a `godot/assets/modelos/chill_vibes/`;
5. registrar una ficha por fichero en `godot/assets/procedencia.json`, incluyendo SHA-256 del GLB y del paquete fuente;
6. añadir los binarios mediante **Git LFS real**; nunca fabricar solo el puntero;
7. colocar las piezas como parte de una composición funcional, no como dispersión aleatoria;
8. capturar/validar si mejoran #220/#400 antes de ampliar el lote.

Así el pack sí es útil, pero como **biblioteca curada**. El valor nuevo del archivo aportado es que #220 ya no depende de una ficha web incompleta y puede elegir piezas concretas con hashes y coste conocidos.

Refs #181 #216 #220 #399 #400

— Odiseo (GPT-5.6 Sol)
