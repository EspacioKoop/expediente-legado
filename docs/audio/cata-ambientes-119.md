# Cata auditiva reproducible — #119

El estado técnico de #119 ya permite reproducir ambiente continuo en las cuatro fases, mezclarlo por un bus independiente y transicionar con fundido. Lo que queda antes de promover las fuentes originales de #826 es una **escucha humana reproducible**.

Este flujo genera un artifact de revisión; no mete OGG en `godot/assets/`, no altera runtime y no convierte métricas automáticas en un veredicto sonoro.

## Generar en local

Desde la raíz:

```bash
python3 -m unittest -v scripts/test_cata_ambientes_originales.py
python3 scripts/preparar_cata_ambientes.py
```

Se genera `build/cata_ambientes_119/` con:

- cuatro OGG ordenados para escucha;
- cada fuente repetida ocho veces sin crossfade oculto, para que la costura del loop sea audible;
- `cata.m3u` con el orden de escucha;
- `manifest.json` con duración, RMS, pico, DC y discontinuidad de loop del PCM fuente;
- `REVISION.md` con una ficha humana para identidad, loop, fatiga, enmascaramiento y decisión.

Los hashes del manifest sirven solo para identificar los OGG del artifact concreto. El bitstream Vorbis puede variar entre versiones de FFmpeg, así que **no son hashes de procedencia**.

## Artifact de GitHub Actions

El workflow `Cata ambientes 119` ejecuta las regresiones, genera el mismo paquete y lo adjunta durante 14 días. Así la revisión no depende de tener FFmpeg/Godot instalado localmente.

La revisión humana debe escuchar cada pista completa. Un valor pequeño de `salto_loop` ayuda a localizar una discontinuidad técnica, pero no demuestra que el loop sea imperceptible ni que el timbre funcione dentro del juego.

## Qué decidir

Para cada fuente:

1. **Identidad:** ¿se distingue inmediatamente de las otras fases?
2. **Loop:** ¿aparece un clic, bombeo o patrón reconocible cada dos segundos?
3. **Fatiga:** ¿algún tono, batido o evento periódico molesta al repetirse?
4. **Jerarquía:** ¿deja espacio a pasos, interacción, diálogo y música puntual?
5. **Decisión:** promover, iterar o descartar.

Solo las fuentes marcadas **promover** deberían pasar después a un corte de producción, con duración/calidad definitivas y la trazabilidad que corresponda bajo `godot/assets/procedencia.json`.

La cata aislada tampoco cierra #119: tras promover una fuente hay que volver a escucharla **en el recorrido real**, con el mixer y los efectos activos.

— Odiseo (GPT-5.6 Sol)
