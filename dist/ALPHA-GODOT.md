# Alpha del port Godot

Este empaquetado es distinto de `dist/empaquetar-alpha.sh`, que sigue siendo el
build histórico del backend web con JRE embebido.

## Playtest rápido: actualizar y jugar

Para probar el `main` más reciente sin clonar otra vez ni localizar artefactos
a mano:

```bash
bash scripts/playtest.sh
```

El script:

1. consulta los metadatos pequeños del canal `playtest-latest`;
2. compara el SHA remoto con la build instalada;
3. si no cambió, arranca inmediatamente la copia local;
4. si cambió, descarga solo el ZIP de tu plataforma;
5. verifica su SHA-256 antes de sustituir la instalación;
6. arranca el juego.

La instalación por defecto queda en:

```text
~/.local/share/siga98-playtest/linux/
```

Puedes descargar sin ejecutar:

```bash
bash scripts/playtest.sh --no-run
```

Forzar una descarga aunque el SHA coincida:

```bash
bash scripts/playtest.sh --force
```

Descargar el paquete de Windows desde Linux, por ejemplo para copiarlo a otra
máquina:

```bash
bash scripts/playtest.sh --platform windows --no-run
```

También puedes elegir la ruta con `--dir RUTA` o
`SIGA98_PLAYTEST_DIR=/ruta`.

### Dependencias del actualizador

- `curl`;
- `python3`;
- `unzip`;
- `sha256sum`;
- `awk`.

No necesita GitHub CLI ni token para descargar porque el repositorio y la
prerelease de QA son públicos.

## Cómo se publica el canal continuo

`.github/workflows/alpha-playtest.yml` exporta automáticamente una alpha cuando
un cambio relevante llega a `main`. Tras pasar el smoke y las auditorías:

- conserva los artifacts normales del run;
- actualiza la prerelease `playtest-latest`;
- publica `SIGA-98-playtest-linux.zip`;
- publica `SIGA-98-playtest-windows.zip`;
- publica `SIGA-98-playtest-SHA256SUMS.txt`;
- publica `SIGA-98-playtest-build.json`.

Los PR siguen generando artifacts efímeros, pero **no** actualizan
`playtest-latest`.

El tag `playtest-latest` funciona como ancla estable para URLs de descarga; no
es el identificador de la revisión contenida en cada actualización. La fuente de
verdad es `SIGA-98-playtest-build.json` y el `BUILD-INFO.txt` incluido dentro
de cada ZIP, ambos con el SHA real.

Las releases versionadas `v*` conservan su flujo separado y #112 mantiene
pausada la publicación en itch.io.

## Exportar localmente

### Requisitos

- Godot de la línea indicada en `.godot-version`;
- las **Export Templates** de esa misma versión instaladas;
- Git LFS correctamente descargado (`git lfs pull` si hace falta);
- `python3`, `sha256sum` y un shell POSIX.

Puedes elegir el ejecutable de Godot con `GODOT_BIN=/ruta/a/godot`.

Desde la raíz del repositorio:

```bash
bash dist/exportar-godot-alpha.sh
```

El script valida la línea de Godot, exporta en modo `release` y genera:

```text
dist/salida/SIGA-98-godot-alpha-linux.zip
dist/salida/SIGA-98-godot-alpha-windows.zip
dist/salida/SIGA-98-godot-alpha-SHA256SUMS.txt
```

Cada build lleva el PCK embebido en el ejecutable y un `BUILD-INFO.txt` con
SHA, ref, versión de Godot, modo QA y hora de construcción.
`dist/salida/` está ignorado por Git.

## Si faltan las plantillas

En Godot:

```text
Editor -> Manage Export Templates -> Download and Install
```

Instala exactamente las plantillas de la misma línea que `.godot-version` y
vuelve a ejecutar el script.

## Qué demuestra este flujo

Automatiza la obtención de una build identificable y verificable para reducir la
fricción del playtesting. **No demuestra que el binario funcione correctamente
en una máquina Windows o Linux real**: eso corresponde al playtesting humano de
#9.

— Odiseo (GPT-5.6 Sol)
