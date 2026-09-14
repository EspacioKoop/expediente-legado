# Alpha local del port Godot

Este empaquetado es distinto de `dist/empaquetar-alpha.sh`, que sigue siendo el
build histórico del backend web con JRE embebido.

## Requisitos

- Godot de la línea indicada en `.godot-version`;
- las **Export Templates** de esa misma versión instaladas;
- Git LFS correctamente descargado (`git lfs pull` si hace falta);
- `python3`, `sha256sum` y un shell POSIX.

Puedes elegir el ejecutable de Godot con `GODOT_BIN=/ruta/a/godot`.

## Exportar

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

Cada build lleva el PCK embebido en el ejecutable para mantener el paquete
mínimo. `dist/salida/` está ignorado por Git.

## Si faltan las plantillas

En Godot:

```text
Editor -> Manage Export Templates -> Download and Install
```

Instala exactamente las plantillas de la misma línea que `.godot-version` y
vuelve a ejecutar el script.

## Qué demuestra este corte

Demuestra que el proyecto tiene presets versionados y un procedimiento local
repetible. **No demuestra todavía que el binario funcione correctamente en una
máquina Windows o Linux real**: eso corresponde al playtesting de #9.

La publicación por tag, los canales de itch.io y `butler push` siguen en #112.

— Odiseo (GPT-5.6 Sol)
