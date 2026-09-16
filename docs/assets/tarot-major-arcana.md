# Tarot CC0 — 22 Arcanos Mayores

Seguimiento de #645, #71 y #395.

## Objetivo

El contrato de #71 pide que las 22 cartas de tarot tengan arte real con procedencia, no rectángulos provisionales. El runtime de cinemática/tarot está reservado por #395 para rescatar el montaje 3D, así que este corte se limita al **pipeline de assets**: identifica, valida y renombra el lote antes de integrarlo en Godot.

El importador no descarga nada, no toca `godot/assets`, no crea punteros LFS y no modifica `godot/assets/procedencia.json`. Su salida vive por defecto en `dist/.cache/tarot-cc0/`, fuera del contenido versionado.

## Fuente aprobada para el lote

- Página de procedencia: <https://opengameart.org/content/tarot-cards-major-arcana>
- Obra: *Tarot Cards (Major Arcana)* / Tarot de Marseille atribuido a Jean Dodal.
- Autor indicado por la página: Jean Dodal; publicación digital enviada por Clint Bellanger.
- Licencia indicada: CC0.
- Archivo publicado: `tarot_de_marseilles_major_arcana.zip`.
- Contenido declarado: 22 Arcanos Mayores.
- Tamaño declarado por carta: 200×375 px.

La página de OpenGameArt, no la URL directa del ZIP, debe conservarse como `fuente` en la procedencia: es donde se declara licencia, autoría y transformaciones realizadas sobre las imágenes de dominio público.

## Mapeo canónico

La numeración se toma del lote **Tarot de Marseille**. En particular, este mazo usa **VIII = Justice** y **XI = Strength**. No se debe deducir la carta a partir de la posición de `godot/datos/prometeo.json`, donde `la-fuerza` aparece antes que `la-justicia`.

| Nº Marsella | Arcano de la fuente | ID del juego | Destino final previsto |
| ---: | --- | --- | --- |
| 0 | The Fool | `el-loco` | `godot/assets/tarot/el-loco.png` |
| I | The Magician | `el-mago` | `godot/assets/tarot/el-mago.png` |
| II | The High Priestess | `la-sacerdotisa` | `godot/assets/tarot/la-sacerdotisa.png` |
| III | The Empress | `la-emperatriz` | `godot/assets/tarot/la-emperatriz.png` |
| IV | The Emperor | `el-emperador` | `godot/assets/tarot/el-emperador.png` |
| V | The Pope | `el-hierofante` | `godot/assets/tarot/el-hierofante.png` |
| VI | The Lovers | `los-enamorados` | `godot/assets/tarot/los-enamorados.png` |
| VII | The Chariot | `el-carro` | `godot/assets/tarot/el-carro.png` |
| VIII | Justice | `la-justicia` | `godot/assets/tarot/la-justicia.png` |
| IX | The Hermit | `el-ermitanio` | `godot/assets/tarot/el-ermitanio.png` |
| X | The Wheel of Fortune | `la-rueda` | `godot/assets/tarot/la-rueda.png` |
| XI | Strength | `la-fuerza` | `godot/assets/tarot/la-fuerza.png` |
| XII | The Hanged Man | `el-colgado` | `godot/assets/tarot/el-colgado.png` |
| XIII | Death | `la-muerte` | `godot/assets/tarot/la-muerte.png` |
| XIV | Temperance | `la-templanza` | `godot/assets/tarot/la-templanza.png` |
| XV | The Devil | `el-diablo` | `godot/assets/tarot/el-diablo.png` |
| XVI | The Tower | `la-torre` | `godot/assets/tarot/la-torre.png` |
| XVII | The Star | `la-estrella` | `godot/assets/tarot/la-estrella.png` |
| XVIII | The Moon | `la-luna` | `godot/assets/tarot/la-luna.png` |
| XIX | The Sun | `el-sol` | `godot/assets/tarot/el-sol.png` |
| XX | The Judgment | `el-juicio` | `godot/assets/tarot/el-juicio.png` |
| XXI | The World | `el-mundo` | `godot/assets/tarot/el-mundo.png` |

## Uso del importador

Puede usarse sobre el ZIP original o sobre una carpeta ya extraída:

```bash
python3 scripts/import_tarot_cc0.py /ruta/tarot_de_marseilles_major_arcana.zip --dry-run
python3 scripts/import_tarot_cc0.py /ruta/tarot_de_marseilles_major_arcana.zip
```

El `--dry-run` comprueba sin escribir:

- que `godot/datos/prometeo.json` conserva exactamente los 22 IDs esperados;
- que hay exactamente 22 imágenes fuente;
- que cada imagen se puede asociar a un único arcano por nombre o numeración;
- que cada imagen mide exactamente 200×375 px;
- que no falta ni se duplica ningún arcano.

Sin `--dry-run`, el staging contiene 22 ficheros con ID canónico y `tarot-cc0-manifest.json`. El manifiesto incluye el `sha256` calculado sobre cada fichero **realmente generado**; esos hashes no se deben copiar a procedencia hasta integrar exactamente esos mismos bytes.

Si el lote contiene JPEG, la normalización a `.png` requiere Pillow. El script no instala dependencias automáticamente. Las entradas PNG se copian sin recomprimir.

Prueba aislada:

```bash
python3 -m unittest scripts.test_import_tarot_cc0
```

También queda incluida en el descubrimiento normal de `scripts/test_*.py`.

## Segundo corte: integración de assets

Solo después de que #395 deje estable el montaje 3D:

1. Ejecutar el importador contra el ZIP fuente real y revisar el manifiesto.
2. Copiar los 22 PNG resultantes a `godot/assets/tarot/` mediante el flujo LFS real del repositorio; no fabricar punteros LFS desde la API de contenidos.
3. Añadir una entrada por carta en `godot/assets/procedencia.json`, usando el `sha256` del manifiesto que corresponda exactamente al fichero integrado.
4. Conectar `carta_id -> res://assets/tarot/<carta_id>.png` al material/frontal 3D resultante de #395, sin volver al plano 2D provisional.
5. Validar visualmente las ocho cartas ocultas de expedientes y, como mínimo, una carta obtenida por progresión normal. Esa comprobación debe ser humana; CI headless no cuenta como validación visual.

Plantilla de procedencia **sin hash inventado**:

```json
{
  "ruta": "tarot/el-loco.png",
  "titulo": "Tarot de Marseille — The Fool",
  "autor": "Jean Dodal (publicación digital enviada por Clint Bellanger)",
  "licencia": "CC0-1.0",
  "fuente": "https://opengameart.org/content/tarot-cards-major-arcana",
  "sha256": "<copiar del manifiesto generado con el fichero real>"
}
```

La integración final no debe cambiar desbloqueos, canje, persistencia, historias políticas ni el resultado de saltar/reducir movimiento en la cinemática; este trabajo solo sustituye el frontal provisional por arte con procedencia verificable.
