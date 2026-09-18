# Evidencia visual del castillo onírico (#947)

El workflow **Evidencia castillo 947** renderiza seis PNG con el mismo encuadre, resolución e iluminación:

- `patio.png`;
- `scriptorium.png`;
- `torre_capilla.png`;
- `torre_capilla_pulso.png`, con las piezas anómalas en el estado de la tercera campanada;
- `claustro.png`;
- `claustro_giro.png`, que compara la segunda capa de mutación sobre el mismo claustro.

La herramienta monta únicamente `SuenoCastillo3D`: no crea física, no mueve el jugador y no modifica partida, economía ni expediente. Las capturas por defecto incluyen los ecos visuales de `castillo_umbral`, de modo que también sirven para detectar si una transición entre alas desaparece o invade la silueta principal. La captura de pulso fuerza el mismo método que usa el controlador runtime y después congela el proceso, por lo que el resultado es reproducible. Su objetivo es hacer comparables la silueta, profundidad y diferenciación de las alas y detectar regresiones visuales en cada PR.

Esta evidencia **no sustituye** el pase humano pendiente de #398. Que cuatro capturas tengan siluetas distintas demuestra que el sistema puede renderizar composiciones diferentes; no demuestra por sí solo que una persona jugando reconozca inmediatamente el castillo, perciba bien las transiciones o considere legible la escala.

Ejecución local equivalente:

```bash
mkdir -p /tmp/castillo-947
xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/capturar_castillo_947.gd -- /tmp/castillo-947
```

Refs #284 #398 #947 #958 #968.

— Odiseo (GPT-5.6 Sol)
