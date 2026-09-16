# Vecinos, portal y rutinas del edificio

Primer corte ejecutable de #673 dentro de la expansión de vida cotidiana de #669. Sigue el gate de #181: **standalone first**, con contrato y regresión aislados antes de reservar escenas compartidas.

## Roster inicial

`VecinosEdificio` define cuatro presencias pequeñas y reconocibles, todas derivadas de `jornada.dia` durante `trayecto`:

- **Manuela, 3º B** aparece en el portal y alterna entre sacudir el felpudo y regar una maceta.
- **2º A** no necesita NPC: el televisor alterna tertulia baja y partido lejano.
- **4º A** se reconoce por pasos en la escalera, con dos ritmos distintos.
- **Repartidor confundido** visita los buzones cada cuatro días; en una visita consulta porteros y en la siguiente deja un paquete para 4º A en el lugar equivocado.

Los patrones usan `inicio + periodo`; no hay azar. Repetir el mismo día y estado produce exactamente las mismas presencias y variantes.

## Portal como estado ambiental

`estado_portal()` expone cambios pequeños para una futura capa 3D: posición/estado del felpudo, aviso del tablón, luz estable o con parpadeo, puerta del 2º A cerrada o entornada y los sonidos de presencia activos. Así una ausencia visible sigue contando como vida del edificio.

Con reducción de movimiento las presencias visibles conservan identidad y estado pero su gesto pasa a `estatico`. El audio ambiental permanece disponible como señal alternativa. Este contrato no consulta teclas físicas ni decide controles; el futuro montaje debe pasar por acciones semánticas/`Interactuable3D` para conservar teclado y mando.

## Paquete equivocado

La segunda aparición del repartidor ofrece `paquete_equivocado_4a`, una interacción explícitamente **sin diálogo**: coger el paquete del suelo y dejarlo en el buzón de 4º A. Es idempotente durante el día y solo persiste la clave local `vecinos_edificio_resueltos`.

No concede dinero, acción extra, afinidad, reputación ni progreso obligatorio. El resultado declara `bloquea_campana=false`; ignorarlo deja intacto el recorrido principal.

La acción declara `correo_postal="buzon_portal"` para reutilizar la misma ancla física introducida por #672. No llama a `CorreoPostal.recoger()` ni crea un segundo inventario de correspondencia: el paquete es un gesto ambiental puntual, no correo del protagonista.

## Integraciones previstas

- **#672**: compartir buzones/ancla visual; las cartas y paquetes del protagonista siguen perteneciendo a `CorreoPostal`.
- **#96**: un montaje posterior puede reflejar felpudo, luz o puerta mediante el estado ambiental de casa/edificio, sin duplicar inventario ni flags domésticos.
- **#442**: ninguna presencia vecinal activa semillas oníricas. Solo un objeto cultural concreto y una interacción deliberada podrían hacerlo en otro corte.
- **#669/#181**: este PR no desplaza gates P0 ni abre un sistema social global.

## Límites deliberados

Este corte no modifica `godot/escenas/dia.tscn`, `godot/datos/textos.csv`, economía, inventario, afinidad, romance ni reputación. Tampoco añade navegación de NPC, diálogo largo, misiones o assets finales.

El objetivo es dejar cerrada y comprobable la lógica que luego podrá montar un controller hijo en `dia.tscn` cuando esa ruta esté libre de reservas activas. Hasta entonces el contrato puede probarse en Godot headless mediante `godot/pruebas/pruebas_vecinos_edificio.gd` y `scripts/test_vecinos_edificio.py`.

## Siguiente corte

Cuando la escena compartida esté libre, el vertical físico puede:

1. montar a Manuela y al repartidor cerca del portal/buzones con geometría ligera;
2. crear emisores 3D para televisor y pasos sin NPC visible;
3. aplicar felpudo, tablón, puerta y luz desde `estado_portal()`;
4. materializar `paquete_equivocado_4a` como `Interactuable3D` con verbo semántico de coger/dejar;
5. validar teclado, mando y reducción de movimiento en el recorrido real.

Refs #96 #181 #442 #669 #672 #673.

— Odiseo (GPT-5.6 Sol)
