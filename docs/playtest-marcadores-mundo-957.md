# Playtest #957 · marcadores diegéticos en mundo

Este gate valida el cierre humano pendiente de #957 sobre una build real. La
implementación ya cubre persistencia por zona, cinco tipos de marca, límite de
cinco por zona, colocación y borrado desde el mundo, restauración tras carga,
variación por estrés y ausencia de colisiones. El objetivo de este pase no es
añadir otra mecánica: es comprobar legibilidad, utilidad y coherencia visual sin
convertir los marcadores en un HUD obligatorio.

## Preparación

1. Usar una build identificable por SHA.
2. Entrar mediante el flujo normal del juego, sin consola ni atajos de prueba.
3. Probar al menos dos zonas jugables distintas.
4. En una de ellas, guardar, salir completamente del juego y volver a cargar.
5. Probar con el tratamiento visual normal del juego; no desactivar postprocesado
   ni sustituir materiales para facilitar la lectura.
6. Registrar capturas de al menos una marca sobre suelo y otra sobre pared.

## Recorrido mínimo

Durante el pase:

- colocar al menos una marca de tiza o carbón en suelo;
- colocar al menos una cinta o nota con texto breve en pared;
- colocar un objeto marcador;
- comprobar que los tipos se distinguen por forma, no solo por color;
- acercarse y alejarse para valorar si ayudan a recordar sin comportarse como
  iconos flotantes ni texto legible desde toda la sala;
- llenar una zona hasta cinco marcas y comprobar que la sexta se rechaza;
- borrar una marca apuntándola y comprobar que no deja bloqueo, colisión ni
  residuo interactivo;
- limpiar una zona completa y comprobar que la otra zona conserva sus marcas;
- guardar, cerrar el juego, reabrir y verificar que posición, tipo, color y texto
  de las marcas supervivientes se conservan;
- atravesar y rodear las marcas para confirmar que nunca bloquean navegación;
- completar un tramo jugable ignorando por completo los marcadores para confirmar
  que no son requisito de progresión;
- observar al menos una marca con estrés alto y confirmar que la distorsión sigue
  siendo reconocible y no parece un error de colocación;
- si el pase alcanza un sueño, comprobar que el tratamiento no rompe la lectura
  de la escena. No se exige crear marcas exclusivas de sueño porque esa opción no
  está expuesta al jugador en este corte.

## Criterios visuales

El pase debe responder explícitamente a estas preguntas:

- ¿la tiza/carbón parece aplicada a una superficie y no un icono 3D?
- ¿cinta y nota parecen utilería física del entorno?
- ¿el texto breve se lee al acercarse sin dominar la habitación a distancia?
- ¿los colores siguen siendo distinguibles bajo iluminación real sin depender de
  saturación moderna?
- ¿el tratamiento encaja con el look PSX/noventero y con el dithering/ruido del
  resto del juego?
- ¿cinco marcas en una zona siguen siendo visualmente manejables?
- ¿alguna marca tapa pistas, puertas, texto ambiental o elementos críticos?

Una respuesta negativa mantiene el gate pendiente y debe convertirse en una
incidencia reproducible con zona, tipo de marca, posición aproximada y captura.

## Registro asistido

Puede generarse un informe Markdown homogéneo con:

```bash
python3 scripts/registrar_playtest_957.py \
  --salida docs/playtests/playtest-957.md
```

El registrador resume únicamente respuestas humanas. Marca
`listo para valorar cierre de #957` cuando:

- se probaron al menos dos zonas y se identificaron en el registro;
- se cubrieron suelo y pared;
- se adjuntó o referenció evidencia trazable (capturas, vídeo o logs);
- se distinguieron tipos sin depender solo del color;
- el texto fue local y no invasivo;
- cinco marcas siguieron siendo legibles;
- el límite, borrado y limpieza funcionaron como se esperaba;
- persistió el estado tras cerrar y reabrir;
- no hubo colisiones ni bloqueo de navegación;
- ignorar el sistema no bloqueó progresión;
- el estrés no volvió irreconocibles las marcas;
- no se tapó información crítica;
- la estética se consideró coherente con el tratamiento visual del juego.

## Qué no valida este script

- No ejecuta Godot.
- No analiza capturas ni vídeo.
- No decide por sí mismo si algo «parece PSX».
- No convierte CI o pruebas headless en aprobación humana.
- No cierra #957 automáticamente.
- No oculta un fallo: cualquier criterio negativo deja el gate pendiente.

La regresión automatizada de `pruebas_marcadores_mundo_957.gd` sigue cubriendo
persistencia estructural, límites, JSON-safe, ausencia de colisiones, restauración
y copy. Este playtest cubre únicamente lo que requiere percepción y recorrido
humano.

Refs #957 #281 #309 #952.
