# Golf de pasillo — assets integrables (#158)

Este directorio contiene assets **reales de producción** para el minijuego de #158. No son renders ni concept art: son escenas 3D nativas de Godot, shaders y SVG que el proyecto puede importar directamente.

## Qué entra

### Modelos / prefabs 3D

- `modelos/bola_siga.tscn`: bola de escala real (42,7 mm), collider esférico y shader procedural de dimples. Se entrega congelable para preview; la futura escena jugable puede controlar el `RigidBody3D` sin usar una malla compleja como collider.
- `modelos/putter_oficina.tscn`: putter ensamblado con cabeza metálica, inserto de goma, varilla y grip; colliders primitivos.
- `modelos/rampa_archivo.tscn`: rampa de oficina con fieltro verde y raíles de cartón; colliders simples.
- `modelos/banderin_hoyo.tscn`: objetivo visual con hueco, mástil y bandera.
- `modelos/papel_arrugado.tscn`: obstáculo con deformación procedural y collider esférico estable.
- `modelos/caja_archivo.tscn`: caja de archivo con cinta, lista para obstáculo.

### Shaders

- `shaders/bola_siga.gdshader`: dimples y respuesta de material sin normal map raster.
- `shaders/papel_arrugado.gdshader`: microdeformación y fibras sin textura externa.

### Decals vectoriales

- `decals/hoyo_1.svg`, `hoyo_2.svg`, `hoyo_3.svg`: señalética de recorrido.
- `decals/tarjeta_puntuacion.svg`: tarjeta diegética de los tres hoyos.

Godot importa SVG como `Texture2D`, por lo que pueden usarse en `Sprite3D`, `TextureRect` o materiales sin añadir PNG al repo.

## Preview

`golf_assets_preview.tscn` monta los seis prefabs y los decals en una galería iluminada. Sirve para revisión visual y para ajustar materiales/escala sin activar todavía el minijuego.

## Decisiones técnicas

- Todo vive en `godot/arte/golf_pasillo/` porque es trabajo de primera parte para Expediente Legado. `godot/assets/` está reservado a material de terceros con ficha de procedencia.
- Se evitan PNG/JPG/GLB para no saltarse la política Git LFS del repositorio.
- Los colliders son primitivos. La apariencia puede ser más rica que la física, lo que encaja con el requisito de #158 de mantener una simulación estable y con terminación garantizada.
- Este corte **no** conecta aún la escena con `Golf`, `Partida` ni el ranking. La integración jugable permanece separada del arte y del freeze actual de expansión opcional.

## Escala orientativa

- Bola: radio `0.02135 m`.
- Putter: ~`0.89 m` de alto total.
- Rampa: `0.29 × 0.42 m`, inclinación visual de 13°.
- Caja: `0.36 × 0.24 × 0.30 m`.
- Papel: ~`0.076 m` de diámetro visual.
