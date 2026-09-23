# Horror Texture Pack — biblioteca de desgaste para #231

Fuente canónica: https://screamingbrainstudios.itch.io/horror-texture-pack  
Autor: Screaming Brain Studios  
Licencia: **CC0-1.0 / dominio público**.

## Auditoría de los archivos aportados

Se han inspeccionado los tres RAR originales aportados para #231. Cada uno contiene los mismos **100 diseños** a una resolución distinta, más `License.txt`:

| Resolución | SHA-256 del RAR |
| --- | --- |
| 128×128 | `1fee483ce0253e64096442a2c16833ec9da90bdfa2836e5d54a061f293abf6fb` |
| 256×256 | `6c78d279ce669d548ce77adf6dd768e40e1436498326a0bbce578f82cab6e9f0` |
| 512×512 | `29feed70b77a17b974cce79a4f343f5f4fdf8f56cec0af91335083bf4cceaae4` |

`License.txt` declara los assets de Screaming Brain Studios bajo CC0/Public Domain, para uso comercial o no comercial sin restricciones. El manifiesto versionado fija estos hashes, el recuento y los perfiles curados en `docs/assets/horror-texture-pack.manifest.json`.

El catálogo por resolución es: 14 Brick + 14 Floor + 14 Metal + 15 Misc + 15 Stains + 14 Stone + 14 Wall = **100 diseños**. Las 15 imágenes `Stains` conservan alfa; se pueden montar como `Sprite3D` mediante `DecalCompat` en el renderer Compatibility.

## No es un “tema horror” global

#231 se trata como **biblioteca transversal de degradación**. La misma fuente sirve para dos intensidades:

- **mundo ordinario:** suciedad, roce, humedad, metal castigado y pequeñas roturas que quitan aspecto de greybox sin convertir oficina/casa/calle en terror;
- **sueño:** materiales conocidos deformados, repetidos o degradados con mucha más libertad. Aquí el pack puede reforzar escuela, archivo industrial, castillo, desierto/mineral y fases de pesadilla.

Los perfiles del manifiesto son deliberadamente semánticos (`sutil`, `sueno_archivo`, `sueno_escuela`, `sueno_castillo`, `sueno_desierto`, `sueno_pesadilla`). Son una selección reutilizable, no una obligación de usar todos sus elementos a la vez.

Las manchas `Stain 01–03` se excluyen de **todos los perfiles automáticos** porque se leen claramente como sangre. Solo pueden entrar en un uso explícito y justificado; no son “suciedad genérica”. `Stain 04–05` tampoco forman parte de la selección por defecto por su lectura orgánica ambigua.

## Política de resolución

**128×128 es la resolución runtime por defecto.** Encaja con el tratamiento PSX, mantiene el píxel visible y evita pagar memoria por detalle que el shader y la cámara no necesitan.

256×256 y 512×512 quedan como fuentes auditadas para casos concretos: primer plano, superficie hero, cinemática o transformación onírica donde una captura demuestre que 128×128 no basta. No se importan las tres resoluciones del mismo diseño por inercia.

## Preparación reproducible

```bash
python3 scripts/preparar_horror_texture_pack.py \
  "/ruta/SBS - Horror Texture Pack 128x128.rar" \
  --perfil sueno_escuela
```

También acepta una carpeta ya extraída. Si recibe un RAR, verifica su SHA-256 contra el manifiesto antes de extraerlo. Por defecto usa 128×128 y, sin `--perfil`, prepara la unión de los perfiles curados. `--todos --permitir-gore` permite auditar/preparar los 100 diseños de una resolución; el segundo flag es deliberadamente obligatorio porque el lote completo contiene Stain 01–03. Esa importación masiva no es una recomendación artística.

El script:

1. valida el RAR o la estructura extraída;
2. comprueba dimensiones y alfa de las manchas seleccionadas;
3. copia a `godot/assets/texturas/horror_sbs/<resolución>/...`;
4. calcula SHA-256 por PNG;
5. escribe `procedencia.fragment.json` para revisión.

No modifica `godot/assets/procedencia.json` y **no crea punteros LFS**. Los PNG preparados deben incorporarse después mediante Git LFS real, conforme a `.gitattributes`; un puntero sin su objeto LFS no es una integración válida.

### Lote instalado

El repositorio contiene, como objetos Git LFS reales, **exactamente los 17 PNG
128×128 que consumen los `PERFILES` de `HorrorTexturas`**: los 10 de muro y suelo
(Brick 11, Floor 12, Metal 06, Misc 13, Stone 07/10/13/14 y Wall 05/09) y las
manchas Stain 07 y 10–15. Se prepararon con el script anterior a partir del RAR
128×128 auditado, y cada uno tiene su ficha en `procedencia.json`. El
`License.txt` del RAR confirma CC0 1.0.

El resto de la unión de perfiles curados del manifiesto no se importa mientras
ningún consumidor lo cargue. `scripts/test_horror_texturas.py` exige que el lote
coincida con los perfiles del runtime, y `horror_texturas_smoke.gd` que cada
pieza planificada se aplique y cargue como `Texture2D` de 128×128, con alfa en
las manchas. Las capturas A/B están en `docs/evidencias/horror-texturas-231/`.

## Integración runtime

`TexturaProcedural` admite rutas `res://` directas además de los alias JPG históricos. Así un espacio puede declarar una textura importada sin crear un segundo sistema de materiales, manteniendo fallback cuando el pack no está instalado.

`HorrorTexturas` aplica el pack **después** de que la forma haya adquirido su identidad onírica final. Escuela, castillo, desierto y montaña reciben perfiles distintos; las formas sin identidad fuerte caen en un perfil de archivo. La intensidad progresa dentro de la misma noche (suave → media → alta) y puede subir un grado cuando la sala ya contiene un acusado retable. El primer nivel conserva el suelo conocido; a partir del segundo el desgaste invade también el suelo. Las manchas se anclan únicamente junto a carteles ya legitimados por #87 y nunca usan Stain 01–05. La ausencia de los binarios deja el aspecto actual intacto y sin warnings.

`Espacio3D` monta además la colección opcional `decals` mediante `DecalCompat`, por lo que paredes, suelo o props pueden declarar manchas transparentes sin acoplarse al renderer ni duplicar colisión.

## Mapa de usos

| Contexto | Materiales candidatos | Decals/anomalías |
| --- | --- | --- |
| Oficina/casa/calle | Wall 02/09, Metal 06/11 | Stain 06–09 a opacidad baja |
| Sueño archivo/industrial | Metal 05/06/11/13, Misc 13 | Stain 10–12, escorrentías verticales |
| Sueño escuela | Floor 12/14, Wall 08/09/10/14 | Stain 07/10/13, humedad y desgaste repetitivo |
| Sueño castillo | Brick 07/10/11/14, Stone 03/07/10/14 | Stain 13/14, musgo/humedad pesada |
| Sueño desierto/mineral | Stone 09/13, Wall 04/05 | Stain 15 como polvo/velo/soot |
| Pesadilla intensa | Wall 11–14, Metal 09/14 | Stain 10–15, nunca 01–03 automáticamente |

El objetivo no es maximizar el número de texturas visibles. Es disponer de una paleta amplia y trazable para que cada espacio pueda degradarse con intención, sobre todo en el sueño, sin caer en una suma de assets genéricos.

Refs #216 #231 #279 #284 #398 #399.

— Odiseo (GPT-5.6 Sol)
