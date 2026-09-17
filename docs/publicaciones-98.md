# Publicaciones físicas de 1998 (#674)

La implementación se divide en contratos pequeños: catálogo/lectura persistente por un lado y presentación por otro. No abre una segunda economía ni duplica el sistema de semillas culturales.

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

Esto mantiene una sola fuente de verdad para precio, saldo y adquisición. Los ejemplares declaran `permite_casa`, de modo que el inventario existente puede llevarlos a almacenamiento doméstico; la representación física específica sigue perteneciendo a #96/#677.

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

## Integración con #442

`revista_umbral_98` es el primer vertical cultural conectado al contrato onírico existente:

1. comprar/encontrar el ejemplar: **no activa nada**;
2. abrirlo y ver una pieza: **no activa nada**;
3. leer una única pieza: **no activa nada**;
4. leer al menos dos piezas distintas: deja la publicación preparada;
5. cerrar deliberadamente tras esa lectura llama a `SemillasOniricas.activar_semilla_onirica()` con `minotauro` y la fuente estable `publicacion:revista_umbral_98`.

La misma fuente es idempotente, por lo que cerrar varias veces no incrementa intensidad artificialmente.

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

`scripts/test_publicaciones_98.py` y `scripts/test_visor_publicacion_674.py` añaden regresión estructural y ejecutan los smokes con Godot headless.

## Alcance pendiente

Este PR **no cierra #674**. Quedan fuera deliberadamente:

- materialización 3D específica de varios ejemplares sobre mesa/estante para #96/#677;
- wiring de los cuatro ejemplares encontrables en escenas reales;
- portada/lomo visual final como objeto físico antes de abrir el visor;
- integración del visor desde los interactuables 3D reales;
- decidir si más publicaciones alimentan #442 sin saturar el sistema cultural;
- validación humana de legibilidad, foco y presentación con teclado/mando físicos.

Refs #93 #96 #133 #181 #442 #674 #676 #677.
