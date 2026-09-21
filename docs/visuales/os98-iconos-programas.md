# OS98 · iconos propios por programa

Primer corte de arte para #781. El objetivo es que las aplicaciones reales del escritorio dejen de compartir iconos genéricos de categoría.

## Atlas

- `godot/arte/os98/iconos_programas_32.svg`: lanzadores del escritorio, 7 celdas de 32×32.
- `godot/arte/os98/iconos_programas_16.svg`: barra de tareas, menú y barra de título, 7 celdas de 16×16 dibujadas específicamente para ese tamaño.

Orden canónico de celdas:

1. `explorador` — carpeta amarilla limpia y reconocible.
2. `web98` — globo azul con meridianos y acento verde.
3. `software` — panel de aplicaciones con módulos de color.
4. `correo` — sobre azul claro con aviso rojo.
5. `bloc-notas` — libreta clara con espiral y lápiz.
6. `calculadora` — calculadora oscura con display cian y teclas diferenciadas.
7. `catalogo-anomalias` — tile oscuro con remolino/anomalía púrpura.

## Dirección visual

Tras la revisión humana del primer pase, se abandona el aspecto de píxel duro. La versión actual sigue siendo compacta y propia del escritorio ficticio, pero busca una lectura más pulida:

- centrado óptico consistente dentro de cada celda;
- siluetas suaves y esquinas redondeadas;
- degradados discretos y volumen ligero, sin fotorealismo;
- colores limpios y contrastados para reconocer cada app de un vistazo;
- detalles simplificados específicamente a 16×16;
- sin texto horneado, logos ni iconos copiados de software comercial real;
- sin `shape-rendering="crispEdges"`: el SVG puede aprovechar antialiasing normal.

La referencia visual aprobada se acerca más a iconografía de escritorio tardía/early-2000s reinterpretada que a pixel-art estricto de 1998. OS98 sigue siendo ficticio: se conserva la personalidad retro del shell, pero no se fuerza toda su iconografía a una cuadrícula de píxel duro.

## Integración en runtime

El shell acepta ahora dos familias de atlas: el atlas base del sistema y este atlas de programas. Explorador, Web98, Archivo de programas, Correo, Bloc de notas, Calculadora y Catálogo de anomalías registran su identidad propia y reutilizan la misma clave en lanzador, menú, barra de tareas y barra de título.

SIGA-98, Ayuda y las superficies estructurales conservan el atlas base. No se duplican ventanas ni se introducen iconos para aplicaciones inexistentes.

Sigue pendiente la captura humana exigida por #781 para validar lectura y escala a 1080p.

— Odiseo (GPT-5.6 Sol)
