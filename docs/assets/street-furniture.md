# Street Furniture (Kkryy): basura urbana y aparatos de aire (#222)

Fuente: **Street Furniture**, de Kkryy.
Página: https://kkryy.itch.io/streetfurniture
Licencia: **CC0 1.0 Universal** (declarada en la página).
Descarga: `Street Furniture.zip`, `sha256` `f0750ab44a7edc705ff351509c74065f103a6abeddd3974ceb44f660e971d7e3`.

## Qué trae el pack de verdad

El comentario previo de #222 suponía farolas y bancos. El ZIP no los trae: sus 13 modelos son `Barrel`, `Bottles`, `Box`, `Conditioner`, `Crowbar`, `Flashlight`, `Floppy`, `GarbageBag`, `GasMask`, `Hammer`, `OldLock`, `TrashCan` y `Сardboard` (con «С» cirílica en el original). Todos vienen en `.blend` + `.fbx` + `.png`.

## Selección

Entran las piezas que dan lectura de calle exterior sin repetir papeleras ni cajas ya presentes:

| GLB | Origen | Uso en `trayecto` |
|---|---|---|
| `TrashCan.glb` | `TrashCan/TrashCan.fbx` + `TrashCan.png` | contenedor en la calzada, junto al bordillo derecho (z 10), con caja de colisión |
| `GarbageBag.glb` | `GarbageBag/GarbageBag.fbx` + `GarbageBag.png` | tres bolsas desbordadas en la acera |
| `Cardboard.glb` | `Сardboard/Сardboard.fbx` + `cardboard.png` | cartón plegado junto a las bolsas |
| `Conditioner.glb` | `Conditioner/Conditioner.fbx` + `Conditioner.png` | tres aparatos de aire colgados de fachadas, por encima de las ventanas |

Se descartan:

- `Bottles`: la lata lleva una marca legible no verificada.
- `Crowbar`, `Hammer`, `Flashlight`, `GasMask`, `OldLock`, `Floppy`: objetos de mano o de interior sin función en la calle.
- `Barrel`, `Box`: el trayecto ya tiene cajas y papeleras.

## Conversión

Los FBX no comparten escala (la bolsa llega a 2 cm y el contenedor a 6 m) y Godot no enlaza sus texturas. Cada FBX se abre en Godot 4.7.2, se le asigna su PNG original como `albedo_texture` y se exporta con `GLTFDocument` a un `.glb` autocontenido, sin tocar vértices ni UV. Los FBX no se versionan. Godot extrae la textura como `*_albedo.png`, que también tiene ficha en `godot/assets/procedencia.json`, con `sha256` y Git LFS.

`godot/guion/mobiliario_urbano_cc0.gd` monta el lote desde `dia_calle_app.gd`:

- **Escala:** cada pieza se escala por su medida real (contenedor 1,35 m de alto, bolsas 0,42–0,55 m, aparato 0,62 m, cartón 0,95 m).
- **Colocación:** las piezas de suelo apoyan su base; los aparatos de aire apoyan la cara trasera en la fachada, con la rejilla hacia la calle.
- **Materiales:** mate y visibles por las dos caras (bolsas y cartón son láminas finas).
- **Física:** solo el contenedor bloquea el paso.

`godot/pruebas/pruebas_mobiliario_urbano_cc0.gd` comprueba:

- escala y apoyo de cada pieza;
- aparatos de aire pegados a la fachada y por encima de la cabeza;
- paso central libre;
- sin invadir conos, escaparate ni coches aparcados;
- presupuesto de triángulos, idempotencia y hook entre fases.

Capturas: `docs/capturas/mobiliario-urbano-222.png` y `docs/capturas/mobiliario-urbano-222-aire.png`.
