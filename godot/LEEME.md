# Port a Godot 4

Primer corte de la migración (#54). **No sustituye todavía a nada**: la app
Spring de `backend/` sigue funcionando igual, y esta carpeta no depende de ella.

```
godot/
├── datos/casos.json      los 8 casos, extraídos de DataSeeder.java
├── datos/extraer.mjs     el extractor, para repetirlo si el seeder cambia
├── guion/                lógica pura portada de service/
└── pruebas/pruebas.gd    la suite, ejecutable sin abrir el editor
```

## Correr las pruebas

```bash
godot4 --headless --path godot --import          # solo la primera vez
godot4 --headless --path godot --script pruebas/pruebas.gd
```

Sale `0` si todo pasa. **Hace falta un Godot de la línea 4.7**, que es la que
declara `project.godot`: con un binario más viejo la suite falla por cosas que
no son del código —assets importados con un formato que no entiende, y guiones
que usan API posterior— y ese ruido esconde los fallos de verdad. Lo que se
mide contra un baseline sucio no se mide.

Los casos están portados uno a uno de `WikiLinkServiceTest`,
`HotspotServiceTest`, `CartaOcultaServiceTest` y `ProgresoServiceTest`, con el
nombre del test Java en un comentario: si el port cambia una decisión del
original, se ve cuál.

## La partida guardada

`guion/partida.gd`, en `user://partida.json`. No es un port de
`cargarEstado`/`guardarEstado`: `localStorage` no se corrompe a medias y no se
puede perder, y un fichero sí. De ahí tres precauciones que el original no
tenía que tomar:

1. **La escritura es atómica** — a un temporal y renombrado encima, así que un
   cierre a destiempo deja la partida anterior entera y no media nueva.
2. **Una partida ilegible no se pisa** — se aparta como `.roto` y se empieza de
   cero al lado. El original hacía `catch {}` y seguía con el estado vacío, o
   sea que el siguiente guardado borraba para siempre lo que hubiera.
3. **El formato va versionado** — una partida de una versión posterior se
   aparta en vez de interpretarse a medias.

Y **solo se guardan ids y banderas**, nunca el texto de los catálogos: si el
guardado se llevara una copia, reescribir la descripción de un logro dejaría
las partidas viejas mostrando la antigua. Bajó de 9.188 a 3.268 bytes al
arreglarlo.

Los catálogos (20 logros, 22 cartas) salen de `datos/prometeo.json`, extraídos
de `prometeo-ui.js` con `datos/extraer-prometeo.mjs` por el mismo motivo que
los casos: es contenido, y teclearlo introduce erratas que nadie compara con el
original.

## El azar de una partida (#147)

`guion/azar.gd`. Una partida tiene **una semilla** (`estado["semilla"]`) y todo
lo jugable que se sortea sale de ella por derivación, no de `randi()` global.
Eso es lo que permite volver a ver un fallo del que alguien informa: misma
semilla y mismas acciones, misma partida.

- `Azar.derivar(raiz, dominio, indices)` — función pura, mismo resultado en
  cualquier máquina. Los dominios son una lista cerrada en `Azar.DOMINIOS`:
  uno nuevo se declara ahí.
- `Azar.derivar_guardable(...)` — **para todo número que acabe en el fichero de
  partida**. JSON no tiene enteros: un entero de 63 bits vuelve redondeado y la
  partida recargada sortea otra cosa. Pasó con la plantilla de compañeros —
  recargar te cambiaba media oficina— y por eso lo persistido cabe en 32 bits.
- `Azar.manifiesto(estado)` / `manifiesto_en_texto(estado)` — semilla, vuelta,
  día, versión del guardado y huella de los catálogos, para pegar en un informe
  de bug. **No se enseña al jugador**: va en las herramientas de depuración.

Cada dominio deriva por su lado a propósito, para que el sueño de la noche 3 no
cambie porque el combate haya tirado una vez más.

Lo que **sí** puede seguir usando el azar global es la presentación —el tono de
una pisada, hacia dónde mira el gato, el grano de una textura—: no decide nada.
La suite tiene una guarda que recorre `guion/*.gd` y falla si aparece un
`randi()`/`randf()`/`randomize()` suelto fuera de esa lista corta.

## La Ventanilla de Reclamaciones

`escenas/ventanilla.tscn`. Piedra-papel-tijera burocrático —Objeción vence a
Silencio, Silencio a Insistencia, Insistencia a Objeción—, tres vidas y una
decisión por ronda. Es la pantalla donde el port deja de parecer un formulario:
la réplica del rival se escribe sola y encajar un golpe sacude el mostrador.

Tres reglas para que ese movimiento no mienta: **la ronda ya está resuelta**
cuando empieza la animación (lo que se ve es el relato de algo decidido, no un
sorteo en curso), **se puede saltar** pulsando, y **se puede apagar** entera con
`reduccion_movimiento`.

Los reclamantes salen del corcho —personas y comités ya descubiertos—, con uno
de oficio siempre disponible: una cola vacía es indistinguible de una pantalla
rota. Las cuatro habilidades (`guion/historias.gd`) se cargan con las
decisiones políticas de las cartas ocultas, tope de dos por eje.

## El día (walking simulator)

`escenas/dia.tscn`. La columna que al port le faltaba: hasta ahora una "vuelta"
no era nada —el sistema te reasignaba y empezabas otra, sin tiempo ni vida
fuera del archivo—. La jornada le da cuerpo: **una vuelta es una vida laboral**,
y la memoria fantasma de #46 (las cartas que recuerdas de vueltas anteriores)
deja de ser una regla rara para ser lo obvio.

El ciclo es `archivo → trayecto → casa → sueño → archivo`, y cada tránsito es
un acto: salir de la oficina **ficha y cobra**, meterse en la cama **paga el día
y cuenta una noche más de gato**.

**El día tiene un tope de acciones** (`ACCIONES_POR_DIA`), y es lo que hace que
la capa exista: sin él, lo óptimo sería no salir nunca de la oficina y cerrar
los ocho expedientes el primer día. Abrir un documento que no habías mirado hoy
gasta una; **releer es gratis**, porque cobrar por volver a un documento
castigaría justo lo que el juego pide hacer. Lo que se decide con esto no es
leer deprisa sino QUÉ leer.

### El gato

Es **el único ser vivo del juego**, y por eso es lo único que no está hecho de
cajas: `guion/malla_organica.gd` construye tubos a lo largo de una espina —un
lomo que se estrecha, cuatro patas, dos orejas de punta (un tubo cuyo último
radio es cero) y una cola que se curva—, con siete lados por anillo, que es la
misma decisión que las texturas de 64 píxeles. Una oficina de cajas es una
oficina de 1998; un gato de cajas es un gato de cajas.

**Se comporta, y de ahí se deduce cómo le has tratado** (`gato_conducta.gd`).
No hay barra ni aviso: bien comido se acerca a ti —la única recompensa que da
el juego por cuidarlo—, y con hambre se queda junto al cuenco con la cola
tensa. Deja de venir **un día antes** del límite de paciencia, así que la señal
llega a tiempo de arreglarla en vez de anunciar algo que ya ha pasado. Hay
prueba de esa desigualdad, que es la que hace que sea una señal.

Se le da de comer **acercándose al cuenco**, como todo lo demás en este juego:
no hay menú ni inventario. La lata se paga (`PRECIO_COMIDA_GATO`), cuesta menos
que vivir un día y un cuenco ya lleno no cobra dos veces.

**El gato no es estado de la vuelta.** Sobrevive a que te reasignen, porque es
tuyo y no del trabajo: si lo cuidaste sigue ahí en la vida laboral siguiente, y
si se fue no vuelve. Acaba siendo lo único cálido del registro permanente, al
lado de las cartas que recuerdas de vueltas anteriores (#46). La economía paga por CERRAR expedientes, no
por acertar — el juego ya declara que no hay sospechoso correcto, y pagar por
acertar desmontaría la sátira. El gato no se muere: si lo desatiendes, un día no
está.

Las tres piezas no se mezclan: `guion/jornada.gd` es el ciclo y la economía
(puro), `guion/espacios_catalogo.gd` declara los sitios y `guion/espacio_3d.gd`
los construye sin conocer el nombre de ninguno. Un sitio nuevo es una entrada
más del catálogo.

La geometría es cajas a propósito, no un placeholder esperando arte: es el mismo
argumento que la tipografía sin suavizar. Y los techos van **emisivos** porque
la luz del motor viene de arriba, así que la cara inferior de un techo está
siempre en el mínimo y salía negra por construcción.

## El sueño

La tercera parte del ciclo. **No es aleatorio: es el archivo devuelto deforme**
(#79). La semilla sale del día y de lo leído ESE día (`jornada.leido_hoy`), así
que dos días distintos sueñan distinto y el mismo día repetido sueña lo mismo —
un sueño que cambiara al recargar la partida sería un generador de ruido con
otro nombre.

Tres escenas por noche (`Sueno.noche`), lo nuevo primero, y el mapa crece con lo
que se pisa. La salida **no se ve** (#90): lo que impide que sea una lotería no
es una marca, es el mapa, que la segunda vez que te toca una sala ya sabes por
dónde se salía. La noche tiene reloj, y si se acaba se despierta de golpe: el
único castigo es que las salas de esa noche no quedan en el mapa.

Lo que amuebla las salas (#87) sale de lo leído: las frases gatillo que **sí**
notaste escritas en las paredes —escribir la que se te pasó sería decirte dónde
mirar, y dormir pasaría a ser lo óptimo— y los sospechosos de esos expedientes
como figuras, con **el que firmaste de otro color**.

### Los combates oníricos (#88)

Y con el que firmaste se puede pelear, acercándose a él. El motor es el mismo
`Combate` de siempre en modo `reactiva` —contesta a tu última jugada, se puede
cebar, que es lo que es discutir con uno mismo—, con las cargas de habilidad de
la partida política.

**Solo contra los que acusaste.** El sueño como conciencia: te persigue lo que
hiciste, no lo que había. Una partida donde no has firmado a nadie no tiene
combates oníricos, y eso está bien.

Y a diferencia del careo —donde el veredicto ya está firmado y el duelo no lo
cambia—, aquí **sí hay consecuencias**, que es su razón de existir:

- **Ganar devuelve una vida**, con el tope de la dificultad, y al vencido no se
  le vuelve a ver: la sala donde estaba está vacía la próxima vez. Es la
  consecuencia que se ve sin texto que la explique.
- **Perder corta la noche** — se despierta de golpe, con lo que eso cuesta. No
  cuesta además una vida: ya te costó una firmarlo mal, y cobrar dos veces por
  el mismo acusado convertiría dormir en un riesgo que se esquiva no durmiendo.

`guion/sueno_combate.gd` es quién y qué pasa (puro), `guion/sueno_duelo.gd` la
pantalla. El motor no se tocó.

## Assets

`assets/` está vacío y **ya vigilado**: `procedencia.json` exige ficha con
sha256 para todo lo que entre, y la prueba lo comprueba en las dos direcciones
—ni ficheros sin ficha ni fichas sin fichero—. La disciplina existe desde antes
del primer asset, que es la única forma de que no se documente "luego".

## Qué cambia respecto al backend Java

**El contenido deja de ser código.** `DataSeeder.java` eran 1.443 líneas de
setters; ahora es `casos.json`, y escribir un caso nuevo no recompila nada. La
extracción está verificada contra las llamadas `.save()` del original: 8 casos,
32 registros, 35 pistas, 27 sospechosos, 16 conceptos, 0 referencias sin
resolver.

**Los tres servicios de texto se funden en uno.** `HotspotService`,
`CartaOcultaService` y `WikiLinkService` hacían lo mismo —encontrar una frase y
envolverla en marcado— y se encadenaban, cada uno sobre la salida del anterior.
`CartaOcultaService` llegaba a hacer `indexOf` sobre HTML ya generado, así que
una frase que cayera dentro del marcado lo partía. Aquí `marcas.gd` devuelve
*dónde* están las marcas y `bbcode.gd` decide *cómo* se pintan, así que el
solapamiento se resuelve una vez y explícitamente (gana la que empieza antes).

**`ProgresoService` adelgaza.** `pistasPorCaso` y la variante de `progreso` que
reutilizaba el mapa existían para evitar un N+1 de consultas SQL. Sin base de
datos no hay consulta que evitar. La regla que sí se conserva: el progreso no se
guarda en el caso, se deriva de las pistas descubiertas.

**El escapado cambia de carácter y de sitio.** En HTML el peligro era `<` y cada
servicio escapaba por su cuenta; en BBCode es `[`, y se escapa una sola vez,
solo en el texto plano.

## El visor

`escenas/visor.tscn` + `guion/visor_expediente.gd` es la pantalla que decide si
Godot sirve para este juego: un `RichTextLabel` con BBCode donde la frase
gatillo es pulsable dentro del texto corrido, y queda resaltada al descubrirse.
Sustituye a `caso.html` + `documento-viewer.js` + `legacy-documentos.js`.

El aspecto de los 90 es `guion/estilo_siga.gd`, port de `legacy-theme.css`. Lo
que en CSS eran `border-style: outset` e `inset` aquí se DIBUJA, porque un
`StyleBoxFlat` solo admite un color de borde y el bisel necesita dos: la luz
arriba y a la izquierda, la sombra abajo y a la derecha. Invertirlas es toda la
diferencia entre un botón y un hueco.

Lo que más delata la época no es la forma de la letra sino el **suavizado**:
con antialiasing y posicionamiento subpíxel el texto se ve contemporáneo aunque
el marco sea gris con biseles. `EstiloSiga.tema()` los apaga y fuerza el
hinting, así que los trazos caen en la rejilla de píxeles. Las fuentes se piden
al sistema por nombre y con degradación (`MS Sans Serif` → `Tahoma` → lo que
haya), para no traer al repositorio ni un fichero de fuente. El cuerpo de un
documento va monoespaciado: es el volcado de un sistema de texto, no una página
maquetada.

Para verlo sin abrir el editor:

```bash
xvfb-run -a godot4 --path godot --script pruebas/capturar.gd -- visor.png 1     # sin descubrir
xvfb-run -a godot4 --path godot --script pruebas/capturar.gd -- visto.png 1 1   # descubierta
```

Mirar la captura ya ha pagado su coste: encontró que el año salía como
"Expediente 1999.0" (los números del JSON llegan en coma flotante) y que el
documento abierto quedaba en blanco sobre blanco en la lista. Ninguna prueba de
las 44 veía ninguno de los dos.

## Estado del port: lógica, interfaz y evidencia (#163)

Esta matriz separa tres cosas que no deben confundirse: que una regla exista,
que la pantalla la use y que haya una prueba que lo demuestre. El estado se
refiere a `main`; los PR abiertos se indican como pendientes y no como trabajo
integrado.

| Área | Lógica implementada | Interfaz conectada | Evidencia disponible | Pendiente |
| --- | --- | --- | --- | --- |
| Casos y visor | Sí: contenido, marcas, progreso y lecturas | Sí: visor SIGA | Suite Godot y capturas headless | Playtesting humano completo |
| Formulario A-7 | Sí: acusación, veredicto y coste de acciones | Sí: formulario de firma | Suite Godot | Careo desde la firma (#75) |
| Persistencia | Sí: escritura atómica, versión y reintentos; H1 integrado por #203 | Parcial: la validación estructural de H5 sigue en #190 | Suite Godot y regresiones de guardado | Integrar H5 (#190) y completar playtesting |
| Jornada y día | Sí: acciones, tránsito, casa, sueño y gato | Sí: escenas del ciclo | Suite y recorrido headless | Playthrough completo y pruebas con hardware |
| Sueño | Sí: salas, semilla, lecturas y reloj; H2/H3 integrados por #166 | Sí: entrada y salida de la noche | Suite y recorrido | Validar experiencia visual con playtesting |
| Careo | Sí: cinemática, combate y consecuencias | Parcial en `main`: escena disponible, conexión A-7 en #75 | Suite aislada del combate | Integrar #75 y probar victoria/derrota |

### Qué significa “evidencia”

- **Suite** demuestra reglas y estados límite; no demuestra que una pantalla sea
  legible ni que el flujo sea cómodo.
- **Recorrido** demuestra que varias escenas pueden encadenarse en headless; no
  sustituye una partida completa con teclado, mando y ratón.
- **Capturas** sirven para inspección visual puntual; no demuestran persistencia.
- Un PR abierto no cuenta como integrado hasta que su CI esté verde, se revise y
  llegue a `main`.

La matriz debe actualizarse cuando un PR cambie de estado. En la revisión actual de #163,
H1, H2 y H3 están integrados; H4 continúa en #75 y H5 en #190. No es una promesa
de cobertura ni un sustituto del playtesting de #9.

## Lo que este corte NO incluye

- La **interfaz** de Prometeo. Sus reglas sí están portadas (`guion/prometeo.gd`,
  port de `prometeo-logic.js`: fusión con lo guardado, tarot, acusación
  precipitada, ejes políticos, el rival del duelo, rachas y el borrado de una
  vuelta), con sus 33 comprobaciones traídas del Vitest — incluida la invariante
  anti-moralizante de #45, que exige que cada ideología sea útil en exactamente
  4 de las 8 cartas. Lo que falta son las 3.181 líneas de DOM de `prometeo-ui.js`.
- El corcho de conceptos y la acusación: sin pantalla todavía.
- El duelo del caso 6: usa el mismo motor que la Ventanilla, pero necesita
  poder llegar al caso 6 y hoy solo se llega al caso 1.
- Sonido. La Ventanilla se mueve pero no suena.
- El relato de las cartas ocultas: el visor acusa el hallazgo y nada más.
- La persistencia. Un `Descubrimiento` era una fila; aquí habrá que decidir
  dónde vive la partida guardada.
