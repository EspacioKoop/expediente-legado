# Benchmark de fachadas vivas (#861)

Este benchmark mide de forma aislada el coste de la capa `CalleFachadasVivas` sobre el mismo tramo y la misma cámara. Su objetivo es convertir el criterio de aceptación de #861 (comparación antes/después y degradación aproximada máxima del 10 %) en una medición reproducible y utilizarla como gate de optimización.

## Escena comparada

Los dos procesos construyen exactamente la misma base:

- espacio `trayecto` producido por `dia_calle_app.gd`;
- geometría común mediante `Espacio3D`;
- `CalleIdentidad`, que contiene el tramo `Ventana0_*` usado por la vertical slice;
- iluminación equivalente y sombras desactivadas para reducir ruido del runner.

La única diferencia es:

- `baseline`: no monta `CalleFachadasVivas`;
- `full`: monta `CalleFachadasVivas` sobre la misma `CalleIdentidad`.

Se ejecutan en procesos separados para que las mutaciones visuales de las ventanas del modo `full` no contaminen el baseline.

## Cámara y muestreo

- resolución: 1280×720;
- posición: `(0.0, 1.65, -7.4)`;
- objetivo: `(-5.25, 5.8, -12.2)`;
- FOV: 68°;
- calentamiento: 90 frames;
- muestreo: 180 frames.

La cámara está situada a altura de jugador en el eje central de la calle y mira hacia el primer tramo residencial, donde viven las nueve ventanas de la slice.

## Métricas

Cada modo genera un JSON con promedios y máximos de:

- draw calls;
- objetos renderizados;
- primitivas;
- tiempo de proceso (`process_ms`);
- memoria estática.

También se registran las nueve ventanas lógicas, el número de lotes `MultiMesh` y el total de instancias conservadas por la capa.

Godot no expone un tiempo GPU portable mediante `Performance` para este runner, por lo que el informe lo marca explícitamente como no disponible. Las cifras se obtienen con render software y sirven para comparar ambos modos en el mismo entorno, no como objetivo de FPS para hardware real.

## Presupuesto

El gate principal usa `process_ms`:

- incremento permitido: 10 % respecto al baseline;
- tolerancia absoluta mínima: 0,20 ms para evitar falsos negativos cuando el baseline es muy pequeño.

El límite efectivo es el mayor de ambos valores. Si el modo `full` lo supera, el workflow falla y conserva igualmente los artefactos para diagnóstico. El presupuesto no se relaja para poner verde una regresión.

## Optimización guiada por el benchmark

La primera ejecución del benchmark sobre la implementación previa al batching midió:

- `process_ms`: 27,684 → 33,498 ms, **+21,00 %**;
- draw calls: 50 → 132, **+82**;
- objetos: 50 → 132, **+82**;
- primitivas: 1276 → 2260, **+984**.

Ese resultado activó una optimización dentro de la misma vertical slice: las 82 piezas visuales siguen existiendo, pero se agrupan por malla/material/LOD en un máximo de 17 `MultiMeshInstance3D` (cinco fondos, tres lotes de marco/persiana y nueve tipos de props). Los nueve nodos `Interior_*` quedan como metadatos lógicos y ya no generan geometría individual.

La comparación posterior usa exactamente el mismo workflow y cámara; por tanto, el efecto del batching se mide con el mismo instrumento que detectó la regresión original.

## Artefactos

El workflow `Benchmark fachadas vivas` genera durante 14 días:

- `baseline.png`;
- `full.png`;
- `baseline.json`;
- `full.json`;
- `summary.json`;
- `report.md`.

Las dos imágenes constituyen la comparación visual sin HUD; los JSON y el Markdown documentan el coste antes/después con la misma cámara.

## Ejecución local

Tras importar el proyecto con la versión de Godot indicada por `.godot-version`:

```bash
mkdir -p benchmark-fachadas-vivas
xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/benchmark_fachadas_vivas.gd -- \
  --mode=baseline --output="$PWD/benchmark-fachadas-vivas"

xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/benchmark_fachadas_vivas.gd -- \
  --mode=full --output="$PWD/benchmark-fachadas-vivas"

python3 scripts/test_benchmark_fachadas_vivas.py --report benchmark-fachadas-vivas
```

El corte no modifica gameplay, navegación ni colisiones. La única modificación funcional es el batching interno de la misma geometría visual ya integrada; variantes, estados, profundidad y rangos LOD se conservan mediante regresiones ejecutables.
