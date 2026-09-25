# Mari — paisaje, cueva y clima (#651)

Pack de arte de primera parte para reforzar el vertical de Mari ya existente sin convertir a Mari en un NPC, boss o figura literal.

## Contenido

- `cueva_portal.obj`: boca de cueva low-poly con jambas irregulares, visera rocosa y piedra húmeda.
- `estratos_montana.obj`: pared/estrato modular para mezclar arquitectura cotidiana con montaña.
- `frente_tormenta.svg`: señal visual abstracta de presión, viento y lluvia lateral.
- `huellas_agua.svg`: cauces/huellas de agua para superficies y rutas reveladas.
- `mari.mtl`: materiales compartidos sin texturas raster.

## Uso

Los OBJ usan unidades aproximadas a metros y están pensados para importación directa en Godot. No llevan colisiones embebidas: el runtime reutiliza primitivas simples para no acoplar arte y navegación.

`SuenoMari` monta actualmente `cueva_portal.obj` y `estratos_montana.obj` como capa visual sobre esa geometría estable. La boca artística solo se muestra cuando la tormenta habilita la ruta de cueva.

Los SVG son originales y no representan iconografía religiosa/histórica. `frente_tormenta.svg` y `huellas_agua.svg` se montan como señales 3D ligadas al mismo estado climático determinista: el cauce aparece con lluvia/tormenta y el frente solo durante tormenta.

## Límites

El paquete sigue la dirección ya documentada en `docs/assets/mari-referencias.md`: cuevas, montaña, lluvia, viento y tormenta como agencia del paisaje. No fija una apariencia humana de Mari ni presenta una ruta, periodicidad o símbolo como hecho tradicional universal.

No se añaden PNG/GLB para no saltarse Git LFS. Todo el contenido es arte original creado para este repositorio.

Refs #650 #651.
