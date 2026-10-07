# Auditoría ROM Hydra Loop 98 contra el listón de #808

Evaluación del estado real de `gbc/minijuegos/hydra_loop_98/main.asm` frente a los criterios de calidad de ROM propia (#808).

---

## 1. Menú, instrucciones y flujo completo (título → juego → final → vuelta)

**Calificación:** Parcial

**Evidencia:**
- **Título / Portada:** Lógica en `PrepararTitulo` (`main.asm`, líneas 127-147) y estado `ESTADO_TITULO` (línea 38).
- **Inicio de juego:** Pulsar Start o A en la portada pasa al estado `ESTADO_JUEGO` e inicia el nivel 1 (`main.asm`, líneas 110-120).
- **Bucle de juego:** Gestionado por `ActualizarJuego` (`main.asm`, líneas 188-231) en `ESTADO_JUEGO`.
- **Pantalla final:** `PantallaFinal` (`main.asm`, líneas 487-526) muestra `LOOP ROTO` en victoria (`ESTADO_VICTORIA`) o `LOOP` + nivel en derrota (`ESTADO_FALLO`).
- **Vuelta:** Desde la victoria (`ESTADO_VICTORIA`), pulsar A o Start regresa a `PrepararTitulo` (`main.asm`, líneas 110-117). En derrota (`ESTADO_FALLO`), reintenta directamente el nivel (`main.asm`, línea 115).
- **Instrucciones:** No encontrado. No existe pantalla de instrucciones ni menú explícito previo a la partida.

---

## 2. Estructura: número de niveles o fases y qué cambia entre ellos

**Calificación:** Cumple

**Evidencia:**
- **Número de niveles:** Constante `NUM_NIVELES EQU 3` (`main.asm`, línea 33).
- **Cambios entre niveles:**
  - **Disposición de cabezas y raíces:** Definida en la tabla `Niveles` (`main.asm`, líneas 651-654):
    - Nivel 1: Una raíz común con 4 cabezas (enseña a leer y sellar).
    - Nivel 2: Tres raíces con una cabeza suelta no sellable directamente.
    - Nivel 3: Tres raíces con alta presión de crecimiento.
  - **Velocidad del reloj:** Tabla `TicksPorSegmento` (`main.asm`, línea 656) con `60, 45, 40` ticks por segmento según el nivel.

---

## 3. Récord o progreso persistente en SRAM

**Calificación:** No cumple

**Evidencia:**
- El cartucho incluye `../comun/cartucho.asm` (`main.asm`, línea 61), que habilita MBC5 con soporte de SRAM.
- Sin embargo, `main.asm` no realiza lecturas ni escrituras en la memoria SRAM (`$A000-$BFFF`).
- El estado de completado se guarda únicamente en WRAM no persistente (`wHydraCompletado` en `$C100`, `main.asm`, líneas 1361-1362).
- `README.md` (línea 43) confirma: «La ROM no guarda nada ni concede dinero, pistas o progreso (#95)».

---

## 4. Música y sonido

**Calificación:** Parcial

**Evidencia:**
- **Efectos de sonido (SFX):** Cumple. Configura el chip de sonido en `ConfigurarAudio` (`main.asm`, líneas 587-593) y emite efectos mediante `Sonar` (`main.asm`, líneas 595-604) en el Canal 1 (NR10-NR14). Define 7 efectos (`main.asm`, líneas 608-614): `SonidoObservar`, `SonidoCortar`, `SonidoError`, `SonidoSellar`, `SonidoCrecer`, `SonidoNivel`, `SonidoDesborde`.
- **Música de fondo (BGM):** No encontrado. No hay secuencias ni motor de BGM implementado.

---

## 5. Arte CGB propio: paletas, atributos con rVBK y sprites

**Calificación:** Cumple

**Evidencia:**
- **Paletas CGB:** `CargarPaletaBG` (`main.asm`, líneas 576-585) y carga directa en `rOCPS`/`rOCPD` (`main.asm`, líneas 178-185). Define `PaletaJuego` (5 paletas de fondo, líneas 659-666), `PaletaCursor` (líneas 668-669) e incluye `assets/title_palette.inc`.
- **Atributos de VRAM (rVBK):** Cambia a banco 1 con `ldh [rVBK], a` en `PrepararTitulo` (línea 133), `IniciarNivel` (línea 163) y `PantallaFinal` (línea 490), aplicando el mapa `AtributosJuego` (líneas 767-786).
- **Sprites:** Dibujados en `ActualizarOAM` (`main.asm`, líneas 528-562), utilizando `TILE_CURSOR` (tile 57) y `TILE_DESTELLO` (tile 58).

---

## 6. Animación o cinemática

**Calificación:** Parcial

**Evidencia:**
- **Animaciones en juego:** El cuello de la cabeza observada se ilumina durante la lectura (`TILE_CUELLO_LUZ`, `main.asm`, líneas 432-440) y la raíz destella con sprite parpadeante (`main.asm`, líneas 545-558).
- **Cinemáticas:** No encontrado. Las transiciones de pantalla (inicio, cambio de nivel, victoria o derrota) se realizan mediante borrado e intercambio directo de tiles sin cinemáticas ni secuencias animadas.

---

## 7. Evidencia de partida completa (tests en scripts/ con PyBoy o Siga98GB)

**Calificación:** Cumple

**Evidencia:**
- Batería de pruebas en `gbc/minijuegos/hydra_loop_98/test_rom.py`.
- `test_niveles_2_y_3_son_resolubles_con_las_reglas` (`test_rom.py`, líneas 119-123) simula y completa una partida real a través de los tres niveles enviando entradas al emulador PyBoy.
- Pruebas adicionales en `test_rom.py` verifican la publicación del handshake `$C100 == 0xA5`, las reglas de interacción, el reloj, el desborde y la restricción de escrituras VRAM a VBlank.
- Pruebas de assets en `scripts/test_hydra_loop_assets.py`.

---

## Defectos verificables y cortes propuestos

1. **Defecto:** Ausencia de pantalla de instrucciones antes de empezar el juego.
   - **Fichero:** `gbc/minijuegos/hydra_loop_98/main.asm`
   - **Qué cambiar:** Añadir un estado `ESTADO_INSTRUCCIONES` con un mapa de tiles que muestre los controles (A: cortar/sellar, B: observar) tras pulsar Start en la portada, antes de iniciar el Nivel 1.
   - **Cómo se comprueba:** Ejecutar `make -C gbc/minijuegos/hydra_loop_98 test` verificando con PyBoy que tras pulsar A/Start en el título se muestra la pantalla de instrucciones y una segunda pulsación inicia la partida.

2. **Defecto:** Falta de persistencia de récords en SRAM.
   - **Fichero:** `gbc/minijuegos/hydra_loop_98/main.asm`
   - **Qué cambiar:** Guardar en la SRAM del cartucho (`$A000`) el mejor tiempo o el menor número de desbordes/reintentos al completar los 3 niveles, y leerlo en el menú.
   - **Cómo se comprueba:** En `test_rom.py`, verificar mediante PyBoy que al completar el juego se escribe un registro en la memoria SRAM (`0xA000`) y que dicho valor persiste tras reiniciar la ROM.

3. **Defecto:** Ausencia de música de fondo (BGM) durante la partida.
   - **Fichero:** `gbc/minijuegos/hydra_loop_98/main.asm`
   - **Qué cambiar:** Añadir un reproductor simple de melodía en VBlank utilizando el Canal 2 o Canal 3 para amenizar la partida durante `ESTADO_JUEGO`.
   - **Cómo se comprueba:** Verificar en `test_rom.py` o mediante inspección de registros de audio que se producen escrituras periódicas en `rNR21`-`rNR24` durante los frames de juego.

4. **Defecto:** Transición sin animación ni fundido al cambiar de estado o nivel.
   - **Fichero:** `gbc/minijuegos/hydra_loop_98/main.asm`
   - **Qué cambiar:** Implementar un efecto de fundido de paleta CGB (manipulando `rBCPD`) antes de apagar la pantalla LCD al pasar del título al juego, entre niveles y a la pantalla final.
   - **Cómo se comprueba:** Verificar en `test_rom.py` que durante los cambios de estado se suceden escrituras de paleta con decremento progresivo de brillo.
