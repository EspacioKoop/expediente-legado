# Auditoría ROM SARNATH 98 contra el listón de #808

Auditoría de `gbc/minijuegos/sarnath_98/main.asm` frente al listón de calidad de #808 («cada ROM propia tiene que parecer un juego de Game Boy Color de 1998 que alguien habría comprado»).

## 1. Menú, instrucciones y flujo completo (título → juego → final → vuelta)

**Estado**: Parcial.

**Evidencia**:
- Flujo completo: Presente en `main.asm`. El estado inicial es título (`ESTADO_TITULO`), pasa a juego (`ESTADO_JUEGO`), alcanza la pantalla final (`ESTADO_FIN`) y la pulsación de A o START en el final reinicia la partida llamando a `IniciarJuego`.
- Menú e instrucciones: En `DibujarTitulo` se muestra una composición estática de tiles sin menú de opciones ni pantalla de instrucciones explicativas con texto («no encontrado»).

## 2. Estructura: número de niveles o fases y qué cambia entre ellos

**Estado**: Cumple.

**Evidencia**:
- Tres rondas o fases deterministas controladas por la variable `wRonda` en WRAM.
- Cambia la secuencia de rumbos a memorizar y la longitud del trayecto:
  - Ronda 1 (`Ruta0`): 3 pasos (Arriba → Derecha → Arriba).
  - Ronda 2 (`Ruta1`): 4 pasos (Izquierda → Arriba → Derecha → Abajo).
  - Ronda 3 (`Ruta2`): 5 pasos (Arriba → Arriba → Derecha → Abajo → Izquierda).
- Las subrutinas `ObtenerRuta` y `LongitudRuta` ajustan la ruta activa. `DibujarNumeroRonda` cambia el tile numérico (`TILE_1`, `TILE_2`, `TILE_3`) y resetea el índice (`wIndice`).

## 3. Récord o progreso persistente en SRAM (el cartucho común MBC5 ya lo permite)

**Estado**: No cumple.

**Evidencia**:
- La ROM no habilita la RAM del cartucho MBC5 (`rRAMG`, `$0A`).
- Solo define la sección `SECTION "Handshake", WRAM0[$C100]` para comunicar el estado a Godot.
- Guardado en SRAM, registro de récords o persistencia de progreso tras apagar la consola: «no encontrado».

## 4. Música y sonido

**Estado**: Parcial.

**Evidencia**:
- `ConfigurarAudio` habilita el chip de sonido APU.
- Contiene 5 efectos de sonido efímeros en el canal 1 de pulsos: `SonidoInicio`, `SonidoMover`, `SonidoError`, `SonidoRonda` y `SonidoVictoria`.
- Música de fondo o reproductor BGM en bucle dentro de `Bucle`: «no encontrado».

## 5. Arte CGB propio: paletas, atributos con rVBK y sprites

**Estado**: Parcial.

**Evidencia**:
- Cabecera CGB dual declarada (`db $80`).
- Grafismo propio en tiles de VRAM (`Tiles` a `TilesFin`).
- `ConfigurarPaletas` escribe 1 paleta BG en CGB mediante `rBCPS`/`rBCPD` a partir de `PaletaCGB`.
- Uso del banco 1 de VRAM (`rVBK`) para atributos de tiles: «no encontrado».
- Sprites u objetos OAM: «no encontrado».

## 6. Animación o cinemática

**Estado**: No cumple.

**Evidencia**:
- No hay animación de tiles, fotogramas articulados ni cinemáticas.
- Las transiciones entre pantallas borran el mapa de fondo (`LimpiarFondo`) apagando y encendiendo la pantalla LCD de golpe (`DesactivarLCD`, `ActivarLCD`, líneas 337 y 343).
- Animación o cinemática: «no encontrado».

## 7. Evidencia de partida completa (tests en scripts/ con PyBoy o Siga98GB)

**Estado**: Parcial.

**Evidencia**:
- `gbc/minijuegos/sarnath_98/test_rom.py` incluye la clase `Sarnath98PlayTest` que simula una partida completa en PyBoy (error, ronda 1, ronda 2, ronda 3, verificación de `$A5` en `$C100` y reinicio).
- Test de partida completa con emulador dentro del directorio `scripts/`: «no encontrado».

## Defectos verificables y cortes propuestos

Los siguientes cortes propuestos respetan los límites culturales de `docs/religion-rom-sarnath-932.md` (no gamifican meditación, recitación o méritos, ni usan símbolos devocionales como pickups):

1. **Pantalla de instrucciones explicativa en `main.asm`**
   - Fichero: `gbc/minijuegos/sarnath_98/main.asm`
   - Qué cambiar: Insertar un estado de instrucciones entre la pantalla de título y el inicio del juego que indique visualmente la regla de memorizar y repetir las direcciones.
   - Cómo se comprueba: Ejecutar `python3 -m unittest gbc/minijuegos/sarnath_98/test_rom.py` tras añadir un test que verifique el avance de pantalla desde instrucciones.

2. **Persistencia de progreso en SRAM en `main.asm`**
   - Fichero: `gbc/minijuegos/sarnath_98/main.asm`
   - Qué cambiar: Habilitar la SRAM del MBC5 mediante `rRAMG` y guardar en `$A000` el contador de rondas completadas o intentos acumulados.
   - Cómo se comprueba: Ejecutar `python3 -m unittest gbc/minijuegos/sarnath_98/test_rom.py` leyendo `$A000` en PyBoy tras reiniciar la emulación.

3. **Música de fondo para el estado de juego en `main.asm`**
   - Fichero: `gbc/minijuegos/sarnath_98/main.asm`
   - Qué cambiar: Añadir un bucle de música de fondo en `Bucle` actualizando frecuencias en cada frame durante `ESTADO_JUEGO`.
   - Cómo se comprueba: Ejecutar `python3 -m unittest gbc/minijuegos/sarnath_98/test_rom.py` comprobando la actualización de registros de canal de audio durante el bucle de juego.

4. **Uso de atributos de color con rVBK en `main.asm`**
   - Fichero: `gbc/minijuegos/sarnath_98/main.asm`
   - Qué cambiar: Conmuta al banco 1 de VRAM usando `rVBK` para asignar paletas diferenciadas a los marcos y flechas en el tilemap.
   - Cómo se comprueba: Verificar mediante PyBoy en `test_rom.py` que la VRAM banco 1 tenga asignados los atributos de paleta correspondientes.

5. **Revelación animada de secuencias en `main.asm`**
   - Fichero: `gbc/minijuegos/sarnath_98/main.asm`
   - Qué cambiar: Mostrar cada paso de la secuencia progresivamente con pequeñas pausas en lugar de escribir toda la ruta de golpe en VRAM.
   - Cómo se comprueba: Ejecutar `python3 -m unittest gbc/minijuegos/sarnath_98/test_rom.py` comprobando estados intermedios del mapa de tiles entre VBlanks.

6. **Integración de test de partida completa en `scripts/test_religion_rom_932.py`**
   - Fichero: `scripts/test_religion_rom_932.py`
   - Qué cambiar: Añadir una prueba que valide la ejecución del flujo completo de SARNATH 98 invocando el arnés PyBoy o la simulación de ciclo.
   - Cómo se comprueba: Ejecutar `PYTHONPATH=scripts python3 -m unittest scripts.test_religion_rom_932`.
