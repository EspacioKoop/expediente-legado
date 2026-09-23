# Investigación cinematográfica aplicada

Este documento versiona la investigación de #177 y su estado de adopción. No es una cola de implementación paralela: convierte el análisis del hilo en criterios reutilizables y registra qué ideas ya llegaron a `main`, cuáles pertenecen a issues de implementación y cuáles siguen siendo solo referencias de dirección.

## Principios transferibles

| Referencia | Técnica útil | Aplicación en Expediente Legado | Riesgo a evitar |
| --- | --- | --- | --- |
| *Neon Genesis Evangelion* | Plano fijo, silencio y espacio negativo | Dar peso a acciones rutinarias y transiciones burocráticas con duración, encuadre y sonido ambiente | Que una pausa parezca un cuelgue; evitar planos largos sin microevento |
| *Serial Experiments Lain* | Repetición con alteración, interfaz narrativa y fragmentación | Deformar en sueño o montaje solo información ya conocida por el jugador | Introducir hechos nuevos o contradicciones que parezcan bugs |
| *Kingdom Hearts* | Objetos recurrentes como anclas emocionales | Reutilizar gato, expediente, sello, TV o espacios como motivos que acumulan significado | Convertirlos en coleccionables obligatorios o sentimentalizar fuera de tono |
| *Persona* | Ritmo de calendario y transiciones con identidad | Diferenciar oficina, trayecto, casa y sueño por luz, sonido, composición y ritmo | Copiar una gramática visual ajena a SIGA-98 o convertir el cierre en puntuación |
| *Steins;Gate* | Interfaz cotidiana como punto de decisión | Hacer que llamadas, avisos o mensajes modifiquen qué se muestra después sin abrir un menú abstracto | Ramificaciones que alteren veredicto/economía sin diseño explícito |
| *Metal Gear* / Kojima | Continuidad entre control y puesta en escena | Mantener el estado real del espacio y usar cámara en tiempo real cuando sea posible | Fingir continuidad al cargar otra escena o separar siempre jugar y mirar |

## Referencias interactivas

### *Steins;Gate*: la interfaz cotidiana como bisagra

Lo transferible no es el viaje temporal, sino el uso de una interfaz diegética corriente como punto de decisión. Una llamada, mensaje, aviso interno o adjunto puede modificar qué fragmento se presenta después sin abrir una pantalla abstracta de elección.

Aplicación de bajo riesgo para SIGA-98:

- responder o ignorar una llamada antes de abandonar la oficina;
- abrir o dejar pendiente un mensaje interno;
- revisar o no un adjunto antes del cierre de jornada;
- usar esa decisión únicamente para elegir una variante de puesta en escena ya autorizada por el estado de la partida.

La decisión no debe alterar por sí sola economía, veredicto o recompensas. Si una consecuencia jugable existe, debe pertenecer a otro issue que la diseñe expresamente.

Referencia: <https://steins-gate.com/>

### *Serial Experiments Lain* de PS1: el archivo como narrativa

El caso útil para el proyecto es tratar el archivo y la navegación entre fragmentos como parte del relato. La presentación puede ser no lineal aunque los hechos sigan teniendo una fuente estable y verificable.

Patrón transferible:

1. seleccionar solo documentos, conceptos o recuerdos ya conocidos;
2. yuxtaponer dos o más fragmentos sin inventar conexiones nuevas;
3. permitir que el jugador reconstruya significado por contexto;
4. conservar la procedencia de cada fragmento para tests y depuración.

Esto encaja con SIGA, el corcho y el sueño siempre que se mantenga una regla estricta: **fragmentar la presentación, no los hechos**. Una deformación puede cambiar escala, orden, encuadre o sonido; no puede crear una pista que no exista en el estado persistido.

Referencias:

- <https://lain.wiki/index.php?title=Serial_Experiments_Lain_%28game%29>
- <https://lain.wiki/wiki/Serial_Experiments_Lain_Official_Guide/Q%26A>

### Kojima: continuidad entre control y puesta en escena

La lección útil es evitar que una cinemática parezca un vídeo desconectado del estado jugado. Siempre que la escena lo permita, la puesta en escena debería conservar variables reales del espacio y partir del contexto donde terminó el jugador.

Criterios transferibles:

- reutilizar el espacio y los objetos realmente presentes;
- conservar estado visible como luces, expediente activo, gato u otros elementos persistidos cuando proceda;
- llevar la cámara desde el control del jugador a un encuadre dirigido y devolverla sin alterar el significado del espacio;
- cuando haya cambio de escena, asumir el corte como recurso expresivo en vez de fingir una continuidad inexistente;
- integrar exposición breve en una acción o transición cuando sea más clara que separar siempre “jugar” y “mirar”.

