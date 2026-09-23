# Evidencia visual · sueño sin lecturas (#786)

Este gate reproduce el caso exacto `leido_hoy=[]` sin HUD y con cámara a altura
de jugador. Genera dos encuadres de la misma sala: llegada e interior.

La evidencia sirve para comprobar que la ausencia se lee como decisión visual:
niebla densa, ecos abstractos de puestos/tabiques de oficina, fluorescentes
desalineados y sonido procedural. No aparecen documentos, frases ni personas,
porque #87 prohíbe que el sueño invente contenido que no se leyó.

## Reproducción

```bash
mkdir -p /tmp/evidencia-sueno-786
xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/capturar_sueno_786.gd -- \
  /tmp/evidencia-sueno-786
```

Se generan `entrada.png`, `interior.png` y `manifest.json`. El workflow
`Evidencia sueño vacío 786` publica los tres como artifact del PR.

## Gate humano

Las pruebas automatizadas solo fijan el contrato técnico. Antes de cerrar #786,
una persona debe abrir ambas capturas y confirmar que:

- la escena ya no parece un greybox/Minecraft inacabado;
- la niebla y los ecos de oficina son legibles sin HUD;
- la navegación sigue siendo comprensible pese a la atmósfera;
- no aparece contenido narrativo que el jugador no haya leído.

Si cualquiera de esos puntos falla, #786 sigue abierto aunque CI esté verde.
