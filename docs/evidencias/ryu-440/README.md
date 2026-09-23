# Evidencia visual de Ryū (#440)

Este gate genera capturas reproducibles del vertical nocturno de Ryū ya integrado en `main`. Su objetivo es convertir el pendiente visual de #440 en material comparable para revisión, sin añadir otra implementación ni tocar el selector onírico.

La evidencia **no sustituye** el playtest visual humano exigido por #398/#181. Un artifact verde demuestra que Godot pudo construir y renderizar los estados pactados; no demuestra por sí solo que el encuadre, la lectura o la sensación sean buenos.

## Qué produce

El workflow `Evidencia Ryū 440` monta un `Espacio3D` real de sueño, inserta `SuenoRyu` con la misma escala `0.48` del controller nocturno y usa una cámara sin HUD a altura de jugador. Publica:

- `normal_inicial.png`: estado inicial, tres compuertas opuestas al objetivo y lluvia completa;
- `normal_resuelto.png`: mismo encuadre tras accionar las tres compuertas mediante `Interactuable3D.interactuar()`, con puente y ojo/luminaria reaccionados;
- `reducido_resuelto.png`: misma solución con `reduccion_movimiento`, menos lluvia y transición ya asentada;
- `manifest.json`: forma, FOV, altura de cámara, escala, ancla, estado de compuertas, número de gotas y estado de resolución de cada captura.

## Qué revisar a mano

Comparar las tres imágenes en el mismo artifact y comprobar:

1. la silueta del dragón se reconoce sin texto y no se confunde con el cauce;
2. compuertas, guías y continuidad del agua se entienden sin HUD;
3. en el estado resuelto se perciben el ascenso del cauce y la reacción espacial de puente/luminaria;
4. la reducción de movimiento conserva la misma solución y lectura, reduciendo densidad/movimiento sin vaciar la escena;
5. desde el encuadre de jugador la criatura no tapa de forma dominante la ruta ni convierte su cuerpo en plataforma necesaria.

Si una captura falla cualquiera de esos puntos, #440 sigue abierta con un fallo visual concreto que ya puede corregirse sin reabrir el framework.

## Ejecución local

Con Godot disponible según `.godot-version`:

```bash
godot4 --headless --editor --path godot --quit
mkdir -p evidencia-ryu-440
xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
  --script res://pruebas/capturar_ryu_440.gd -- \
  "$PWD/evidencia-ryu-440"
```

Las imágenes son evidencia de revisión y no se versionan; el workflow las publica como artifact efímero.
