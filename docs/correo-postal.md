# Correo postal del portal (#672)

El correo postal introduce vida cotidiana de 1998 como una superficie física y periódica del recorrido. No es una bandeja de tareas, una economía nueva ni una lista de misiones.

## Flujo

`dia.tscn` monta `DiaCorreoPostalApp` como controller hijo. Cuando la fase real de `Jornada` es `trayecto`, el controller coloca un `BuzonPostalInteractivo3D` junto al portal de casa. El objeto usa `Interactuable3D`, de modo que hereda la acción semántica común de interacción en vez de introducir una tecla propia.

`CorreoPostal` deriva las piezas disponibles desde `jornada.dia` y estado ya existente. Solo persiste en `jornada.correo_postal.recogidos` la lista de piezas retiradas. No hay contador de urgencia, tareas pendientes, deuda propia ni progreso obligatorio.

Al retirar una pieza, el controller persiste primero Jornada/Inventario y después abre `CorreoPostalLector`. El lector es una `Window` exclusiva y transitoria: muestra remitente, jornada, categoría, asunto y contenido de la pieza que acaba de recogerse. No conserva otra copia del correo ni permite navegar una bandeja histórica.

Si ya no queda nada disponible, la señal `buzon_vacio` abre la misma superficie con un mensaje breve. Consultar un buzón vacío no muta Jornada ni Inventario.

Los textos de interfaz del lector viven en `godot/datos/correo_postal_presentacion.json`; el catálogo narrativo sigue perteneciendo a `CorreoPostal`.

## Catálogo inicial

El sistema incluye ocho categorías distintas:

- publicidad de comercio de barrio;
- factura doméstica informativa;
- catálogo de electrónica;
- circular de la comunidad;
- carta vecinal condicionada por el estado del gato;
- recordatorio de alquiler condicionado al vencimiento no resuelto;
- paquete promocional con un calendario magnético físico;
- comunicación certificada condicionada a haber cerrado al menos un expediente ese día.

Las fechas se derivan del número de jornada. El mismo estado produce el mismo buzón al recargar.

## Fronteras con sistemas existentes

### Economía (#83 / #93)

Recoger una factura o un aviso **no modifica `dinero`**. `CorreoPostal` no llama a `Jornada.gastar()` ni crea crédito, deuda, recargos o una moneda secundaria. El aviso de alquiler desaparece cuando `jornada.alquiler.ultimo_resuelto` indica que el vencimiento ya fue resuelto por la economía canónica.

### Inventario (#97)

Las piezas narrativas no llenan el inventario. Solo una pieza que declara `objeto` intenta materializarlo mediante `Inventario.recoger()`. El paquete del día 4 contiene `postal_iman_calendario`, no vendible y con origen `correo_postal`. Si Inventario rechaza el objeto, la pieza no se marca como recogida.

El lector solo informa de que el objeto fue recogido. No mueve objetos, no vende, no consume y no introduce una segunda fuente de verdad.

### Casa (#96 / #677)

El calendario postal se declara como categoría visual `papel`. La recogida en el portal lo deja en `Inventario.CARRIED`: no aparece mágicamente en casa.

Cuando el jugador usa el almacenamiento doméstico existente, `Inventario.guardar_en_casa()` lo mueve a `HOME_STORAGE`. A partir de ahí `CasaEstadoAmbiental.derivar()` lo incluye en `objetos_casa` y `CasaAcumulacion3D` reconoce únicamente el id real `postal_iman_calendario` para colocarlo sobre la puerta de `NeveraCasa`.

La representación es procedural y ligera: una cartulina fina con cabecera, cuadrícula y pequeño imán, situada unos milímetros delante de la puerta y apartada de las asas. Conserva `objeto_id` y `origen` como metadatos; no crea ningún flag de decoración. Si el objeto sale de `HOME_STORAGE`, el siguiente refresco retira el imán. Si la escena no ofrece `NeveraCasa`, el objeto mantiene el fallback de `papel` en `EstanteriaComprasCasa` en vez de desaparecer.

Así el correo produce un cambio visual específico mediante el contrato de #96/#677 sin introducir estado estético paralelo ni teletransportar el paquete desde el portal.

## Persistencia y accesibilidad

Tras una recogida válida, el controller solicita el guardado del `Dia` **antes** de abrir el lector para evitar duplicados incluso si el juego se cierra desde la lectura.

Durante la lectura el árbol queda pausado y el ratón pasa temporalmente a visible. La ventana usa controles estándar con el botón `Cerrar` enfocado, acepta el flujo normal de teclado y añade el mismo fallback A/B de mando usado por otras `Window` del proyecto; `cancelar`/`ui_cancel` también cierran la lectura. Al cerrar se restaura la captura previa del ratón y se reanuda el árbol.

El buzón no anima puertas ni desplaza cámara, así que no añade movimiento forzado. No hay HUD persistente, indicador de correo pendiente ni obligación de abrirlo.

## Cobertura automatizada

`pruebas_correo_postal.gd` cubre catálogo, variación por jornada/estado, economía delegada, persistencia de recogida, modelo del lector, feedback vacío, paquete físico y el recorrido `carried → home_storage → CasaEstadoAmbiental → CasaAcumulacion3D`.

`pruebas_casa_acumulacion.gd` verifica además que el calendario aparece sobre `NeveraCasa`, no se duplica en la estantería, conserva identidad/procedencia, desaparece al salir de `HOME_STORAGE` y conserva un fallback visible si la nevera no está disponible.

Los wrappers Python verifican las fronteras estáticas de integración y ejecutan ambas verticales en Godot headless dentro del preflight canónico.

## Fuera de este corte

Quedan como validación final los assets definitivos de sobres/paquetes y el playtest humano del flujo completo con teclado, mando y tecnologías de accesibilidad. La lógica automatizada ya cubre el recorrido postal y el cambio visual doméstico, pero #672 no debe cerrarse automáticamente sin esa validación humana.
