# Identidad visual de expedientes SIGA

Pack de iconos de 32×32 para que los nueve expedientes principales sean
reconocibles antes de leer el título completo. Son SVG construidos con
primitivas simples y sin material externo; conservan el aspecto sobrio de una
aplicación administrativa de finales de los 90.

| Expediente | Código visual | Motivo |
| --- | --- | --- |
| 1 | F-1999 | factura, cierre y revisión urgente |
| 2 | 4-B | silla ergonómica y trámite circular |
| 3 | 13 | ascensor / piso inexistente |
| 4 | CARCOSA | escenario y segundo acto |
| 5 | MEMO 78/93/07 | copias superpuestas del mismo memorándum |
| 6 | 1958 | acta fundacional y sello amarillo |
| 7 | KARAMÁZOV | árbol de tres reclamantes |
| 8 | #427 | botón y ficha numerada |
| 9 | R-17 → R-18 | reclasificación entre series |

La asociación entre caso, color e icono vive en
`res://datos/identidad_expedientes.json`. El visor solo consume ese catálogo:
no contiene casos codificados uno a uno ni altera pistas, acciones, acusaciones
o guardado.
