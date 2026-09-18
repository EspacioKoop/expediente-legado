# Playtest físico de mando · Bolos de pasillo (#159)

Este protocolo cubre el último gate de #159 que CI no puede demostrar: que el minijuego de bolos se controla correctamente con un **mando físico real** y no solo con el mapa de entrada simulado.

La regresión automática ya comprueba el contrato de acciones compartido con #98/#770: stick izquierdo y cruceta para `mover_izquierda`/`mover_derecha`, botón principal para `interactuar` y botón secundario para `cancelar`. Este pase evalúa detección real, tacto, deadzone y ausencia de bloqueos.

## Preparación

Usar una build que contenga #1000 y el PR de este protocolo. Registrar:

- `build_sha` de `BUILD-INFO.txt`;
- plataforma;
- modelo de mando tal como lo identifica el sistema/juego;
- familia aproximada: Xbox, PlayStation, Nintendo u otro;
- conexión: cable, Bluetooth u otra;
- si se usan controles por defecto o un remapeo guardado.

Durante el pase no usar teclado ni ratón salvo para recuperar una incidencia ya detectada. Si hace falta tocarlos para completar el flujo, el gate no pasa.

## Pase

1. Conectar el mando antes de abrir la actividad y confirmar que el juego lo detecta.
2. En un día elegible, entrar en los bolos usando solo el mando.
3. Sin tocar el stick, observar unos segundos: el apuntado no debe derivar por sí solo.
4. Mover el apuntado a izquierda y derecha con el **stick izquierdo**.
5. Repetir el movimiento con la **cruceta**.
6. Mantener y soltar el botón principal para cargar potencia y ejecutar el primer lanzamiento.
7. Completar el segundo lanzamiento también con mando y llegar al resultado.
8. Volver a entrar y usar el botón secundario para abandonar.
9. Confirmar que vuelve la oficina y que se puede entrar una tercera vez sin controles clavados.
10. Durante todo el pase, anotar cualquier doble pulsación, deriva, pérdida de foco, acción que requiera teclado/ratón o bloqueo reproducible.

## Checks del facilitador

Marcar únicamente hechos observados:

- el mando físico es detectado;
- se entra en la actividad sin teclado/ratón;
- el stick izquierdo apunta en ambos sentidos;
- la cruceta apunta en ambos sentidos;
- no hay deriva apreciable en reposo;
- mantener/soltar el botón principal carga y lanza;
- se completan dos lanzamientos y aparece resultado;
- el botón secundario abandona;
- abandonar restaura la oficina;
- se puede repetir la actividad con mando;
- no queda ninguna incidencia reproducible que impida completar el flujo.

No exigir una marca concreta ni asumir que las letras impresas coinciden entre familias. El contrato semántico es botón principal/secundario según el mapeo mostrado por el juego.

## Criterio de salida para #159

El gate de mando queda satisfecho cuando todos los checks anteriores pasan en al menos un mando físico real y la evidencia incluye build, plataforma y modelo del dispositivo.

Una preferencia subjetiva sobre sensibilidad no bloquea el cierre si el control es estable y utilizable. Sí lo bloquean, por ejemplo, deriva que impide apuntar, botones invertidos respecto al mapeo activo, imposibilidad de completar dos lanzamientos, incapacidad de abandonar o necesidad de teclado/ratón.

## Registro asistido

```bash
python3 scripts/registrar_playtest_159.py
```

El script no simula hardware ni interpreta el resultado: conserva los datos del pase y resume únicamente los checks introducidos por quien lo ejecuta.

## Qué adjuntar a #159

- build SHA;
- plataforma;
- modelo/familia y conexión del mando;
- controles por defecto o remapeados;
- checks del pase;
- incidencia reproducible, si existe;
- observaciones opcionales.

Refs #159 #98 #770 #113.

— Odiseo (GPT-5.6 Sol)
