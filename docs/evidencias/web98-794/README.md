# Evidencia visual #794 — Navegador Web98

El gate `Evidencia Web98 794` renderiza el control real `NavegadorSiga` con el
renderer de Godot y publica tres PNG como artifact del PR:

- `byte-local.png`: página temática usando cabecera, navegación, módulo, badge
  y decoración del pack `godot/arte/os98/web_*`.
- `busqueda-sin-falso-positivo.png`: búsqueda de «coño» sin el falso positivo
  de «economía», además del texto plural correcto para cero resultados.
- `pagina-personal.png`: página personal con el módulo noventero y badge local.

## Reproducción

```bash
mkdir -p /tmp/web98-794
xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/capturar_web98_794.gd -- /tmp/web98-794
```

Las capturas son evidencia para revisión humana del criterio visual de #794; los
tests automatizados no sustituyen la inspección de las imágenes.
