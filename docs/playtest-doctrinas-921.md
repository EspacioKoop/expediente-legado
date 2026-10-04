# Playtest humano de doctrinas ideológicas · #921

Este protocolo valida **lectura, utilidad, coste y frecuencia de uso** de las cuatro doctrinas ya implementadas. No cambia balance ni declara una doctrina “correcta”. El gate es humano: CI puede comprobar que el registro está completo, pero no decidir si la experiencia resulta clara o equilibrada.

## Datos obligatorios de la sesión

Registrar antes de jugar:

- fecha;
- commit/SHA o identificador exacto de build;
- plataforma y resolución;
- dispositivo de entrada: teclado/ratón o mando;
- estado de `reduccion_movimiento`;
- persona que prueba;
- incidencia conocida que pueda sesgar la sesión.

No mezclar resultados de dos builds distintas en la misma ficha.

## Doctrinas a comparar

| Doctrina | Función esperada | Riesgo de regresión a vigilar |
| --- | --- | --- |
| Asamblea | convertir presión/choque en iniciativa favorable | que se perciba como bonus pasivo o solución universal |
| Mesa de diálogo | neutralizar/interrumpir y recuperar distancia | que equivalga a daño gratis o a una pausa sin coste |
| Comisión de seguimiento | ampliar lectura/telegraph de la siguiente intención | que la información llegue tarde o no se distinga del HUD base |
| Externalizar | apuesta explícita de riesgo/recompensa | que sólo aumente recompensa y oculte el coste al fallar |

El combate **sin doctrina** es el control: debe seguir siendo viable y legible.

## Matriz mínima

Completar todos los casos siguientes. Cada fila es una observación independiente.

| Caso | Doctrina | Ritual | Reducción de movimiento | Entrada |
| --- | --- | --- | --- | --- |
| A0 | ninguna | ninguno | no | teclado/ratón |
| A1 | Asamblea | ninguno | no | teclado/ratón |
| A2 | Mesa de diálogo | ninguno | no | teclado/ratón |
| A3 | Comisión de seguimiento | ninguno | no | teclado/ratón |
| A4 | Externalizar | ninguno | no | teclado/ratón |
| R1 | una doctrina compatible | ritual con tag compartido de #1115 | no | teclado/ratón |
| R2 | otra doctrina | segundo ritual/tag distinto de #1115 | no | teclado/ratón |
| M1 | doctrina a elección | cualquiera de los casos anteriores | sí | teclado/ratón |
| G1 | doctrina a elección | ninguno o R1/R2 | no | mando físico, cuando esté disponible |

R1 y R2 deben usar **dos cruces doctrina + ritual realmente soportados por tags en la build**. No inventar combinaciones manuales para cumplir la tabla.

Si no hay mando disponible, G1 queda explícitamente como `NO EJECUTADO · falta hardware`; no se convierte en PASS.

## Qué registrar en cada caso

Usar una escala breve de 1–5 cuando proceda y acompañarla de una frase observable.

1. **Comprensión** — ¿se entendió qué cambió al activar la doctrina?
2. **Decisión táctica** — ¿hubo que elegir cuándo usarla o se pulsó de forma automática?
3. **Coste/ventana** — ¿el coste, exposición o oportunidad perdida fue visible?
4. **Utilidad** — ¿cambió una decisión del combate sin resolverlo por sí sola?
5. **Frecuencia** — número de usos, intentos y cargas disponibles.
6. **Dominancia** — ¿pareció claramente mejor que las otras en situaciones comparables?
7. **Feedback** — ¿animación, sonido, espacio y HUD contaron la misma historia?
8. **Incidencias** — pasos exactos, resultado esperado, resultado observado y si se reproduce.

Además, anotar el resultado del combate **sólo como contexto**. Ganar no convierte automáticamente una doctrina en buena y perder no la convierte en mala.

## Procedimiento

1. Arrancar desde un estado reproducible con las cargas necesarias para el caso.
2. Confirmar que el combate base funciona antes de activar doctrina o ritual.
3. Ejecutar el caso sin cambiar deliberadamente otros parámetros.
4. Registrar la valoración inmediatamente después del encuentro.
5. Repetir una vez cualquier caso con resultado sorprendente antes de clasificarlo como incidencia.
6. Para R1/R2, anotar el tag común que explica la interacción; no basta con escribir el nombre del ritual.
7. Para M1, comparar la misma información táctica con `reduccion_movimiento=false` y `true`.
8. Para G1, comprobar navegación, activación y lectura con mando físico; no sustituirlo por emulación de teclado.
9. Guardar el SHA/build junto al registro final.

## Preguntas de cierre

Responder para cada doctrina:

- ¿qué situación hace que quiera usarla?
- ¿qué situación hace que prefiera guardarla?
- ¿qué coste percibo al usarla?
- ¿qué señal me confirma que funcionó?
- ¿qué alternativa tenía si no disponía de carga?
- ¿la elegiría siempre frente a las otras? Si sí, describir por qué.

Responder también:

- ¿el combate base sigue completo sin cargas?
- ¿algún cruce con ritual parece duplicar el mismo efecto?
- ¿alguna doctrina castiga o premia una ideología por etiqueta en vez de por decisión táctica?
- ¿la reducción de movimiento conserva la misma información necesaria para decidir?
- ¿hay una doctrina que monopoliza la frecuencia de uso?

## Criterio de evaluación

El playtest puede considerarse **completo** cuando:

- A0–A4, R1, R2 y M1 tienen respuestas humanas completas;
- G1 está completo o marcado explícitamente como pendiente por falta de mando;
- cada doctrina tiene al menos una observación sobre utilidad, coste y frecuencia;
- los dos cruces rituales identifican su tag común;
- cualquier dominancia aparente tiene un ejemplo reproducible;
- cualquier pérdida de información con `reduccion_movimiento` tiene pasos de reproducción;
- el SHA/build está registrado.

El protocolo **no autoriza automáticamente cambios numéricos**. Si aparece dominancia, ambigüedad o un coste ilegible, abrir un issue pequeño con el caso reproducible antes de tocar balance.

## Plantilla de observación

```text
Caso:
Build/SHA:
Entrada:
Reducción de movimiento:
Doctrina:
Ritual / tag:

Comprensión (1-5):
Decisión táctica (1-5):
Coste/ventana (1-5):
Utilidad (1-5):
Usos / intentos / cargas:
¿Dominante?:
Feedback:
Resultado del combate:
Incidencias / pasos:
Comentario libre:
```

## Resultado final de la sesión

Cerrar con tres apartados:

- **Conservar**: comportamientos que ya comunican bien su función.
- **Investigar**: casos dudosos que necesitan repetición.
- **Abrir issue**: problemas reproducibles de lectura, coste, input, ritual o dominancia.

No escribir `PASS` si faltan respuestas humanas de la matriz obligatoria.
