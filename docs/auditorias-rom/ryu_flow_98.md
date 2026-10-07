# Auditoría ROM River of the Dragon (`ryu_flow_98`)

Informe de auditoría frente al listón de calidad de #808 («cada ROM propia tiene que parecer un juego de Game Boy Color de 1998 que alguien habría comprado»).

## 1. Menú, instrucciones y flujo completo (título → juego → final → vuelta)
- **Estado:** Cumple.
- **Evidencia:**
  - **Pantalla de título:** `EstadoTitulo` (`main.asm`, líneas 201-218) y `DibujarTitulo` (`main.asm`, líneas 638-669). Carga la pantalla completa `TituloCGB` en GBC (`main.asm`, línea 640) o muestra texto en DMG (`TextoTitulo`, línea 1369). Pulso de `A` o `START` inicia la campaña normal; `B` inicia el postgame «Cauce inverso» si está desbloqueado.
  - **Instrucciones:** Diálogos del anciano en GBC al inicio de cada nivel (`EstadoDialogo`, líneas 242-250; `AbrirDialogo`, líneas 976-981; `DialogosCGB`, líneas 1554-1557), que el jugador avanza con `A` o `START`. En DMG muestra la guía `A GIRA` (`TextoGira`, línea 1373; `DibujarJuego`, líneas 672-698).
  - **Bucle de juego:** `EstadoJuego` (`main.asm`, líneas 219-240) e `IniciarJuego` / `IniciarNivel` (`main.asm`, líneas 306-362).
  - **Pantalla final:** `MostrarFinal` (`main.asm`, líneas 516-537) y `EstadoFin` (`main.asm`, líneas 252-271). Carga `VictoriaCGB` en GBC (`main.asm`, línea 524) o texto en DMG (`DibujarFinal`, líneas 709-751).
  - **Vuelta:** Desde `EstadoFin` (`main.asm`, líneas 266-270), pulsar `A` o `START` reinicia el flujo completo vía `IniciarJuego` (nivel 1); pulsar `B` ejecuta `IniciarDesafio`.

## 2. Estructura: número de niveles o fases y qué cambia entre ellos
- **Estado:** Cumple.
- **Evidencia:**
  - **Estructura de niveles:** 3 niveles en campaña normal (`NUM_NIVELES EQU 3`, `main.asm`, línea 80; tabla `Niveles`, líneas 1441-1456) y 3 niveles en postgame Cauce inverso (`NivelesDesafio`, líneas 1458-1471). En DMG solo se juega el primer nivel (`main.asm`, línea 485).
  - **Cambio de mecánicas:**
    - Nivel 1-1 (Día): 3 compuertas independientes, 2 estados (abierta/cerrada), `NIVEL_ACOPLADO = 0` (`main.asm`, líneas 1443-1446). Mínimo 3 movimientos.
    - Nivel 1-2 (Amanecer): 3 compuertas independientes, 3 estados (abierta/media/cerrada), `NIVEL_ACOPLADO = 0` (`main.asm`, líneas 1448-1451). Mínimo 6 movimientos.
    - Nivel 1-3 (Noche): 3 compuertas acopladas (`NIVEL_ACOPLADO = 1`, mover una compuerta altera también la de su derecha), 3 estados (`main.asm`, líneas 1453-1456). Mínimo 6 movimientos.
    - Postgame Cauce inverso: 3 niveles con estados iniciales y soluciones distintas (3, 6 y 7 movimientos mínimos, líneas 1458-1471).
  - **Cambios visuales entre niveles:**
    - Paletas de fondo CGB por nivel (`PaletasNivelCGB`, `main.asm`, líneas 1559-1560; `PaletasAmanecerCGB`, línea 1640; `PaletasNocheCGB`, línea 1642; aplicadas en `CargarPaletasNivelCGB`, líneas 876-899).
    - Paleta del dragón CGB por nivel (`PaletasDragonCGB`, `main.asm`, líneas 1588-1590; aplicadas en `CargarPaletaDragonCGB`, líneas 903-919).
    - Diálogos CGB específicos por nivel (`DialogosCGB`, `main.asm`, líneas 1554-1557).
    - Brillo y color del agua animados según la paleta del nivel actual (`AguaCGB`, `main.asm`, línea 1644; `AnimarAgua`, líneas 923-974).

