# Gramática simbólica de SIGA-98

Refs: #79, #87, #435, #645, #779, #830, #888.

## Propósito

Esta gramática sirve para repetir motivos entre vigilia, sueño, tarot, combate, cinemáticas y anomalías sin convertir *Expediente Legado* en una enciclopedia de símbolos ni en una colección de easter eggs.

La referencia cultural es una capa de diseño, no una explicación dentro del juego. Una escena debe seguir funcionando aunque el jugador no reconozca el tarot, el mito o el arquetipo que ayudó a construirla.

## Regla principal: estructura antes que icono

Priorizar, en este orden:

1. **espacio** — simetría, pasillo, umbral, descenso, centro, bucle;
2. **comportamiento** — repetición, duplicación, regeneración, pérdida, retorno;
3. **objeto cotidiano** — sello, bandeja, ascensor, reloj, CRT, archivador, reflejo;
4. **composición** — luz, peso visual, encuadre, fuera de campo;
5. **iconografía explícita**, solo cuando el contenido diegético ya la justifique.

No añadir una carta, estatua, glifo o nombre mitológico únicamente para señalar al jugador que existe una referencia.

## Familias canónicas

| Familia | Expresión SIGA-98 | Ecos posibles | Uso recomendado |
| --- | --- | --- | --- |
| Umbral / guía | puerta, ascensor, ventanilla, gato, transición | psicopompo, Hermes, Anubis, Caronte | cambios de estado y espacios de paso |
| Doble / sombra | reflejo discordante, duplicado, objeto desplazado | sombra, gemelo, Luna | anomalías y sueño reconocible |
| Balanza / juicio | dos bandejas, simetría, sello, pesos visuales | Justicia, Ma'at, pesaje | archivo, careo, combate y decisiones |
| Laberinto / búsqueda | archivadores, pasillos, rutas plegadas | Minotauro, Ariadna, búsqueda | sueño y arquitectura imposible |
| Ciclo / centro | reloj, ventilador, rotonda, sello circular | Rueda, ouroboros, mandala | repetición con variaciones y progreso |
| Descenso | sótano, metro, pérdida de altura/luz | katábasis, Duat, inframundo | transición hacia sueño o consecuencia |
| Herida / vulnerabilidad | grieta, desgaste, punto débil | Aquiles, torre herida | lectura espacial y combate |
| Regeneración | incidencia que vuelve, expediente que se multiplica | Hidra | problemas sistémicos y puzzles reactivos |

Estas asociaciones son **ecos**, no equivalencias canónicas. No existe una tabla del tipo «X significa Y» que el jugador deba aprender.

## Uso de arquetipos psicológicos

Los arquetipos se emplean como vocabulario de dirección, nunca como diagnóstico de personajes ni como afirmación clínica.

- **persona**: credenciales, firmas, uniforme, fotografía, máscara social;
- **sombra**: doble, reflejo, versión incompatible de algo conocido;
- **guía/psicopompo**: quien o aquello que cruza un umbral con el jugador;
- **centro/integración**: motivos circulares o composiciones que reúnen elementos antes separados;
- **trickster**: error pequeño que revela que una regla aparentemente estable no lo era.

En pantalla se muestran sus consecuencias visuales o mecánicas, no estas etiquetas.

## Tarot

Las 22 cartas existentes de #645 pueden aparecer cuando el sistema de tarot lo requiera. Fuera de esa superficie, es preferible **rimar con su composición** antes que mostrar otra carta.

Ejemplos:

- una composición bilateral y dos bandejas con pesos distintos puede evocar Justicia;
- un CRT como única fuente de luz puede recordar al Ermitaño;
- lluvia, cristal y reflejo ambiguo pueden rimar con la Luna;
- un objeto circular que vuelve a la misma posición con una pequeña diferencia puede recordar la Rueda.

No mostrar el nombre del arcano ni convertir estas asociaciones en HUD, buffs o pistas automáticas.

## Mitología

