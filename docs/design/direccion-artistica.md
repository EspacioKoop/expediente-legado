# Dirección artística canónica — Expediente Legado

**Estado:** pauta para nuevas contribuciones y revisiones gráficas, a partir del corte de #398.  
**Alcance:** arte 3D, escenarios, personajes, criaturas, materiales, iluminación, props, cinemáticas y capturas de validación.  
**Issues dueños:** #398 (lectura espacial), #399 (materiales), #126 (oficina), #2519 (modelos/escenarios realistas), #115 (tratamiento retro).  
**Implementación inicial:** #2982 (materiales importados opt-in). [Contrato técnico de assets](../assets/realismo-2519.md).

## Resultado buscado

**Realismo cinematográfico de 1998**, cotidiano y usado, capaz de sostener horror burocrático y extrañeza sin que el decorado parezca un prototipo low-poly ni una composición generativa inconexa.

El juego debe parecer construido a partir de lugares y objetos físicos. La arquitectura tiene función, las personas pesan y ocupan espacio, el material responde a la luz y las deformaciones oníricas parten de objetos que el jugador reconoce. «Fotorrealista» describe la **dirección de acabado**, no una garantía que pueda inferirse de un shader, un número de polígonos o un prompt de IA.

La nostalgia de finales de los 90 se expresa con **diseño material y diegético** (CRT, fluorescentes, archivadores, impresoras, mobiliario y vestuario de época), composición, sonido y comportamiento. No requiere que toda la geometría presente jitter PSX o dithering.

## Tres tratamientos visuales, no un shader universal

| Uso | Acabado de referencia | Excepciones |
| --- | --- | --- |
| **Vigilia:** oficina, casa, calle, vehículos, personajes, mobiliario | Geometría y escala plausibles; superficies PBR o materiales equivalentes con albedo/roughness/normal donde proceda; iluminación, profundidad y sombras coherentes | LOD distante, siluetas narrativas deliberadas, VFX |
| **Sueño / criaturas / lugares imposibles** | Objetos y criaturas materiales convincentes en arquitecturas físicamente imposibles; tensión por escala, movimiento, repetición y contradicción de luz/reflejo | Deformación localizada, cambios de textura/espacio justificados por narrativa |
| **Interfaces, medios y anomalías** | SIGA-98, OS98, CRT, VHS, ROMs y fragmentos corruptos pueden utilizar pixels, scanlines, cuantización, jitter, dithering o filtros según el dispositivo ficticio | No contagiar automáticamente ese acabado a las mallas del escenario |

La gramática simbólica sigue en [gramatica-simbolica-siga98.md](gramatica-simbolica-siga98.md). Los códigos visuales retro son útiles donde cuentan algo; **no pueden usarse para ocultar una falta de modelado o textura**.

## Reglas materiales y espaciales

1. **Forma reconocible a cámara de juego.** Contorno correcto, proporciones humanas, espesores, uniones, ruedas, tiradores y bordes donde cambian la silueta. El simple redondeo/subdivisión de una caja no equivale a un modelo realista.
2. **Escala y función.** Antes de decorar, comprobar altura de puertas y muebles, distancia de asientos, conexiones, accesos y recorrido físico. Un objeto debe justificar su presencia y su posición en el espacio.
3. **Materialidad.** Metal, melamina, plástico ABS, vidrio, caucho, papel y tela reaccionan de forma distinta. No sustituir un conjunto PBR con albedo, rugosidad y normales por un único color plano. No inventar normal maps que no describan geometría verosímil.
4. **Huellas de uso localizadas.** Rozaduras donde hay manos, desgaste en suelos de tránsito, marcas de archivado y polvo en rincones. Evitar repetir grunge, manchas o ruido aleatorio de forma uniforme: delatan un decorado sintético.
5. **Luz motivada.** Fluorescentes y luz de ventana en la oficina; alumbrado urbano en la calle; lámparas domésticas en casa. Sombras, exposición y reflejos han de concordar con sus fuentes.
6. **Coherencia entre packs.** Si un asset es mejor que otro en detalle o estilo, ajustar o sustituir el débil. No disimular la inconsistencia aplicando el mismo filtro a ambos.
7. **Calidad bajo presupuesto.** Optimizar por cámara/distancia de lectura, textura y rendimiento. LOD y texturas menores para fondos son aceptables; **low-poly evidente en primer plano presentado como acabado final, no**. No exigir 4K indiscriminadamente.

## Cómo debe trabajar un agente gráfico

**Identificar → obtener/modelar → preparar → integrar → mirar en Godot → corregir.** Ninguna fase implica automáticamente la siguiente.

