# Auditoría ROM VITRAL 98 frente al listón de #808

Informe del estado de `gbc/minijuegos/vitral_98/main.asm` frente a los siete criterios de calidad de la épica #808.

## 1. Menú, instrucciones y flujo completo (título → juego → final → vuelta)

**Estado:** Parcial

**Evidencia:**
- Pantalla de título: `EstadoTitulo` (líneas 115-121) muestra el título con `DibujarTitulo` (líneas 277-298).
- Flujo de juego: `EstadoJuego` (líneas 123-146) y rutina `IniciarJuego` (líneas 156-171).
- Pantalla final: `CompletarVitral` (líneas 257-267) activa `ESTADO_FIN` y llama a `DibujarVictoria` (líneas 412-427).
- Vuelta al inicio: `EstadoFin` (líneas 148-154) reinicia el bucle hacia `IniciarJuego` al pulsar A o Start.
- Instrucciones: no encontrado en `main.asm`. No hay texto ni pantalla de instrucciones o controles.

## 2. Estructura: número de niveles o fases y qué cambia entre ellos

**Estado:** No cumple

**Evidencia:**
- La variable `wFases` (líneas 162-165, 625) almacena únicamente la rotación de las 4 piezas del único puzle.
- Número de niveles: 1 nivel único.
- Variación entre niveles: no encontrado en `main.asm`. No existen más escenarios, fases ni niveles progresivos.

## 3. Récord o progreso persistente en SRAM (el cartucho común MBC5 ya lo permite)

**Estado:** No cumple

**Evidencia:**
- `main.asm` incluye `../comun/cartucho.asm` (línea 61) e invoca `IniciarCartucho` (línea 79).
- Solo se escribe la marca de completado `$A5` en WRAM `$C100` (`wVitralCompletado`, líneas 261-262, 622).
- Uso o guardado en SRAM (`$A000-$BFFF`): no encontrado en `main.asm`. No se guarda progreso ni récords entre reinicios.

## 4. Música y sonido

**Estado:** Parcial

**Evidencia:**
- `ConfigurarAudio` (líneas 523-530) inicializa la APU (`rNR50`-`rNR52`).
- Efectos de sonido: `SonidoInicio` (líneas 532-541), `SonidoMover` (líneas 543-552) y `SonidoVictoria` (líneas 554-563) en Canal 1.
- Música de fondo (BGM): no encontrado en `main.asm`. No existe motor de música continua ni melodía en bucle.

## 5. Arte CGB propio: paletas, atributos con rVBK y sprites

**Estado:** Parcial

**Evidencia:**
- Modo CGB dual declarado en la cabecera `$0143`: `db $80` (línea 72).
- Paletas CGB: `ConfigurarPaletas` (líneas 509-521) escribe en `rBCPS`/`rBCPD` desde `PaletaCGB` (línea 575: `dw $0000, $001F, $03E0, $7C00`).
- Atributos por tile con `rVBK` (banco 1 VRAM): no encontrado en `main.asm`.
- Sprites u objetos OAM: no encontrado en `main.asm`. Todo el dibujado se hace sobre el fondo (`BG_MAP`).

## 6. Animación o cinemática

**Estado:** No cumple

**Evidencia:**
- Ciclado de paletas, intercambio de tiles animados, scroll o cinemáticas: no encontrado en `main.asm`.
- Los gráficos se redibujan estáticamente en `BG_MAP` solo tras una entrada de control (`ActualizarJuego`, líneas 269-275).

## 7. Evidencia de partida completa (tests en scripts/ con PyBoy o Siga98GB)

**Estado:** Parcial

**Evidencia:**
- `gbc/minijuegos/vitral_98/test_rom.py` incluye `Vitral98PlayTest` (líneas 45-89) probando la partida completa con PyBoy.
- Test de integración con PyBoy/Siga98GB en `scripts/`: no encontrado. `scripts/test_religion_rom_932.py` comprueba solo la integración Godot y aserciones de código fuente en `main.asm`.

## Defectos verificables y cortes propuestos

1. **Falta de indicación de controles e instrucciones en pantalla**
   - Fichero: `gbc/minijuegos/vitral_98/main.asm`
   - Cambio: Dibujar texto descriptivo de botones en `DibujarTitulo` o añadir una pantalla previa de instrucciones.
   - Comprobación: Test de PyBoy en `test_rom.py` que valide los tiles cargados en `BG_MAP`.

2. **Ausencia de música de fondo en bucle**
   - Fichero: `gbc/minijuegos/vitral_98/main.asm`
   - Cambio: Implementar un secuenciador simple de notas sobre el Canal 1 o 2 en el bucle principal.
   - Comprobación: Test con PyBoy comprobando la actualización de frecuencia en `rNR13`/`rNR14`.

3. **Sin uso de atributos de color CGB con `rVBK` ni sprites**
   - Fichero: `gbc/minijuegos/vitral_98/main.asm`
   - Cambio: Seleccionar el banco 1 de VRAM mediante `rVBK` al dibujar para asignar paletas distintas al plomo y al vidrio.
   - Comprobación: Test de PyBoy verificando la memoria VRAM del banco 1.

4. **Inexistencia de persistencia en SRAM para récords o estado**
   - Fichero: `gbc/minijuegos/vitral_98/main.asm`
   - Cambio: Habilitar SRAM (`$0A` en `$0000`), registrar el tiempo o conteo de movimientos al finalizar en `$A000` y deshabilitar SRAM.
   - Comprobación: Test de PyBoy validando la lectura de la SRAM guardada tras reiniciar.

5. **Falta de test PyBoy integrado dentro del directorio global `scripts/`**
   - Fichero: `scripts/test_auditorias.py`
   - Cambio: Crear una prueba con PyBoy que cargue y resuelva `build/vitral_98.gbc`.
   - Comprobación: Ejecutar `PYTHONPATH=scripts python3 -m unittest scripts.test_auditorias`.

6. **Limitación a un único puzle sin fases ni progresión de niveles**
   - Fichero: `gbc/minijuegos/vitral_98/main.asm`
   - Cambio: Añadir un array con un segundo patrón de vidriera para requerir completar dos niveles antes de escribir `$A5` en WRAM `$C100`.
   - Comprobación: Test con PyBoy que valide el cambio de nivel tras completar la primera solución.

7. **Ausencia de efectos de animación o simulación de luz**
   - Fichero: `gbc/minijuegos/vitral_98/main.asm`
   - Cambio: Implementar un contador en VBlank para alternar la paleta CGB de luz en `EstadoFin`.
   - Comprobación: Test de PyBoy verificando la alteración periódica de paleta en `rBCPS`/`rBCPD`.
