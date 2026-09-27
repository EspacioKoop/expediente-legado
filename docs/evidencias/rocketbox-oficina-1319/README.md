# Evidencia Rocketbox en oficina · #1319

Este gate fija la matriz visual que falta para validar las animaciones de captura
de movimiento de Rocketbox dentro de la oficina real: **pie**, **sentado**,
**teléfono** y **conversación**.

El workflow `evidencia-rocketbox-oficina-1319.yml` genera un artifact reproducible
en CI usando Vulkan por software. Sirve para detectar una regresión de clip,
posturas hundidas, assets ausentes o una captura rota, pero **no sustituye** el
criterio de aceptación de #1319, que exige revisión humana en GPU real.

## Pase final en GPU real

Desde un checkout con los objetos LFS presentes:

```bash
env DISPLAY=:0 SIGA98_GPU_REAL=1 godot4 --rendering-method forward_plus --path godot \
  --script res://pruebas/capturar_rocketbox_oficina_1319.gd -- /tmp/rocketbox-1319
```

Revisar los cuatro PNG junto con `manifest.json`:

- los pies no se hunden ni flotan en las posturas de pie;
- sentado mantiene los pies por encima del suelo y la cadera en lectura de silla;
- brazos, hombros y cuello no aparecen retorcidos;
- teléfono y conversación se leen como acciones distintas;
- la ropa/cara Rocketbox se conserva;
- el contexto sigue siendo la oficina real, no una escena de poses aislada;
- cada caso registra un clip `rocketbox/*` del sexo del avatar.

El manifest marca `gpu_real: true` únicamente cuando el capturador se ejecuta
con `SIGA98_GPU_REAL=1`; el artifact automático de CI debe conservarlo en
`false` para no presentar Lavapipe como validación física.
