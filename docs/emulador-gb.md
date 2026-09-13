# Emulador GB de la Portátil Color 98

El vertical de #124 integra un núcleo nativo para que la portátil de la casa pueda ejecutar la ROM propia `Caza Píxeles 98` y ROMs locales aportadas opcionalmente por el jugador.

## Núcleo y licencia

La GDExtension usa dos dependencias fijadas por commit en `godot/native/siga98_gb/deps.lock.json`:

- `godotengine/godot-cpp`, licencia MIT, bindings oficiales de GDExtension;
- `deltabeard/Peanut-GB`, licencia MIT, núcleo de emulación Game Boy/DMG.

Las dependencias no se vendorizan ni se descargan en tiempo de juego. `scripts/preparar_emulador_gb.sh` las obtiene exclusivamente durante el build desde los commits fijados y genera las bibliotecas nativas.

No se incluye BIOS, boot ROM ni ROM comercial.

## Compatibilidad real

Peanut-GB es un núcleo **DMG**, no un emulador Game Boy Color completo. Por eso este corte declara exactamente estas reglas:

- ROM Game Boy normal: compatible si el cartucho/MBC es admitido por Peanut-GB;
- cartucho dual-mode con byte CGB `0x80`: se admite en fallback DMG;
- ROM CGB-only con byte `0xC0`: se rechaza antes de inicializar el núcleo.

`Caza Píxeles 98` usa `0x80` y contiene fallback DMG, así que sirve como fixture propio para la integración. Sus paletas CGB no se reproducen todavía cuando corre mediante este núcleo.

## Interfaz

Al usar la Portátil Color 98:

1. el mundo se pausa sin modificar `Partida` ni `Jornada`;
2. aparece el selector de ROMs;
3. se ofrece la ROM propia si la build la contiene;
4. se añaden los `.gb`/`.gbc` válidos descubiertos en `user://roms`;
5. la ROM elegida se carga en memoria y el núcleo produce un framebuffer RGBA de 160×144;
6. `Esc` sale de la portátil y restaura el estado de pausa previo.

Controles del primer corte:

| Portátil | Teclado | Mando 0 |
| --- | --- | --- |
| Cruceta | Flechas o WASD | D-pad |
| A | Z o Espacio | A / botón inferior |
| B | X | B / botón derecho |
| Start | Enter | Start |
| Select | Tab | Back/Select |
| Salir | Esc | botón de UI |

## ROMs del jugador

`user://roms` sigue siendo una carpeta local, vacía por defecto. El proyecto no descarga ROMs, no ofrece enlaces para obtenerlas y no intenta convertir la presencia de un archivo en permiso para usarlo o redistribuirlo.

El catálogo solo acepta archivos directos `.gb`/`.gbc` de 32 KiB a 8 MiB. La persona que añade una ROM es responsable de tener derecho a usarla.

## Aislamiento

El wrapper nativo recibe únicamente:

- bytes de la ROM seleccionada;
- estado de ocho botones;
- RAM de cartucho efímera en memoria.

Devuelve únicamente el framebuffer RGBA y mensajes de error. No recibe referencias a `Partida`, `Jornada`, expedientes, dinero, pistas ni guardados del juego principal.

## Limitaciones del primer vertical

- sin emulación CGB real;
- sin audio embebido todavía;
- SRAM de cartucho no persistente todavía;
- una ROM incompatible se rechaza en la inicialización cuando Peanut-GB puede identificarla;
- no se promete compatibilidad con todos los MBC o homebrew existentes.

## Build reproducible

En Linux, con RGBDS disponible para la ROM propia:

```bash
bash scripts/preparar_emulador_gb.sh linux-debug
bash scripts/preparar_emulador_gb.sh rom
```

Para generar bibliotecas de exportación:

```bash
bash scripts/preparar_emulador_gb.sh linux-all
bash scripts/preparar_emulador_gb.sh windows-release
```

CI ejecuta además `godot/pruebas/emulador_gb_smoke.gd`: carga `Caza Píxeles 98`, ejecuta doce frames y exige un framebuffer de 160×144×4 bytes con contenido no uniforme.

— Odiseo (GPT-5.6 Sol)
