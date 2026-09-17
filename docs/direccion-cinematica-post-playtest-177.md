# Dirección cinematográfica tras el playtest humano (#177)

Este documento es un addendum operativo a `docs/investigacion-cinematografica.md`. No abre un sistema de cinemáticas nuevo ni autoriza cambios de gameplay: convierte el resultado del gate humano del 17 de septiembre de 2026 en criterios de dirección para el trabajo dueño de la puesta en escena, principalmente #395, manteniendo #66/#67 como contrato del reproductor y #280 como validación de integración/export.

## Resultado del gate humano

El pase humano sobre las builds `dffdff8d` y la asociada a #771 no validó el acabado cinematográfico. El problema observado no fue una regresión técnica aislada: se señalaron a la vez ritmo, encuadres, contenido de los planos y acabado visual.

Eso cambia la lectura de #177:

- la investigación documental sigue siendo válida como repertorio de técnicas y guardas;
- los checks técnicos ya cubiertos —skip seguro, reducción de movimiento, no inventar pistas, reproducción en export— siguen siendo necesarios;
- pero **no son suficientes para cerrar la investigación** mientras la traducción a puesta en escena siga fallando el pase humano;
- no conviene añadir más referencias: el siguiente avance útil es aplicar mejor las ya elegidas.

La regla de trabajo pasa a ser: **cada cinemática debe poder explicar su intención antes de tocar cámara, texto o assets**.

## Gramática común de una secuencia

Una secuencia corta debería construirse, por defecto, con tres funciones legibles. No tienen que ser tres planos exactos, pero sí tres beats distinguibles:

1. **Orientar**: dónde está el jugador y cuál es el sujeto visual principal.
2. **Acción**: qué cambia, qué gesto ocurre o qué transición se está produciendo.
3. **Residuo**: qué imagen, objeto, sonido o composición queda para cerrar la idea y devolver control.

Una escena que no puede describirse con esos tres beats debería simplificarse antes de añadir más planos.

### Regla por plano

Cada plano debe declarar explícitamente:

- **sujeto**: qué debe mirar primero el jugador;
- **verbo visual**: qué ocurre en el plano (`espera`, `cruza`, `enciende`, `sella`, `desaparece`, `se deforma`, etc.);
- **función**: orientar, ejecutar la acción o dejar residuo;
- **duración inicial**: suficiente para leer sujeto y verbo, ajustable tras playtest;
- **sonido base** y, si procede, un único acento sonoro;
- **salida**: corte, continuidad espacial, fundido o devolución de control.

Un plano que solo existe para mostrar un asset, una frase o una cámara bonita no supera esta plantilla.

## Traducción de las referencias a decisiones concretas

### Evangelion: duración y espacio negativo con intención

Lo útil no es “hacer planos largos”, sino sostener un encuadre cuando la duración añade presión o significado.

Aplicación:

- usar un plano fijo o casi fijo después de una acción burocrática para que el espacio pese;
- permitir vacío en el encuadre si dirige la atención al aislamiento, espera o amenaza fuera de campo;
- apoyar la pausa con ambiente reconocible: fluorescente, ventilación, lluvia, tráfico lejano, ascensor, CRT;
- introducir como máximo un microevento durante una pausa: un parpadeo, un piloto, un paso, una puerta, una vibración de pantalla.

Evitar:

- cámara quieta sin sujeto ni tensión;
- pausas cuya única lectura posible sea “el juego se ha quedado colgado”;
- encadenar varios planos contemplativos sin acción entre ellos.

### Serial Experiments Lain: alteración mínima de algo conocido

Lo útil es que lo extraño nazca de un espacio o dato que el jugador ya reconoce.

Aplicación:

- partir del espacio real jugado, no de una tarjeta abstracta separada;
- cambiar una sola variable fuerte por beat: luz, escala, presencia, sonido, continuidad o posición;
- en sueño, deformar solo información rastreable al estado persistido;
- mantener una referencia estable —cama, puerta, terminal, expediente, gato, silla— mientras el resto se vuelve dudoso.

Evitar:

- sumar glitches, textos, flashes y ruido a la vez;
- convertir la ambigüedad en ilegibilidad;
- inventar una pista para que el plano “tenga algo interesante”.

### Kingdom Hearts: objeto o gesto como ancla

Lo útil es la claridad emocional de un gesto sencillo en escenas con contexto complejo.

Aplicación:

