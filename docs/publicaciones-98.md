# Publicaciones físicas de 1998 (#674)

La implementación se divide en contratos pequeños: catálogo/lectura persistente por un lado y presentación por otro. No abre una segunda economía ni duplica el sistema de semillas culturales.

## Qué queda implementado

`Publicaciones98` declara siete publicaciones originales y ficticias:

- `revista_umbral_98`: misterio barato, comprable en el quiosco;
- `libro_popol_wuj_98`: cuaderno cultural k’iche’/Popol Wuj, comprable en el quiosco;
- `periodico_tarde_98`: prensa local general, comprable en el quiosco;
- `byte_domestico_42`: informática doméstica;
- `marcador_98_deportes`: prensa deportiva;
- `estratos_ciudad_06`: arqueología/cultura urbana;
- `manual_casa_98`: guía práctica doméstica.

Todas incluyen al menos una pieza legible. `Umbral — nº 17` y `La Tarde Local` tienen tres piezas diferenciadas cada una (portada + artículos/secciones), suficiente para probar hojeado real sin maquetar una revista completa.

El contenido evita cabeceras, logos, artículos, personajes o portadas reales. La inspiración se limita a gramática editorial general de finales de los noventa.

## Economía e inventario

Las publicaciones comprables no conocen precios ni modifican saldo directamente. `Publicaciones98.comprar()` delega en `ComercioBarrio.comprar(..., "quiosco", ...)` de #676, que ya usa `Jornada.gastar()` e `Inventario` conforme a #93.

Esto mantiene una sola fuente de verdad para precio, saldo y adquisición. Los ejemplares declaran `permite_casa`, de modo que el inventario existente puede llevarlos a almacenamiento doméstico mediante `Inventario.guardar_en_casa()`.

Comprar nunca registra una semilla cultural.

## Lectura y contenido visto

El estado vive en `jornada["publicaciones_98_lecturas"]` y conserva, por publicación:

- IDs de piezas ya vistas;
- última pieza consultada.

`hojear()` solo aumenta progreso cuando la pieza es nueva. Releer una portada o artículo es idempotente y no permite fabricar progreso cultural repitiendo el mismo contenido.

## Visor de publicaciones

La interfaz de lectura ya tiene un primer vertical reusable: `VisorPublicacion` (`escenas/visor_publicacion.tscn`) presenta cualquier entrada del catálogo sin copiar su estado. Es una ventana modal y desplazable con foco inicial sobre el texto, botones navegables y cuatro tamaños de lectura acotados: 18, 22, 26 y 30 px.

Controles explícitos del segundo corte:

- `PageUp` / `PageDown`: pieza anterior/siguiente;
- flecha izquierda/derecha mientras el cuerpo tiene foco: anterior/siguiente;
- `L1/R1`: anterior/siguiente con mando;
- `A−` / `A+` o `X/Y` en mando: reducir/ampliar texto;
- `B`, `cancelar` o `ui_cancel`: cerrar;
- `A` de mando activa el botón que tenga foco.

Los botones siguen siendo controles nativos de Godot, por lo que tabulador/D-pad pueden recorrer el foco sin una ruta de navegación paralela. El cuerpo es un `RichTextLabel` con scroll y selección habilitados.

Mostrar una pieza llama a `Publicaciones98.hojear()`. Cerrar llama a `Publicaciones98.cerrar_tras_lectura()`. El visor no conoce `SemillasOniricas`, precios, saldo ni `Partida`: la presentación no puede inventar progreso, cobrar ni activar una familia por su cuenta.

## Publicaciones físicas en casa

El tercer corte conecta #674 con la acumulación doméstica ya existente de #96/#677 sin crear una segunda lista de objetos. La fuente de verdad sigue siendo `Inventario.HOME_STORAGE`: `CasaEstadoAmbiental` deriva de ahí `objetos_casa` y `CasaAcumulacion3D` materializa únicamente lo que realmente quedó guardado.

