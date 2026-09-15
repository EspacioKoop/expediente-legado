# PSX Style Cars — contrato de integración (#230)

Fuente verificada: **GGBotNet — PSX Style Cars**  
Página: https://ggbot.itch.io/psx-style-cars  
Licencia publicada por el autor: **CC0 1.0 Universal**.  
La página del pack declara además que no se utilizó IA generativa.

## Selección mínima

No importar el pack completo. Para el primer corte se seleccionan tres familias por silueta y utilidad:

1. **Car 01 — station wagon, 5 puertas** (438 tris): vehículo civil aparcado.
2. **Car 03 — hatchback, 3 puertas** (448 tris): segunda silueta civil para evitar repetición evidente.
3. **Car 04 — minivan** (476 tris): volumen distinto para fondo de calle/aparcamiento.

Quedan fuera del primer corte policía/taxi, coche quemado, vehículo de los años 1920 y step van: añaden semántica o época que no hace falta para poblar una calle civil genérica de 1998.

## Formatos y escala

El pack publica `.blend`, `.obj`, `.png` y `.ogg`. Para Godot se debe preferir una exportación reproducible a `.glb` desde el `.blend` o una importación basada en `.obj` + texturas, conservando el original descargado fuera del árbol runtime si no hace falta distribuirlo.

**Importante:** el propio autor avisa de que la unidad de escala entre coches no es correcta. Por tanto, cada coche debe normalizarse individualmente antes de colocarlo. No se debe asumir un factor común para todo el pack.

Objetivo de escala de trabajo: turismos civiles en torno a **4–4,8 m de largo**, manteniendo proporciones originales. La comprobación final debe hacerse contra el `Caminante` y las fachadas de la calle, no solo por números.

## Materiales

- conservar texturas originales del pack en el primer corte;
- adaptar únicamente lo necesario para que el modelo responda al pipeline visual del proyecto;
- no introducir brillo plástico fuerte ni materiales PBR que rompan la lectura retro;
- variantes de color: usar como máximo dos colores por familia en el primer corte.

## Uso jugable inicial

Primer PR con binarios:

- **estáticos**; sin física de vehículo;
- colocados fuera de la línea principal de paso;
- sin colisión detallada de rueda/carrocería: una envolvente simple es suficiente;
- sin sonidos en esta fase;
- no bloquear portal, escaparate ni señalización del trayecto;
- máximo 3–5 coches visibles simultáneamente para no convertir el fondo en ruido.

Movimiento simple queda para un segundo corte y solo si mejora claramente la lectura de calle. Un coche que cruza el plano del jugador exige además resolver seguridad de colisión y ritmo del recorrido, por lo que no entra en la importación inicial.

## Procedencia y LFS

Todo fichero finalmente incorporado debe tener entrada real en `godot/assets/procedencia.json` con:

- ruta exacta;
- título/modelo;
- autor `GGBotNet`;
- licencia `CC0-1.0`;
- fuente `https://ggbot.itch.io/psx-style-cars`;
- `sha256` calculado sobre el fichero que realmente entra al repositorio.

Los `.glb`, `.blend` y `.png` deben entrar mediante **Git LFS real**, conforme a `.gitattributes`. No se deben subir como blobs normales mediante la API de contenidos de GitHub.

## Primer lote importado (#230)

Descarga oficial: `PSX_Style_Cars_by_GGBot_(August2023).zip`, `sha256` `db67b0b0fbaa02454a5d000dc9ec1cc53f360e8f41ab44f3fb1c7e8f71e699e4`.

| GLB | Origen en el ZIP | Textura (un color por familia) | Triángulos | Largo | Posición en `trayecto` |
|---|---|---|---|---|---|
| `Car01.glb` | `Car 01/Car.obj` | `car.png` (verde) | 438 | 4,60 m | acera izquierda, z −11 |
| `Car04.glb` | `Car 04/Car4.obj` | `car4.png` (azul) | 476 | 4,30 m | acera derecha, z −3,5 |
| `Car03.glb` | `Car 03/Car3.obj` | `car3_red.png` (rojo) | 448 | 4,00 m | acera izquierda, z 9,5 |

Conversión: cada `.obj` se empaqueta a `.glb` con su textura embebida sin tocar vértices, UV ni caras (`trimesh`, `process=False`). El `.blend` no entra en el repositorio. Godot extrae la textura como `CarNN_0.png`, que también tiene ficha.

El monovolumen se queda en 4,30 m porque el modelo es muy ancho en proporción: a 4,7 m sobresalía del bordillo.

`godot/guion/coches_psx_cc0.gd` monta el lote desde `dia_calle_app.gd` al entrar en `trayecto`. Cada coche calcula su propio factor de escala sobre la malla importada, apoya las ruedas en el asfalto, lleva material mate sin especular ni sombra proyectada y usa una única `BoxShape3D` estática. Los coches aparcan orientados según la circulación por la derecha, fuera del paso central (|x| < 1,6), sin tapar el escaparate y lejos de los conos/barrera de #225, la entrada y el portal. `godot/pruebas/pruebas_coches_psx_cc0.gd` comprueba todo eso y el hook real entre fases.

Capturas: `docs/capturas/coches-psx-230.png` (desde el punto de entrada) y `docs/capturas/coches-psx-230-monovolumen.png`.

## Checklist del PR binario

- [x] descargar `PSX_Style_Cars_by_GGBot_(August2023).zip` desde la fuente oficial;
- [x] seleccionar Car 01, Car 03 y Car 04;
- [x] normalizar escala individualmente;
- [x] exportar/importar solo los ficheros necesarios;
- [x] `git lfs track` ya cubre los formatos binarios usados;
- [x] comprobar que el commit contiene punteros LFS donde corresponde;
- [x] calcular SHA-256 de cada asset final y registrar procedencia;
- [x] colocar 3–5 instancias en calle/aparcamiento sin bloquear el recorrido;
- [ ] ejecutar importación Godot, suite, recorrido, arranque y Alpha (CI);
- [ ] validación visual humana de escala, clipping y lectura desde el punto de entrada.

## Fuera de alcance

Movimiento, sonido y el resto de modelos del pack siguen fuera de este corte.

— Odiseo (GPT-5.6 Sol)
