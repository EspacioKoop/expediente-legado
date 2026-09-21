# Playtest #513 · profundidad documental en SIGA-98

Este corte valida el hueco que queda después de #514: los cuatro folios ampliados del `caso@1` ya están en catálogo, pero todavía hay que comprobar en ejecución que se leen y recorren bien en el visor sin convertir la evidencia en una conclusión automática.

## Objetivo

Comprobar que `F-1999-00231`, `MEMO-1999-088`, `EMP-0456` y `ACTA-1999-014` son consultables de principio a fin en el visor de expedientes con el viewport canónico del proyecto (`1920×1080`).

No se evalúa aquí si el jugador acusa a la persona correcta ni se añade una respuesta correcta. El test observa presentación, lectura y descubrimiento de evidencia.

## Preparación

1. Arrancar el proyecto Godot con una partida nueva o una partida en la que `caso@1` siga abierto.
2. Entrar en SIGA-98 y abrir el expediente del cierre contable de 1999.
3. Mantener la ventana en el viewport configurado por `godot/project.godot`: `1920×1080`.
4. No usar herramientas de depuración para marcar pistas como descubiertas antes de abrir los folios.

## Recorrido

### 1. Factura · `F-1999-00231`

- Abrir el folio desde la lista de documentos.
- Verificar que se muestran folio, tipo y fecha en la cabecera.
- Leer hasta el final del cuerpo.
- Confirmar que el texto no expande la ventana ni queda recortado fuera del panel.
- Confirmar que el cuerpo puede desplazarse cuando excede el área visible.
- Localizar la mención a que el concepto no identifica qué trabajo se entregó.

### 2. Memorándum · `MEMO-1999-088`

- Abrir el folio y recorrerlo completo.
- Localizar literalmente `sin revisión previa` y comprobar que sigue funcionando como frase gatillo.
- Llegar a la nota del peritaje de tinta.
- Confirmar que esa nota se presenta como evidencia del expediente y no como identificación del receptor del dinero.

### 3. Ficha · `EMP-0456`

- Abrir el folio y recorrerlo completo.
- Localizar `cuatro días después del cierre de caja` y comprobar que la frase gatillo sigue siendo interactuable.
- Llegar a la referencia de cotejo con el memorándum.
- Confirmar que la ficha no presenta el peritaje como una comprobación independiente.

### 4. Acta · `ACTA-1999-014`

- Abrir el folio y recorrerlo completo.
- Confirmar que se entiende la contradicción documental entre `sin revisión previa` y el acta que declara revisión.
- Confirmar que el intervalo de cinco minutos queda presentado como motivo para cuestionar el alcance, no como prueba automática de negligencia o dolo.

## Comprobaciones cruzadas

Después de leer los cuatro folios:

- Cambiar varias veces entre documentos y confirmar que ninguno queda inaccesible por longitud.
- Comprobar que releer un folio ya leído conserva el comportamiento económico actual de SIGA-98 y no consume una lectura nueva por el mero hecho de tener más texto.
- Comprobar que descubrir una frase gatillo sigue guardando la pista y que el texto ampliado no rompe el enlace interactivo.
- Comprobar que las conclusiones que requieren relacionar dos registros siguen dependiendo del sistema de relación; el texto ampliado no debe desbloquearlas por sí solo.

## Registrar evidencia reproducible

Durante el recorrido puede usarse el registrador específico del gate:

```bash
python3 scripts/registrar_playtest_513.py --salida docs/playtests/playtest-513.md
```

El registrador fija en el informe:

- build SHA, plataforma, fecha y viewport `1920×1080`;
- estado individual de cabecera, lectura completa, recorte y desplazamiento para los cuatro folios;
- conservación de las dos frases gatillo;
- carácter no concluyente del peritaje y del intervalo de cinco minutos;
- relectura sin coste adicional y relaciones documentales no automáticas;
- una ruta o URL de captura obligatoria por cada uno de los cuatro folios;
- notas por folio cuando haga falta documentar una incidencia.

El resumen `listo para valorar cierre de #513` solo queda en **SÍ** cuando están presentes exactamente los cuatro folios esperados, todos los checks están marcados como cumplidos y cada folio aporta evidencia visual. El script no interpreta la narrativa ni sustituye el playtest humano: convierte su resultado en evidencia trazable y revisable.

## Criterio de salida

El corte puede considerarse validado cuando los cuatro documentos se leen completos en `1920×1080`, cada folio queda respaldado por una captura, las dos frases gatillo existentes siguen funcionando y el contenido añadido no produce una conclusión automática ni altera el coste de lectura.

Si aparece un fallo visual, registrar al menos: folio, resolución, posición aproximada del scroll y una captura. Si aparece un fallo de lógica, abrirlo separado del contenido editorial para no mezclar texto, economía de jornada y descubrimiento de pistas en el mismo parche.
