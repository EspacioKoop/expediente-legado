# Evidencia comparativa · identidades oníricas #284

Este artifact prepara el gate humano de #398 para **castillo, montaña, desierto y escuela**. No sustituye ese playtest ni afirma que una escena sea legible por el mero hecho de renderizar correctamente.

## Qué normaliza

Las cuatro capturas se producen a **1280×720**, sin HUD, con **FOV 70°** y cámara a **1,65 m**. Cada familia conserva un encuadre propio porque su arquitectura y escala son distintas, pero `manifest.json` registra posición, objetivo, forma base e identidad onírica para que la comparación sea reproducible.

El capturador parte de `Sueno.espacio()` y aplica los mismos adaptadores de #284. Usa una única frase neutra de contenido ya conocido (`EXPEDIENTE CONOCIDO`) para que montaña, desierto y escuela puedan materializar su interacción sin inventar hechos de expediente.

## Cómo generar

```bash
mkdir -p /tmp/evidencia-sueno-284
xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/capturar_sueno_284.gd -- \
  /tmp/evidencia-sueno-284
```

Se generan:

- `castillo.png`
- `montana.png`
- `desierto.png`
- `escuela.png`
- `manifest.json`

El workflow **Evidencia sueño 284** publica el mismo conjunto como artifact de GitHub Actions.

## Rúbrica humana para #398

La revisión debe mirar las cuatro imágenes **sin leer el nombre del archivo primero** y responder, para cada una:

1. ¿Se reconoce el tipo de lugar por **silueta/arquitectura**?
2. ¿La iluminación y profundidad refuerzan esa lectura en vez de parecer un greybox?
3. ¿Hay al menos un objeto o punto de referencia visual propio de esa familia?
4. ¿Las cuatro escenas parecen pertenecer al mismo juego sin parecer recolores entre sí?
5. Al jugar la build, ¿el **sonido** confirma una identidad distinta —campanas, viento/crujidos, desierto/silencio, timbre/voces—?
6. ¿Alguna escena vuelve a leer como bloques genéricos, pasillo técnico o decoración intercambiable?

Si una captura falla, el ajuste debe dirigirse a esa evidencia concreta. No se abre una quinta familia para compensar una de las cuatro que todavía no se lea.

## Alcance

Las capturas son evidencia técnica de composición y encuadre. #398 sigue necesitando una persona mirando y recorriendo las escenas desde la build, porque una imagen no valida orientación, ritmo, sonido espacial ni comprensión durante movimiento.

Refs #284 #398 #755 #757 #761 #763 #947.
