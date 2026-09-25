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


## Validación humana de cierre (#645)

La presencia del asset, el hash, la importación de Godot y el cableado 3D sí se pueden comprobar automáticamente. La **legibilidad y correspondencia visual** de la carta en un export real siguen requiriendo revisión humana.

El capturador de `godot/pruebas/capturar.gd` permite generar evidencia reproducible de las ocho cartas ocultas por el camino jugable real. Localiza automáticamente el expediente que contiene cada folio y admite un cuarto argumento `normal` o `reducido`.

La forma recomendada es generar con un solo comando la matriz de cierre: **8 cartas ocultas × normal/reducido/skip + El Mago por progreso real × normal/reducido**:

```bash
python3 scripts/preparar_validacion_tarot_645.py
```

La salida queda en `dist/qa/tarot-645/` junto a un `manifest.json` con los **26 recorridos** y su resultado. Cada nombre empieza por `tarot-`, así que `--output` puede apuntar a cualquier directorio sin romper el dispatcher de QA. También existe `--dry-run` para revisar comandos sin abrir Godot.

El mismo comando genera `revision-humana.md` en ese directorio. La hoja agrupa las 26 evidencias, incrusta cada captura por ruta relativa y añade casillas de revisión para correspondencia visual, legibilidad, persistencia, skip y reducción de movimiento. Sirve para que el pase humano quede auditable sin convertir CI en una falsa aprobación visual.

Estas capturas sirven como **preflight visual reproducible**, no sustituyen el pase humano sobre el export candidato exigido por el criterio de cierre.

Cada ejecución debe usar un temporal XDG distinto. La carta se revela una sola vez y el capturador rechaza ejecutar Tarot sin `XDG_DATA_HOME`, para evitar que una prueba modifique la partida personal:

```bash
mkdir -p dist/qa/tarot-645

tmp="$(mktemp -d)"
XDG_DATA_HOME="$tmp/data" XDG_CONFIG_HOME="$tmp/config" XDG_CACHE_HOME="$tmp/cache" \
  xvfb-run -a godot4 --path godot --script pruebas/capturar.gd -- \
  ../dist/qa/tarot-645/la-justicia-normal.png ACTA-1999-014 2 normal

tmp="$(mktemp -d)"
XDG_DATA_HOME="$tmp/data" XDG_CONFIG_HOME="$tmp/config" XDG_CACHE_HOME="$tmp/cache" \
  xvfb-run -a godot4 --path godot --script pruebas/capturar.gd -- \
  ../dist/qa/tarot-645/la-justicia-reducido.png ACTA-1999-014 2 reducido

tmp="$(mktemp -d)"
XDG_DATA_HOME="$tmp/data" XDG_CONFIG_HOME="$tmp/config" XDG_CACHE_HOME="$tmp/cache" \
  xvfb-run -a godot4 --path godot --script pruebas/capturar.gd -- \
  ../dist/qa/tarot-645/la-justicia-skip.png ACTA-1999-014 -1 normal
```

Matriz mínima de folios/cartas:

| Folio | Carta |
| --- | --- |
| `ACTA-1999-014` | `la-justicia` |
| `OF-1990-114` | `la-rueda` |
| `MEMO-1993-201` | `el-juicio` |
| `F-1996-00187` | `la-luna` |
| `ACTA-2007-002` | `el-carro` |
| `FAX-1996-077` | `el-sol` |
| `OF-1998-077` | `la-emperatriz` |
| `ACTA-1998-427B` | `la-sacerdotisa` |

Para cada carta hay que revisar el frontal del plano 2 en modo normal y reducido, y comprobar que `-1` salta la cinemática y desemboca en la historia sin perder el hallazgo.

La comprobación de «al menos una carta obtenida por progresión normal» **no debe fabricarse desde QA**. #1029 porta como primer vertical la regla heredada primera pista → `el-mago`: el visor desbloquea la carta y su memoria fantasma en el mismo guardado de la pista, sin reutilizar la ruta de las ocho cartas ocultas ni abrir una historia política.

El generador anterior incluye ya las dos capturas de `el-mago` (`normal` y `reducido`). El capturador también puede prepararlas de forma aislada. Primero abre un documento real y descubre una pista por `_al_pulsar_marca`; solo después exige que `el-mago` esté recogido y conocido, y entonces usa `TarotCinematica` como visor de QA del frontal:

```bash
tmp="$(mktemp -d)"
XDG_DATA_HOME="$tmp/data" XDG_CONFIG_HOME="$tmp/config" XDG_CACHE_HOME="$tmp/cache" \
  xvfb-run -a godot4 --path godot --script pruebas/capturar.gd -- \
  ../dist/qa/tarot-645/el-mago-progreso-normal.png 2 normal

tmp="$(mktemp -d)"
XDG_DATA_HOME="$tmp/data" XDG_CONFIG_HOME="$tmp/config" XDG_CACHE_HOME="$tmp/cache" \
  xvfb-run -a godot4 --path godot --script pruebas/capturar.gd -- \
  ../dist/qa/tarot-645/el-mago-progreso-reducido.png 2 reducido
```

Estas capturas prueban el **camino de obtención** y preparan la imagen a revisar; no sustituyen la aprobación visual humana de #645, que **permanece pendiente**. #1029 sigue abierto para portar el resto de triggers no ocultos del legado.