## 3. Récord o progreso persistente en SRAM (el cartucho común MBC5 ya lo permite)
- **Estado:** Parcial.
- **Evidencia:**
  - **Progreso persistente:** Al completar la campaña normal (`CompletarFlujo`, `main.asm`, líneas 504-508), la ROM llama a `DesbloquearDesafio` (`main.asm`, líneas 1409-1425) y escribe la marca de desbloqueo del modo postgame en SRAM (`SRAM_DESAFIO`, dirección `$A004`, líneas 87-92). Al arrancar, `CargarProgreso` (`main.asm`, líneas 1379-1407) verifica la cabecera mágica `$A000-$A002`, la versión y el checksum `$A005`.
  - **Récord numérico de movimientos / puntuación:** no encontrado. El contador de movimientos se calcula en WRAM (`wMovimientos`, `main.asm`, líneas 1187-1206) y se dibuja con sprites HUD (`main.asm`, líneas 1025-1037), pero no se guarda en SRAM ni mantiene una mejor marca.

## 4. Música y sonido
- **Estado:** Parcial.
- **Evidencia:**
  - **Efectos de sonido:** `ConfigurarAudio` (`main.asm`, líneas 1320-1327) habilita los canales. Ofrece tres efectos de sonido en el canal 1 (`rNR10`-`rNR14`): `SonidoInicio` (`main.asm`, líneas 1329-1340) al pulsar inicio/confirmación, `SonidoCompuerta` (`main.asm`, líneas 1342-1353) al girar compuertas, y `SonidoExito` (`main.asm`, líneas 1355-1366) al completar un nivel o la partida.
  - **Música de fondo:** no encontrado. No hay motor de música ni melodía en bucle durante el menú, la partida o el desenlace.

## 5. Arte CGB propio: paletas, atributos con rVBK y sprites
- **Estado:** Cumple.
- **Evidencia:**
  - **Cabecera dual CGB:** `0x80` en `$0143` (`main.asm`, línea 143) y título `RYUFLOW98` (`main.asm`, línea 141).
  - **Láminas CGB a pantalla completa:** `CARGAR_PANTALLA_CGB` (`pantalla_cgb.asm`) carga `TituloCGB` (`main.asm`, línea 640), `JuegoCGB` (`main.asm`, línea 754) y `VictoriaCGB` (`main.asm`, línea 524).
  - **Atributos y VRAM2 (rVBK):** Acceso a banco 1 de VRAM vía `rVBK` (`main.asm`, líneas 761, 766, 1087) para transferir tiles de sprites y gestionar atributos por tile en pantallas GBC.
  - **Paletas CGB:** Control de paletas de fondo con `rBCPS`/`rBCPD` (`CargarPaletasNivelCGB`, `main.asm`, líneas 876-899) y de objetos con `rOCPS`/`rOCPD` (`ConfigurarPaletas`, líneas 1291-1318; `DibujarJuegoCGB`, líneas 778-788).
  - **Sprites y OAM:** Buffer OAM en sombra `wOAMSombra` en `$C200` (`OAM_BASE`, `main.asm`, línea 34; `OAM_REAL` en `$FE00`, línea 35). Copia 28 sprites en VBlank (`VolcarOAM`, líneas 1240-1250). Muestra cursor flotante (`ActualizarSpritesCGB`, líneas 993-1008), indicador de nivel, dragones despiertos, contador de 3 dígitos (`main.asm`, líneas 1009-1037), cabeza del dragón animada (`DragonCabezaFotogramas`, líneas 1039-1056) y dragón rugiendo en victoria (`ActualizarRugidoCGB`, líneas 1101-1119).

