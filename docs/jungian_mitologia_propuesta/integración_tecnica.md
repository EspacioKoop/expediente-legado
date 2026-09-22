# Integración técnica jungiana / mitológica

Este documento describe el contrato técnico introducido por #1172 y conectado al juego real por #1174.

## Autoloads

`project.godot` registra cuatro servicios:

- `GestorArquetipos`: insight, desbloqueos, puntos de habilidad y efectos activos.
- `GestorMomentum`: medidor de momentum, pérdida al recibir daño y consumo por finisher.
- `GestorCombos`: buffer de entradas, requisitos de combos y catálogo de finishers.
- `GestorLiteratura`: puente de obras conocidas hacia insight/momentum sin duplicar recompensas.

Los paths son relativos a la raíz del proyecto Godot (`res://`), no a la raíz del repositorio.

## Arquetipos e insight

`GestorArquetipos.ganar_insight(cantidad)` es el punto de entrada para progreso. Al cruzar el umbral de un arquetipo:

1. el desbloqueo es idempotente;
2. se suma un punto de habilidad;
3. se emite `arquetipo_desbloqueado(id)`;
4. se emite `puntos_habilidad_cambiados(total)`.

`efectos_combinados()` reduce los efectos de todos los arquetipos desbloqueados a un diccionario consumible por combate.

Integración actual en `JuicioCombate3D`:

| Efecto | Uso |
| --- | --- |
| `bonus_crit` | probabilidad adicional de crítico; el crítico añade daño y mejora la ganancia de momentum |
| `curacion` | curación fraccional acumulada por impactos válidos |
| `evasion` | amplía la ventana de esquiva |
| `bonus_todo` | contribuye a crítico, curación y evasión |
| modificadores por arquetipo | Sombra mejora ganancia de momentum, Anima reduce decay y Self amplía el máximo |

El HUD del combate escucha `arquetipo_desbloqueado` y muestra una notificación con el total de puntos de habilidad.

## Momentum

Umbrales canónicos:

- finisher normal: 75;
- super finisher: 100.

`registrar_golpe()` aumenta momentum y conserva un pequeño multiplicador de combo. `registrar_dano_recibido()` resta momentum y rompe el combo. El medidor decae tras una breve ventana sin impacto.

El HUD real de `JuicioCombate3D` contiene una `ProgressBar` de momentum y un botón de finisher. El botón solo se habilita cuando `GestorCombos.finisher_disponible_actual()` devuelve un finisher cuyo arquetipo está desbloqueado y cuyo coste puede pagarse.

## Combos y finishers

El combate registra entradas semánticas, no teclas físicas:

- `ataque_ligero`;
- `ataque_pesado`;
- `esquivar`.

`GestorCombos` compara los últimos eventos del buffer contra secuencias declaradas y valida momentum + arquetipo. Al resolver un combo emite `combo_ejecutado(nombre, efectos)`.

`JuicioCombate3D` consume esos efectos sobre su rival real:

- daño adicional o multiplicado;
- curación;
- contraataque;
- evasión temporal;
- radio visual para efectos de área.

La arena actual tiene un único rival, por lo que el componente de área se representa visualmente alrededor del objetivo y queda preparado para una futura arena multiobjetivo sin inventar un segundo sistema de daño.

Los finishers se ejecutan mediante `GestorCombos.ejecutar_finisher(id)`. El gestor de combos valida el arquetipo; el gestor de momentum valida y consume el coste.

## Feedback de finisher

Al ejecutar un finisher, `JuicioCombate3D` aplica:

- reacción física del rival;
- partículas `CPUParticles3D`;
- sacudida breve de cámara;
- sonido de énfasis mediante `Sonido`;
- aviso textual de FINISHER / SUPER FINISHER.

`reduccion_movimiento` sigue respetándose: con reducción de movimiento activa no se fuerza la sacudida de cámara.

## Escena de prueba

`res://test_jungian/test_jungian.tscn` crea una instancia de `JuicioCombate3D` con un rival mínimo y desbloquea los arquetipos mediante insight. Sirve para validar manualmente HUD, combos y finishers sobre la misma implementación usada por el juego.

## Pruebas automáticas

`res://pruebas/pruebas_jungian.gd` forma parte de `pruebas/pruebas.gd` y cubre:

- umbrales de insight;
- idempotencia implícita de desbloqueos y acumulación de puntos;
- agregación de efectos;
- ganancia y pérdida de momentum;
- detección de `Golpe de la Sombra`;
- disponibilidad y consumo de un finisher.

Estas pruebas se ejecutan en el gate canónico de `scripts/verificar_godot.py`.

## Ciclo de vida

Al comenzar un `JuicioCombate3D` se reinician momentum y buffer de combos, se reaplican los modificadores de los arquetipos ya desbloqueados y se abre el combate. Al terminar se cierra momentum y se limpia el buffer.

El progreso de insight/arquetipos no se reinicia al entrar o salir del combate.
