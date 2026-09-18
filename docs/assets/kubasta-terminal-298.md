# Kubasta — rol tipográfico de terminal (#298)

Fuente canónica: https://zichy.itch.io/kubasta  
Licencia publicada por el autor: **CC0-1.0 / Public Domain**.

## Estado del proyecto

Desde #836, `main` ya empaqueta **IBM Plex Mono** y
`EstiloSiga.fuente_mono()` dejó de depender de fuentes instaladas en el
sistema. #945 separó además el rol semántico de terminal para que Kubasta pueda
entrar sin alterar la monoespaciada genérica.

#1041 dejó integrado en `main` el paquete auditado, el fallback y el materializador reproducible:

- ZIP: **41.483 bytes**;
- SHA-256 del ZIP:
  `e2d4c74fbec43a9c5b9d1b818fb943976144be2980bd504e83b0f4f21a8a288c`;
- miembro seleccionado: `Kubasta/Kubasta.ttf`;
- TTF: **150.820 bytes**;
- SHA-256 del TTF:
  `73febb398631f45a0763e275dcb8c4d60fe74ac9e00e74edb21b176f7b4d6824`;
- familia detectada: **Kubasta Regular**;
- `cmap`: **902 puntos Unicode**.

La auditoría estática confirma los caracteres del contrato:
**áéíóúüñ¿¡ ÁÉÍÓÚÜÑ** y `0123456789 []{}:/\\-_+*=#`.

## Rol y fallback

- `fuente_mono()`: IBM Plex Mono para rótulos técnicos, publicaciones, texto
  3D y otros consumidores generales;
- `fuente_terminal()`: intenta cargar
  `res://assets/fonts/Kubasta.ttf` cuando el recurso está disponible;
- si Kubasta no está materializada, no está importada o no puede cargarse,
  `fuente_terminal()` vuelve a IBM Plex Mono;
- `terminal_font` sigue limitado a `RichTextLabel` y `LineEdit`; no se
  convierte Kubasta en fuente global.

Por tanto, mergear este corte **no cambia visualmente** un checkout que aún no
contenga el TTF LFS.

## Consumidores reales

El rol ya no queda como una entrada de `Theme` sin uso:

- el visor SIGA aplica `terminal_font` a la cabecera técnica del registro
  (folio/tipo/fecha) y a la barra de estado;
- el cuerpo del documento conserva `document_font` (MFB Oldstyle), por lo que
  Kubasta no invade la lectura de expedientes;
- la consola de playtest aplica `fuente_terminal()` tanto al registro
  `RichTextLabel` como a la línea de comandos `LineEdit`;
- mientras `Kubasta.ttf` no exista, esos consumidores reciben IBM Plex Mono
  mediante el fallback ya integrado.

Esto convierte #298 en una integración funcional y acotada: cuando el objeto
LFS real entre en el repositorio, las superficies anteriores cambiarán de
identidad sin modificar la tipografía global ni el texto documental.

## Materialización reproducible

El conector de GitHub puede versionar código y punteros, pero no subir el objeto
binario al almacén Git LFS. Para evitar un puntero huérfano, el TTF debe
materializarse desde un checkout real con Git LFS:

```bash
python scripts/materializar_kubasta_298.py /ruta/a/Kubasta.zip
python scripts/materializar_kubasta_298.py /ruta/a/Kubasta.zip --aplicar
```

El materializador:

1. exige por defecto el SHA-256 exacto del ZIP auditado;
2. permite un ZIP reempaquetado solo con `--aceptar-reempaquetado` y únicamente
   si el TTF coincide byte a byte por **hash y tamaño**;
3. extrae solo `Kubasta/Kubasta.ttf`, sin desplegar el resto del ZIP;
4. escribe `godot/assets/fonts/Kubasta.ttf`;
5. fusiona una ficha idempotente en `godot/assets/procedencia.json` con autor,
   CC0-1.0, fuente canónica, hash, miembro de origen y hash del paquete;
6. exige que `.gitattributes` resuelva `*.ttf` a `filter=lfs`;
7. hace `git add` de TTF + procedencia;
8. lee el blob desde el índice y exige el puntero LFS canónico con OID
   `73febb398631f45a0763e275dcb8c4d60fe74ac9e00e74edb21b176f7b4d6824`
   y tamaño `150820`;
9. restaura fichero/procedencia y deshace staging si la operación falla.

## Matriz de validación pendiente

La cobertura de glifos ya está comprobada estáticamente. La aceptación visual
sigue requiriendo el TTF materializado y debe cubrir:

- tamaños **10/12/14/16 px**;
- alto contraste claro/oscuro;
- **escalado entero** y **escalado no entero**;
- comparación frente a IBM Plex Mono en la misma superficie;
- fallback sin cajas vacías ni sustituciones silenciosas;
- ausencia de recortes o cambios de layout en terminales y bloques técnicos.

## Criterio de alcance

Kubasta queda acotada a identidad de terminal y texto técnico pequeño. No debe
sustituir MFB Oldstyle, Atkinson Hyperlegible ni IBM Plex Mono fuera de ese rol
sin un playtest específico.

Refs #172 #216 #780 #836 #945.

— Odiseo (GPT-5.6 Sol)
