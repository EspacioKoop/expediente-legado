# Identidad visual de expedientes SIGA

Pack visual para que los diez expedientes principales sean reconocibles antes
de leer el título completo. Todo el material es SVG original construido con
primitivas simples y sin fuentes gráficas externas.

Cada expediente tiene tres piezas:

- **Icono 32×32:** identificación rápida en la lista de SIGA.
- **Lámina 320×120:** portada visual que aparece al seleccionar la carpeta y se
  retira al abrir un folio, para no competir con la lectura.
- **Ficha de sujeto 96×120:** acompaña a la lámina en la portada y se retira con
  ella.

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
| 10 | 86 + MESA 0 | empleado adicional sin alta |

## Fichas de sujeto

Cada ficha representa a quien la descripción del expediente pone en el centro,
no a quien resulte responsable. Son deliberadamente **no biográficas**: el
catálogo no define rasgos físicos, así que no hay rostro, edad ni vestimenta; los
nombres no se rasterizan y solo aparecen motivos que el propio caso ya afirma.
Cuando el sujeto es una entidad o no tiene titular, la silueta se sustituye.

| Expediente | Sujeto | Motivo de la ficha |
| --- | --- | --- |
| 1 | J. Ibarra | firma y autorización urgente |
| 2 | R. Salcido | silla y formularios encadenados |
| 3 | E. Montalvo | doce plantas y una decimotercera punteada; sello de recibido |
| 4 | Carcosa Servicios Escénicos | telón cerrado en lugar de retrato; Acto II tachado y recargo |
| 5 | el auditor al que se dirige la nota | retrato vacío; tres copias idénticas y nota manuscrita |
| 6 | Comité Ad Honorem | tres plazas sin rostro; sello amarillo en vez de notarial |
| 7 | F. P. Karamázov | banda de luto; acciones divididas en tres ramas |
| 8 | #427 | el botón de su descripción de funciones; tres actas del mismo día |
| 9 | Leandro Vela | lote devuelto sin tramitar; serie ausente reclasificada |
| 10 | titular de la tarjeta 0000 | solo contorno, sin alta; tarjeta de acceso a ceros |

La asociación entre caso, color, icono, lámina y ficha vive en
`res://datos/identidad_expedientes.json`. El componente visual consume ese
catálogo sin contener casos codificados uno a uno ni alterar pistas, acciones,
acusaciones o guardado.