## 6. Animación o cinemática
- **Estado:** Cumple.
- **Evidencia:**
  - **Animación de paletas (agua):** `AnimarAgua` (`main.asm`, líneas 923-974) alterna el color del cauce cada 10 fotogramas (`AGUA_FOTOGRAMAS EQU 10`) sobre `PALETA_AGUA` siguiendo `SecuenciaBrilloAgua` (`0, 1, 2, 1`, `main.asm`, línea 1562; `AguaCGB`, línea 1644).
  - **Animación de sprites (Dragón en juego):** En reposo cicla 4 fotogramas (`DragonCabezaFotogramas`, `main.asm`, líneas 1051-1052, 1580). Al orientar una compuerta correctamente, el dragón abre el ojo durante 40 fotogramas (`wReaccion`, líneas 1040-1049).
  - **Animación de victoria (Dragón rugiendo):** En la pantalla final, `ActualizarRugidoCGB` (`main.asm`, líneas 1101-1119) anima el rugido alternando 2 fotogramas (`DragonRugido0`, `DragonRugido1`, línea 1584).
  - **Cinemática:** no encontrado. No se incluyen cinemáticas de vídeo o secuencias precalculadas independientes; las animaciones funcionan por sprites y paletas en tiempo real.

## 7. Evidencia de partida completa (tests en scripts/ con PyBoy o Siga98GB)
- **Estado:** Cumple.
- **Evidencia:**
  - **Pruebas de partida en PyBoy:** `gbc/minijuegos/ryu_flow_98/test_rom.py`:
    - `test_gbc_tres_niveles_con_dialogos_hasta_despertar_al_dragon` (líneas 194-250): recorre la partida completa en GBC (3 niveles, cierre de diálogos, giro de compuertas, reacción del dragón y verificación de la marca final `wRyuFlowCompletado = $A5` en WRAM `$C100`).
    - `test_cauce_inverso_recorre_tres_niveles_sin_publicar_handshake` (líneas 252-276): prueba la partida completa del postgame Cauce inverso en SRAM.
    - `test_game_boy_clasica_conserva_la_version_de_texto` (líneas 278-285): valida el recorrido en modo Game Boy clásica.
  - **Tests de superficie en scripts:** `scripts/test_ryu_runtime_surface.py` y `scripts/test_roms_propias.py` verifican el contrato de runtime, catálogo y coherencia del handshake `$C100 = $A5`.

---

## Defectos verificables y cortes propuestos

1. **Añadir música de fondo en la pantalla de título y durante el juego**
   - **Fichero a tocar:** `gbc/minijuegos/ryu_flow_98/main.asm`
   - **Qué cambiar:** Incorporar un reproductor de melodías en VBlank usando los canales 1 y 2 para emitir un bucle musical armónico en la pantalla de título y durante el recorrido del cauce.
   - **Cómo se comprueba:** Inspeccionar en test unitario que la rutina VBlank actualiza las notas del reproductor o comprobar que los registros `rNR10`-`rNR24` reciben datos periódicos durante la partida.

2. **Persistir el récord del menor número de movimientos en SRAM**
   - **Fichero a tocar:** `gbc/minijuegos/ryu_flow_98/main.asm`
   - **Qué cambiar:** Reservar una dirección en SRAM (`$A006`) para almacenar la menor cantidad de movimientos acumulados al completar los 3 niveles y mostrar la mejor marca en el HUD o pantalla de título.
   - **Cómo se comprueba:** `python3 -m unittest gbc/minijuegos/ryu_flow_98/test_rom.py` añadiendo una prueba que complete una partida, reduzca el número de movimientos en la segunda y verifique que el valor en `$A006` guarda el valor mínimo.
