# Playtest #666 · Mensajería interna OS98

El modelo y la UI del chat corporativo están integrados. Este pase valida el último tramo que CI no puede certificar: foco, lectura, teclado/mando, reducción de movimiento y el canal temporal alimentado por un evento real de Jornada.

## Preparación

1. Usar una build identificable por SHA.
2. Ejecutar a `1920×1080`.
3. Probar teclado real y mando físico.
4. Repetir el recorrido con reducción de movimiento activada.
5. No inyectar `impresora_atascada` por consola ni fixture para el gate final.

## Recorrido

### Apertura y presencia

- Encontrar **Mensajería interna** desde las superficies normales de OS98.
- Abrirla y comprobar foco inicial.
- Confirmar que canal, nicks y estados de presencia son legibles.

### Canales y navegación

- Cambiar entre varios canales con teclado.
- Repetir con mando físico.
- Entrar y volver sin dejar foco atrapado.
- Recorrer historial suficiente para comprobar escala y lectura.

### Respuestas cerradas

- Elegir una respuesta disponible.
- Confirmar que no existe campo de texto libre.
- Cerrar y volver a abrir la aplicación: la respuesta debe persistir para la misma partida.
- En otra vuelta del recorrido, ignorar por completo el chat y comprobar que la campaña sigue avanzando.

### Incidencia de impresora

Este punto distingue el fixture ya cubierto por tests del comportamiento real que aún falta validar.

- Provocar/alcanzar una Jornada que publique el evento real `impresora_atascada`.
- Confirmar que antes del evento no existe el canal temporal.
- Tras el evento, abrir Mensajería interna y verificar que aparece `#inc-impresora`.
- Comprobar que los mensajes se distinguen del resto y que la incidencia no escribe progreso paralelo.

Si la build no tiene ninguna ruta real capaz de producir `impresora_atascada`, marcar **NO** en `evento_real`. Ese resultado identifica un hueco técnico concreto para el siguiente corte; no debe sustituirse con el fixture de la suite.

## Registro asistido

```bash
python3 scripts/registrar_playtest_666.py \
  --salida docs/playtests/playtest-666.md
```

El informe solo queda listo para valorar cierre cuando los cuatro escenarios tienen evidencia, se han probado ambos dispositivos, reducción de movimiento y el canal temporal procede de una Jornada real.

## Criterio de salida

Un FAIL debe registrar build, dispositivo, pasos y evidencia. Si el único FAIL es `evento_real`, el siguiente PR debe conectar un productor diegético real de esa incidencia al `jornada.eventos` ya consumido por el chat, sin crear otro bus de eventos ni ampliar el protocolo del chat.