Cuando un objeto de categoría `publicacion` está en `home_storage`, su nodo físico pasa a ser un `Interactuable3D` con verbo `LEER`. Conserva en metadatos el ID, título, categoría editorial y el título de portada/primera pieza del catálogo. El raycast común de #283 puede detectarlo mediante una colisión propia.

La materialización 3D sigue siendo procedural y sin assets externos nuevos, pero ya distingue tres siluetas útiles:

- revista/cuaderno: cubierta fina, lomo y bloque de portada;
- periódico: pliego más ancho y fino con cabecera y bloque de foto;
- libro/guía: cuerpo más grueso, lomo y cubierta diferenciada.

Las siete publicaciones tienen una paleta propia estable. Por tanto, varios ejemplares pueden coexistir en los ocho anchors domésticos de #677 y conservar una lectura visual reproducible sin inventario paralelo ni contador de colección.

`DiaAcumulacionCasaApp` conecta los `Interactuable3D` recién materializados con el `VisorPublicacion` ya mergeado. Apuntar a un ejemplar guardado y usar la interacción común abre ese mismo contenido; cerrar el visor guarda la lectura mediante el dueño de la jornada. Leer desde la estantería no cobra dinero, no mueve inventario y no activa semillas fuera de las reglas de `Publicaciones98`.

## Ejemplares encontrables

El cuarto corte coloca los cuatro títulos no comprables en espacios reales sin abrir un sistema de coleccionables paralelo. Todos usan `Recogible3D` y el `Inventario` persistente de #97/#283:

- `byte_domestico_42` aparece en el primer puesto de la oficina desde el día 1;
- `marcador_98_deportes` aparece junto a la máquina de café desde el día 1;
- `estratos_ciudad_06` aparece en otro puesto de oficina desde el día 2;
- `manual_casa_98` aparece sobre el sofá de casa desde el día 1.

Al recoger un ejemplar entra en `carried`; si después se guarda con `Inventario.guardar_en_casa()`, el tercer corte lo materializa en la estantería doméstica como objeto `LEER`. Un ID ya presente en `carried` o `home_storage` no respawnea. Los cuatro hallazgos son no vendibles y no activan semillas al recogerlos.

Ignorar cualquiera de estos props no consume acciones, no bloquea la campaña y no altera la economía. `DiaPublicacionesEncontrablesApp` solo monta los props cuando sus anclas de oficina/casa existen y pide al dueño de la jornada que guarde después de una recogida válida.

## Portadas y lomos

El quinto corte elimina la divergencia visual entre un ejemplar encontrado y el mismo ejemplar una vez guardado. `PublicacionFisica3D` es ahora la única representación editorial para ambos caminos: `PublicacionesEncontrables3D` y `CasaAcumulacion3D` delegan en el mismo renderer procedural.

Cada una de las siete publicaciones conserva una cabecera ficticia y una edición corta propias. La portada física incorpora `Label3D` con cabecera y número/año; revistas y libros añaden un lomo rotulado, mientras que el periódico mantiene el pliego sin inventar un lomo que no tendría sentido. La misma representación añade cuerpos distintos para revista, periódico y guía, además de paletas estables ya usadas por el sistema doméstico.

Los rótulos son texto del mundo, no HUD: usan la fuente monoespaciada de `EstiloSiga`, no siguen a la cámara y viven pegados a la geometría. Por tanto, examinar una portada/lomo exige acercarse al objeto como a cualquier otro prop de #283. El visor sigue siendo la única capa que muestra el contenido hojeable a tamaño accesible.

El acabado no conoce `ComercioBarrio`, `Jornada`, `Inventario` ni `SemillasOniricas`; cambiar una portada no puede comprar, guardar, registrar progreso o alterar #442.

## Integración con #442

`revista_umbral_98` es el primer vertical cultural conectado al contrato onírico existente:

1. comprar/encontrar el ejemplar: **no activa nada**;
2. abrirlo y ver una pieza: **no activa nada**;
3. leer una única pieza: **no activa nada**;
4. leer al menos dos piezas distintas: deja la publicación preparada;
5. cerrar deliberadamente tras esa lectura llama a `SemillasOniricas.activar_semilla_onirica()` con `minotauro` y la fuente estable `publicacion:revista_umbral_98`.

