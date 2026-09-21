# VITRAL 98

Segunda micro-ROM cultural de #932, original para Game Boy / Game Boy Color.

## Base documentada

Fuentes principales:

- V&A, **Stained glass: an introduction**:
  https://www.vam.ac.uk/articles/stained-glass-an-introduction
- V&A, **How was it made? Stained glass**:
  https://www.vam.ac.uk/articles/how-was-it-made-stained-glass

El V&A documenta el uso destacado de vidrieras en Europa entre 1150 y 1550, la relación entre vidrio coloreado y luz arquitectónica, y el proceso de diseño, corte, pintura y ensamblado con tiras de plomo. La segunda fuente reproduce técnicas históricas a partir de un panel procedente del coro de la catedral de Erfurt, Alemania, hacia 1375.

VITRAL 98 no reproduce el episodio religioso del panel ni ninguna figura sagrada. Toma únicamente la lógica material del taller: **diseño previo → piezas de vidrio → red de plomo → composición iluminada**.

## Mecánica

Hay cuatro bandas/piezas abstractas.

- arriba / abajo: seleccionar pieza;
- izquierda / derecha: rotar entre cuatro variantes;
- A: comprobar;
- A / Start: iniciar o reiniciar.

La solución es determinista: 2 / 1 / 3 / 2. El jugador debe haber manipulado las cuatro piezas.

## Handshake

WRAM $C100:

- arranque: 0x00;
- progreso parcial: 0x00;
- composición completa: 0xA5;
- reinicio: 0x00.

La ROM no escribe en Partida/Jornada ni concede dinero, pistas o progreso de SIGA.

## Representación

Se registra exposición cultural relacionada con cristianismo medieval europeo por la procedencia histórica del medio, no identidad o convicción del jugador. El puzzle evita:

- escenas bíblicas convertidas en piezas intercambiables;
- santos, cruces u objetos devocionales como pickups;
- texto litúrgico;
- convertir completar la vidriera en práctica religiosa.

La documentación ampliada vive en docs/religion-rom-vitral-932.md.
