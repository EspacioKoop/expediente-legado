# Baseline de balance del Juicio por Combate (#912)

Este documento fija el **punto de partida cuantitativo** antes del playtest físico. No sustituye jugar los siete escenarios: sirve para detectar qué combinaciones merecen observación prioritaria y para impedir que futuros cambios muevan silenciosamente los extremos conocidos.

La fuente ejecutable es `godot/pruebas/playtest_juicio_912.gd`. El harness lee directamente las constantes de `JuicioCombate3D` y los seis rituales declarados por `JuicioSimbolico`; no mantiene una segunda copia de los valores de producción.

## Matriz actual

| Escenario | Determinación efectiva | Radio | Velocidad rival | DPS ligero bruto | DPS fuerte bruto | Rasgo cuantitativo a observar |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Base | 8 | 5,00 | 2,50 | 3,57 | 3,45 | Ligero y fuerte quedan a ~3,6 % de distancia en rendimiento bruto; alcance y timing deben diferenciarlos. |
| Luna + Minotauro | 8 | 4,15 | 2,15 | 3,57 | 3,45 | Arena al 83 % del radio base y persecución al 86 %: comprobar si ambos efectos se compensan o aprietan demasiado la cámara. |
| Justicia + Duat | 8 | 5,00 | 2,50 | 3,57 | 3,45 | Una esquiva válida arma `CONTRA +1`; medir cuántas veces se convierte realmente en decisión ofensiva. |
| Fuerza + Aquiles | 8 | 5,00 | 2,50 | 3,57 | 3,66 | El fuerte gana ~6,1 % de rendimiento frente al fuerte base pese a subir su recuperación a 0,82 s. |
| Sol + Māui | 8 | 5,00 | 2,50 | 3,57 | 3,45* | La recarga fuerte (0,58 s) cabe de sobra dentro del ciclo rival mínimo (~1,60 s); un jugador disciplinado puede intentar reservar fuerte para cada telegrafiado. |
| Colgado + Anansi | 8 | 5,00 | 2,50→1,13 | 3,57 | 3,45 | El enredo dura 1,10 s, equivalente a 3,93 recargas ligeras: con impactos continuos puede mantenerse sin hueco. |
| Muerte + Hidra | 10 | 5,00 | 2,50 | 3,57 | 3,45 | El retorno único añade 2 puntos: +25 % de determinación efectiva frente a base. |

`*` El DPS fuerte de la tabla no incorpora el +1 específico de una interrupción solar porque no está activo en todos los golpes fuertes.

## Lecturas iniciales, no cambios de balance

No se modifica ningún valor en este corte. La matriz señala dos escenarios prioritarios para el playtest manual:

1. **Robo del Sol**: comprobar si reservar el fuerte permite cancelar prácticamente toda la presión rival. Si ocurre, medir antes de tocar daño o recargas: el coste real puede estar en posicionamiento y oportunidad perdida de atacar.
2. **Nudo suspendido**: comprobar si una cadena de ligeros convierte el 45 % de velocidad rival en estado casi permanente. Hay que distinguir entre control intencional y bloqueo trivial de persecución.

También deben observarse Luna + Minotauro por cámara/espacio y Justicia + Duat por frecuencia real de contraataques. Aquiles e Hidra quedan como referencias útiles: actualmente representan, respectivamente, una mejora ofensiva moderada (~6,1 % de throughput fuerte) y una extensión de resistencia acotada (+25 %).

## Runner de sesiones manuales

`playtest_juicio_sesion_912.gd` instancia una subclase exclusiva de pruebas que hereda `JuicioCombate3D`. La subclase no se usa desde la Ventanilla y no escribe en `Partida` ni `Jornada`; únicamente observa eventos del combate real y mantiene contadores en memoria.

Ejemplo:

```bash
godot4 --path godot --script res://pruebas/playtest_juicio_sesion_912.gd -- --escenario=sol-maui
```

Escenarios disponibles:

- `base`
- `luna-minotauro`
- `justicia-duat`
- `fuerza-aquiles`
- `sol-maui`
- `colgado-anansi`
- `muerte-hidra`

Para repetir la matriz con accesibilidad dinámica desactivada:

```bash
godot4 --path godot --script res://pruebas/playtest_juicio_sesion_912.gd -- --escenario=base --reduccion-movimiento
```

Al terminar por victoria, derrota o cancelación, el proceso imprime una línea `PLAYTEST_912_JSON=...` con:

- duración de la sesión;
- determinación perdida por el jugador;
- ligeros y fuertes conectados;
- esquivas útiles;
- interrupciones solares;
- contraataques consumidos;
- retornos de Hidra;
- resultado y ritual activo;
- determinación final de ambos contendientes;
- escenario y estado de reducción de movimiento.

El resumen es una copia: herramientas externas pueden transformarlo o agregarlo sin mutar los contadores internos del combate de prueba.

## Qué falta para cerrar #912

El baseline y el runner cubren la preparación reproducible, pero **no autorizan por sí solos ajustes numéricos ni el cierre del issue**. El siguiente paso sigue siendo ejecutar los siete escenarios desde controles reales y comparar las líneas `PLAYTEST_912_JSON` junto a observaciones de cámara, alcance, telegráfico y feedback.

Cualquier cambio posterior de números debe citar esa observación y añadir una regresión que impida volver al extremo que motivó el ajuste.


## Registro humano normalizado

El runner anterior produce telemetría por sesión, pero #912 también exige
conservar observaciones que no se deducen de esos contadores: cámara, alcance,
legibilidad del telegráfico, función percibida de ligero/fuerte/esquiva y si el
ritual cambió una decisión real.

Para reunir ambas capas en un informe único:

```bash
python3 scripts/registrar_playtest_912.py \
  --salida docs/playtests/playtest-912.md
```

El registrador recorre exactamente la misma matriz de siete escenarios y pide
las métricas de cada sesión, evidencia concreta y checks humanos. También exige
la matriz completa con teclado, al menos una muestra con mando físico y una
comprobación específica con reducción de movimiento.

El campo `listo para valorar cierre de #912` es solo un control de completitud:
no compara DPS, no puntúa rituales y no decide qué combinación es mejor. La
conclusión sobre dominancia/inutilidad la introduce explícitamente el tester a
partir del pase real.

La regresión `scripts/test_registrar_playtest_912.py` protege ese límite: un
valor numérico extremo no hace fallar o pasar el gate por sí solo, mientras que
la falta de evidencia, dispositivo o legibilidad sí deja el registro pendiente.
