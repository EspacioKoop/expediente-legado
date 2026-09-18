# Street Furniture (Kkryy): mobiliario y props utilizables (#222, #680)

Fuente: **Street Furniture**, de Kkryy.
Página: https://kkryy.itch.io/streetfurniture
Licencia: **CC0 1.0 Universal** (declarada en la página).
Descarga: `Street Furniture.zip`, `sha256` `f0750ab44a7edc705ff351509c74065f103a6abeddd3974ceb44f660e971d7e3`.

## Qué trae el pack de verdad

El comentario previo de #222 suponía farolas y bancos. El ZIP no los trae: sus 13 modelos son `Barrel`, `Bottles`, `Box`, `Conditioner`, `Crowbar`, `Flashlight`, `Floppy`, `GarbageBag`, `GasMask`, `Hammer`, `OldLock`, `TrashCan` y `Сardboard` (con «С» cirílica en el original). Todos vienen en `.blend` + `.fbx` + `.png`.

## Selección de mobiliario urbano (#222)

Entran las piezas que dan lectura de calle exterior sin repetir papeleras ni cajas ya presentes:

| GLB | Origen | Uso en `trayecto` |
|---|---|---|
| `TrashCan.glb` | `TrashCan/TrashCan.fbx` + `TrashCan.png` | contenedor en la calzada, junto al bordillo derecho (z 10), con caja de colisión |
| `GarbageBag.glb` | `GarbageBag/GarbageBag.fbx` + `GarbageBag.png` | tres bolsas desbordadas en la acera |
| `Cardboard.glb` | `Сardboard/Сardboard.fbx` + `cardboard.png` | cartón plegado junto a las bolsas |
| `Conditioner.glb` | `Conditioner/Conditioner.fbx` + `Conditioner.png` | tres aparatos de aire colgados de fachadas, por encima de las ventanas |

Quedan fuera de #222:

- `Bottles`: la lata lleva una marca legible no verificada.
- `Crowbar`, `Hammer`, `Flashlight`, `GasMask`, `OldLock`, `Floppy`: objetos de mano o de interior, derivados a #680.
- `Barrel`, `Box`: el trayecto ya tiene cajas y papeleras; `Barrel` acabó entrando posteriormente como pieza urbana adicional en #679.

## Primer corte de props utilizables (#680)

El primer vertical se limita deliberadamente a **dos piezas**:

- `Crowbar` → `palanca_kkryy`: herramienta recogible con uso semántico `forzar`.
- `Flashlight` → `linterna_kkryy`: herramienta recogible con uso semántico `iluminar`.

La selección busca validar el contrato transversal antes de atarlo a un puzzle concreto. Ambos objetos reutilizan `Recogible3D` e `Inventario`; no crean persistencia, economía ni menú propios. El catálogo vive en `godot/guion/props_utilizables_cc0.gd`.

Este primer corte **no carga todavía los GLB** porque `Crowbar.glb` y `Flashlight.glb` no están en `main`. Activarlos con rutas ausentes haría fallar importación/exportación, y subirlos como blobs normales violaría `.gitattributes`. La integración visual posterior debe entrar mediante **Git LFS real**, con ficha y `sha256` en `godot/assets/procedencia.json`.

Decisiones para el resto del pack:

- `Floppy`: reservar para una interacción de terminal/datos que justifique qué contiene.
- `OldLock`: reservar para un puzzle que defina qué abre o qué herramienta lo resuelve.
- `GasMask`: candidata a sueño/espacio contaminado; no convertirla en simple coleccionable.
- `Hammer`: fuera mientras no aporte un verbo distinto de la palanca.
- `Box`: fuera mientras duplique cajas ya existentes.

## Materialización segura de Crowbar / Flashlight (#680)

El tercer corte prepara la importación binaria sin añadir todavía los modelos al repositorio.

`scripts/materializar_street_furniture_680.py` separa dos fases:

1. **Preparación fuera del repo**: convertir `Crowbar/Crowbar.fbx` y `Flashlight/Flashlight.fbx` a GLB2 autocontenido siguiendo el patrón de #679, y conservar el PNG extraído por Godot como `<Nombre>_<Nombre>_albedo.png`.
2. **Materialización**: validar fuente + resultado y dejar únicamente los binarios elegidos y `procedencia.json` en el índice Git.

Dry-run del lote completo:

```bash
python3 scripts/materializar_street_furniture_680.py \
  /tmp/street-furniture-extraido \
  /tmp/street-furniture-preparado \
  --repo .
```

Dry-run solo de la palanca:

```bash
python3 scripts/materializar_street_furniture_680.py \
  /tmp/street-furniture-extraido \
  /tmp/street-furniture-preparado \
  --repo . \
  --asset crowbar
```

Aplicación real:

```bash
python3 scripts/materializar_street_furniture_680.py \
  /tmp/street-furniture-extraido \
  /tmp/street-furniture-preparado \
  --archivo "/ruta/Street Furniture.zip" \
  --repo . \
  --asset crowbar \
  --aplicar
```

Con `--aplicar` el script:

- exige el ZIP original con SHA-256 `f0750ab44a7edc705ff351509c74065f103a6abeddd3974ceb44f660e971d7e3`;
- exige el FBX y PNG originales del asset dentro del árbol extraído;
- rechaza GLB que no sean glTF 2 o que dependan de buffers/imágenes externas;
- comprueba que el PNG preparado coincide con una imagen realmente embebida en el GLB;
- calcula SHA-256 de los artefactos materializados y añade `archivo_origen` + `paquete_sha256` a procedencia;
- no pisa una ruta con otro contenido/procedencia;
- ejecuta `git add` solo sobre GLB/PNG elegidos y `procedencia.json`;
- verifica que el **índice**, no solo el working tree, contiene punteros Git LFS con OID y tamaño exactos;
- deja el cambio staged para revisión, sin commit ni push automáticos.

Esto convierte el bloqueo de #680 en un paso mecánico y auditable cuando estén disponibles los binarios preparados, sin volver a improvisar el proceso de #679.

## Conversión

Los FBX no comparten escala (la bolsa llega a 2 cm y el contenedor a 6 m) y Godot no enlaza sus texturas. Cada FBX se abre en Godot 4.7.2, se le asigna su PNG original como `albedo_texture` y se exporta con `GLTFDocument` a un `.glb` autocontenido, sin tocar vértices ni UV. Los FBX no se versionan. Godot extrae la textura como `*_albedo.png`, que también tiene ficha en `godot/assets/procedencia.json`, con `sha256` y Git LFS.

`godot/guion/mobiliario_urbano_cc0.gd` monta el lote de #222 desde `dia_calle_app.gd`:

- **Escala:** cada pieza se escala por su medida real.
- **Colocación:** las piezas de suelo apoyan su base; los aparatos de aire apoyan la cara trasera en la fachada, con la rejilla hacia la calle.
- **Materiales:** mate y visibles por las dos caras cuando corresponde.
- **Física:** solo los objetos voluminosos seleccionados bloquean el paso.

`godot/pruebas/pruebas_mobiliario_urbano_cc0.gd` comprueba el lote urbano. Para #680, `godot/pruebas/pruebas_props_utilizables_cc0.gd` comprueba que la selección siga acotada, que los metadatos sean aptos para la UI de inventario, que los objetos reutilicen `Recogible3D` y que `Inventario` impida duplicados sin introducir recompensas económicas.

Capturas de #222: `docs/capturas/mobiliario-urbano-222.png` y `docs/capturas/mobiliario-urbano-222-aire.png`.
