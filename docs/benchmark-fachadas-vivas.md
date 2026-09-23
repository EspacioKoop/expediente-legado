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

## Cámara y muestreo de rendimiento

- resolución: 1280×720;
- posición: `(0.0, 1.65, -7.4)`;
- objetivo: `(-5.25, 5.8, -12.2)`;
- FOV: 68°;
- calentamiento: 90 frames;
- muestreo: 180 frames.

La cámara está situada a altura de jugador en el eje central de la calle y mira hacia el primer tramo residencial. Esta toma se mantiene estable para que el coste sea comparable entre runs.

## Evidencia visual desde la ruta

La comparación visual se ejecuta en un proceso separado del benchmark de rendimiento. `capturar_fachadas_vivas_ruta.gd` genera baseline/full desde tres estaciones del eje jugable, todas mirando al mismo tramo `Ventana0_*`:

- **cerca**: cámara `(0.0, 1.65, -12.0)`, distancia aproximada al objetivo **6,7 m**; permite revisar marco, cristal y mobiliario 3D;
- **media**: cámara `(0.0, 1.65, 5.5)`, distancia aproximada **19,2 m**; cruza el LOD de props de 18 m y permite comprobar que desaparece el mobiliario sin perder lectura interior;
- **lejos**: cámara `(0.0, 1.65, 14.5)`, distancia aproximada **27,8 m**; permite revisar repetición, iluminación, persianas y lectura del tramo desde el extremo opuesto del trayecto.

Cada estación espera 12 frames después de mover la cámara y guarda una captura 1280×720. Baseline y full deben declarar exactamente las mismas posiciones, objetivos, FOV y distancias; `scripts/test_capturas_fachadas_vivas.py` falla si las parejas dejan de ser comparables o falta una imagen.

Estas capturas son evidencia automatizada y reproducible. Sirven para detectar regresiones visuales y facilitar una revisión humana, pero no equivalen por sí solas a un playtest visual completo.

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

## Extensión de animación ambiental (#1230)

El mismo runner conserva la pareja histórica `baseline/full` de #861 y añade
una segunda comparación aislada:

- `ambiental_baseline`: fachadas vivas + el mismo arbolado CC0, con los
  parámetros de viento y animación en su valor apagado;
- `ambiental_full`: exactamente la misma geometría y cámara, pero activa
  `AnimadorAmbiental3D`, el lote único de ventanas vivas y `VientoAmbiental`.

Esto evita atribuir a la animación el coste geométrico de los árboles o de
`CalleFachadasVivas`. La comparación usa la misma resolución, calentamiento,
número de muestras, métricas y presupuesto que #861: máximo 10 % de incremento
en `process_ms`, con tolerancia absoluta mínima de 0,20 ms.

El informe ambiental registra además cuántas ventanas animadas, materiales de
follaje y piezas activas entraron realmente en el corte. Así un PASS no puede
salir de un benchmark donde el consumidor no se montó.

## Artefactos

El workflow `Benchmark fachadas vivas` genera durante 14 días:

- `baseline.png` y `full.png` para la toma fija del benchmark;
- `ambiental_baseline.png` y `ambiental_full.png` para el corte de #1230;
- `baseline.json`, `full.json`, `summary.json` y `report.md` para métricas de #861;
- `ambiental_baseline.json`, `ambiental_full.json`, `ambiental-summary.json` y
  `ambiental-report.md` para el presupuesto ambiental;
- `baseline-ruta.json` y `full-ruta.json` para el contrato de las tres estaciones;
- `baseline-ruta-cerca.png` / `full-ruta-cerca.png`;
- `baseline-ruta-media.png` / `full-ruta-media.png`;
- `baseline-ruta-lejos.png` / `full-ruta-lejos.png`;
- `ruta-report.md` con el emparejado de capturas y distancias.

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

xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/benchmark_fachadas_vivas.gd -- \
  --mode=ambiental_baseline --output="$PWD/benchmark-fachadas-vivas"

xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/benchmark_fachadas_vivas.gd -- \
  --mode=ambiental_full --output="$PWD/benchmark-fachadas-vivas"

python3 scripts/test_benchmark_fachadas_vivas.py --report benchmark-fachadas-vivas

xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/capturar_fachadas_vivas_ruta.gd -- \
  --mode=baseline --output="$PWD/benchmark-fachadas-vivas"

xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/capturar_fachadas_vivas_ruta.gd -- \
  --mode=full --output="$PWD/benchmark-fachadas-vivas"

python3 scripts/test_capturas_fachadas_vivas.py --report benchmark-fachadas-vivas
```

El corte no modifica gameplay, navegación, colisiones ni incorpora assets externos. La cobertura, el número de ventanas de detalle, el batching, los estados de iluminación, la profundidad, los rangos LOD y la comparabilidad de las capturas quedan cubiertos por regresiones ejecutables.
