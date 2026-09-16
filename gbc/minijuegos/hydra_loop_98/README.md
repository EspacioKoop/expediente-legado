# HYDRA LOOP 98

Prototipo jugable de ROM propia para la **Portátil Color 98**, contraparte de
vigilia del sueño de la Hidra (#439). Su id canónico es `hydra_loop_98`. Se
mantiene como fuente RGBDS; el `.gbc` se genera en build/CI y no se versiona.

Sigue **en proyecto**: el workflow GBC la compila y la prueba, pero no entra en
la build de runtime, la tienda ni la consola. `HidraVigilia` aún no lee su
handshake.

## Regla

La Hidra representa trabajo que se reproduce cuando solo se tapa el síntoma.
Todo es determinista: no hay RNG.

- **Cortar** (A sobre una cabeza) la elimina y hace brotar **dos** cabezas de la
  misma raíz en huecos libres.
- **Observar** (B sobre una cabeza) revela su raíz: la placa a su derecha pasa
  de `?` a la marca del nodo (círculo, cuadrado o triángulo), el cuello de esa
  cabeza se ilumina y el nodo destella. Leer cuesta medio segundo sin poder
  actuar, y la Hidra sigue creciendo mientras tanto.
- **Sellar** (A sobre un nodo) solo funciona si ya se han leído **al menos dos
  cabezas** de esa raíz. Entonces caen todas sus cabezas y el reloj se reinicia.
  Sellar a ciegas, o un nodo que no se ha leído, tapa el síntoma: brota una
  cabeza en la raíz dominante.
- El **reloj** (seis segmentos arriba a la derecha) hace brotar una cabeza en la
  raíz dominante cada vez que se vacía.
- Si una cabeza nueva no cabe en los diez huecos, la Hidra **desborda**: aparece
  `LOOP` y se reintenta el nivel.

Hay tres niveles:

1. Una raíz común con cuatro cabezas: se aprende a leer y sellar.
2. Tres raíces, y una de ellas con una sola cabeza. Esa cabeza suelta no se
   puede sellar hasta cortarla y leer sus dos brotes: cortar tiene un uso, pero
   solo cuando se entiende.
3. Tres raíces con presión y un reloj más rápido.

Romper el último nivel muestra `LOOP ROTO`.

## Handshake

Como `RYU FLOW`, al completar el tercer nivel escribe `0xA5` en WRAM `$C100`
(`wHydraCompletado`). Arrancar, jugar a medias, desbordar o salir no lo
escriben, y el arranque lo pone a cero. La ROM no guarda nada ni concede dinero,
pistas o progreso (#95). Una integración futura podría usar el handshake igual
que `RyuFlowVigilia`.

## Controles

- Cruceta: mover el cursor entre los diez huecos y los tres nodos.
- A: cortar una cabeza o sellar un nodo.
- B: observar una cabeza.
- Start/A: empezar desde la portada o reintentar tras desbordar.

## Arte y render

Dirección «Pantano de Lerna»: cabezas de serpiente con cuello que salen del
agua, muñones donde se cortó una cabeza, nudos de raíz que laten sobre el barro
y un nudo apagado con aspa cuando se sella.

- La portada reutiliza los 251 tiles, el mapa y la paleta de
  `gbc/minijuegos/hydra_loop/assets` (#556). El juego recarga su propio banco de
  59 tiles con la LCD apagada. Los tiles están en `main.asm` como literales
  gráficos de RGBDS, legibles píxel a píxel.
- En CGB, el color se asigna con el mapa de atributos, **estático**: agua,
  hidra, raíz y barro, placas y HUD usan cinco paletas. Se escribe una vez al
  cargar cada nivel con la LCD apagada y no cuesta nada en VBlank. Las cuatro
  primeras comparten el azul del agua como color 0, así que los bordes de cada
  bloque no se notan.
- En DMG, las escrituras de atributos caen en el mapa normal y se sobrescriben
  enseguida. El color 0 es el blanco del fondo, de modo que una placa sin
  cabeza es agua y no un cuadrado gris.
- Cabezas y nodos son bloques 2×3 con la placa en la fila central. Solo el
  cuello de la cabeza observada cambia durante la lectura y se redibuja al
  terminar.
- Durante la partida, VRAM y OAM solo se tocan al comienzo de VBlank. Cada
  cambio marca un elemento pendiente (hueco, nodo, HUD o reloj) y se dibujan
  como mucho tres por frame, así que un sellado se reparte en dos o tres frames.
- Solo hay dos sprites: el cursor y el destello del nodo.

## Compilar y probar

Requiere RGBDS 1.0.x.

```bash
make
python3 -m venv /tmp/hydra-tests
/tmp/hydra-tests/bin/python -m pip install pyboy==2.6.1
make test PYTHON=/tmp/hydra-tests/bin/python
```

`test_rom.py` arranca la ROM real en PyBoy y comprueba:
- la cabecera;
- la regla de cortar, observar y sellar, incluido el nodo equivocado y sellar a ciegas;
- las placas (`?`, marca o agua) y el cuello iluminado solo durante la lectura;
- el reloj y el desborde con reintento;
- el handshake, que solo aparece al terminar;
- que los niveles 2 y 3 se resuelven jugando con las reglas;
- con instrumentación de las escrituras, que VRAM y OAM solo se tocan en VBlank.

Sin PyBoy, solo corre la prueba de cabecera. El workflow GBC instala
PyBoy 2.6.1 y ejecuta la batería completa. No sustituye el playtest con mando.
