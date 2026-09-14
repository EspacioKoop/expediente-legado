# Quaternius Ultimate Buildings Pack — contrato de integración (#218)

Fuente oficial: **Quaternius — Ultimate Buildings Pack**  
Página: https://quaternius.com/packs/ultimatetexturedbuildings.html  
Licencia publicada por el autor: **CC0**.  
Fecha del pack: **diciembre de 2019**.

La página oficial describe un conjunto de **76 modelos** de edificios modulares con distintas texturas atlas para cambiar la paleta. Publica formatos **FBX, OBJ y Blend**. Una publicación original del autor sobre este pack también describe versiones base y piezas modulares.

Este contrato no importa el pack completo. Fija un corte pequeño y verificable para skyline, manzanas lejanas y fachadas de fondo de SIGA-98, sin interacción, IA ni colisiones de gameplay.

## Primer corte: cuatro roles, no cuatro nombres inventados

La página pública del pack no enumera los nombres de fichero. Por tanto, este documento **no inventa rutas ni nombres de modelos**. El PR binario deberá descargar la distribución oficial y seleccionar exactamente una pieza real para cada uno de estos cuatro roles:

1. **bloque residencial bajo/medio** — volumen ancho, repetible en manzana y legible a distancia;
2. **bloque residencial alto** — silueta vertical para romper el horizonte sin convertirse en edificio protagonista;
3. **edificio terciario/oficinas** — fachada más regular para alternar con vivienda y evitar un skyline monótono;
4. **pieza comercial o de esquina** — volumen con lectura de zócalo o fachada distinta para rematar una manzana lejana.

Si la distribución descargada no contiene una pieza adecuada para uno de esos roles, se documenta la ausencia y se reduce el lote. **No se sustituye por otro pack ni se amplía el alcance para llegar a cuatro a toda costa.**

El PR binario debe dejar escrita la correspondencia `rol -> nombre/ruta real del fichero` y registrar exactamente esos ficheros en procedencia.

## Uso previsto

El lote se usa como **fondo visual**:

- skyline y fachadas lejanas;
- manzanas fuera del espacio interactuable;
- composición de profundidad desde calle/oficina/ventanas cuando corresponda;
- sin interiores navegables;
- sin puertas funcionales;
- sin navegación, IA ni colisiones de personaje;
- sin convertir una escena completa del pack en escenario jugable.

La adaptación debe vivir en montaje, materiales y parámetros del proyecto. Los originales seleccionados se conservan sin edición destructiva siempre que sea viable.

## Distancia, LOD y coste

El objetivo de #218 no necesita geometría de primer plano. El PR binario debe probar una composición con al menos tres bandas de distancia:

- **mid/far**: modelo seleccionado completo cuando su silueta siga aportando lectura;
- **far**: reutilización agresiva, menor detalle/material y sin elementos que no cambien la silueta;
- **very far**: sustitución por geometría simplificada, silueta o impostor si el modelo completo deja de justificar su coste.

No se fija una distancia universal en metros antes de medir el escenario real. Las bandas se calibran desde cámaras jugables existentes y deben priorizar estabilidad visual y coste bajo.

El PR binario debe aportar, como mínimo:

- conteo de instancias del montaje de prueba;
- triángulos/vértices de las cuatro piezas seleccionadas o métrica equivalente disponible;
- número de materiales/texturas efectivamente cargados;
- comprobación de que no hay colisiones ni nodos de interacción añadidos;
- una captura desde una cámara jugable o comparable que demuestre que el skyline funciona como fondo.

## Paleta y materiales SIGA-98

El pack usa texturas atlas y permite variaciones de paleta. La adaptación al proyecto debe favorecer:

- saturación contenida;
- contraste menor que el de elementos interactivos de primer plano;
- valores suficientemente próximos para que la niebla/distancia unifique la manzana;
- ventanas y detalles sin emissive moderno salvo que una escena concreta lo justifique;
- repetición de atlas/materiales antes que duplicación innecesaria de recursos;
- coherencia con el tratamiento PSX del proyecto sin destruir el material fuente.

