# Retro Urban Kit — corte SIGA-98

Seguimiento: #295 (sub-issue de #216).

## Procedencia y licencia

- Autor/editor: **Kenney**.
- Pack: **Retro Urban Kit**.
- Fuente canónica: <https://kenney.nl/assets/retro-urban-kit>.
- Licencia publicada por Kenney: **CC0 1.0**.
- Pieza usada en el corte actual: `detail-awning-small.glb`.
- SHA-256 del GLB fuente: `b012c04b39d39a66c7cb45392621d7374f1ff34c6054b4a05bee019abc55b155`.
- Espejo usado para obtener la pieza de forma reproducible: `KoshkiKode/cordite`, commit `46edc7df41a3b658d7e2d1b7332b7da803c5e7d6`, ruta `assets/models/kenney-urban/detail-awning-small.glb`.

La geometría necesaria se conserva como datos de vértices/triángulos en `godot/arte/retro_urban_awning.gd`; no se incorpora un GLB nuevo fuera del flujo LFS. Los materiales/texturas del pack no se reutilizan: SIGA-98 aplica su shader PSX y una paleta propia.

## Integración actual

`godot/guion/dia_retro_urban_app.gd` monta dos toldos decorativos durante `trayecto`, sobre la fachada existente. Son dos `MeshInstance3D` con una superficie cada uno que comparten el mismo `ArrayMesh`; sólo cambia el material/color por instancia.

Decisiones del corte:

- sin logos ni señalética;
- sin `StaticBody3D`, `CollisionShape3D` ni generación de colisión trimesh;
- sin entrada de teclado ni interacción de gameplay;
- sombras desactivadas para no añadir una pasada de sombra;
- una única construcción de la malla en CPU, reutilizada por las dos instancias;
- presupuesto del pase base del dressing Retro Urban: **máximo 2 draw calls** (dos instancias × una superficie/material).

El número final de draw calls de un frame completo depende del renderer y del resto de la escena; este presupuesto sólo acota el aporte de este dressing y debe contrastarse con el profiler cuando se haga la captura visual del corte.

## Estado frente a #295

Este vertical mejora trazabilidad y coste, pero **no cierra #295**. El objetivo del issue pide un primer corte de 6–10 piezas representativas y una captura antes/después. A día de hoy hay **1 pieza fuente** (`detail-awning-small.glb`) reutilizada en dos posiciones.

Próximo incremento recomendado: añadir 5–9 piezas pequeñas y neutras (mobiliario de calle, remates de fachada y masas lejanas), todas sin logos/señalética problemática, manteniendo procedencia/hash por pieza y un presupuesto explícito por grupo. Después, capturar la misma vista antes/después y medir el frame con el profiler.

— Odiseo (GPT-5.6 Sol)
