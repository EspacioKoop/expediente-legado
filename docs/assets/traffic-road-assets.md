# Traffic Road Assets — contrato de integración (#225)

Fuente verificada: **jamesdev — Traffic Road Assets**  
Página: https://milkandbanana.itch.io/traffic-road-assets  
Licencia de assets publicada por el autor: **CC0 1.0 Universal**.  
La página del pack declara además que no se utilizó IA generativa.

## Alcance real de la fuente

La página oficial enumera estas familias:

- traffic cones;
- crush barriers / fences;
- manhole covers;
- wooden / concrete / plastic roadblocks;
- streetlights;
- water hydrants.

El pack publica **FBX y GLB**, usa una textura atlas y tres materiales.

Importante: la fuente **no anuncia** mallas de carretera, cruces, señales de tráfico ni vehículos. Por tanto, #225 no debe fingir que esas piezas salen de este pack. Este vertical se limita a *roadside dressing* y obstáculos visuales. La carretera base puede reutilizar el asfalto CC0 ya versionado; los vehículos civiles y eventual tráfico lejano pertenecen a #230.

## Selección mínima para SIGA-98

No importar el pack completo. Primer lote recomendado, sujeto a inspección visual del ZIP real:

1. **Manhole cover**: detalle neutro para romper superficies de asfalto.
2. **Concrete roadblock**: masa simple para un borde de obra/servicio, preferiblemente al fondo.
3. **Traffic cone**: 1–3 instancias como detalle secundario, sin convertir la calle en una obra permanente.
4. **Streetlight**: solo si la silueta no resulta demasiado contemporánea para el entorno de 1998.

Quedan fuera del primer corte:

- **water hydrants**, por su lectura geográfica potencialmente poco coherente con el entorno;
- variantes de plástico o piezas cuya forma/color parezca demasiado contemporánea;
- cualquier elemento que, tras abrir el ZIP, dependa de señalética/logos no coherentes con época y lugar.

La selección final debe hacerse mirando los modelos reales, no por el nombre de archivo.

## Tratamiento visual

- materiales apagados y compatibles con el tratamiento PSX/low-poly del proyecto;
- reducir saturación del atlas si compite con elementos interactivos;
- evitar brillo PBR fuerte;
- sin logos añadidos ni señalización inventada para justificar la fuente;
- mezclar estas piezas con el asfalto/fachadas/vehículos de otras fuentes CC0 para que el pack no se lea como bloque reconocible;
- priorizar silueta y masa en elementos lejanos.

## Uso jugable y coste

Este pack entra como escenografía. En el primer corte:

- sin `RigidBody3D`, IA ni interacción;
- sin colisión detallada para piezas fuera del recorrido;
- colisión simple únicamente si una barrera invade físicamente una zona alcanzable;
- máximo orientativo de 4–8 piezas visibles de este pack en una misma vista;
- luces de farola, si se usan, deben resolverse con presupuesto explícito: preferir material/emisión o iluminación compartida antes que una luz dinámica por farola.

El **tráfico lejano en movimiento no lo proporciona este pack**. Si se añade, debe reutilizar los coches de #230 y una ruta simple, sin navegación, avoidance ni física de vehículo. Ese movimiento debe quedar visualmente al fondo y no cruzar la ruta del jugador en el primer corte.

## Procedencia y LFS

Todo fichero finalmente incorporado bajo `godot/assets/` necesita entrada real en `godot/assets/procedencia.json` con:

- ruta exacta;
- título/modelo;
- autor `jamesdev`;
- licencia `CC0-1.0`;
- fuente `https://milkandbanana.itch.io/traffic-road-assets`;
- `sha256` calculado sobre el fichero exacto que entra al repositorio.

Los `.glb`, `.fbx` y texturas raster deben entrar mediante **Git LFS real**, conforme a `.gitattributes`. No se deben subir como blobs normales mediante la API de contenidos de GitHub.

## Checklist del PR binario

- [ ] descargar `Traffic Road Assets.zip` desde la página oficial;
- [ ] inspeccionar nombres, escalas, atlas y materiales reales del ZIP;
- [ ] elegir solo 3–4 modelos neutrales de las familias anteriores;
- [ ] descartar piezas con lectura temporal/geográfica problemática;
- [ ] importar preferentemente GLB; no conservar FBX duplicado en runtime si no hace falta;
- [ ] comprobar que cada binario entra como puntero LFS;
- [ ] calcular SHA-256 de cada fichero final y registrar `procedencia.json`;
- [ ] adaptar materiales al look SIGA-98 sin introducir señalética nueva;
- [ ] colocar las piezas fuera de objetivos interactivos y del paso principal;
- [ ] medir el coste con varias instancias simultáneas;
- [ ] ejecutar importación Godot, suite, arranque y Alpha;
- [ ] validación visual humana de época, escala, clipping y legibilidad.

## Relación con otros issues

- #216: catálogo CC0 padre y reglas visuales/rendimiento.
- #230: coches civiles; es la fuente correcta para tráfico lejano con movimiento simple.
- #225: este pack aporta mobiliario/obstáculos viales, no vehículos ni una red de carreteras.

## Fuera de alcance de este corte

Este documento **no cierra #225**. Fija una selección honesta y reproducible antes de introducir binarios. El issue debe seguir abierto hasta que un pequeño lote real entre por LFS, quede registrado con hashes y sea visible en el trayecto con validación visual.

— Odiseo (GPT-5.6 Sol)
