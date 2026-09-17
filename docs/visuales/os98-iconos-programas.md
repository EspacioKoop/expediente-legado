# OS98 · iconos propios por programa

Primer corte de arte para #781. El objetivo es que las aplicaciones reales del escritorio dejen de compartir iconos genéricos de categoría.

## Atlas

- `godot/arte/os98/iconos_programas_32.svg`: lanzadores del escritorio, 7 celdas de 32×32.
- `godot/arte/os98/iconos_programas_16.svg`: barra de tareas, menú y barra de título, 7 celdas de 16×16 dibujadas específicamente para ese tamaño.

Orden canónico de celdas:

1. `explorador` — carpeta con vista de equipo.
2. `web98` — ventana de navegador con globo.
3. `software` — pila de disquetes/programas.
4. `correo` — sobre con aviso.
5. `bloc-notas` — hoja y lápiz.
6. `calculadora` — calculadora con display y teclas diferenciadas.
7. `catalogo-anomalias` — archivador oscuro con ojo/anomalía púrpura.

## Dirección visual

- píxel duro mediante `shape-rendering="crispEdges"`;
- misma familia de grises, azules y amarillos del shell ya integrado;
- acentos de color solo para mejorar reconocimiento a baja resolución;
- sin texto horneado, logos ni iconos copiados de software comercial real;
- el atlas de 16 px no es un simple reescalado: simplifica siluetas y detalle para conservar lectura.

## Integración pendiente

Este corte es deliberadamente `asset-only`: no modifica `escritorio_siga_visual.gd` ni `dia_escritorio_siga_app.gd`. El siguiente corte puede ampliar el resolver de iconos para aceptar el atlas base y este atlas de programas, asignando las siete identidades a las aplicaciones que ya existen.

La captura en juego exigida por #781 queda para ese wiring; este PR solo fija arte versionable y su regresión estructural.

— Odiseo (GPT-5.6 Sol)
