# Evidencia visual · menú de inicio 3D #830

Este gate cubre el último criterio visual pendiente de #830 sin cambiar el menú ni el diorama.

El workflow **Evidencia inicio 830** monta la escena real `res://escenas/inicio.tscn` a **1920×1080** y genera dos estados comparables:

- `inicio-normal.png`: menú con lluvia y movimiento ambiental normal;
- `inicio-reduccion-movimiento.png`: la misma composición tras activar la reducción de movimiento del `InicioDiorama3D` real.

El capturador verifica además que la reducción alcanza la ventana exterior y elimina el vapor no esencial. `manifest.json` conserva resolución, archivos y `veredicto_automatico=false`.

## Revisión humana

El artifact verde demuestra que ambos estados se renderizan de extremo a extremo, pero no decide la calidad artística. Antes de valorar el cierre de #830 hay que registrar una revisión humana:

1. **Legibilidad:** `Continuar / Nueva partida / Cargar / Ventanilla / Extras / Opciones / Salir` deben leerse con claridad sobre lluvia, CRT y luces.
2. **Identidad:** la escena debe seguir pareciendo una oficina nocturna de finales de los 90 y no un fondo genérico o excesivamente moderno.
3. **Low-res:** el diorama puede ser deliberadamente low-res, pero la UI final a 1920×1080 no debe parecer borrosa o accidental.
4. **Reducción de movimiento:** el segundo estado debe conservar la composición y la atmósfera sin depender de vapor, drift o attract mode.

Formato sugerido:

```text
Validación visual #830
- Legibilidad con movimiento normal: PASS/FAIL — motivo breve
- Identidad low-res/noventera: PASS/FAIL — motivo breve
- Reducción de movimiento: PASS/FAIL — motivo breve
- Composición general 1920×1080: PASS/FAIL — motivo breve
```

Refs #830 #835 #876 #879 #886 #888 #1355.
