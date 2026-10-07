# Auditoría ROM JALI 98 contra el listón de #808

Auditoría del estado real de `gbc/minijuegos/jali_98/main.asm` frente al listón de calidad #808 («cada ROM propia tiene que parecer un juego de Game Boy Color de 1998 que alguien habría comprado»).

Restricción cultural respetada: `docs/religion-rom-jali-932.md` prohíbe la gamificación o recompensa con elementos sagrados, textos coránicos, nombres divinos o rituales.

---

## 1. Menú, instrucciones y flujo completo (título → juego → final → vuelta)
- **Estado:** Parcial
- **Evidencia:**
  - Pantalla de título: `EstadoTitulo` (líneas 123-129) y `DibujarTitulo` (líneas 220-239).
  - Estado de juego: `EstadoJuego` (líneas 131-155) y `DibujarJuego` (líneas 241-249).
  - Pantalla de final: `EstadoFin` (líneas 157-163) y `DibujarVictoria` (líneas 294-316).
  - Vuelta al juego: `EstadoFin` reinicia el puzle al pulsar A o Start llamando a `IniciarJuego` (líneas 157-163 y 165-179).
  - Instrucciones: no encontrado. No hay pantalla de ayuda ni texto explicativo sobre el control o la meta.

## 2. Estructura: número de niveles o fases y qué cambia entre ellos
- **Estado:** No cumple
- **Evidencia:**
  - `main.asm` contiene únicamente un puzle de 3 bandas (`wFases`, línea 394) con solución fija 1/3/2 (líneas 196-206).
  - No hay niveles progresivos, fases adicionales ni cambios de reglas o escenario (líneas 131-155).

## 3. Récord o progreso persistente en SRAM (el cartucho común MBC5 ya lo permite)
- **Estado:** No cumple
- **Evidencia:**
  - No existe `SECTION "SRAM"` en `main.asm`.
  - El cartucho incluye `cartucho.asm` (línea 68), pero solo utiliza WRAM0 (`SECTION "Handshake", WRAM0[$C100]`, líneas 390-398). No guarda récord, número de intentos ni estado resuelto en la SRAM con batería ($A000-$BFFF).

## 4. Música y sonido
- **Estado:** Parcial
- **Evidencia:**
  - Efectos de sonido: implementa tres efectos en el canal 1 mediante `SonidoInicio` (líneas 361-369), `SonidoMover` (líneas 371-379) y `SonidoVictoria` (líneas 381-389).
  - Música: no encontrado. No hay motor de audio ni melodía continua de fondo en el bucle principal (`Bucle`, líneas 112-121) ni en la interrupción `VBlank` (líneas 70-72).

## 5. Arte CGB propio: paletas, atributos con rVBK y sprites
- **Estado:** Parcial
- **Evidencia:**
  - Paletas CGB: carga una única paleta CGB de 4 colores (`PaletaCGB`, líneas 346-347) con `rBCPS` y `rBCPD` en `ConfigurarPaletas` (líneas 338-344).
  - Atributos con `rVBK`: no encontrado. No se usa el registro `rVBK` para direccionar el banco 1 de VRAM ni asignar paletas por tile.
  - Sprites: no encontrado. No habilita OAM ni usa sprites hardware. El cursor de selección se dibuja como un tile de fondo en la VRAM BG (`DibujarCursor`, líneas 274-292).

## 6. Animación o cinemática
- **Estado:** No cumple
- **Evidencia:**
  - Animación: no encontrado. La interrupción `VBlank` ejecuta `reti` directamente (líneas 70-72). No hay animación de tiles ni ciclado de paleta.
  - Cinemática: no encontrado. La pantalla de victoria (`DibujarVictoria`, líneas 294-316) es un redibujado estático del mapa de fondo.

