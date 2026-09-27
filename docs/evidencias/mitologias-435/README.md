# Evidencia visual reproducible — mitologías #435

Este gate cubre las tres familias originales que todavía no tenían un capturador dedicado:

- **#436 Gilgamesh:** entrada a escala de runtime, lectura cercana del puzzle y ciudad transformada tras completar la tablilla.
- **#438 Aquiles:** talón revelado por lectura espacial y estado resuelto/sellado.
- **#441 Duat:** pesaje inicial y arquitectura equilibrada.

Minotauro (#437), Hidra (#439) y Ryū (#440) conservan sus workflows específicos existentes.

## Qué valida automáticamente

El workflow comprueba únicamente propiedades mecánicas y reproducibles:

- se generan siete capturas PNG;
- Gilgamesh produce tres vistas (entrada, puzzle y resuelto) y Aquiles/Duat dos estados cada uno;
- el manifiesto identifica #436, #438 y #441;
- el capturador alcanza las transiciones mediante las APIs reales del vertical;
- no se introduce HUD ni una escena alternativa de gameplay.

Para **Gilgamesh #436**, el capturador ya no usa el diorama standalone. Instancia `sueno_gilgamesh.tscn`, retira `CamaraStandalone` como hace `Dia`, monta una base real con `Espacio3D`, aplica `SuenoGilgamesh.ESCALA_ENCUENTRO` y encuadra a 1,65 m de altura con FOV 70. La tercera captura acerca la cámara al puzzle para revisar motivo↔ancla sin una vista cenital artificial.

## Qué **no** valida

El gate no decide que el arte sea bueno, reconocible o suficientemente claro. El manifiesto fija:

- `veredicto_automatico: false`;
- `requiere_revision_humana: true`.

La revisión humana debe comprobar, al menos:

1. que Gilgamesh se reconoce desde la entrada jugable sin explicación textual y no se confunde con castillo/desierto;
2. que en `436_gilgamesh_puzzle.png` la correspondencia fragmento↔ancla se entiende por forma/motivo, sin ensayo ciego;
3. que el cambio entre estados comunica una reacción a la acción del jugador;
4. que los nuevos materiales PBR y props no parecen un diorama desconectado del lenguaje SIGA-98;
5. que ningún prop tapa la lectura de la mecánica principal;
6. que la composición sigue siendo legible con reducción de movimiento.

## Ejecución local

```bash
godot4 --headless --editor --path godot --quit
mkdir -p /tmp/evidencia-mitologias-435
xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/capturar_mitologias_435.gd -- \
  /tmp/evidencia-mitologias-435
```

El artifact de CI se conserva 14 días para revisión.
