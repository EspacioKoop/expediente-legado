# Kit visual procedural de Ryū (#440)

Este directorio contiene dressing 3D opcional relacionado con el sueño de Ryū. El objetivo es ampliar el lenguaje visual del vertical sin modificar todavía su lógica, navegación, semilla, objetivos ni selección nocturna.

## Piezas

- **ToriiSuspendido**: pórtico lacado flotante y ligeramente inclinado, útil como umbral o landmark vertical.
- **CascadaInvertida**: láminas de agua que ascienden hasta un nacimiento suspendido, con gotas ascendentes y lectura clara de gravedad imposible.
- **NubeInterior**: volumen de nube dentro de arquitectura cerrada, atravesado por un umbral metálico.
- **PuenteVertebra**: pasarela modular inspirada en vértebras, con eje transitable y arcos repetidos.
- **FarolesDeLluvia**: faroles flotantes con núcleos emisivos y gotas suspendidas por encima, pensados para reforzar profundidad y ritmo.

Todo se genera con `BoxMesh`, `CylinderMesh`, `SphereMesh` y `StandardMaterial3D`. No hay binarios, texturas externas ni dependencias de licencia.

## Vista previa

Abrir:

`res://arte/ryu_440/muestra_kit_visual_ryu.tscn`

La escena monta el kit mediante `kit_visual_ryu.gd`, añade iluminación de muestra y una cámara. El script es `@tool` para que las piezas puedan inspeccionarse también desde el editor.

## Integración futura

Este corte **no está conectado al runtime de #440**. Es deliberado: el vertical actual sigue esperando el pase humano transversal de #398/#181. Tras ese pase, estas piezas pueden integrarse individualmente si resuelven un hallazgo concreto.

Candidatos de uso:

1. torii como referencia de dirección/altura en un tramo donde el cauce pierda lectura;
2. cascada invertida junto al canal elevado para reforzar la anomalía de gravedad;
3. nube interior como fondo o transición espacial sin introducir una puerta funcional nueva;
4. puente-vértebra como sustitución visual de una pasarela si el playtest la percibe demasiado genérica;
5. faroles de lluvia como profundidad ambiental, siempre reduciendo densidad o inmovilizándolos con `reduccion_movimiento`.

No se debe insertar todo a la vez: son módulos para elegir según evidencia del playtest, no una nueva capa obligatoria de complejidad.

## Rendimiento

El kit usa pocas primitivas y evita partículas densas, simulación hidráulica, rig, física y assets de alta resolución. Las transparencias se limitan al agua y pequeños acentos emisivos; si una integración real muestra problemas de orden de transparencia, debe corregirse en ese vertical concreto antes de fusionar.

Refs #440 #398 #435.
