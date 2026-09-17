# Retro Urban Kit — corte SIGA-98

Seguimiento: #295 (sub-issue de #216).

## Procedencia y licencia

- Autor/editor: **Kenney**.
- Pack: **Retro Urban Kit**.
- Fuente canónica: <https://kenney.nl/assets/retro-urban-kit>.
- Licencia publicada por Kenney: **CC0 1.0**.
- Piezas usadas en el corte actual: `detail-awning-small.glb`, `detail-bench.glb`, `detail-light-single.glb`, `detail-barrier-type-a.glb`.
- SHA-256 de los GLB fuente:
  - `detail-awning-small.glb`: `b012c04b39d39a66c7cb45392621d7374f1ff34c6054b4a05bee019abc55b155`
  - `detail-bench.glb`: `ccf6f0a95b04db1720c9a7040404ca0d676a0f850815aee90de5edc33b96c47c`
  - `detail-light-single.glb`: `aac24987fa7651f8e892f4e661b3bb67c6866edb726e0ab092e9c747f0a69151`
  - `detail-barrier-type-a.glb`: `8ad30f159654cccd2cb176b84852275c375a2d4cb868b6969b184474d3d765ef`
- Espejo usado para obtener las piezas de forma reproducible: `KoshkiKode/cordite`, commit `46edc7df41a3b658d7e2d1b7332b7da803c5e7d6`, ruta `assets/models/kenney-urban/<pieza>.glb`.

La geometría necesaria se conserva como datos de vértices/triángulos en `godot/arte/retro_urban_awning.gd`, `retro_urban_bench.gd`, `retro_urban_lamp.gd` y `retro_urban_barrier.gd`; no se incorpora ningún GLB nuevo fuera del flujo LFS. Los materiales/texturas del pack no se reutilizan: SIGA-98 aplica su shader PSX y una paleta propia por pieza.

## Integración actual

`godot/guion/dia_retro_urban_app.gd` monta ocho piezas decorativas durante `trayecto`, todas `MeshInstance3D` de una superficie que comparten `ArrayMesh` por tipo:

- 2 toldos (`ToldoRetroUrban*`) sobre la fachada del escaparate;
- 1 banco (`BancoRetroUrban`) en la acera, frente al escaparate;
- 2 farolas (`FarolaRetroUrban*`) flanqueando el tramo;
- 3 barreras (`BarreraRetroUrban*`) marcando el borde de la acera.

Decisiones del corte:

- sin logos ni señalética;
- sin `StaticBody3D`, `CollisionShape3D` ni generación de colisión trimesh;
- sin entrada de teclado ni interacción de gameplay;
- sombras desactivadas para no añadir una pasada de sombra;
- una única construcción de malla en CPU por tipo de pieza, reutilizada por sus instancias;
- presupuesto del pase base del dressing Retro Urban: **máximo 8 draw calls** (ocho instancias × una superficie/material).

El número final de draw calls de un frame completo depende del renderer y del resto de la escena. El benchmark reproducible de `docs/benchmark-cc0.md` dispone ahora de un modo `retro_urban` que monta **solo** este controller sobre el mismo baseline/cámara y produce captura PNG + métricas JSON específicas. La primera ejecución aislada detectó que el controller también montaba `CalleMateriales` (#399), inflando el delta a 11 draw calls; #940 separa ambos controllers para que el coste atribuido a #295 sea medible sin esa contaminación.

## Estado frente a #295

El corte actual usa **4 piezas fuente** (`detail-awning-small.glb`, `detail-bench.glb`, `detail-light-single.glb`, `detail-barrier-type-a.glb`) montadas en ocho posiciones. El rango inicial de 6–10 piezas era un objetivo de exploración, no un motivo para añadir geometría sin necesidad: tras #603 el gate útil de cierre es demostrar visualmente y medir el aporte real del kit.

El modo `retro_urban` del benchmark cubre ese gate de forma aislada y reproducible: `baseline.png` frente a `retro_urban.png`, más `retro_urban-summary.json` y `retro_urban-report.md`. Solo si esa comparación o el playtest de #398 detectan un hueco concreto tiene sentido añadir más piezas del pack.

— Odiseo (GPT-5.6 Sol), Claude Sonnet 5
