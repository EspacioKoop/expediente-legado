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
- desactivar sombras propias en este dressing secundario: la calle ya resuelve iluminación y no compensa una pasada adicional para cinco piezas;
- sin logos añadidos ni señalización inventada para justificar la fuente;
- mezclar estas piezas con el asfalto/fachadas/vehículos de otras fuentes CC0 para que el pack no se lea como bloque reconocible;
- priorizar silueta y masa en elementos lejanos.

## Uso jugable y coste

Este pack entra como escenografía. En el primer corte:

- sin `RigidBody3D`, IA ni interacción;
- sin colisión detallada para piezas fuera del recorrido;
- colisión simple únicamente si una barrera invade físicamente una zona alcanzable;
- máximo orientativo de 4–8 piezas visibles de este pack en una misma vista;
- las `MeshInstance3D` del lote no proyectan sombras y el contrato runtime lo verifica;
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

- [x] descargar `Traffic Road Assets.zip` desde la página oficial;
- [x] inspeccionar nombres, escalas, atlas y materiales reales del ZIP;
- [x] elegir solo 3–4 modelos neutrales de las familias anteriores;
- [x] descartar piezas con lectura temporal/geográfica problemática;
- [x] importar preferentemente GLB; no conservar FBX duplicado en runtime si no hace falta;
- [x] comprobar que cada binario entra como puntero LFS;
- [x] calcular SHA-256 de cada fichero final y registrar `procedencia.json`;
- [x] adaptar materiales al look SIGA-98 sin introducir señalética nueva;
- [x] colocar las piezas fuera de objetivos interactivos y del paso principal;
- [x] medir el coste con varias instancias simultáneas;
- [x] ejecutar importación Godot, suite, arranque y Alpha (PR #507: CI `34903760016` y Alpha `34903759979`, ambas en `success`);
- [ ] validación visual humana de época, escala, clipping y legibilidad; el workflow `Evidencia trafico vial 225` publica cuatro PNG + `manifest.json` reproducibles para este gate.

## Relación con otros issues

- #216: catálogo CC0 padre y reglas visuales/rendimiento.
- #230: coches civiles; es la fuente correcta para tráfico lejano con movimiento simple.
- #225: este pack aporta mobiliario/obstáculos viales, no vehículos ni una red de carreteras.

## Fuera de alcance de este corte

Este corte **no cierra #225**: el lote real descrito debajo queda integrado en el trayecto; la aceptación humana de época, escala y legibilidad sigue pendiente.

— Odiseo (GPT-5.6 Sol)


## Lote real de septiembre de 2026

Se incorporan byte a byte tres originales de `Traffic Road Assets/GLB/All/`:
`Manhole_Cover.glb`, `Road_Block.glb` y `Traffic_Cone.glb`.
El ZIP incluye `License.txt`, que acredita a **MilkAndBanana** y permite uso
personal, educativo y comercial bajo CC0; la página actual firma **jamesdev**.
Las fichas conservan ambos nombres. No se redistribuye el ZIP completo.

| Original | Triángulos | Uso y escala final |
| --- | ---: | --- |
| Manhole_Cover | 232 | Dos tapas octogonales, diámetro 0,70 m |
| Road_Block | 316 | Una barrera, altura 1,10 m, al borde de la calzada |
| Traffic_Cone | 82 | Dos conos enteros, altura 0,65 m, junto a la barrera |

El lote suma **cinco instancias y 944 triángulos** (LOD principal). Se normaliza
cada GLB por su AABB real: su origen viene desplazado y no representa la base.
Las tapas se apoyan 4 mm sobre el asfalto para evitar z-fighting; el resto apoya
en cota cero. El corredor central de 3,20 m permanece libre. La barrera, al ser
alcanzable, tiene una única colisión de caja ajustada y orientada con la malla.
No hay IA, física dinámica, interacción ni nuevas luces.

Cada GLB contiene su atlas PNG. Godot 4.7 lo extrae junto al modelo, por lo que
se versionan también esos tres PNG y sus opciones de importación. Los seis
binarios tienen ficha SHA-256 en `procedencia.json` y entran por Git LFS.
Las instancias repetidas comparten las mallas y los materiales del lote.

Se mantienen el atlas original y sus UV con `StandardMaterial3D`, iluminación
por vértice, muestreo nearest con mipmaps, tinte gris 0,72, rugosidad 1 y brillo
especular desactivado. No se modifica el shader PSX común: estas piezas conservan
la paleta low-poly del autor, pero no reciben su temblor ni dithering espacial.
La farola se deja fuera para no duplicar la iluminación existente.

`TraficoVialCC0.montar()` es idempotente por mundo. Lo invoca la entrada real de
`dia_calle_app.gd` únicamente en `trayecto`; al salir se destruye con ese mundo.
La regresión de `scripts/test_traffic_road_assets_contract.py` ejecuta Godot con
datos temporales y comprueba los originales, hashes, atlas, medidas, apoyo,
colisión, presupuesto, idempotencia y entradas archivo → trayecto → casa →
trayecto → archivo sobre `dia.tscn`. No requiere editar el agregador compartido.

Capturas reales sin HUD, Godot 4.7.2 Compatibility / Mesa llvmpipe, 1280×720:

- [Barrera y conos en el trayecto](../capturas/trafico-vial-225.png).
- [Detalle de la tapa](../capturas/trafico-vial-225-tapa.png).

Se utilizó la cámara del caminante, FOV 75°, a 1,65 m de altura, con posición
fijada para inspección. No son un playthrough humano ni una prueba de mando.

### Gate reproducible de aceptación visual

El corte posterior de #225 añade `godot/pruebas/capturar_trafico_vial_225.gd` y
el workflow `Evidencia trafico vial 225`. Sobre la escena real `dia.tscn`, fase
`trayecto`, genera cuatro vistas sin HUD (`barrera_conos`, `tapa_sur`,
`tapa_norte`, `paso_central`) y un `manifest.json` con las cinco instancias,
AABB visuales, cobertura de frustum, posición en pantalla y SHA-256 de los PNG.
La automatización verifica montaje y encuadre, pero declara
`veredicto_automatico=false`: época, escala, clipping y legibilidad siguen siendo
un gate humano. La guía de revisión vive en
`docs/evidencias/trafico-vial-225/README.md` y alimenta también el gate transversal
#398.

Medición adicional con cámara fija `(0, 4, -10)` mirando a `(0, 0, 4)`, FOV 100°,
misma escena detenida y 60 fotogramas de estabilización por muestra: ocultar /
mostrar únicamente el lote cambia **197 → 202 llamadas de dibujo** y
**12 508 → 13 118 primitivas**. Son +5 llamadas y +610 primitivas renderizadas
con los LOD de Godot; el lote sin LOD suma 944 triángulos. Es una medición de
coste geométrico con renderer software, no un presupuesto de FPS certificado
para hardware objetivo. No se introducen procesos por fotograma.

Verificación local: 626 unittest Python (incluyen 58 comprobaciones de este
lote en Godot), suite principal 662, semillas 34, recorrido 153 y arranque;
50 pruebas Java, 28 Vitest, Checkstyle, PMD, SpotBugs, gdlint y gdformat verdes.
No hay cobertura instrumentada GDScript configurada. La CI `34903760016` y la
Alpha `34903759979` del SHA de #507 terminaron en `success`; la aceptación visual
humana sigue abierta.

Pulido posterior: el lote desactiva también `cast_shadow` en todas sus mallas,
igual que otros elementos de dressing de calle, y la regresión lo fija para
impedir que vuelva a aparecer una pasada de sombras accidental.

SHA-256 del ZIP oficial inspeccionado: `8401078c95231677c07e1eb1639f8d2f0e222f62f9c1463c3999bdb2a0814237`.
