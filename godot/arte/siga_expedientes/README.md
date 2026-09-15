# Identidad visual de expedientes SIGA

Pack visual para que los nueve expedientes principales sean reconocibles antes
de leer el título completo. Todo el material es SVG original construido con
primitivas simples y sin fuentes gráficas externas.

Cada expediente tiene dos escalas:

- **Icono 32×32:** identificación rápida en la lista de SIGA.
- **Lámina 320×120:** portada visual que aparece al seleccionar la carpeta y se
  retira al abrir un folio, para no competir con la lectura.

| Expediente | Código visual | Motivo |
| --- | --- | --- |
| 1 | F-1999 | factura, cierre y revisión urgente |
| 2 | 4-B | silla ergonómica y trámite circular |
| 3 | 13 | ascensor / piso inexistente |
| 4 | CARCOSA | escenario y segundo acto |
| 5 | MEMO 78/93/07 | copias superpuestas del mismo memorándum |
| 6 | 1958 | acta fundacional y sello amarillo |
| 7 | KARAMÁZOV | árbol de tres reclamantes |
| 8 | #427 | ficha laboral y empleado numerado |
| 9 | R-17 → R-18 | reclasificación entre series |

La asociación entre caso, color, icono y lámina vive en
`res://datos/identidad_expedientes.json`. El componente visual consume ese
catálogo sin contener casos codificados uno a uno ni alterar pistas, acciones,
acusaciones o guardado.
