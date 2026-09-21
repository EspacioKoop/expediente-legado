# Cultura material cristiana — assets de #934

Segundo corte visual para #934. Este directorio contiene **arte de primera parte** en formatos textuales que Git/Godot pueden importar sin fabricar punteros Git LFS.

## Assets

| Fichero | Uso previsto | Escala aproximada |
| --- | --- | --- |
| `banco.obj` | banco de iglesia/capilla | 1.8 m de ancho |
| `atril.obj` | lectura / libro físico | 1.3 m de alto |
| `altar.obj` | superficie arquitectónica cristiana | 1.85 m de ancho |
| `velas_votivas.obj` | cultura material / iluminación | 1.15 m de ancho |
| `columna.obj` | arquitectura | 2.4 m de alto |
| `vidriera_luz.svg` | textura/vector para ventana o panel | proporción 1:2 |
| `religion_934.mtl` | materiales OBJ compartidos | — |

Los OBJ usan unidades equivalentes a metros y comparten materiales simples sin texturas raster. Godot puede importarlos y luego recibir materiales PBR más ricos sin cambiar la malla.

## Límites de representación

Este corte representa **cultura material cristiana**, no identidad ni convicción de NPCs. La presencia de un banco, altar, velas o vidriera en una escena no debe disparar por sí sola eventos de práctica/convicción.

La vidriera es deliberadamente no narrativa: usa geometría, vidrio azul/ámbar y un motivo vegetal abstracto. No copia una obra histórica concreta ni trocea una escena sagrada.

Las piezas parten de la dirección visual generada en esta conversación el 2026-09-21, pero el PNG original no se versiona porque `*.png` está sujeto a Git LFS. Los modelos y el SVG se reconstruyen como arte original textual para este repositorio.

## Integración recomendada

El primer vertical de #934 ya introdujo `ReligionMundo9343D`. Un corte posterior puede sustituir/acompañar sus cajas procedurales con estas mallas donde corresponda, manteniendo intacta la separación entre exposición, práctica y convicción.

Refs #916 #934.
