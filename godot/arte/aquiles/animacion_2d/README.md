# Myrmidon 98 — entrega de fuente animada 2D

Este corte prepara una hoja original transparente de 12 fotogramas (3 × 4 celdas de 362 × 362 px) y una escena Godot 4.7 `AnimatedSprite2D`. El paquete de revisión contiene el PNG, la escena y las instrucciones de integración; se entrega en la conversación de la PR para revisión antes de añadir el PNG a Git LFS.

| Estado | Fotogramas | Bucle |
| --- | ---: | --- |
| `reposo` | 0–1 | sí |
| `avance` | 2–3 | sí |
| `ataque` | 4–5 | no |
| `bloqueo` | 6–7 | sí |
| `vulnerable` | 8–9 | sí |
| `derrota` | 10–11 | no |

La vulnerabilidad se muestra solo después de la deducción del talón. Esta fuente para presentación y redibujo no sustituye el pack GBC de #1804: no es un metasprite 24 × 32 ni usa paletas de cuatro colores. El corte GBC mantiene sus archivos y reserva independientes.

## Integración pendiente

1. Añadir `myrmidon_12_fotogramas.png` a Git LFS, verificando que el objeto se sube junto al puntero.
2. Añadir `godot/escenas/myrmidon_fuente_animada_1804.tscn` desde el paquete.
3. Comprobar la carga de seis animaciones y 12 regiones en Godot 4.7.
4. Marcar la PR lista para revisión solo después de los gates y de validar el objeto LFS.

## Procedencia

Creado para EspacioKoop el 29-09-2026 mediante generación visual de OpenAI, tomando `godot/arte/aquiles/aquiles_atlas_referencia.jpg` como dirección de silueta, armadura azul, escudo y capa roja. PNG original: SHA-256 `c306976ddbf54a51835dbf909c1d0b5cb79789e0182c6b76eeb8329f8c728c0c`. Se distribuye bajo la licencia aplicable al repositorio. La vista GIF sirve solo para revisión.