1. **Situar el asset.** Señalar escena, issue dueño, cámara y acción jugable que afecta, escala aproximada y objetos con los que debe combinar. Evitar assets sin destino.
2. **Sourcing primero.** Buscar un modelo/escaneado apropiado con derechos verificables (preferiblemente CC0/CC-BY compatible con el proyecto). Verificar **distribución y redistribución**: un archivo permitido en un juego no siempre puede publicarse como fuente descargable en este repo.
3. **Si no existe, modelado autoral con referencias.** Blender y referencias reales de proporciones, diseño y materiales. Los agentes de IA pueden investigar, preparar UV, exportar, retopologizar o automatizar ajustes, pero una colección de primitivas creada por código no se presenta como asset final fotorrealista.
4. **Preparar.** Malla, pivote, UV, albedo, normal, roughness, metallic cuando aplique, LOD proporcionado, escala en metros y jerarquía de submallas. Preferencia por glTF/GLB para importación en Godot.
5. **Legalidad y entrega real.** Registrar autor, fuente, licencia y SHA-256 efectivamente verificados en `godot/assets/procedencia.json`. Respetar LFS y confirmar que los objetos binarios se subieron realmente; no inventar enlaces, licencias, archivos, hashes ni capturas.
6. **Integrar sin reescribir el juego.** Reusar `Modelos.cargar`, `Modelos.mueble` y el descriptor de escena. Para un GLB con superficies PBR auditadas, optar por `materiales_importados: true` por **instancia** (ver #2982); sin ese opt-in el shader heredado es la compatibilidad actual. No modificar colisiones, pistas, progreso ni escalas jugables para acomodar un mesh.
7. **Comparar en motor.** Captura desde **la cámara del jugador**, Godot Forward+ y encuadre fijo; dos vistas útiles cuando el objeto sea central. Revisar silhouette, detalle, iluminación, continuidad, navegación e interacción. Un screenshot en Blender o una imagen IA *no* acredita cómo se ve el juego.
8. **Iterar o dejar explícitamente pendiente.** Si la escena solo contiene proxies, puede entregarse como *blockout funcional*, pero no etiquetarse «acabado realista», «pase visual», «asset final» ni darse por cerrado el criterio artístico.

### Qué debe incluir la entrega de arte / PR

- **Destino concreto:** issue, escena, objeto, cámara/uso.
- **Procedencia:** modelo/pack, autor, fuente, licencia, SHA-256 de los binarios nuevos (o «sin binarios nuevos»).
- **Integración:** rutas, materiales, qué preserva del juego y qué queda como placeholder.
- **Evidencia:** dos capturas de juego comparables (antes/después o dos ángulos), SHA de build, renderer, dimensiones y condición de iluminación; enlazar artifact/ubicación verificable.
- **Rendimiento:** coste apreciable del cambio comparado con baseline, si afecta a geometría/iluminación relevante; no inventar FPS si no se midió.
- **Juicio visual:** observaciones humanas concretas sobre proporción, material, sombras, coherencia y silueta; «CI verde» no lo sustituye.
- **Decisión:** `bloqueo funcional`, `blockout jugable`, `pendiente revisión artística` o `acabado artístico aprobado`. No mezclar esos estados.

## Señales de rechazo

Revisar, no aprobar como arte final, cuando ocurra cualquiera de estos casos:

- mobiliario o criatura de primer plano que se reconoce como cajas/cápsulas/esferas o un cuerpo liso con piezas pegadas;
- personas con geometría facial improvisada, ojos/accesorios incoherentes o proporciones inhumanas no intencionales;
- texturas repetidas, estiradas o de escala inconsistente; plástico uniforme en metal/madera/tela;
- siluetas, luces y sombras que no comparten física; superficies sin contacto o apoyos creíbles;
- composiciones «IA genérica»: exceso de detalle irrelevante, suciedad idéntica, objetos sin uso, eclecticismo entre packs y señalética sin sentido;
- imágenes vistosas de Blender/IA **sin vista del juego**; prueba headless que solo verifica que la escena carga;
- material de terceros sin derechos para distribuirlo aquí o puntero LFS sin binario verificable.

Una excepción estilizada requiere **anotar la intención narrativa** y compararla con el resto de la escena. Las siluetas del acusado, UI pixel-art o efectos diegéticos pueden ser deliberadamente abstractos; no son un fallo por defecto.

## Primer vertical obligatorio para consolidar la pauta

**La planta de SIGA-98 (#126/#398) es el patrón de referencia antes de multiplicar escenas nuevas.**

- **Plano 1 — entrada:** puerta, perspectiva de puestos, zona de clasificación, batería de archivadores y ventanas, sin HUD. Debe leerse como una oficina funcional.
- **Plano 2 — puesto:** escritorio, asiento, terminal CRT, teléfono/papeles y archivo a escala de jugador; comprobar material, sombras y detalle cercano.
- **Arte prioritario:** escoger primero un escritorio, una silla, un archivador y un CRT reales/de buena factura, ya licenciados o producidos con referencia; reutilizar las rutas y la interacción existentes. **No importar un pack completo por volumen.**
- **Prueba de mundo:** recorrer entrada → puesto → archivo → salida y verificar colisiones, luz, legibilidad y que la presencia del jugador/NPC Rocketbox no desentone.
- **Salida:** capturas Godot mismo SHA y playtest humano del gate #126. Un CI verde o comparación de imágenes automatizada no reemplaza la aprobación de calidad.

Tras superar este patrón, extenderlo **en este orden gráfico**: calle y casa (#398/#399); transición de la misma materia hacia sueño (#279); criaturas y espacios mitológicos (#2519). El orden no bloquea correcciones de gameplay prioritarias de #181 y no autoriza reabrir decenas de subissues.

### Cooperación entre agentes

Dividir trabajos por **resultado** y rutas reservadas, no por cantidad de assets. Un agente puede encontrar y auditar candidatos; otro preparar Blender/GLB; otro integrarlos en un punto concreto; una persona juzga el resultado en juego. Si faltan derechos o binarios, informar el bloqueo **sin producir otro low-poly para llenar el hueco**. No crear nuevas tareas de «realismo» si ya hay una PR/CLAIM del mismo archivo.

## Compatibilidad con decisiones anteriores

El issue #399 documentó un mínimo técnico anterior («no se busca fotorrealismo»): continúa siendo válido como **base ya alcanzada** de materiales reconocibles, pero **no fija el techo de calidad de las nuevas entregas** tras esta decisión de #398. La capa PSX de #115 sigue disponible para lugares y efectos donde tenga sentido. Ningún asset previo se declara automáticamente incorrecto; su sustitución responde a un defecto observado y un vertical jugable.

No cambiar el significado de `CI verde`, `evidencia generada`, `playtest humano` o `acabado aprobado`: son cuatro cosas distintas.