#435 sigue siendo la superficie principal para mitología 3D explícita en el sueño. La vigilia prepara el motivo mediante objetos y estructuras cotidianas.

Ejemplos de traducción:

- Minotauro → navegación de archivadores antes que cuernos dibujados;
- Hidra → incidencias que se duplican al tratar el síntoma;
- Aquiles → punto débil legible en una estructura aparentemente sólida;
- Duat → descenso y pesaje burocrático antes que decoración funeraria gratuita;
- psicopompo → función de guía/umbral antes que representación literal de una deidad.

## Vertical slice: menú de inicio

El attract mode de #830 usa cuatro **tableaux internos**. Sus IDs solo existen en código/documentación; no se muestran al jugador.

| ID interno | Construcción | Eco |
| --- | --- | --- |
| `balanza` | deriva hacia archivo/bandeja, luz casi neutra, FOV contenido | Justicia / Ma'at / juicio burocrático |
| `vigilia` | CRT más dominante y encuadre algo más cerrado | Ermitaño / observador nocturno |
| `reflejo` | composición general más oscura y ligeramente abierta | Luna / sombra / doble |
| `umbral` | encuadre hacia elementos secundarios con apertura leve | guía / psicopompo / paso entre estados |

Las diferencias deben permanecer pequeñas. No se crean escenas, viewports, modelos, cartas ni texto adicional. Cualquier input abandona el attract mode y `reduccion_movimiento` impide que se active.

## Vertical slice: ecos del sueño

El segundo vertical de #888 vive en `SuenoUtileria`, que ya cumple la regla de #79/#87: solo monta anomalías a partir de originales que el jugador tocó, leyó o recogió realmente ese día.

Sobre esos originales puede aparecer un **eco geométrico estático**. No es otro objeto jugable: duplica únicamente la forma visual ya deformada, sin colisión, prompt, objetivo ni persistencia propia.

| Original reconocido | Motivo interno | Construcción del eco | Lecturas posibles |
| --- | --- | --- | --- |
| silla de oficina | `umbral` | repetición alineada un poco más al fondo | paso, guía, psicopompo |
| monitor/CRT | `doble` | copia desplazada y ligeramente desfasada | sombra, reflejo, Luna |
| archivador | `laberinto` | copia parcial girada a 90° | Minotauro, Ariadna, búsqueda |
| tarot válido del día | `ciclo-centro` | copia reducida y vuelta sobre el centro | Rueda, retorno, integración |

Reglas específicas:

- el nombre del motivo nunca aparece en UI;
- el eco no añade una segunda interacción ni una colisión invisible;
- si el original no está legitimado por el estado del día, tampoco existe el eco;
- la misma noche/semilla conserva el mismo motivo y el mismo original;
- el sistema no altera `objetivos_requeridos`, detectores ni feedback de #281;
- al ser estático, no introduce movimiento adicional que deba suprimirse con `reduccion_movimiento`.

Este patrón permite escalar después a composiciones mayores —simetrías, corredores repetidos, ciclos o descensos— sin convertir cada referencia cultural en un asset nuevo.

## Límites

- Nada simbólico introduce hechos nuevos de un expediente.
- Nada simbólico sustituye feedback necesario para comprender una mecánica.
- Evitar asociaciones rígidas entre culturas distintas; compartir una función visual no las convierte en «la misma» tradición.
- No utilizar motivos religiosos vivos como mero jumpscare o decoración exotizante.
- La rareza debe partir de un original reconocible, especialmente en el sueño (#79/#87).
- Si una referencia necesita explicación textual para funcionar, todavía no está integrada con suficiente sutileza.

## Criterio de reutilización

Una implementación futura debería poder nombrar una de estas familias en su issue/PR y explicar:

1. qué original cotidiano reconoce el jugador;
2. qué estructura o comportamiento se altera;
3. qué función jugable/narrativa cumple;
4. cómo se comporta con reducción de movimiento;
5. por qué sigue siendo comprensible sin reconocer la referencia.
