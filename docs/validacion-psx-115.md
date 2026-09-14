# Validación visual del shader PSX (#115)

Validación realizada sobre la alpha Linux que contiene el corte integrado en #300. El objetivo era cerrar el criterio visual de #115 sin cambiar otra vez el shader a ciegas.

## Método

Se usó el mismo ejecutable y el mismo estado de partida para cada pareja de capturas. La copia de control modifica **solo** el valor por defecto del uniforme `dithering` del shader espacial embebido, de `0.65` a `0.00`; no cambia geometría, texturas, cámara, cuantización de color ni temblor de vértices. Esa copia se utilizó únicamente para las capturas y no forma parte del juego.

La escena de sueño se abrió con una jornada controlada en `sueño` y `sueno_escenas = ["crucero"]`, para comparar el mismo espacio en ambos pases.

### Oficina

![Oficina: control sin dithering frente a producción](capturas/psx-115-office-before-after.jpg)

### Sueño

![Sueño: control sin dithering frente a producción](capturas/psx-115-dream-before-after.jpg)

## Resultado

- El Bayer 4×4 a `0.65` es visible en superficies 3D, pero no domina la imagen ni borra siluetas, iluminación o lectura espacial.
- En el sueño oscuro sigue siendo contenido: no convierte las zonas de baja luz en una trama de alto contraste.
- El visor, documentos y HUD quedan fuera del efecto por arquitectura: `psx.gdshader` es `shader_type spatial`, y la regresión `scripts/test_psx_dither.py` exige además que no aparezcan `canvas_item` ni `hint_screen_texture`.
- El mapeado afín **no se añade** en este cierre. El material actual usa proyección triplanar en coordenadas de mundo para mantener una escala de textura coherente entre superficies; sustituirlo por UV por cara sería otra decisión de render y no un requisito para validar el dithering.

## Decisión

Se mantiene el valor de producción `dithering = 0.65`. Cumple la frontera buscada en #115: efecto perceptible en el mundo 3D y UI documental limpia.

Refs #115 #123 #300

— Odiseo (GPT-5.6 Sol)
