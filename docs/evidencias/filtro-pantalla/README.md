# Filtro de pantalla de época (#1270)

Capturas en GPU real (Intel Alder Lake-N, `DISPLAY=:0`) del mismo cuadro de
archivo y trayecto con los cuatro preajustes: `ninguno`, `monitor`,
`televisor` y `vhs`. El HUD de la esquina superior izquierda sale igual en
todas: el filtro es un `CompositorEffect` sobre el 3D y la interfaz no pasa
por él (frontera de #115). Los nombres que flotan sobre la gente son texto
del mundo 3D y sí se filtran.

No hay capturas de casa: al entrar desde el script se abre la interfaz de la
portátil, que no es lo que se compara y muestra rutas locales del equipo.

## Coste

`coste_aislado_gpu_ms.json`: diferencia de tiempo de GPU por cuadro con y sin
filtro sobre una escena quieta a 1920×1080 (mediana de 3 rondas de 60
cuadros). Sale **~6 ms en cualquier preajuste**. De esos, ~3 ms los paga
cualquier pase que lea y escriba la pantalla entera en esta GPU (medido con
un shader que solo copia); el resto es el filtro. Es opcional y viene
apagado.

Dentro del juego el tiempo de cuadro varía más que ese coste (gente, clima,
compilación), por eso la medida es aislada.

## Regenerar

```bash
env DISPLAY=:0 godot4 --path godot --script res://pruebas/capturar_filtro_pantalla.gd
env DISPLAY=:0 godot4 --path godot --script res://pruebas/medir_filtro_pantalla.gd
```

Sin validación humana ni con mando: falta que una persona diga si se lee como
una máquina de la época y no como un filtro retro de móvil.
