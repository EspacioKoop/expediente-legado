# Evidencia de cierre — Pixel Exodus (#882)

Este documento vincula los criterios de aceptación de #882 con implementación y evidencia reproducible. La evidencia final se genera con la ROM real `caza_pixeles_98.gbc` ejecutada por **Siga98GB**, el mismo núcleo usado por la Portátil Color 98.

## Artefacto reproducible

El workflow `.github/workflows/evidencia-pixel-exodus-882.yml` compila RGBDS, la GDExtension y las ROMs propias, ejecuta las regresiones y lanza `godot/pruebas/capturar_pixel_exodus_882.gd`.

El artifact `evidencia-pixel-exodus-882-<sha>` contiene:

- `titulo.png`;
- `instrucciones.png`;
- `fase1.png`;
- `fase2-obstaculos.png`;
- `fase3-restauracion.png`;
- `behemoth.png`;
- `final-records.png`;
- `audio-sample-s16le-stereo-48k.pcm`;
- `manifest.json` con score, restauración, firmas PCM por tramo y récords SRAM reabiertos.

El playtest es automático y determinista en cuanto al objetivo de validación: después de arrancar la ROM pulsa A, lee el estado interno de la propia WRAM para perseguir objetivos y núcleos, evita las barreras por ruta y exige terminar el Behemoth. No escribe memoria del juego ni usa atajos de depuración.

## Matriz de aceptación

| Criterio de #882 | Cobertura |
| --- | --- |
| Trama ecológica entendible jugando | Intro y beats visuales de #906: Chromia → extractor → fuga de croma; zona muerta; retorno de ecosistema; Behemoth como residuo industrial. `instrucciones.png`, fases y final dejan la secuencia visible. |
| Degradación y restauración visibles | #892 añadió cuatro estados de Chromia (seco, agua, bosque, vivo) y retirada progresiva de basura orbital; #896 añadió fauna reactiva y fondos por fase. `fase3-restauracion.png` exige restauración real > 0. |
| Tres fases con reglas/presentación distintas | #887 implementó 45→30→15→0 s y reglas por fase; #896 añadió fondos/parallax/fauna diferenciados; #906 añadió música propia por fase. |
| Tres tipos de objetivo y obstáculos jugables | Croma, semilla y foco están cubiertos desde #887. El corte final añade barreras BG de residuo en fases 2/3 con AABB real y rechazo de movimiento; se retiran durante el Behemoth. |
| Restaurar compite con score/combo | Cerrar un foco restaura, pero rompe combo y devuelve x1 (#887). |
| Combo visible y riesgo/recompensa | HUD x1/x2/x3, ventana de 1,5 s y récord de combo (#887). |
| Glitch Behemoth ligado a residuos/sobreexplotación | #892: metasprite 32×32, cuatro focos vulnerables y restauración por limpieza; #906 refuerza la lectura narrativa. `behemoth.png` y el playtest exigen su derrota. |
| Título, instrucciones, cinemáticas, gameplay, final y récords | Título CGB (#810/#887), onboarding iconográfico congelando el primer segundo efectivo (este corte), beats/cinemáticas (#906), gameplay completo, final y récords SRAM (#887/#892). |
| Récords persisten al cerrar/reabrir | Formato `PX98` con versión/checksum y MBC5+8 KiB battery RAM (#887/#819). La evidencia guarda SRAM, crea una segunda instancia Siga98GB, la carga, arranca de nuevo y compara los 10 bytes de cabecera/récords. |
| Arte CGB detallado y atributos por tile | #892/#896 usan paletas BG separadas, `rVBK`, fauna BG, parallax y metasprite del boss; el presupuesto OAM del boss sigue en 18 entradas y máximo teórico 6/scanline. |
| Música y efectos propios | #906 separó SFX en canal 1 y música en canal 2 con patrones propios para fases, boss y finales. El manifest exige PCM a 48 kHz y firmas para fase1/fase2/fase3/boss/final. |
| README documenta técnicas, trama y procedencia | `gbc/minijuegos/caza_pixeles_98/README.md` describe campaña, CGB/rVBK/paletas/OAM/SRAM, música/cinemáticas y licencia MIT del código original del proyecto. |
| Capturas y playtest en Siga98GB | Este corte genera siete PNG directamente desde `run_frame_rgba()`, muestra PCM nativo y valida SRAM con `Siga98GB`. |
| Sin recompensa externa a la ROM | El bloque SRAM es privado del cartucho y no se conecta con `Partida`, `Jornada`, economía, pistas, sueños ni progreso del juego principal (#887 y README). |

## Presupuestos y límites preservados

Los obstáculos y las instrucciones son tiles BG: **0 sprites OAM adicionales**. El Behemoth conserva 16 sprites de cuerpo + núcleo + jugador, 18 entradas OAM totales y máximo teórico de 6 sprites por scanline. Las barreras se limpian al activarse el boss para no alterar su arena.

La intro de instrucciones dura 150 frames (~2,5 s a 60 Hz). Durante ese tramo se restauran la posición segura del jugador y los contadores de objetivo/frame cada tick; por tanto la partida entrega el control aún en **45 s**, sin consumir el primer segundo mientras se leen los iconos. Las transiciones de fase posteriores siguen siendo no bloqueantes.

## Condición de cierre

#882 puede cerrarse cuando el PR de este corte esté integrado y estén verdes:

1. `GBC fixtures` / build RGBDS de la ROM;
2. CI general y smoke de Siga98GB;
3. Alpha playtest;
4. `Evidencia Pixel Exodus #882`, incluido el artifact audiovisual y la reapertura SRAM.

Si cualquiera de esos gates descubre un defecto funcional o visual objetivo, el issue permanece abierto hasta corregirlo.

— Odiseo (GPT-5.6 Sol)