- elegir un objeto recurrente como ancla de la escena: expediente, sello, CRT, gato, cama, TV, tarjeta, ascensor;
- hacer que el plano cambie el significado de ese objeto por contexto, no por exposición verbal;
- cerrar una transición sobre un gesto o estado visible antes que sobre una explicación.

Evitar:

- sentimentalizar los objetos fuera del tono burocrático/horror cotidiano;
- convertir el motivo en coleccionable o recompensa;
- usar primeros planos de objetos sin que cambie su función narrativa.

### Persona: identidad clara entre bloques de la jornada

Lo útil es que el cambio de modo se entienda sensorialmente sin depender de un cartel.

Aplicación:

- oficina, trayecto, casa y sueño deben distinguirse por una combinación consistente de luz, ambiente, composición y ritmo;
- el paso entre bloques puede tener una firma propia, pero debe seguir perteneciendo al lenguaje de SIGA-98;
- texto y tipografía acompañan el cambio; no lo sustituyen.

Evitar:

- un fundido genérico idéntico para todas las fases;
- una pantalla de texto que cargue sola con la comprensión del cambio;
- copiar paletas, iconografía o composición reconocible de la referencia.

## Criterios de cámara y blocking

El playtest obliga a tratar los encuadres como dirección, no como coordenadas de prueba.

- **Un sujeto dominante por plano.** Si hay varios elementos importantes, ordenar su lectura por profundidad, luz, movimiento o sucesión de planos.
- **Altura y distancia con intención.** Cámara baja, alta o lejana solo si altera la relación con el espacio o personaje.
- **Movimiento motivado.** Travelling, paneo o acercamiento deben seguir una acción o revelar información; si no, usar cámara fija.
- **Entrada y salida limpias.** Evitar empezar un plano ya a mitad de gesto o cortar antes de que el jugador haya podido leer el resultado.
- **Continuidad espacial.** Siempre que sea posible, partir de los espacios 3D reales y preservar su orientación. Si hay un cambio imposible de ocultar, usar un corte deliberado en lugar de fingir continuidad.
- **NPCs y props como blocking.** Antes de añadir texto, probar si una animación breve, una mirada, una puerta, una silla o un objeto desplazado comunica la idea.

Las animaciones UAL, packs CC0 y assets ya validados pueden elevar el blocking, pero solo cuando tienen una función concreta en el beat y su procedencia sigue registrada. No se añade material externo para decorar un plano sin necesidad narrativa.

## Ritmo: respiración, no lentitud

La duración no debe fijarse por número mágico. El primer corte se ajusta a lectura y acción:

- el plano debe durar lo suficiente para reconocer sujeto + verbo;
- después de una acción importante puede reservarse un breve residuo antes del corte;
- dos planos consecutivos no deberían competir por atención con texto largo y movimiento simultáneo;
- una escena rutinaria debe ser más corta en repeticiones mediante el sistema común ya existente;
- si una escena necesita tiempo, debe justificarlo con tensión, acción o información visual, no con espera vacía.

En playtest se debe preguntar **qué plano se sintió rápido, largo o confuso**. “La cinemática va mal” no es granular suficiente para el siguiente ajuste.

## Sonido: capa narrativa, no relleno

Cada secuencia debería tener un suelo sonoro reconocible. El silencio absoluto se reserva para una decisión expresiva y nunca debe confundirse con audio roto.

Patrón recomendado:

- **ambiente continuo** del espacio;
- **un acento** ligado a la acción principal (sello, puerta, ascensor, CRT, respiración, lluvia, cama, interruptor);
- música solo si aporta una función que el ambiente no cubre;
- toda información necesaria sigue siendo comprensible sin audio.

La identidad puede cambiar de bloque por tratamiento del mismo mundo sonoro: zumbido de oficina, exterior/lluvia, interior doméstico, grave onírico. No hace falta añadir una pista musical nueva para cada transición.

## Texto, voz e interfaz

Tras el fallo humano, el texto no debe usarse para rescatar una composición que no cuenta nada por sí sola.

- primero debe entenderse la acción visual;
- el texto añade contexto, precisión o tono;
- evitar varias frases mientras la cámara, NPCs y entorno también exigen atención;
- una frase importante necesita tiempo real de lectura;
- si al eliminar el rótulo la secuencia deja de tener sujeto o acción, el problema es de puesta en escena.

## Tres blueprints para #395

Estos blueprints no son commits de gameplay; son criterios para que #395 rehaga o ajuste los verticales que fallaron el pase humano.

### Entrada / oficina

