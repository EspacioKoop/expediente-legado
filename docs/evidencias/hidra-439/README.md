# Evidencia perceptiva · Hidra #439

Este gate genera tres capturas comparables del vertical jugable de la Hidra. Su objetivo es preparar el último pase perceptivo de #439 con un estado reproducible; **no sustituye la revisión humana** ni convierte métricas estructurales en una nota artística.

## Estados capturados

Las tres imágenes usan 1280×720, FOV 70°, cámara fija, sin HUD y el renderer canónico **Forward+** del proyecto.

1. `01_inicial.png`: tres cabezas, raíz común y conexiones todavía discretas.
2. `02_proliferacion.png`: después de insistir dos veces sobre el síntoma; debe haber más cabezas, al menos una regeneración arquitectónica y conexiones más legibles hacia la raíz.
3. `03_resuelta.png`: después de actuar sobre el nodo común; la proliferación desaparece y queda el pequeño cartucho `HYDRA_LOOP` que sembró el sueño.

`manifest.json` registra cabezas, regeneraciones, legibilidad del nodo, estado de resolución y SHA-256 de cada captura. Esos campos validan que se capturaron estados distintos; no deciden si la composición se entiende bien.

## Cómo generar

```bash
mkdir -p /tmp/evidencia-hidra-439
xvfb-run -a godot4 --path godot \
  --script res://pruebas/capturar_hidra_439.gd -- \
  /tmp/evidencia-hidra-439
```

El workflow **Evidencia Hidra 439** publica el mismo conjunto como artifact de GitHub Actions.

## Revisión humana de cierre

Mirar las imágenes en orden, sin apoyarse en el nombre del archivo, y comprobar:

- si el primer estado se lee como una criatura/problema de varias cabezas y no como primitivas aisladas;
- si el segundo estado comunica que actuar sobre síntomas empeora la situación;
- si las conexiones hacen evidente una causa compartida sin necesitar texto externo;
- si la regeneración arquitectónica se percibe como cambio espacial y no como ruido visual;
- si el nodo común destaca lo suficiente cuando ya es deducible;
- si el colapso final al cartucho se entiende como retorno a la semilla doméstica;
- si ninguna conexión, cabeza o sala regenerada oculta la ruta principal o domina la cámara de forma accidental.

Si aparece un defecto, el siguiente cambio debe responder a esa captura o al recorrido real correspondiente. Si las tres transiciones se leen correctamente en el artifact y en movimiento, #439 queda listo para cierre.

Refs #439 #435 #597 #687 #1283.
