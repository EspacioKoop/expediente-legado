# Apertura original de 1998 — montaje de pesadilla

## Orden de arranque

1. Fondo negro, epígrafe de T. S. Eliot (fragmento abreviado; texto completo sujeto a derechos): opacidad 0 → 1 durante 2 s, retención y salida.
2. Epígrafe de Bob Dylan con la única línea facilitada, misma puesta en escena.
3. Montaje psicodélico **original**, 24 planos 3D y ~80 s (identificador `montaje-onirico-1998`).
4. Secuencia preexistente de créditos 3D, con paginado de contribuciones.
5. Menú de juego y diorama nocturno 3D, sin cargar una partida antes de elegir.

El montaje se inspira en las estrategias formales de openings psicológicos de finales de los 90: discontinuidad, escala y repetición; no incorpora escenas, música, personajes, ilustraciones, tipografías distintivas ni metraje de otras obras.

## Dramaturgia de la versión implementada

| Movimiento | Motivos | Ritmo |
|---|---|---|
| I · Rutina | puesto de trabajo, monitor encendido, archivadores, una fecha incierta | primeros travellings lentos frente a un corte abrupto |
| II · Calle | ciudad con farolas de sodio, escaparates, pantallas, pasos que no llegan | repetición y microcortes, cambios de focal |
| III · Archivo/sueño | archivadores, silla vacía, año 1998 como intrusión | cortes de 0,8–1 s que rompen continuidad geográfica |
| IV · Casa | habitaciones íntimas, umbrales, regreso imposible | tomas sostenidas y nueva interrupción |
| Coda | denegación de acceso, último trayecto, registro inexistente | final de 4,2 s hasta negro y créditos |

**Estado real:** la implementación actual anima cámaras en los decorados ya existentes (`EspaciosCatalogo`), con foco/fundidos/rótulos gestionados por `cinematica_app.gd`. Es un corte funcional del montaje, **no** una prueba de que existan ya modelos orgánicos fotorrealistas de monstruos o personajes, ni sonido de apertura final. El resultado visual todavía necesita revisión en pantalla y probablemente assets 3D nuevos. No sustituir esa necesidad por primitivas de colores.

## Segunda fase delegada — dirección artística

- Planos de rostro humano parcialmente oculto, reflejo imposible sobre el CRT y ventana con ciudad nocturna; usar modelos 3D originales con autoría/licencia verificable.
- Criaturas mitológicas y anomalías que **perturben escenas reconocibles**, no una sucesión abstracta de pirámides o cubos.
- Archivo municipal metamorfoseado: sillas y muebles con materiales reales, pasillos largos, puertas, lluvia y neón sobre PBR.
- Diseño de audio: ruidos de tubos fluorescentes, radio AM, cinta magnética, silencio y respiración; no utilizar música o fragmentos sonoros de series/anime.
- Extensión optativa y local al reproductor común: rotulación fragmentada, nieve CRT, iris, flashes moderados no fotosensibles. Con reducción de movimiento se desactiva cualquier destello repetitivo o cámara brusca.
- Capturas de QA a 1920×1080 y baja resolución; revisar encuadre, legibilidad y rendimiento para evitar planos que solo apunten a paredes.

## Contrato técnico

- Los 24 planos son `tipo = "3d"` y usan decorados existentes; no se han añadido sustitutos geométricos 2D.
- La introducción solo se muestra una vez por sesión, y puede saltarse sin romper los créditos y el menú.
- Las pruebas Python actuales son estáticas y de regresión: no prueban calidad de iluminación, encuadre ni audio. El playtest Godot sigue pendiente si faltan bibliotecas de GDExtension o recursos de traducción en el entorno.
- PR dependiente de [#2574](https://github.com/EspacioKoop/expediente-legado/pull/2574); no mezclar con [#2573](https://github.com/EspacioKoop/expediente-legado/pull/2573), cuyo diff contenía archivos de infraestructura ajenos.