No se traslada el tono, la escala ni la duración de sus escenas. La referencia sirve para continuidad y uso del estado en tiempo real, no para justificar monólogos largos o exposición excesiva.

Referencias:

- <https://www.metalgearinformer.com/kojima-talks-about-use-of-camera-in-metal-gear-solid-v/>
- <https://www.kojimaproductions.jp/>

## Guardas de diseño

Toda escena derivada de esta investigación debería cumplir estas reglas:

- No revelar IDs, pistas, conceptos ni relaciones que el jugador no haya podido conocer.
- Si una escena deforma recuerdos o documentos, cada elemento debe ser rastreable a datos persistidos de la partida.
- La variación cinematográfica no cambia recompensas, acciones, economía ni desenlaces salvo que otro issue lo defina expresamente.
- El estado jugable debe resolverse y guardarse antes de una cinemática saltable; saltarla no puede perder progreso.
- Las transiciones deben ser saltables y tener una alternativa compatible con `reduce_motion` basada en cortes o fundidos simples.
- La información esencial debe seguir siendo legible sin audio mediante subtítulos, texto o señal visual equivalente.
- Las selecciones procedurales de elementos para una escena deben poder reproducirse de forma determinista en tests.

## Tres prototipos de bajo riesgo

### Oficina → trayecto

Plano fijo breve del espacio de salida, un microevento de luz o sonido y corte al exterior. El cambio de fluorescente a calle, de linóleo a asfalto y de zumbido a ambiente exterior debe comunicar el cambio de bloque sin añadir exposición.

No debe abrir ahora un sistema paralelo. La puesta en escena concreta pertenece al trabajo de cinemáticas 3D de #395 y debe coordinarse con la identidad espacial de #277/#398.

### Casa → sueño

Repetir el mismo encuadre de casa y alterar únicamente parámetros de presentación ya disponibles: luz, niebla, sonido y, si procede, presencia o ausencia de un objeto persistido. La escena no inventa pistas; deforma lo conocido.

El principio de repetición con variación ya llegó a `main` mediante #311: la entrada al sueño presenta únicamente folios leídos y, si no hay lecturas, varía la presentación sin inventar un expediente. La conversión espacial 3D y su puesta en escena pertenecen a #395; el contenido onírico sigue perteneciendo a #87.

### Cierre de jornada

Rematar el día con una pieza breve y fría: pantalla SIGA, sonido mecánico y un plano final del espacio u objeto recurrente. Debe registrar, no juzgar. Nada de notas, estrellas o clasificación moral.

No es un P0 autónomo mientras el playtest siga señalando problemas de control, HUD, identidad espacial y cinemáticas principales. Solo debe abrirse como implementación separada si un gate de recorrido demuestra que el cierre diario es un problema real; #177 no autoriza por sí solo otro modal o sistema de resultados.

## Matriz de riesgo ampliada

| Riesgo | Señal de que se está abusando | Regla de contención |
| --- | --- | --- |
| Dependencia del canon externo | La escena solo se entiende si se reconoce la referencia | Debe funcionar sin conocer ninguna obra externa; la referencia nunca es contenido requerido |
| Exceso de exposición | La cinemática explica en texto o diálogo lo que ya comunica el estado | Preferir gesto, encuadre, sonido u objeto antes que explicación redundante |
| Metanarrativa invasiva | El efecto requiere información real del jugador o rompe la frontera de privacidad | No usar telemetría real, archivos externos ni datos personales como recurso narrativo |
| Repetición cansina | Una escena recurrente mantiene siempre la misma duración y composición | Variar solo con estado real y usar el acortado del sistema común cuando corresponda |
| Ambigüedad confundida con bug | El jugador no puede distinguir deformación deliberada de inconsistencia | Toda variación debe derivar de una fuente reconocible o regla estable |
| Duración excesiva | La escena interrumpe una acción rutinaria más de lo que aporta | Mantener prototipos en segundos, no minutos; dejar la extensión para momentos explícitamente excepcionales |
| Interfaz decorativa | El texto o HUD aparece sin aportar decisión, contexto o información | Toda interfaz cinematográfica debe cumplir una función narrativa o funcional concreta |
| Elección falsa con efecto sistémico | Una decisión de presentación altera economía, progreso o veredicto sin diseño previo | Las variantes de #177 son de presentación salvo que otro issue autorice una consecuencia jugable |
| Parpadeos o movimiento problemático | La identidad de la escena depende de flashes o paneos intensos | `reduce_motion`, evitar flashes rápidos y ofrecer corte/fundido estable equivalente |
| Dependencia del audio | Sin sonido se pierde una pista o instrucción necesaria | Subtítulos, texto o señal visual equivalente para toda información esencial |
| Cinématica bloqueante | Saltarla cambia el resultado o pierde progreso | Resolver y guardar el estado antes de reproducirla; la escena siempre es saltable |
| Aleatoriedad irreproducible | Un fallo visual no puede reconstruirse en tests | Persistir o sembrar de forma determinista la selección de fragmentos y variantes |

