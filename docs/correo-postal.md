# Correo postal del portal (#672)

Primer corte funcional de la vida cotidiana de 1998. El correo es una superficie física y periódica del recorrido, no una bandeja de tareas ni una economía nueva.

## Flujo

`dia.tscn` monta `DiaCorreoPostalApp` como controller hijo. Cuando la fase real de `Jornada` es `trayecto`, el controller coloca un `BuzonPostalInteractivo3D` junto al portal de casa. El objeto usa `Interactuable3D`, de modo que hereda la acción semántica común de interacción en vez de introducir una tecla o botón específicos.

`CorreoPostal` deriva las piezas disponibles desde `jornada.dia` y estado ya existente. Solo persiste en `jornada.correo_postal.recogidos` la lista de piezas retiradas. No hay contador de urgencia, tareas pendientes, deuda propia ni progreso obligatorio.

## Catálogo inicial

El corte incluye ocho categorías distintas:

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

Las piezas narrativas no llenan el inventario. Solo una pieza que declara `objeto` intenta materializarlo mediante `Inventario.recoger()`. En este corte, el paquete del día 4 contiene `postal_iman_calendario`, no vendible y con origen `correo_postal`. Si Inventario rechaza el objeto, la pieza no se marca como recogida.

### Casa (#96)

El calendario queda disponible como objeto físico del inventario y puede entrar en el flujo doméstico existente. Este PR no añade todavía su representación específica pegada a la nevera ni un cambio visual permanente de la casa; ese es el siguiente enlace natural con #96.

## Persistencia y accesibilidad

Tras una recogida válida, el controller solicita el guardado del `Dia` antes de abandonar el portal para evitar duplicados al recargar. El buzón no anima puertas ni desplaza cámara, así que no añade movimiento forzado. La interacción pasa por `Interactuable3D`; no se hardcodean `E`, Escape ni botones de mando.

## Fuera de este corte

Quedan para cortes posteriores la presentación completa del contenido (carta/visor diegético), feedback específico de buzón vacío, assets finales de sobre/paquete, representación visual del objeto doméstico en #96 y validación humana con teclado/mando. Por eso este corte debe enlazar el issue con `Refs #672`, no cerrarlo.
