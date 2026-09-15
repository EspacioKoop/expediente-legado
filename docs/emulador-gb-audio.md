# Audio del emulador GB/GBC

#456 ya dispone de recorrido de audio de extremo a extremo: SameBoy produce PCM y la Portátil Color 98 lo reproduce en Godot sin mezclarlo con la capa de sonidos físicos de #245.

## Contrato nativo

`Siga98GB` configura la APU de SameBoy a **48 kHz**, registra `GB_apu_set_sample_callback` y conserva las muestras producidas por el núcleo como **PCM S16LE estéreo intercalado** (`L16, R16`, cuatro bytes por frame de audio).

La GDExtension expone:

- `audio_sample_rate()`, que devuelve `48000`;
- `drain_audio_pcm16()`, que devuelve un `PackedByteArray` con el PCM acumulado y vacía la cola;
- `supports_audio() == true`, porque ya existe un consumidor Godot conectado al runtime real de la portátil.

El buffer nativo está limitado a un segundo de audio. Si Godot deja de drenar la cola, el núcleo descarta muestras nuevas al alcanzar ese límite en vez de permitir crecimiento de memoria sin cota. `reset()` y la carga de una ROM nueva sustituyen el estado interno completo, por lo que el PCM de un cartucho anterior no se conserva.

SameBoy asocia el callback con la instancia correcta mediante `GB_set_user_data` / `GB_get_user_data`; no hay estado PCM global compartido entre emuladores.

## Consumer Godot

`EmuladorPortatilAudioApp` extiende la superficie existente sin tocar la capa física de #245. La consola instancia esta variante para el juego real.

El consumer:

1. crea un `AudioStreamGenerator` a 48 kHz y un `AudioStreamPlayer` llamado `AudioEmuladoPortatil`;
2. drena `drain_audio_pcm16()` después de ejecutar frames del emulador;
3. decodifica cada par S16LE y lo normaliza a `Vector2(left, right)`;
4. usa `get_frames_available()` y `push_buffer()` para no escribir por encima de la capacidad disponible;
5. conserva un backlog Godot acotado a 9600 frames (0,2 s a 48 kHz), descartando audio antiguo antes de permitir crecimiento sin límite;
6. limpia tanto el backlog como `AudioStreamGeneratorPlayback` al cambiar de ROM, cerrar la portátil o salir del árbol.

El audio emulado tiene volumen y mute propios mediante `set_audio_emulado_volumen()` y `set_audio_emulado_muted()`. Al mutear se limpia el audio pendiente para que al volver a activarlo no reaparezca sonido atrasado.

Los clics procedurales de cartucho, encendido y botones siguen en el `AudioStreamPlayer` físico de `EmuladorPortatilApp`; no comparten stream, volumen ni cola con la ROM.

## Gate de capacidad

`supports_audio()` pasa a `true` únicamente en este corte, después de conectar el PCM a `AudioStreamGenerator`. El mismo criterio ya usado para CGB se mantiene: una capacidad pública no se anuncia antes de existir de extremo a extremo.

## Regresión ejecutable

`godot/pruebas/emulador_gb_smoke.gd` ejecuta la ROM propia durante 60 frames y comprueba que:

- `supports_audio()` está activo;
- la frecuencia declarada es 48 kHz;
- SameBoy produjo un `PackedByteArray` PCM no vacío;
- el tamaño está alineado a frames estéreo S16LE de cuatro bytes;
- un segundo `drain_audio_pcm16()` queda vacío.

`scripts/test_emulador_gb_audio.py` fija además el contrato del consumer Godot: `AudioStreamGenerator`, decodificación S16LE, backlog acotado, limpieza y controles independientes de mute/volumen.

## Pendiente de validación manual

El smoke headless valida generación y contrato, pero un runner CI sin dispositivo de audio no demuestra percepción humana ni latencia acústica. Antes de dar por cerrado todo #456 conviene una pasada manual de la alpha en Linux/Windows comprobando continuidad, ausencia de chasquidos al cambiar de ROM y que el audio se corta al salir.

Refs #456 #245 #124 #592.

— Odiseo (GPT-5.6 Sol)