## Regla para futuros prototipos interactivos

Un prototipo inspirado por estas referencias solo debería entrar en implementación cuando pueda expresarse como una función de estado ya existente:

`estado persistido -> variante de presentación`

No debe convertirse implícitamente en:

`variante de presentación -> nuevo estado jugable`

La segunda forma requiere diseño propio, criterios de aceptación y, normalmente, un issue separado.

## Estado de adopción

La investigación ya no parte de cero. A fecha de 23/09/2026:

| Entrega | Estado | Consecuencia |
| --- | --- | --- |
| Matriz inicial de técnicas, riesgos y tres prototipos (#246) | Integrada | Este documento es la fuente versionada de las guardas de dirección |
| *Steins;Gate*, Lain PS1 y continuidad inspirada por Kojima (#247) | Integrada | Queda fijada la frontera `estado persistido -> variante de presentación` |
| Repetición con variación casa → sueño (#311) | Integrada y probada | Primer principio de #177 que llegó a gameplay real; no se debe reimplementar en otro sistema |
| Comparación jugable de Evangelion (#329) | Integrada | Completa la entrega pendiente de adaptaciones jugables y refuerza estado/determinismo/accesibilidad |
| Síntesis post-playtest (#856) | Integrada | El fallo humano del 17/09 se convirtió en la gramática `orientar → acción → residuo` |
| Entrada / oficina (#858) | Integrada | Primer vertical rehecho bajo la gramática post-playtest |
| Casa → sueño (#1073) | Integrada | Segundo vertical rehecho; continuidad de cámara y fundido opt-in sobre la casa real |
| Oficina → trayecto (#1074) | Integrada | Tercer vertical rehecho; mantiene un referente del archivo hasta completar el tránsito |
| Enganches funcionales entre fases (#280 / #1036) | Cerrados | Entrada, inicio de jornada, archivo → trayecto y casa → sueño están cubiertos por regresión real |
| Protocolo de validación humana (#682) | Integrado | El último gate puede ejecutarse de forma ciega y registrar respuestas literales |
| Calidad/dirección P0 (#395) | Validación humana | No autoriza más retoques por lectura de código: el siguiente cambio debe responder a un fallo observado |

Por tanto, #177 **no debe generar más PR de código por inspiración aislada**. Los tres blueprints derivados del fallo humano ya están implementados. Una técnica solo vuelve a pasar a implementación si un pase real detecta un problema concreto y el issue dueño de ese problema la adopta.

### Gate restante de investigación

La parte documental y la traducción a gameplay están cubiertas. El único gate propio que queda es el pase ciego sobre una build posterior a #1074, usando el protocolo de #682 y registrando el resultado bajo #395.

Para poder cerrar #177 deben quedar verificadas conjuntamente estas guardas:

- saltar una escena no cambia estado ni pierde progreso;
- la alternativa de movimiento reducido conserva información y continuidad;
- ninguna variación revela información no conocida;
- una persona sin conocimiento previo de las referencias entiende **entrada/oficina**, **oficina → trayecto** y **casa → sueño**;
- el participante puede identificar dónde estaba y dónde termina cada transición sin depender de rótulos explicativos;
- no se reproducen los fallos del 17/09 de ritmo, encuadre, contenido de plano o acabado de forma que bloqueen la comprensión;
- las escenas recurrentes no se vuelven más largas o invasivas con la repetición.

#280 ya no bloquea este cierre: quedó resuelto como defecto funcional. El bloqueo vigente es #395 en `estado:validacion-humana`.

Si el pase ciego supera esos puntos, #177 puede cerrarse como investigación aplicada completada. Si falla, el nuevo trabajo debe abrirse o continuar bajo el issue dueño de la escena concreta y #177 solo debe conservar la trazabilidad de qué principio se corrigió.

## Fronteras con otros issues

- #66: reproductor y reglas comunes de cinemáticas.
- #67: ritmo, salto y acortado reutilizable.
- #72 y #74: antecedentes de implementación concreta de transiciones.
- #87: contenido y reglas de deformación del sueño.
- #92: uso del gato como elemento recurrente.
- #98, #100 y #140: finales, presentación de resultados y otros sistemas relacionados.
- #177: investigación, guardas y trazabilidad de adopción; no es dueño de gameplay nuevo.
- #280: validación de transiciones/cinemáticas en export.
- #395: implementación P0 de cinemáticas 3D prioritarias.
- #398/#399: identidad espacial y materiales sobre los que se rueda la puesta en escena.

Los próximos cambios de comportamiento deben vivir en el issue que posea el problema observado. #177 queda como referencia de dirección y como checklist de validación, no como backlog de features.
