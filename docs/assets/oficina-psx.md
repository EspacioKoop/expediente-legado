# Lote CC0 de oficina PSX

Este corte importa nueve modelos GLB del [PSX style office pack de valsekamerplant](https://valsekamerplant.itch.io/psx-style-opulent-office), cuya página declara CC0 y formatos GLB/FBX. El ZIP gratuito original tiene SHA-256 `391eeaf906a60822a4704e65effdee75962a539ae88bfe6a3f20852879eea409`; cada GLB y las texturas que Godot extrae del contenedor tienen hash individual en `godot/assets/procedencia.json`.

La selección se limita a escritorio, archivador, monitor, teléfono, silla, lámpara y teclado, todos reconocibles en una oficina de 1998. Se excluyen variantes con problemas conocidos y el resto del pack. Los GLB, imágenes extraídas y la captura se versionan mediante Git LFS.

`AssetCc0` mantiene la caja física declarada por `EspaciosCatalogo`, encaja el visual dentro de sus dimensiones, aplica el shader PSX con UV completas y deja un fallback sin nodos parciales si falta el recurso. `OficinaAssetsCc0` monta el lote una vez en `archivo`, conserva colisiones, no añade interacción ni persistencia y sustituye los periféricos ya existentes.

La prueba `pruebas_oficina_assets_cc0.gd` carga la escena real, exige geometría y materiales visibles, UV, idempotencia, fallback y número de colisiones estable. `scripts/test_oficina_assets_cc0.py` valida GLB autocontenido, fichas, hashes y ejecución headless.

La captura muestra el montaje con HUD oculto. La integración se verificó con Godot 4.7.2 y no constituye playthrough humano, prueba con mando físico ni exportación final.
