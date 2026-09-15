# Benchmark CC0 del trayecto

Este benchmark cubre el criterio de rendimiento combinado de #493/#216 sin añadir assets ni modificar gameplay. Compara dos procesos de Godot aislados sobre el mismo `trayecto`, con cámara, resolución, calentamiento y número de frames fijos:

- `baseline`: geometría actual del trayecto, sin dressing CC0 opcional;
- `full`: el mismo trayecto con cielo CC0, tren/vía, DressingCC0, Retro Urban, skyline y naturaleza ya presentes en `main`.

Cada proceso produce un JSON y una captura PNG sin HUD. `scripts/test_benchmark_cc0.py` valida que ambos informes sean comparables y genera `summary.json` y `report.md` con el incremento del dressing respecto al baseline.

## Métricas

Se registran los monitores de Godot disponibles de forma reproducible en el runner: draw calls, objetos, primitivas, tiempo de proceso y memoria estática. El tiempo GPU queda explícitamente como `N/D`: `Performance` no ofrece un contador GPU portable que podamos comparar de forma fiable en este runner.

Las cifras de CI se obtienen con Mesa/llvmpipe bajo Xvfb. Son útiles para detectar cambios relativos entre baseline y `full` en el mismo entorno, pero no son una promesa de FPS en el hardware de un jugador. Por eso este primer corte no fija un umbral arbitrario de regresión: el gate exige datos válidos y comparables; un presupuesto máximo podrá fijarse cuando exista una serie histórica suficiente.

## Ejecución local

Con Godot de la versión declarada en `.godot-version` disponible como `godot4`:

```bash
rm -rf benchmark-cc0
mkdir -p benchmark-cc0
xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/benchmark_cc0.gd -- --mode=baseline --output="$PWD/benchmark-cc0"
xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/benchmark_cc0.gd -- --mode=full --output="$PWD/benchmark-cc0"
python3 scripts/test_benchmark_cc0.py --report benchmark-cc0
```

El workflow `.github/workflows/benchmark-cc0.yml` ejecuta esa misma secuencia en cambios relevantes, manualmente y cada noche. Siempre conserva JSON, capturas y el informe Markdown como artifact para poder comparar resultados posteriores.
