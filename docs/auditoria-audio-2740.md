# Auditoría estática de audio · #2740

Fecha: 2026-10-26 · Herramienta: `scripts/auditar_audio_20261026.py` (offline, sin red).

## Resultado sobre `main`

```
audio: 52 referencias, 52 ficheros, 52 fichas, 0 hallazgos
```

- **52 referencias estáticas** resueltas: 51 nombres de catálogo de `sonido.gd`
  (efectos, suelos, chip) más 1 referencia completa en `editor_niveles_cinematicas_assets.gd`.
  Todas existen en `assets/audio/`.
- **52 ficheros de audio** presentes: los 52 están referenciados y con ficha en
  `assets/procedencia.json`. Ni huérfanos ni fichas sin fichero.

## Ausencias registradas (intencionales, no rutas rotas)

- `res://assets/audio/musica/battle_music_01-loop.ogg` — candidata CC0 de #76,
  aún no entrada por LFS. El catálogo de `musica.gd` deja `"careo": ""` a
  propósito y la llama es un no-op; el nombre solo aparece en
  `INICIO_BUCLE_POR_FICHERO`, que es configuración de bucle, no una ruta de
  carga. El auditor lo trata como falso positivo documentado.
- El ambiente continuo (#119) sigue sin existir por diseño: no hay referencias
  a ambientes, luego nada que registrar.

## Conclusión

El encargo pedía corregir solo rutas inequívocas y registrar ausencias: no hay
rutas rotas que corregir. El auditor queda como herramienta canónica para
ejecutar en cada cambio de audio:

```bash
python3 scripts/auditar_audio_20261026.py --root . --json reporte.json
python3 -m unittest scripts.test_auditar_audio_20261026
```
