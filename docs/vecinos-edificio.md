# Vecinos, portal y rutinas del edificio

Segundo corte ejecutable de #673 dentro de la expansión de vida cotidiana de #669. El contrato standalone de #739 sigue siendo la única fuente de calendario y estado; este corte lo materializa en el `trayecto` real mediante un controller hijo de `dia.tscn`.

## Roster inicial

`VecinosEdificio` define cuatro presencias pequeñas y reconocibles, todas derivadas de `jornada.dia` durante `trayecto`:

- **Manuela, 3º B** aparece en el portal y alterna entre sacudir el felpudo y regar una maceta.
- **2º A** no necesita NPC: el televisor alterna tertulia baja y partido lejano.
- **4º A** se reconoce por pasos en la escalera, con dos ritmos distintos.
- **Repartidor confundido** visita los buzones cada cuatro días; en una visita consulta porteros y en la siguiente deja un paquete para 4º A en el lugar equivocado.

Los patrones usan `inicio + periodo`; no hay azar. Repetir el mismo día y estado produce exactamente las mismas presencias y variantes.

## Materialización física

`VecinosEdificio3D` consume el contrato sin duplicarlo:

- Manuela y el repartidor usan figuras procedurales ligeras junto al portal;
- el televisor del 2º A deja un brillo de ventana distinto según el estado;
- los pasos del 4º A dejan una huella visual ambiental en el acceso;
- felpudo, tablón, luz y puerta del 2º A se derivan de `estado_portal()`;
- `dia_vecinos_edificio_app.gd` solo monta la capa durante `trayecto` y respeta `reduccion_movimiento`.

La presentación no añade colisiones de bloqueo a los vecinos ni navegación de NPC. Son presencias de baja complejidad, no un sistema social.

## Paquete equivocado

La segunda aparición del repartidor ofrece `paquete_equivocado_4a`, una interacción explícitamente **sin diálogo**. El paquete físico es un `Interactuable3D` con verbo `COGER`, por lo que teclado y mando reutilizan la acción semántica común.

Resolverlo:

1. llama a `VecinosEdificio.resolver_interaccion()`;
2. persiste únicamente `vecinos_edificio_resueltos`;
3. guarda mediante el flujo existente de `Dia`;
4. retira el paquete del suelo y deja una representación pequeña junto al buzón de 4º A;
5. no concede dinero, acción, afinidad, reputación ni progreso obligatorio.

La acción mantiene `correo_postal="buzon_portal"` para compartir la misma superficie conceptual de #672 sin llamar a `CorreoPostal.recoger()` ni crear una segunda bandeja.

## Accesibilidad y movimiento

Con reducción de movimiento las presencias visibles conservan identidad y estado pero su gesto pasa a `estatico`. La capa 3D no consulta teclas físicas y no introduce una acción nueva: el único objeto manipulable usa `Interactuable3D`.

La información ambiental no depende de una animación continua. Los cambios de jornada quedan visibles de forma estática en felpudo, tablón, puerta, luz y presencias.

## Límites deliberados

Este corte no añade afinidad, reputación, romance, economía, quests, diálogo largo ni reloj paralelo. Tampoco convierte los sonidos declarativos del contrato en audio nuevo: los ids siguen disponibles como metadatos para una pasada auditiva posterior con el mixer común.

Queda pendiente para cierre de #673:

- pase humano del recorrido con teclado y mando;
- comprobar legibilidad/escala de Manuela, repartidor, tablón y paquete desde la cámara real;
- decidir si los dos estados sonoros necesitan audio 3D propio o si la lectura visual basta;
- ajustar arte final si la composición procedural invade el portal o la señalética de #277.

## Pruebas

- `godot/pruebas/pruebas_vecinos_edificio.gd`: contrato declarativo original.
- `godot/pruebas/pruebas_vecinos_edificio_3d.gd`: montaje físico, accesibilidad y paquete idempotente.
- `scripts/test_vecinos_edificio.py`: regresión del contrato.
- `scripts/test_vecinos_edificio_3d.py`: wiring en `dia.tscn`, ausencia de sistemas paralelos y smoke headless.

Refs #96 #181 #277 #442 #669 #672 #673 #739.

— Odiseo (GPT-5.6 Sol)