**Intención:** “Estoy entrando en un archivo burocrático, este es mi puesto y aquí empieza mi trabajo”.

- **Orientar:** plano que sitúe físicamente entrada, escala del archivo y dirección del puesto.
- **Acción:** acompañar un gesto útil —acercamiento al terminal, acreditación, NPC que ocupa su rutina, encendido del CRT— en lugar de una sucesión de tarjetas.
- **Residuo:** dejar el puesto/expediente/terminal como ancla antes de devolver control.

Prueba humana: tras verla una vez, una persona nueva debe poder decir dónde está, cuál parece ser su rol inmediato y qué elemento del espacio concentra la acción.

### Oficina → trayecto

**Intención:** “La jornada de oficina ha terminado o se interrumpe; ahora abandono ese espacio y paso al exterior”.

- **Orientar:** conservar un último referente del archivo o salida real.
- **Acción:** puerta, ascensor, escalera o desplazamiento según la ruta jugable real; acompañar con cambio de ambiente.
- **Residuo:** primer encuadre exterior con lluvia/tráfico/luz si esos elementos están presentes en el estado real, antes de devolver control.

Prueba humana: el cambio debe entenderse espacialmente sin un rótulo que diga “trayecto”.

### Casa → sueño

**Intención:** “Me dormí aquí; el espacio conocido empieza a dejar de ser fiable”.

- **Orientar:** cama/habitación reconocibles y estado doméstico real.
- **Acción:** una alteración dominante —luz, sonido, escala, objeto persistido— mientras la cama sigue siendo ancla.
- **Residuo:** corte o continuidad al primer espacio onírico conservando una relación visual/sonora con el beat anterior.

Prueba humana: debe poder decir qué acción provocó el cambio y distinguir deliberadamente “me estoy durmiendo/entrando en sueño” de “el juego cambió de escena sin explicación”.

## Mapa de implementación

### Resolvable con el runtime existente

- cámara 3D y planos del reproductor común;
- continuidad en `World3D` cuando la escena real ya está montada;
- skip y final normal convergiendo en el mismo estado;
- `reduccion_movimiento` mediante poses/cortes estables;
- luces, props, puertas, CRT, cama, sello, terminales y otros elementos ya presentes;
- ambientes y acentos sonoros ya disponibles, cuando su licencia/procedencia esté validada.

### Puede requerir assets o trabajo adicional

- animaciones de NPC específicas para un gesto que no exista todavía;
- props que sean imprescindibles para el verbo visual del plano;
- ambientes/foley ausentes en la biblioteca validada;
- composición o iluminación específica que no pueda obtenerse reutilizando el espacio jugable.

Ese trabajo debe vivir bajo el issue dueño de la escena o del asset. #177 no crea por sí mismo una cola paralela de producción.

## Checklist antes de pedir otro gate humano

Una escena candidata a validación debe llegar con:

- intención en una frase;
- beats `orientar → acción → residuo` escritos;
- sujeto y verbo visual de cada plano;
- storyboard o capturas de los encuadres sobre el espacio real;
- sonido base y acentos definidos;
- versión normal y comportamiento con `reduccion_movimiento`;
- skip seguro y mismo estado final;
- ausencia de pistas o hechos no conocidos;
- export real de la build que se va a probar.

La revisión humana no debe limitarse a “¿te gusta?”. Debe registrar, como mínimo:

1. qué cree que acaba de ocurrir;
2. dónde estaba y dónde terminó;
3. qué elemento recuerda del plano principal;
4. qué parte se sintió demasiado rápida, larga o confusa;
5. si algún texto, movimiento o efecto compitió con la lectura de la acción.

## Consecuencia para el cierre de #177

El gate humano ya no está “pendiente de ejecutar”: **se ejecutó y falló**. Por tanto #177 no debe cerrarse todavía.

Tampoco necesita más investigación de franquicias. El criterio de cierre pasa a ser:

- #395 aplica esta síntesis a las secuencias que fallaron;
- el siguiente export mantiene las guardas técnicas ya cubiertas;
- una persona sin conocimiento de las referencias comprende las escenas y no reproduce los fallos de ritmo, encuadre, contenido y acabado señalados el 17 de septiembre;
- si el nuevo pase detecta un fallo concreto, se corrige bajo el issue dueño de esa escena y #177 conserva la trazabilidad de qué principio de dirección se adoptó.

Así #177 permanece como investigación aplicada y checklist de dirección, no como backlog infinito de inspiración.

— Odiseo (GPT-5.6 Sol)
