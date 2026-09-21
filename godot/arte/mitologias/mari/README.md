# Mari — paisaje, cueva y clima (#651)

Pack de arte de primera parte para reforzar el vertical de Mari ya existente sin convertir a Mari en un NPC, boss o figura literal.

## Contenido

- `cueva_portal.obj`: boca de cueva low-poly con jambas irregulares, visera rocosa y piedra húmeda.
- `estratos_montana.obj`: pared/estrato modular para mezclar arquitectura cotidiana con montaña.
- `frente_tormenta.svg`: señal visual abstracta de presión, viento y lluvia lateral.
- `huellas_agua.svg`: cauces/huellas de agua para superficies y rutas reveladas.
- `mari.mtl`: materiales compartidos sin texturas raster.

## Uso

Los OBJ usan unidades aproximadas a metros y están pensados para importación directa en Godot. No llevan colisiones embebidas: el runtime puede reutilizar primitivas simples para no acoplar arte y navegación.

Los SVG son originales y no representan iconografía religiosa/histórica. Funcionan como decals, paneles o referencias de material para comunicar **clima → cambio espacial**.

## Límites

El paquete sigue la dirección ya documentada en `docs/assets/mari-referencias.md`: cuevas, montaña, lluvia, viento y tormenta como agencia del paisaje. No fija una apariencia humana de Mari ni presenta una ruta, periodicidad o símbolo como hecho tradicional universal.

No se añaden PNG/GLB para no saltarse Git LFS. Todo el contenido es arte original creado para este repositorio.

Refs #650 #651.