La misma fuente es idempotente, por lo que cerrar varias veces no incrementa intensidad artificialmente.

El segundo vertical cultural es `libro_popol_wuj_98`, un cuaderno ficticio comprable en **Quiosco Avenida** durante `fase=trayecto`. Su contenido sigue los límites y fuentes documentados en [`docs/assets/popol-wuj-referencias.md`](assets/popol-wuj-referencias.md): identifica explícitamente el Popol Wuj como tradición k’iche’ y evita iconografía histórica copiada o una etiqueta «maya» genérica.

Su handshake es el mismo y no abre una vía especial:

1. comprar el cuaderno en el trayecto: **no activa nada**;
2. leer solo `portada`: **no activa nada**;
3. cerrar con una única pieza: **no activa nada**;
4. leer dos piezas distintas y cerrar deliberadamente: activa `popol_wuj` mediante #442;
5. la fuente estable es `libro:popol_wuj_98`, la misma que usa el vertical standalone de #655, por lo que una futura convivencia de ambas representaciones seguirá siendo idempotente.

El ejemplar usa el mismo `Inventario`, `VisorPublicacion`, almacenamiento doméstico y `PublicacionFisica3D` que el resto. Se materializa como cuaderno/libro con cabecera ficticia «CUADERNO CULTURAL»; no importa portadas, glifos ni ilustraciones externas.

La prensa general y el resto de publicaciones no tienen semilla por defecto: ocio y ambientación no equivalen automáticamente a contenido onírico.

## Pruebas

`godot/pruebas/pruebas_publicaciones_98.gd` verifica el contrato base en runtime: catálogo, compra reutilizada, persistencia, idempotencia y handshake con #442.

`godot/pruebas/pruebas_visor_publicacion.gd` verifica el segundo corte en Godot headless:

- apertura y foco inicial del contenido;
- navegación por `PageUp`/`PageDown`;
- navegación de mando con `L1/R1`;
- escalado de texto y topes;
- registro de piezas vistas sin duplicados;
- ausencia de activación antes del cierre;
- cierre deliberado que activa `minotauro` solo cuando corresponde;
- cierre con `B` en una publicación sin semilla;
- rechazo de IDs inexistentes.

`godot/pruebas/pruebas_publicaciones_casa_3d.gd` verifica el tercer corte:

- tres publicaciones simultáneas derivadas de `home_storage`;
- `Interactuable3D.Verbo.LEER` y colisión para el detector común;
- identidad, portada y formato conservados por ejemplar;
- revista, periódico y libro con geometría diferenciada;
- colocación determinista;
- retirada física cuando `Inventario.sacar_de_casa()` cambia la fuente de verdad.

`godot/pruebas/pruebas_publicaciones_encontrables_3d.gd` verifica el cuarto corte: catálogo no comprable, anclas reales de puesto/café/sofá, `Recogible3D`, ausencia de respawn, no venta y el flujo completo encontrar → `carried` → `home_storage` → objeto doméstico `LEER`.

`godot/pruebas/pruebas_publicacion_fisica_3d.gd` verifica el quinto corte: las seis cabeceras/ediciones, `Label3D` de portada, lomos solo donde corresponden, formatos diferenciados y colisión opcional para los ejemplares domésticos. `scripts/test_publicacion_fisica_674.py` además impide que casa y hallazgos vuelvan a bifurcar la representación.

Los tests Python asociados ejecutan estos smokes con Godot headless y comprueban que las capas de presentación no compran, cobran ni mueven objetos por su cuenta.

## Alcance pendiente

Este PR **no cierra #674**. Quedan fuera deliberadamente:

- decidir si más publicaciones alimentan #442 sin saturar el sistema cultural;
- validación humana de legibilidad, foco, tamaño físico y presentación con teclado/mando reales.

Refs #93 #96 #97 #133 #181 #283 #442 #674 #676 #677.