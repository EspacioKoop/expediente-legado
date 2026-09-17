# Publicaciones físicas de 1998 (#674)

Este corte crea el contrato común para revistas, prensa, cuadernos y guías físicas de #674 sin abrir una segunda economía ni un lector documental paralelo.

## Qué queda implementado

`Publicaciones98` declara seis publicaciones originales y ficticias:

- `revista_umbral_98`: misterio barato, comprable en el quiosco;
- `periodico_tarde_98`: prensa local general, comprable en el quiosco;
- `byte_domestico_42`: informática doméstica;
- `marcador_98_deportes`: prensa deportiva;
- `estratos_ciudad_06`: arqueología/cultura urbana;
- `manual_casa_98`: guía práctica doméstica.

Todas incluyen al menos una pieza legible. `Umbral — nº 17` y `La Tarde Local` tienen tres piezas diferenciadas cada una (portada + artículos/secciones), suficiente para probar hojeado real sin maquetar una revista completa.

El contenido evita cabeceras, logos, artículos, personajes o portadas reales. La inspiración se limita a gramática editorial general de finales de los noventa.

## Economía e inventario

Las publicaciones comprables no conocen precios ni modifican saldo directamente. `Publicaciones98.comprar()` delega en `ComercioBarrio.comprar(..., "quiosco", ...)` de #676, que ya usa `Jornada.gastar()` e `Inventario` conforme a #93.

Esto mantiene una sola fuente de verdad para precio, saldo y adquisición. Los ejemplares declaran `permite_casa`, de modo que el inventario existente puede llevarlos a almacenamiento doméstico; la representación física específica sigue perteneciendo a #96.

Comprar nunca registra una semilla cultural.

## Lectura y contenido visto

El estado vive en `jornada["publicaciones_98_lecturas"]` y conserva, por publicación:

- IDs de piezas ya vistas;
- última pieza consultada.

`hojear()` solo aumenta progreso cuando la pieza es nueva. Releer una portada o artículo es idempotente y no permite fabricar progreso cultural repitiendo el mismo contenido.

Este contrato no decide todavía la interfaz de lectura. Una futura capa visual puede presentar portada, lomo y páginas con escalado/foco adecuados sin cambiar la persistencia.

## Integración con #442

`revista_umbral_98` es el primer vertical cultural conectado al contrato onírico existente:

1. comprar/encontrar el ejemplar: **no activa nada**;
2. abrirlo: **no activa nada**;
3. leer una única pieza: **no activa nada**;
4. leer al menos dos piezas distintas: deja la publicación preparada;
5. cerrar deliberadamente tras esa lectura llama a `SemillasOniricas.activar_semilla_onirica()` con `minotauro` y la fuente estable `publicacion:revista_umbral_98`.

La misma fuente es idempotente, por lo que cerrar varias veces no incrementa intensidad artificialmente.

La prensa general y el resto de publicaciones no tienen semilla por defecto: ocio y ambientación no equivalen automáticamente a contenido onírico.

## Pruebas

`godot/pruebas/pruebas_publicaciones_98.gd` verifica en runtime:

- seis publicaciones con IDs únicos;
- dos ejemplares de quiosco comprables mediante la economía existente;
- compra idempotente y sin activación onírica;
- contenido visto persistente e idempotente;
- umbral de lectura + cierre deliberado para #442;
- fuente cultural estable e intensidad idempotente;
- una segunda publicación hojeable sin contaminación del sueño;
- rechazo de publicaciones/piezas inexistentes.

`scripts/test_publicaciones_98.py` añade regresión estructural y ejecuta ese smoke en Godot headless.

## Alcance pendiente

Este PR **no cierra #674**. Quedan fuera deliberadamente:

- interfaz de lectura con foco/escalado y navegación final por teclado/mando;
- materialización 3D específica de varios ejemplares sobre mesa/estante para #96;
- wiring de los cuatro ejemplares encontrables en escenas reales;
- portada/lomo visual final y feedback de cierre;
- decidir si más publicaciones alimentan #442 sin saturar el sistema cultural;
- validación humana de legibilidad y presentación.

Refs #93 #96 #133 #442 #674 #676.
