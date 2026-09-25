# Fondos fotorealistas de calle 1998

Primer lote de impostores urbanos generado específicamente para *Expediente Legado*.
Su objetivo no es sustituir las fachadas 3D existentes, sino cubrir los huecos visibles
hacia el centro a izquierda y derecha entre los bloques principales del trayecto.

## Contenido

- `bloque_01.webp`
- `bloque_02.webp`
- `bloque_03.webp`
- `bloque_04.webp`

Son cuatro bloques residenciales de finales de los 80/90, recortados con alfa y reducidos
a 288 px de alto para funcionar como fondo barato en la estética PSX del juego.

## Integración

`CalleFondosFotorealistas98` coloca dos piezas detrás de las fachadas del lado oeste y
dos detrás del lado este. Las posiciones están deliberadamente fuera de aceras y calzada,
a x ±9–12 m, de modo que aparecen únicamente a través de los huecos de la línea frontal.

Los sprites usan billboard vertical (`BILLBOARD_FIXED_Y`) como impostores de segunda línea:
solo giran sobre Y para presentar la fachada hacia la cámara sin inclinarse. Conservan prueba
de profundidad y escala de mundo; se modulan con un tono nocturno estable y usan alpha cut
para evitar los problemas habituales de ordenación de transparencias. No añaden colisión,
interacción, navegación ni reglas de jornada.

## Procedencia

La imagen matriz fue generada con OpenAI ImageGen para este proyecto y después recortada,
separada y reducida localmente. Cada WebP distribuido tiene su SHA-256 exacto registrado
en `godot/assets/procedencia.json`.

Los edificios no reproducen una localización real concreta ni incluyen rótulos comerciales.
Antes de reutilizar una pieza como primer plano debería revisarse de nuevo el recorte:
este lote está diseñado expresamente para segunda línea de fondo.
