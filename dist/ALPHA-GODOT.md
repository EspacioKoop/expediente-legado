# Alpha del port Godot

Este empaquetado es distinto de `dist/empaquetar-alpha.sh`, que sigue siendo el
build histórico del backend web con JRE embebido.

## Testers externos: sin Git ni checkout

El canal `playtest-latest` publica launchers junto a cada alpha para que probar
una build no requiera clonar el repositorio ni localizar artifacts de Actions.

### Windows: flujo recomendado

Descarga **`SIGA-98-Actualizador-Windows.zip`** desde la prerelease
`playtest-latest`, extrae sus dos archivos en cualquier carpeta y haz doble
clic en:

```text
Actualizar-SIGA98.cmd
```

El paquete contiene también `Actualizar-SIGA98.ps1`. El CMD únicamente lanza
ese actualizador local; no descarga ni ejecuta scripts remotos.

El actualizador usa Windows PowerShell incluido en Windows y:

1. consulta el JSON pequeño de la build actual;
2. compara su SHA con el de la instalación local;
3. no descarga el juego si ya es la misma build;
4. si cambió, descarga `SIGA-98-playtest-windows.zip`;
5. verifica SHA-256 contra el fichero publicado por CI;
6. extrae primero a una carpeta temporal y sustituye la instalación solo cuando
   el paquete está completo;
7. arranca `SIGA-98.exe`.

La ruta por defecto es:

```text
%LOCALAPPDATA%\SIGA98\playtest
```

No necesita Git, GitHub CLI, Python, WSL, Git Bash ni Godot.

Desde una consola se pueden usar opciones adicionales:

```text
Actualizar-SIGA98.cmd -NoRun
Actualizar-SIGA98.cmd -Force
Actualizar-SIGA98.cmd -InstallDir "D:\Juegos\SIGA98-playtest"
```

### Linux: sin clonar el repositorio

Descarga `Actualizar-SIGA98.sh` desde la misma prerelease y ejecuta:

```bash
bash Actualizar-SIGA98.sh
```

El launcher Linux mantiene las opciones `--no-run`, `--force`,
`--platform` y `--dir`.

## Desarrollo: usar el launcher desde el checkout

Desde un checkout del repositorio también puede ejecutarse:

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

La instalación Linux por defecto queda en:

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

### Dependencias del launcher Linux

- `curl`;
- `python3`;
- `unzip`;
- `sha256sum`;
- `awk`.

No necesita GitHub CLI ni token porque el repositorio y la prerelease de QA son
públicos.

## Cómo se publica el canal continuo

`.github/workflows/alpha-playtest.yml` exporta automáticamente una alpha cuando
un cambio relevante llega a `main`. Tras pasar el smoke y las auditorías:

- conserva los artifacts normales del run;
- actualiza la prerelease `playtest-latest`;
- publica `SIGA-98-playtest-linux.zip`;
- publica `SIGA-98-playtest-windows.zip`;
- publica `SIGA-98-Actualizador-Windows.zip`, que contiene el CMD y el
  PowerShell juntos;
- publica `Actualizar-SIGA98.sh` para Linux;
- publica `SIGA-98-playtest-SHA256SUMS.txt`;
- publica `SIGA-98-playtest-build.json`.

Los checksums cubren los dos paquetes del juego, el paquete de actualizador
Windows y el launcher Linux distribuidos.

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