## 7. Evidencia de partida completa (tests en scripts/ con PyBoy o Siga98GB)
- **Estado:** Cumple
- **Evidencia:**
  - Test con PyBoy: `gbc/minijuegos/jali_98/test_rom.py` en la clase `Jali98PlayTest` (líneas 49-98) simula la partida completa (arranque, rotación de bandas, resolución y verificación de WRAM `$C100 == $A5`).
  - Test de integración: `scripts/test_religion_rom_932.py` comprueba el cumplimiento del contrato técnico y la frontera documental definida en `docs/religion-rom-jali-932.md`.

---

## Defectos verificables y cortes propuestos

1. **Añadir texto de instrucciones en el menú de título**
   - Fichero: `gbc/minijuegos/jali_98/main.asm`
   - Qué cambiar: Dibujar en `DibujarTitulo` un texto explicativo breve sobre las tres bandas y el control de luz/sombra.
   - Cómo se comprueba: Verificar mediante assert de inspección de VRAM BG map en `gbc/minijuegos/jali_98/test_rom.py`.

2. **Persistencia de victorias o movimientos en SRAM**
   - Fichero: `gbc/minijuegos/jali_98/main.asm`
   - Qué cambiar: Añadir `SECTION "SRAM", SRAM[$A000]` y escribir el contador de victorias o mejor número de rotaciones activando el acceso a SRAM (`$0A` en `$0000`).
   - Cómo se comprueba: Test PyBoy en `gbc/minijuegos/jali_98/test_rom.py` leyendo `$A000` en SRAM tras reiniciar la ROM.

3. **Mapeo de paletas por zona con rVBK (VRAM banco 1)**
   - Fichero: `gbc/minijuegos/jali_98/main.asm`
   - Qué cambiar: Alternar `rVBK` a 1 durante la carga del mapa de fondo para aplicar atributos de paletas CGB diferenciadas entre el marco de piedra, las bandas y las marcas de luz.
   - Cómo se comprueba: Test PyBoy en `gbc/minijuegos/jali_98/test_rom.py` leyendo el banco 1 de VRAM (`$9800`) para validar que los atributos contienen índices de paleta distintos de cero.

4. **Cursor mediante Sprites OAM**
   - Fichero: `gbc/minijuegos/jali_98/main.asm`
   - Qué cambiar: Sustituir el dibujo del cursor en el mapa BG por la gestión de un sprite en la tabla OAM (`$FE00`), actualizando sus coordenadas Y/X según la banda seleccionada.
   - Cómo se comprueba: Test PyBoy en `gbc/minijuegos/jali_98/test_rom.py` leyendo `$FE00` para confirmar las coordenadas del sprite en OAM.

5. **Animación de pulso de luz en VBlank**
   - Fichero: `gbc/minijuegos/jali_98/main.asm`
   - Qué cambiar: Incrementar un contador en `VBlank` para modular levemente la intensidad de la paleta de luz o alternar tiles de rayos.
   - Cómo se comprueba: Test PyBoy en `gbc/minijuegos/jali_98/test_rom.py` haciendo avanzar varios fotogramas y comprobando la alternancia del registro de paleta o VRAM.

6. **Estructurar la ROM en tres composiciones progresivas**
   - Fichero: `gbc/minijuegos/jali_98/main.asm`
   - Qué cambiar: Añadir tres niveles o rondas con diferentes configuraciones de solución geométrica antes de publicar la marca de completado `$A5` en `$C100`.
   - Cómo se comprueba: Test PyBoy en `gbc/minijuegos/jali_98/test_rom.py` resolviendo el primer nivel y comprobando que el estado avanza al nivel 2 antes de finalizar.

7. **Bucle de música de fondo en canal de onda**
   - Fichero: `gbc/minijuegos/jali_98/main.asm`
   - Qué cambiar: Implementar un secuenciador simple que actualice las frecuencias de los canales de sonido en `VBlank` para mantener una melodía ambiental continua.
   - Cómo se comprueba: Test PyBoy en `gbc/minijuegos/jali_98/test_rom.py` verificando que los registros `rNR13`/`rNR14` cambian periódicamente tras varios ticks sin pulsar botones.
