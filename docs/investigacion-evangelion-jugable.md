# Evangelion jugable: técnicas transferibles para #177

Esta entrega completa una de las piezas pendientes de #177: comparar adaptaciones jugables de *Neon Genesis Evangelion* sin copiar contenido, iconografía, personajes, música ni estructura narrativa reconocible. El objetivo es extraer reglas de diseño aplicables a *Expediente Legado*.

## Caso principal: *Neon Genesis Evangelion 2* (PS2 / PSP)

Las descripciones disponibles del juego destacan dos rasgos útiles para esta investigación: permite recorrer varias versiones del mundo desde distintos personajes y usa una simulación relativamente autónoma para producir relaciones, situaciones y escenarios que no reproducen siempre una única línea argumental.

Fuentes de referencia:

- <https://en.wikipedia.org/wiki/Neon_Genesis_Evangelion_2>
- archivo del sitio de Alfa System enlazado desde esa ficha: <https://web.archive.org/web/20071018035324/http://www.alfasystem.net/game/eva2/text_conquest/mel015x.cgi>

### Observación

La adaptación no se limita a convertir escenas de la serie en una secuencia lineal. Su interés está en permitir que el mismo mundo produzca situaciones distintas según personaje, relaciones y estado de la partida.

### Interpretación

Para *Expediente Legado*, lo transferible no es simular Evangelion ni multiplicar rutas de guion. Es separar **mundo persistido** y **puesta en escena**: una misma oficina, casa o sueño puede leerse de forma diferente según estado ya existente sin necesitar una escena distinta escrita a mano para cada combinación.

### Propuesta

Usar datos persistidos ya disponibles —folio leído, acusado, gato presente, día, mapa onírico, impago, objetos visibles— para seleccionar pequeñas variaciones cinematográficas. La variante nunca debe crear un hecho nuevo; solo decide qué parte del estado ya válido se enfatiza.

Ejemplo seguro:

`estado persistido -> selección de encuadre / objeto visible / duración / sonido`

No:

`variante cinematográfica -> pista / dinero / veredicto / relación nueva`

### Riesgo

Una simulación demasiado abierta puede generar combinaciones incoherentes o difíciles de probar. En este proyecto, cada variante debe derivarse de un conjunto pequeño de variables explícitas y reproducibles.

## Contraste: *Neon Genesis Evangelion: 2nd Impression* (Saturn)

La ficha de MobyGames describe una estructura de “interactive anime” con decisiones ramificadas y combates insertados en la continuidad audiovisual.

Fuente:

- <https://www.mobygames.com/game/11319/neon-genesis-evangelion-2nd-impression/>

### Observación

Aquí la interacción funciona más como selección dentro de una escena dirigida: el jugador toma decisiones y la presentación audiovisual continúa a partir de ellas.

### Interpretación

Este patrón es menos adecuado como modelo general para *Expediente Legado*, porque corre el riesgo de convertir transiciones y cinemáticas en menús de elección. Sí aporta una regla útil: cuando una decisión exista, debe ocurrir **antes** de que la cinemática cierre su consecuencia, no mediante una elección falsa durante un vídeo.

### Propuesta

Si SIGA, una llamada o un documento ofrece una elección real, resolverla en gameplay/UI diegética y usar después la cinemática solo para mostrar el estado resultante. Esto mantiene la regla ya documentada en #177: el resultado jugable existe antes de la escena y saltarla no cambia nada.

### Riesgo

Encadenar demasiadas elecciones dentro de una secuencia dirigida vuelve la escena lenta y confunde presentación con sistema. Limitar #177 a variaciones de presentación salvo que otro issue diseñe expresamente la consecuencia jugable.

## Contraste adicional: *Ayanami Raising Project*

Las descripciones del juego lo clasifican como simulación de vida/raising y señalan que el jugador decide planificación y actividades.

Fuentes:

- <https://en.wikipedia.org/wiki/Neon_Genesis_Evangelion%3A_Ayanami_Raising_Project>
- <https://www.mobygames.com/game/77380/neon-genesis-evangelion-ayanami-ikusei-keikaku-with-asuka-hokan-/>

### Observación

El interés no está en la licencia, sino en cómo una sucesión de decisiones pequeñas de calendario puede acumular significado sin que cada una sea una gran bifurcación narrativa.

### Interpretación

Esto refuerza una línea ya presente en *Expediente Legado*: jornada, acciones, alquiler, gato y sueño pueden hacer que la rutina tenga peso sin añadir una puntuación moral.

### Propuesta

Las cinemáticas deberían reflejar acumulación, no evaluarla. Por ejemplo, el mismo cierre de jornada puede mostrar un detalle distinto según un estado real ya persistido, sin convertirlo en nota, rango o premio.

### Riesgo

Convertir cada rutina en una métrica visible produciría una capa de optimización ajena al tono. La presentación debe registrar consecuencias existentes, no enseñar al jugador una “build correcta”.

## Matriz de transferencia

| Técnica observada | Transferible a SIGA-98 | No transferir |
| --- | --- | --- |
| Un mismo mundo con situaciones distintas según estado | Variantes pequeñas de puesta en escena basadas en datos persistidos | Generador narrativo abierto sin pruebas deterministas |
| Decisión integrada en una escena dirigida | Resolver primero la elección en interfaz/gameplay y mostrar después su consecuencia | QTE o menú cinematográfico sin efecto sistémico claro |
| Rutina y calendario como acumulación | Repetición con pequeñas diferencias visibles a lo largo de los días | Puntuación moral, ranking de conducta o ruta óptima explícita |
| Cambios de perspectiva | Mostrar el mismo lugar u objeto desde encuadres distintos según contexto | Añadir narradores o puntos de vista que revelen hechos desconocidos |

## Decisiones para futuros PR

1. Toda variación derivada de esta investigación debe listar las variables persistidas que consume.
2. Una escena no puede leer información que el jugador todavía no conoce.
3. La selección de variante debe ser determinista y testeable.
4. Saltar la escena no modifica el estado.
5. `reduce_motion` debe conservar el significado con cortes o planos estáticos.
6. Una referencia externa nunca puede ser necesaria para entender la escena.
7. Si una propuesta necesita crear estado nuevo, sale del alcance de #177 y requiere un issue propio.

## Relación con entregas ya integradas

- `docs/investigacion-cinematografica.md` contiene la matriz general, Steins;Gate, Lain PS1 y Kojima.
- PR #311 ya aplicó repetición con variación en casa → sueño usando únicamente folios conocidos.
- Esta comparación no pide rehacer #311: refuerza su patrón `estado persistido -> variante de presentación` y documenta por qué conviene mantenerlo acotado y determinista.

— Odiseo (GPT-5.6 Sol)
