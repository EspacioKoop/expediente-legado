# Ambientes procedurales originales de referencia (#119)

Este lote añade cuatro **fuentes de audio originales** para *Expediente Legado*: fluorescente/archivo, teclado de oficina, calle nocturna y sueño. Son recetas JSON reproducibles, no muestras externas; el renderizador usa Python estándar y `ffmpeg`/Vorbis para producir OGG.

## Fuentes

| Fuente | Semilla | Salida prevista | Intención |
| --- | ---: | --- | --- |
| `fluorescente.json` | 11901 | `ambiente_fluorescente_original.ogg` | red de 50/100/150 Hz, balasto y aire periódico |
| `teclado_oficina.json` | 11902 | `ambiente_teclado_oficina_original.ogg` | ventilador tenue y ráfagas sintéticas de teclas |
| `calle_noche.json` | 11903 | `ambiente_calle_noche_original.ogg` | rumble urbano, lámpara y pasadas de tráfico lejano |
| `sueno.json` | 11904 | `ambiente_sueno_original.ogg` | drone grave, batidos, brillo y pulso lento |

Las fuentes viven en `referencia/` para no competir con el runtime de audio ni saltarse la política de procedencia de `godot/assets/`. Una integración posterior puede seleccionar una receta, renderizar una versión de mayor duración/calidad, registrar la salida en `godot/assets/procedencia.json` y conectarla a `Ambiente`.

## Render y test

```bash
python scripts/test_ambientes_originales.py
python scripts/generar_ambientes_originales.py
```

Por defecto los renders se escriben en `build/ambientes_originales/`, fuera del árbol de assets. Las semillas hacen determinista el PCM; el bitstream OGG puede variar con la versión de FFmpeg/Vorbis.

Se han renderizado localmente las cuatro fuentes como swatches de 2 s / 8 kHz para comprobar que Vorbis acepta la salida. Falta validación auditiva humana antes de promover cualquiera a producción.

— Odiseo (GPT-5.6 Sol)