No se debe usar la variación de paleta para crear edificios protagonistas. La función del lote es sostener profundidad y masa urbana.

## Formato

Para este caso se prioriza **OBJ** cuando permita conservar la pieza seleccionada con materiales/texturas correctos y reduzca complejidad de importación. OBJ es textual en el repositorio y facilita revisión de cambios.

FBX puede usarse si una pieza concreta no se reproduce correctamente desde OBJ. Blend no debe entrar en runtime salvo necesidad técnica demostrada.

La elección final se documenta por pieza; no se convierten todos los modelos del pack ni se mantienen formatos duplicados del mismo activo.

## Escala

No se fija un factor de escala global sin medir los modelos reales. Cada pieza se valida en Godot contra referencias existentes:

- altura del personaje/Caminante;
- puertas y plantas de edificios ya presentes;
- ancho de calle y distancia de cámara;
- lectura de una planta típica desde el punto de observación.

Como son fondos no interactivos, una corrección de escala visual es aceptable si conserva proporciones coherentes y queda documentada en el montaje.

## Procedencia y Git LFS

Cada fichero que finalmente entre bajo `godot/assets/` debe tener una entrada propia en `godot/assets/procedencia.json` con:

- ruta exacta dentro del repositorio;
- nombre/título real del modelo;
- autor `Quaternius`;
- licencia `CC0`/`CC0-1.0` según el esquema del manifiesto;
- fuente `https://quaternius.com/packs/ultimatetexturedbuildings.html`;
- `sha256` calculado sobre **el fichero exacto que entra** al repositorio.

Los `.fbx`, `.blend` y texturas binarias deben entrar mediante **Git LFS real** conforme a `.gitattributes`. Los `.obj` son texto y no requieren LFS por sí mismos, pero sus texturas sí.

No se registran enlaces temporales de descarga como fuente de licencia. La fuente canónica es la página del autor.

## Checklist del PR binario

- [ ] descargar el pack desde la fuente oficial de Quaternius;
- [ ] inventariar los nombres/rutas reales de los modelos candidatos;
- [ ] elegir como máximo una pieza para cada uno de los cuatro roles del primer corte;
- [ ] justificar cualquier rol descartado en lugar de ampliar el lote;
- [ ] preferir OBJ cuando importe correctamente y usar FBX solo si resuelve una limitación real;
- [ ] importar únicamente modelos y dependencias estrictamente necesarias;
- [ ] conservar los originales seleccionados sin edición destructiva cuando sea viable;
- [ ] adaptar paleta/materiales en recursos u overrides del proyecto;
- [ ] comprobar escala desde cámaras reales del proyecto;
- [ ] montar una composición de skyline/manzana no interactiva;
- [ ] eliminar o no crear colisiones, navegación, IA e interacción;
- [ ] medir instancias, geometría y materiales/texturas del montaje;
- [ ] comprobar que los binarios cubiertos por `.gitattributes` son punteros Git LFS reales;
- [ ] calcular SHA-256 y registrar procedencia por fichero;
- [ ] ejecutar importación Godot, suite, recorrido, arranque y pruebas Python;
- [ ] capturar al menos una vista que demuestre lectura de fondo y ausencia de protagonismo excesivo.

## Criterio de cierre

Este documento no cierra #218 por sí solo. #218 puede cerrarse cuando exista al menos un montaje real del lote seleccionado que cumpla simultáneamente:

- procedencia/licencia y hashes registrados;
- selección pequeña sin dependencia del pack completo;
- adaptación visual SIGA-98 aplicada fuera del original cuando sea posible;
- uso como fondo/LOD sin interacción ni colisiones de gameplay;
- coste básico medido;
- binarios gestionados por Git LFS cuando corresponda;
- validación visual desde una cámara representativa.

Refs #216 #218

— Odiseo (GPT-5.6 Sol)
