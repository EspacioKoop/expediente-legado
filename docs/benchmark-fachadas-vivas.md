# Benchmark de fachadas vivas (#861)

Este benchmark mide de forma aislada el coste de la capa `CalleFachadasVivas` sobre la misma calle y la misma cámara. Su objetivo es convertir el criterio de aceptación de #861 (comparación antes/después y degradación aproximada máxima del 10 %) en una medición reproducible y utilizarla como gate de optimización.

## Escena comparada

Los dos procesos construyen exactamente la misma base:

- espacio `trayecto` producido por `dia_calle_app.gd`;
- geometría común mediante `Espacio3D`;
- `CalleIdentidad`, incluidas sus 61 ventanas altas de `PisosFachada`;
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

La cámara está situada a altura de jugador en el eje central de la calle y mira hacia el primer tramo residencial. Las capturas sirven para comparar la misma toma automatizada; no sustituyen una validación visual humana desde la ruta jugable.

## Métricas

Cada modo genera un JSON con promedios y máximos de:

- draw calls;
- objetos renderizados;
- primitivas;
- tiempo de proceso (`process_ms`);
- memoria estática.

También se registran el número de ventanas lógicas cubiertas, los lotes `MultiMesh` y el total de instancias conservadas por la capa.

Godot no expone un tiempo GPU portable mediante `Performance` para este runner, por lo que el informe lo marca explícitamente como no disponible. Las cifras se obtienen con render software y sirven para comparar ambos modos en el mismo entorno, no como objetivo de FPS para hardware real.

## Presupuesto

El gate principal usa `process_ms`:

- incremento permitido: 10 % respecto al baseline;
- tolerancia absoluta mínima: 0,20 ms para evitar falsos negativos cuando el baseline es muy pequeño.

El límite efectivo es el mayor de ambos valores. Si el modo `full` lo supera, el workflow falla y conserva igualmente los artefactos para diagnóstico. El presupuesto no se relaja para poner verde una regresión.

## Evolución de la optimización

### Vertical slice de 9 ventanas

La implementación previa al batching creaba 82 `MeshInstance3D` independientes y midió:

- `process_ms`: 27,684 → 33,498 ms, **+21,00 %**;
- draw calls: 50 → 132, **+82**;
- objetos: 50 → 132, **+82**;
- primitivas: 1276 → 2260, **+984**.

El primer batching agrupó las mismas 82 piezas por malla/material/LOD en 17 `MultiMeshInstance3D`. Con la misma cámara y workflow pasó a:

- `process_ms`: 28,313 → 29,110 ms, **+0,797 ms / +2,82 %**;
- draw calls: 50 → 65, **+15**;
- objetos: 50 → 67, **+17**;
- primitivas: 1276 → 2260, **+984**;
- memoria estática: **+1,00 %**.

### Escalado a 61 ventanas

El primer intento de cobertura completa mantuvo fondo, cuatro piezas de marco y persiana opcional en las 61 ventanas, reservando solo el mobiliario para las nueve cercanas. Aunque seguía batcheado en 17 lotes, subía a 353 instancias y el mismo benchmark detectó:

- `process_ms`: 27,595 → 31,545 ms, **+3,950 ms / +14,32 %**;
- resultado: **FAIL** frente al presupuesto del 10 %.

No se relajó el umbral. La capa se dividió por coste visual:

- **61 ventanas**: cristal translúcido, fondo aparente, estado de iluminación determinista y persiana cuando corresponde;
- **9 ventanas del tramo `Ventana0_*`**: además conservan marco con volumen y mobiliario 3D;
- **52 ventanas restantes**: profundidad aparente barata sin marco volumétrico ni props 3D.

El resultado conserva 61 ventanas lógicas y los mismos 17 tipos de lote, pero reduce la geometría añadida de 353 a **145 instancias batcheadas**. El benchmark posterior midió:

- `process_ms`: 26,617 → 27,616 ms, **+0,999 ms / +3,75 %**;
- draw calls: 50 → 67, **+17**;
- objetos: 50 → 67, **+17**;
- primitivas: 1276 → 3016, **+1740**;
- memoria estática: **+0,86 %**;
- resultado: **PASS**; límite efectivo de `process_ms`: +2,662 ms.

El criterio de optimización es por tanto explícito: cubrir toda la calle con profundidad e iluminación aparente, y reservar la geometría interior más cara para el tramo que se observa de cerca.

## Artefactos

El workflow `Benchmark fachadas vivas` genera durante 14 días:

- `baseline.png`;
- `full.png`;
- `baseline.json`;
- `full.json`;
- `summary.json`;
- `report.md`.

Las dos imágenes constituyen la comparación automatizada sin HUD; los JSON y el Markdown documentan el coste antes/después con la misma cámara.

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

El corte no modifica gameplay, navegación, colisiones ni incorpora assets externos. La cobertura, el número de ventanas de detalle, el batching, los estados de iluminación, la profundidad y los rangos LOD quedan cubiertos por regresiones ejecutables.
