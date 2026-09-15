# Puente de audio nativo del emulador GB/GBC

Este corte de #456 prepara la salida de audio de la ROM sin mezclarla todavía con la capa de sonidos físicos de la Portátil Color 98.

## Contrato nativo

`Siga98GB` configura la APU de SameBoy a **48 kHz**, registra `GB_apu_set_sample_callback` y conserva las muestras producidas por el núcleo como **PCM S16LE estéreo intercalado** (`L16, R16`, cuatro bytes por frame de audio).

La GDExtension expone dos métodos nuevos:

- `audio_sample_rate()` devuelve `48000`;
- `drain_audio_pcm16()` devuelve un `PackedByteArray` con el PCM acumulado y vacía la cola.

El buffer nativo está limitado a un segundo de audio. Si Godot deja de drenar la cola, el núcleo descarta muestras nuevas al alcanzar ese límite en vez de permitir crecimiento de memoria sin cota. `reset()` y la carga de una ROM nueva sustituyen el estado interno completo, por lo que el PCM de un cartucho anterior no se conserva.

SameBoy asocia el callback con la instancia correcta mediante `GB_set_user_data` / `GB_get_user_data`; no hay estado PCM global compartido entre emuladores.

## Gate de capacidad

Aunque la APU ya produce PCM real, `supports_audio() == false` se mantiene deliberadamente en este corte. La capacidad pública solo debe pasar a `true` cuando `EmuladorPortatilApp` consuma `drain_audio_pcm16()` mediante un `AudioStreamGenerator`, con mute/volumen propios y limpieza al pausar o cerrar.

Esto evita repetir el problema que #456 ya previno con CGB: anunciar una capacidad antes de que exista de extremo a extremo.

## Regresión ejecutable

`godot/pruebas/emulador_gb_smoke.gd` ejecuta la ROM propia durante 60 frames y después comprueba que:

- la frecuencia declarada es 48 kHz;
- SameBoy produjo un `PackedByteArray` PCM no vacío;
- el tamaño está alineado a frames estéreo S16LE de cuatro bytes;
- un segundo `drain_audio_pcm16()` queda vacío;
- `supports_audio()` continúa en `false` hasta conectar el consumidor Godot.

La inspección textual complementaria vive en `scripts/test_emulador_gb_audio.py`; no sustituye al smoke nativo.

## Siguiente corte

Con este puente disponible, el siguiente PR puede limitarse a UI/audio de Godot:

1. crear un `AudioStreamGenerator` independiente del `AudioStreamPlayer` de clics físicos;
2. decodificar S16LE a frames estéreo normalizados y alimentar `AudioStreamGeneratorPlayback`;
3. añadir mute y volumen exclusivos para la ROM;
4. drenar/limpiar al cambiar de ROM, pausar o salir;
5. activar `supports_audio()` únicamente cuando esa ruta pase CI.

Refs #456 #245 #124.

— Odiseo (GPT-5.6 Sol)
