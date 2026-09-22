# JALI 98

Micro-ROM cultural original para Game Boy / Game Boy Color del vertical #932.

## Base documentada

El punto de partida no es una estética islámica genérica, sino un objeto y contexto concretos:

- The Metropolitan Museum of Art, **Pierced Window Screen (Jali)**, segunda mitad del siglo XVI, probablemente Agra (India), arenisca roja, inv. 1993.67.1:
  https://www.metmuseum.org/art/collection/search/453343
- The Met, **Geometric Patterns in Islamic Art**:
  https://www.metmuseum.org/essays/geometric-patterns-in-islamic-art

La ficha del Met documenta que los jalis se emplearon extensamente en arquitectura india como ventanas, divisores y barandillas, y que sus patrones de silueta se desplazaban por el suelo con la luz del día. El ejemplo 1993.67.1 se atribuye al periodo de Akbar y combina formas estrelladas, hexagonales y entrelazadas.

JALI 98 no reproduce esa pieza. El pixel-art, las fases y la solución son originales. La ROM abstrae únicamente una relación material documentada: **calado geométrico → paso de luz → patrón de sombra**.

## Mecánica

La pantalla muestra tres bandas de calado.

- arriba / abajo: elegir banda;
- izquierda / derecha: rotar una de cuatro fases;
- A: comprobar la composición;
- A / Start: iniciar o reiniciar tras completar.

Cada banda da una lectura inmediata de luz/sombra. La solución es determinista, pero el handshake solo se publica si el jugador ha manipulado las tres bandas y llega a la composición completa.

## Contrato de finalización

El primer byte de la sección fija WRAM en $C100 es wJaliCompletado.

- arranque: 0x00;
- juego parcial: 0x00;
- solución completa: 0xA5;
- reinicio: vuelve a 0x00.

La ROM no escribe en Partida/Jornada, no concede dinero, pistas ni progreso de SIGA y no registra práctica ni convicción.

## Representación

La pieza se etiqueta internamente como exposición cultural relacionada con arquitectura mogol dentro de historia del arte islámico. Se evita deliberadamente:

- texto coránico o caligrafía sagrada como código jugable;
- nombres divinos;
- símbolos rituales como pickups;
- una supuesta decoración islámica universal;
- presentar la abstracción como reconstrucción histórica;
- inferir práctica o creencia del jugador.

La tradición, lugar y periodo quedan declarados en el observer de Godot y en docs/religion-rom-jali-932.md.

## Compilar y probar

Requiere RGBDS 1.0.x.

    make
    make test PYTHON=/ruta/a/python-con-pyboy

La prueba PyBoy recorre el puzzle real y comprueba que el handshake permanece a cero durante arranque y progreso parcial, alcanza 0xA5 solo al resolver las tres bandas y vuelve a cero al reiniciar.
