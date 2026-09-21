# Evidencia visual de comercios — #676

Este gate produce cuatro capturas reproducibles del **trayecto real** de
`dia.tscn`, con cámara jugable, locale español y HUD oculto. Su objetivo es
separar la revisión artística de los comercios de nuevas ampliaciones de sistema.

| Captura | Qué debe poder juzgar una persona |
| --- | --- |
| `bit98_exterior.png` | La fachada se reconoce como tienda de videojuegos de barrio; rótulo, escaparate, volumen de producto y puerta forman un único local. |
| `bit98_interior.png` | Tras entrar por la puerta real, el interior se lee como tienda: mostrador, baldas, cajas, CRT y arte propio tienen jerarquía clara. |
| `quiosco_avenida.png` | El quiosco se reconoce como superficie de prensa/compra y no como un bloque añadido sin contexto. |
| `el_trastero.png` | La segunda mano se reconoce como superficie distinta del quiosco y sigue dejando legible la calle y su mobiliario. |

El runner entra en Bit 98 mediante `EntrarTiendaVideojuegos.interactuar()`.
No hace visible el interior a mano: si la puerta deja de activar el microinterior,
el gate falla antes de producir una falsa captura válida.

`manifest.json` fija resolución, FOV, locale, fase, hashes, tipo de espacio y
criterio por imagen. El workflow solo comprueba contratos objetivos: que las
capturas existan, sean distintas, procedan de la cámara jugable y no lleven HUD.

## Revisión humana

Descarga el artifact `evidencia-comercios-676-<sha>` del workflow
**Evidencia comercios 676** y registra **PASS/FAIL** por captura con una frase
visual concreta:

- `bit98_exterior`: PASS/FAIL — reconocimiento, profundidad y puerta.
- `bit98_interior`: PASS/FAIL — lectura del espacio, producto y mostrador.
- `quiosco_avenida`: PASS/FAIL — identidad de quiosco y legibilidad de producto.
- `el_trastero`: PASS/FAIL — identidad de segunda mano y composición con la calle.

Este gate **no cierra #676 ni autoaprueba la dirección artística**. Un FAIL debe
traducirse en una corrección sobre una de estas vistas antes de añadir más
geometría, economía o catálogos por intuición.

Refs #676 #277 #96 #674.

— Odiseo (GPT-5.6 Sol)
