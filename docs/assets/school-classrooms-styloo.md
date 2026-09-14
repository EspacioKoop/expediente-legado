# School Classrooms Asset Pack — contrato de integración (#223)

Fuente verificada: **styloo — School Classrooms Asset Pack**  
Página: https://styloo.itch.io/classroom-asset-pack  
Licencia publicada por el autor: **Creative Commons Zero v1.0 Universal (CC0-1.0)**.  
El autor declara además que el pack no usa IA generativa.

La distribución oficial incluye modelos en **FBX y GLTF/GLB** y separa ficheros individuales de escenas de demostración. Para Godot se prioriza GLB: el propio autor recomienda este formato porque conserva los materiales configurados.

## Alcance del primer corte

No importar el pack completo ni ninguna demo scene. El primer corte de #223 se limita a seis piezas reutilizables que cubren despacho administrativo, archivo y sala de formación sin obligar a que el proyecto adopte una escena escolar prefabricada:

1. **`desk`** — mesa de despacho del bloque *Principal's Office*.
2. **`principal's chair`** — silla de despacho con una silueta distinta de la silla escolar básica.
3. **`shelf`** — almacenamiento reutilizable en oficina, archivo o aula.
4. **`telephone`** — teléfono de sobremesa para despacho/recepción.
5. **`old pc`** — ordenador del bloque *Computer Room*; candidato deliberado frente a `new pc`.
6. **`printer`** — periférico administrativo reutilizable en despacho o sala informática.

Los nombres anteriores son los nombres publicados por el autor. **No se inventarán rutas de archivo**: al descargar el ZIP oficial se conservará el nombre/ruta real del fichero individual seleccionado y esa ruta será la que entre en procedencia.

## Corte escolar posterior ligado a #284

`lockers` y `blackboardbig` quedan como siguientes candidatos para la pesadilla escolar de #284. No forman parte del primer lote administrativo para mantener el PR binario pequeño y revisable.

El montaje onírico debe componerse en Godot con geometría, iluminación, sonido e interacciones propias. No se reutilizará la *classroom demo scene* ni otra escena completa del pack como solución final.

## Coherencia temporal con 1998

El filtro temporal se aplica por **lectura visual**, no solo por el nombre del fichero.

- `old pc`, `telephone` y `printer` deben inspeccionarse antes de integración para descartar rasgos claramente posteriores al entorno de 1998.
- `new pc`, `new monitor`, `router` y las distintas `usb keys` quedan fuera del primer corte por ser innecesarios y/o temporalmente ambiguos para esta ambientación.
- mobiliario genérico (`desk`, `principal's chair`, `shelf`) se acepta solo si materiales, proporciones y silueta no introducen una estética contemporánea evidente.
- cualquier duda temporal bloquea esa pieza concreta, no todo el pack.

## Formato, escala y materiales

### Formato

- preferir el **GLB individual** publicado por el autor;
- usar FBX solo como alternativa si el GLB concreto presenta un problema real de importación;
- no convertir una demo scene en fuente de piezas cuando existe el fichero individual;
- no introducir `.blend` en runtime si no es necesario para reproducir la importación.

### Escala

La página del pack no fija aquí una escala de trabajo para el proyecto. Por tanto, cada pieza se valida dentro de Godot contra referencias existentes:

- altura del `Caminante`/personaje;
- mesa y silla ya usadas por la oficina;
- puertas y altura de techo;
- alcance de interacción si la pieza termina siendo interactuable.

No se fijará un factor común sin medir primero los modelos reales.

### Materiales

- conservar como punto de partida los materiales incluidos en GLB;
- adaptar únicamente lo necesario al pipeline visual del proyecto;
- evitar brillo/metallic excesivo que haga leer plástico moderno donde no corresponde;
- no modificar destructivamente el binario fuente para hacer la adaptación: los overrides/materiales del proyecto deben vivir aparte cuando sea posible;
- el tratamiento PSX puede aplicarse después de que volumen, textura y época sean legibles; no sustituye esa validación.

## Procedencia y Git LFS

Cada fichero que finalmente entre bajo `godot/assets/` debe tener una entrada propia en `godot/assets/procedencia.json` con:

- ruta exacta dentro del repositorio;
- título/nombre del modelo;
- autor `styloo`;
- licencia `CC0-1.0`;
- fuente `https://styloo.itch.io/classroom-asset-pack`;
- `sha256` calculado sobre **el fichero exacto que entra** al repositorio.

Los `.glb` y `.fbx`, y cualquier textura binaria añadida, deben entrar mediante **Git LFS real** conforme a `.gitattributes`. No se deben subir como blobs normales mediante la API de contenidos de GitHub.

La fuente registrada es la página que declara la licencia, no un enlace temporal de descarga ni una copia de terceros.

## Checklist del PR binario

- [ ] descargar `StylooClassroomAssetPack GLTF & FBX.zip` desde la página oficial;
- [ ] localizar los ficheros individuales reales de `desk`, `principal's chair`, `shelf`, `telephone`, `old pc` y `printer`;
- [ ] inspeccionar visualmente cada pieza para 1998 antes de copiarla al árbol runtime;
- [ ] preferir GLB individual y descartar demo scenes;
- [ ] importar solo las seis piezas aprobadas y las dependencias estrictamente necesarias;
- [ ] comprobar escala en Godot contra personaje, puertas y mobiliario existente;
- [ ] aplicar ajustes de material mediante recursos/overrides del proyecto cuando sea posible;
- [ ] comprobar que los binarios del commit son punteros Git LFS reales;
- [ ] calcular SHA-256 de cada fichero final y registrar una ficha por fichero en `godot/assets/procedencia.json`;
- [ ] ejecutar importación Godot, suite, recorrido, arranque y pruebas Python;
- [ ] validar visualmente clipping, escala, legibilidad y coherencia temporal;
- [ ] si el lote se usa en #284, componer la escena escolar propia sin importar la demo scene.

## Fuera de alcance de este corte

Este documento no entrega #223 por sí solo. Fija una selección reproducible y evita que el siguiente PR tenga que decidir otra vez qué importar o cómo justificarlo.

#223 permanece abierto hasta que al menos el lote administrativo aprobado se haya incorporado con Git LFS y procedencia/hash reales y se haya validado visualmente en Godot.

Refs #216 #223 #284 #399

— Odiseo (GPT-5.6 Sol)
