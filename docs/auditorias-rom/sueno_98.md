# Auditoría ROM SUEÑO 98 contra el listón de #808

Estado real de `gbc/minijuegos/sueno_98/main.asm` frente al listón de calidad de #808 y las restricciones culturales de `docs/literatura-rom-sueno-1179.md`.

---

## 1. Menú, instrucciones y flujo completo

**Resultado:** Parcial

**Evidencia:**
- **Pantalla de título:** Existe la etiqueta `EstadoTitulo` y la función `DibujarTitulo`.
- **Instrucciones:** No encontrado. No hay pantalla ni texto de instrucciones en `main.asm`.
- **Juego:** Existe la etiqueta `EstadoJuego` y la función `DibujarJuego`.
- **Pantalla final:** Existe la etiqueta `EstadoFin` y la función `DibujarVictoria`.
- **Vuelta:** En `EstadoFin`, pulsar `KEY_A` o `KEY_START` llama a `IniciarJuego`. Reinicia el juego directamente en lugar de volver a la pantalla de título.

---

## 2. Estructura: número de niveles o fases y qué cambia entre ellos

**Resultado:** Cumple

**Evidencia:**
- **Fases:** Tres rondas/niveles (`wRonda` = 0, 1, 2 en WRAM).
- **Variación de objetivos:** Tabla `Objetivos`: ronda 1 (`%00000101`), ronda 2 (`%00000110`), ronda 3 (`%00000011`).
- **Indicador visual:** La función `DibujarRonda` escribe el tile correspondiente (`TILE_1`, `TILE_2`, `TILE_3`) en el mapa de fondo (`BG_MAP + (3 * 32) + 9`).

---

## 3. Récord o progreso persistente en SRAM

**Resultado:** No cumple

**Evidencia:**
- **Uso de SRAM:** No encontrado.
- El archivo `main.asm` solo utiliza WRAM (sección `Handshake` en `WRAM0[$C100]`). No habilita ni escribe en la SRAM del cartucho MBC5 (`$A000-$BFFF`).

---

## 4. Música y sonido

**Resultado:** No cumple

**Evidencia:**
- **Audio:** No encontrado.
- `main.asm` no inicializa ni escribe en los registros de audio de la Game Boy (`rNR10` a `rNR52`, `$FF10-$FF26`). Tampoco incluye rutinas de sonido o efectos sonoros.

---

## 5. Arte CGB propio: paletas, atributos con rVBK y sprites

**Resultado:** Parcial

**Evidencia:**
- **Paletas CGB:** La función `ConfigurarPaletas` define una única paleta de fondo CGB en `PaletaCGB` (líneas 354-355: `dw $0000, $18C6, $3DEF, $7FFF`).
- **Atributos de fondo con rVBK:** No encontrado. No se utiliza la banca 1 de VRAM (`rVBK` = `$FF4F`) ni mapa de atributos CGB.
- **Sprites:** No encontrado. El registro `rLCDC` se configura sin habilitar objetos/sprites (`ld a, $91`) y no hay llamadas a OAM o DMA.

---

## 6. Animación o cinemática

**Resultado:** No cumple

**Evidencia:**
- **Animación y cinemática:** No encontrado.
- La pantalla no contiene secuencias animadas de tiles, transiciones de paleta ni cinemáticas. Todas las actualizaciones de pantalla son redibujados estáticos completos mediante `DibujarJuego` o `DibujarVictoria`.

---

## 7. Evidencia de partida completa

**Resultado:** Cumple

**Evidencia:**
- **Test de partida completa:** El archivo `gbc/minijuegos/sueno_98/test_rom.py` contiene la suite `Sueno98PlayTest`.
- **Ejecución PyBoy:** Simula el arranque, la navegación de la pantalla de título, la resolución de las 3 rondas mediante combinaciones de botones, la verificación de `$C100 == 0xA5` al finalizar y el reinicio de la ROM.

---

## Defectos verificables y cortes propuestos

Lista de propuestas técnica y culturalmente alineadas con `docs/literatura-rom-sueno-1179.md` (sin texto de la obra, ni gamificación de lectura, ni elementos ajenos a la invención abstracta de SIGA-98):

1. **Retorno al menú de título al finalizar la partida en lugar de reinicio directo.**
   - **Fichero a modificar:** `gbc/minijuegos/sueno_98/main.asm`
   - **Cambio:** En `EstadoFin`, cambiar la llamada de `IniciarJuego` por `call DibujarTitulo` y cambiar el estado a `ESTADO_TITULO`.
   - **Comprobación:** Ejecutar `PYTHONPATH=. python3 -m unittest gbc/minijuegos/sueno_98/test_rom.py` adaptando la aserción de la pulsación final para verificar que el estado vuelve a `ESTADO_TITULO`.

2. **Implementación de retroalimentación sonora básica para acciones de juego.**
   - **Fichero a modificar:** `gbc/minijuegos/sueno_98/main.asm`
   - **Cambio:** Habilitar el chip de sonido en `Inicio` (registros `rNR50`, `rNR51`, `rNR52`) y añadir llamadas a una rutina de pitido abstracto al mover el cursor, alternar panel o completar el objetivo.
   - **Comprobación:** Inspeccionar en `main.asm` las escrituras en `$FF24`, `$FF25` y `$FF26` durante las acciones del jugador.

3. **Uso de atributos CGB y banco 1 de VRAM (`rVBK`) para coloreado diferenciado.**
   - **Fichero a modificar:** `gbc/minijuegos/sueno_98/main.asm`
   - **Cambio:** Seleccionar banca de VRAM 1 mediante `rVBK` (`$FF4F`) al cargar el mapa de fondo en `BG_MAP` para aplicar paletas CGB distintas al marco y a los paneles.
   - **Comprobación:** Buscar referencias a `rVBK` y escrituras en VRAM banco 1 en `main.asm`.

4. **Persistencia de recuento de victorias o estado en SRAM.**
   - **Fichero a modificar:** `gbc/minijuegos/sueno_98/main.asm`
   - **Cambio:** Habilitar SRAM escribiendo `$0A` en `$0000`, incrementar un contador de completados en `$A000` al llegar a `CompletarObjetivoFinal` y deshabilitar SRAM escribiendo `$00` en `$0000`.
   - **Comprobación:** Inspeccionar en `main.asm` el bloque de código `CompletarObjetivoFinal` para validar el guardado en `$A000`.
