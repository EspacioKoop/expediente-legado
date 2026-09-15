# #399 — contrato para materiales PBR 4K de calle y sueño

Este corte prepara la entrada de texturas **grandes y fotorrealistas** sin fingir que una lámina de referencia es un asset final. Los binarios reales deben entrar por Git LFS, con licencia/fuente/hash verificables; el script de `scripts/preparar_texturas_pbr.py` valida y organiza el set antes de subirlo.

## Materiales objetivo

La referencia visual de este corte se traduce a nueve familias de material:

- `acera_barcelona`
- `asfalto_urbano`
- `fachada_edificio`
- `metal_puerta`
- `cristal_escaparate`
- `azulejo_hidraulico`
- `asfalto_sueno`
- `fachada_sueno`
- `suelo_onirico`

Cada material se entrega como un set de cuatro mapas con el mismo tamaño:

```text
albedo.jpg       # 4096x4096 o superior; JPG para compatibilidad inmediata
normal.png       # 4096x4096 o superior
roughness.png    # 4096x4096 o superior
ao.png           # 4096x4096 o superior
```

El objetivo 4K es conservar detalle en el **master**; el aspecto retro/PSX se sigue decidiendo en el import/shader del juego. No se debe confundir una fuente fotorrealista con eliminar el tratamiento PSX de #115.

## Integración runtime

`TexturaProcedural.por_nombre()` sigue intentando cargar `res://assets/texturas/<nombre>.jpg` antes de usar el fallback procedural. El preparador conserva esa compatibilidad y, además, guarda el set completo en:

```text
godot/assets/texturas/pbr/<nombre>/
```

`TexturasPBR` detecta esa carpeta y crea un material con `psx_pbr.gdshader` cuando existe al menos el albedo. La variante PBR conserva temblor de vértices, cuantización de color y dithering Bayer, pero usa iluminación por píxel para que normal/roughness/AO puedan aportar volumen. El shader PSX canónico no se modifica: cualquier superficie sin set PBR conserva el camino anterior.

La primera integración real está en `CalleMateriales`: las tres masas de fachada intentan cargar `fachada_edificio`. Si el set no está disponible —por ejemplo, en un checkout sin objetos Git LFS— vuelven automáticamente al `revoco_urbano` procedural ya integrado.

El mapa normal se aplica únicamente cuando el material usa UV de malla; roughness y AO funcionan tanto en UV como en el muestreo triplanar de la variante PBR. Este primer corte evita fingir un normal triplanar correcto sin transformar el espacio tangente de cada proyección.

Ejemplo de preparación:

```bash
python3 scripts/preparar_texturas_pbr.py /tmp/acera_barcelona \
  --nombre acera_barcelona \
  --autor "<autor real>" \
  --licencia "<licencia real>" \
  --fuente "<URL o descripción verificable>"
```

La carpeta de entrada debe contener exactamente `albedo`, `normal`, `roughness` y `ao` en PNG/JPG. El script exige 4096 px por lado como mínimo, dimensiones coherentes y metadatos de procedencia no vacíos; después calcula SHA-256, copia los mapas y emite `procedencia.fragment.json`.

## Git LFS y procedencia

`.gitattributes` ya envía PNG/JPG a Git LFS. No debe crearse manualmente un puntero LFS si el objeto binario no se puede subir también al almacén LFS. El flujo correcto es preparar el set en un checkout real con Git LFS, revisar `procedencia.fragment.json`, fusionar esas entradas en `godot/assets/procedencia.json` y solo entonces hacer `git add`/commit.

El fragmento se genera aparte a propósito: `procedencia.json` es la fuente de verdad y no debe ser sobrescrito automáticamente ni rellenado con autor/licencia/fuente inventados.

## QA visual antes de dar por bueno un material

El validador comprueba estructura, tamaño y hashes, no calidad artística. Antes de integrar un set hay que revisar manualmente: costuras en mosaico 2x2, escala física coherente, normal sin inversión de canal Y, roughness sin clipping, ausencia de texto/logos accidentales y legibilidad real con el tratamiento PSX activo.

Para sueño, la deformación debe seguir partiendo de un material reconocible: `asfalto_sueno`, `fachada_sueno` y `suelo_onirico` no deben convertirse en ruido oscuro genérico.
