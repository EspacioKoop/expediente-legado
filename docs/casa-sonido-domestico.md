# Sonido doméstico espacial (#96)

La casa puede reforzar hechos reales con sonido, pero solo cuando el hecho implique una fuente sonora física.

## Regla

No existe una “banda sonora de situación económica”. Recibos, comida escasa, vueltas acumuladas o una bombilla fundida siguen siendo señales visuales. El primer caso sonoro de #96 es el grifo averiado, porque un goteo sí es una consecuencia física del estado ya persistido.

## Goteo

`CasaConsecuenciasAudio` genera un `AudioStreamWAV` procedural, determinista y en bucle. `CasaConsecuencias3D` lo monta como `AudioStreamPlayer3D` dentro de `GrifoGoteando`:

- bus `Ambiente`;
- volumen local moderado;
- atenuación 3D;
- alcance máximo corto;
- sin assets externos ni procedencia inventada;
- desaparece al desaparecer `casa_grifo_averiado`.

La fuente sonora no modifica estado, economía ni consecuencias.
