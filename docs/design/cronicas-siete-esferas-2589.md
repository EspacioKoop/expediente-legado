# Crónicas de las Siete Esferas: El Hijo del Nigromante

**Concepto autorizado (2026-10-12).** RPG original de fantasía 3D que existe como videojuego ficticio de 1998 dentro de `Expediente Legado`, adquiere una contraparte en el sueño y, en el clímax, forma parte de una confrontación presentada entre capas de realidad. Issue padre: [#2589](https://github.com/EspacioKoop/expediente-legado/issues/2589).

**Estado de este corte:** contrato de presentación **aislado**, sin wiring con pantallas jugables. Ni escenas nuevas, ni juego 3D completo, ni rediseño del final. No se declara jugable Crónicas todavía. El nombre de trabajo del castillo y los personajes siguientes es provisional. El playthrough humano [#9](https://github.com/EspacioKoop/expediente-legado/issues/9) sigue siendo el gate P0.

## Identidad y autonomía

El juego ficticio cuenta la historia de una sucesión dinástica disputada por siete tradiciones rivales de memoria. No se limita a una colección de guiños a la campaña principal: cada personaje debe tener deseos propios, alianzas transformables y consecuencias narrativas dentro del programa. Deberá poder jugarse sin conocer la campaña de rol que inspira **temas** y sin conocer los secretos de SIGA-98.

Los siete ámbitos de las esferas son **borradores originales**, no siete objetos mágicos coleccionables: **nombre, testimonio, tiempo, memoria, identidad, juramento y ausencia**. Se expresarán a través de documentos contradictorios, arquitectura y decisiones, no a través de un inventario nuevo ni un sistema de niveles introducido sin justificación.

La fortaleza inicial provisional, **Bastión de los Nombres Ausentes**, tiene estancias que cambian cuando el jugador recuerda o cuestiona su nombre. Su arquitectura se diseñará nueva; no debe reproducir un mapa de campaña o una fortaleza de ninguna franquicia.

### Figuras dramáticas originales (por desarrollar)

- **El Cronista Velado:** archiva versiones rivales de un mismo conflicto; manipula el derecho a ser recordado.
- **El Guardián Sin Nombre:** la identidad más visible es precisamente la que puede ser falsa. Sus acciones permiten explorar culpa, transformación y pertenencia.
- **El Maestro del Estuario:** mentor que enseña a leer contradicciones y tiene motivos propios, no una brújula moral infalible.
- **La Heredera del Umbral:** investigadora y protagonista con agencia que rebate los testimonios oficiales y puede cambiar el curso del reino.

Estas funciones toman *inspiración de procesos narrativos* de una campaña de rol privada; no son adaptaciones literales de sus fichas, parentescos, mapas, aspecto, voces ni frases. El guion definitivo requiere auditoría de originalidad y revisión de derechos de coautores antes de publicarse.

## Matriz de lore: fuente, manifestación, límite

| Sistema canónico | Cómo aparece Crónicas | Límite y fuente de verdad |
| --- | --- | --- |
| SIGA-98 y expedientes ([#2445](https://github.com/EspacioKoop/expediente-legado/issues/2445)) | Caso verosímil de 1998 sobre procedencia editorial, un manuscrito en disputa y su traducción. Los testimonios contradictorios del RPG dialogan con documentos reales del caso. | Solo la lectura y evidencia explícita de SIGA produce hechos; el sueño y el videojuego no fabrican pruebas ni firman expedientes. |
| OS98 y Prometeo ([#539](https://github.com/EspacioKoop/expediente-legado/issues/539)) | Aplicación de entretenimiento de 1998 cuyo lenguaje gráfico aparece de manera contenida en ventanas y errores diegéticos conforme progresa la contaminación. | No simular acceso al sistema real, ni otro shell, ni otro handoff; `ClimaxOs98Controller` continúa iniciando el clímax existente. |
| Vida doméstica, tiempo, precariedad y gato ([#61](https://github.com/EspacioKoop/expediente-legado/issues/61), [#787](https://github.com/EspacioKoop/expediente-legado/issues/787)) | Jugar es una actividad voluntaria de ocio; el ánimo del protagonista y sus relaciones pueden matizar descripciones, sin alterar las obligaciones materiales del día. | El RPG no crea una segunda economía, reloj, alimentación, afecto ni progreso autónomo de `Partida`. |
| Sueños y memoria ([#79](https://github.com/EspacioKoop/expediente-legado/issues/79), [#442](https://github.com/EspacioKoop/expediente-legado/issues/442)) | Interactuar realmente con el juego activa su semilla onírica cuando se integre, y abre arquitecturas deformadas de escenas **ya vistas**. | No entrar en sueños nuevos solo por tener el juego instalado; conservar selección determinista y frontera memoria/evidencia. |
| Mitologías ([#435](https://github.com/EspacioKoop/expediente-legado/issues/435)) | Ecos visuales y reglas espaciales reconocibles; temas como juramento, legado, memoria y destino sin reciclar personajes de tradiciones concretas. | No apropiarse de símbolos rituales de culturas vivas ni confundir mito, ideología o verdad documental. |
| Ideologías y decisiones ([#915](https://github.com/EspacioKoop/expediente-legado/issues/915)) | Reinos que disputan quién puede definir la historia. Una misma acción tiene lecturas sociales contradictorias. | No crear un medidor político alternativo ni imponer un eje ganador universal. |
| Castellanía, combate y mando ([#284](https://github.com/EspacioKoop/expediente-legado/issues/284), [#1752](https://github.com/EspacioKoop/expediente-legado/issues/1752), [#1771](https://github.com/EspacioKoop/expediente-legado/issues/1771)) | Reusar navegación, esquiva, `JuicioCombate3D`, cámara y enemigos existentes en una sección original del castillo. | No copiar mapas o assets y no levantar un segundo sistema de combate/vida. |
| Final de Hastur ([#1103](https://github.com/EspacioKoop/expediente-legado/issues/1103), [#9](https://github.com/EspacioKoop/expediente-legado/issues/9)) | Montaje intercalado de OS98, sueño, Crónicas y vigilia; cada plano refleja la **misma** decisión/combate. | `ClimaxHastur` es la única autoridad de fase, vida, victoria, derrota y veredicto; el final político sigue su pipeline actual. |
| Ecos entre jugadores ([#374](https://github.com/EspacioKoop/expediente-legado/issues/374), [#382](https://github.com/EspacioKoop/expediente-legado/issues/382)) | Posibles mensajes o sombras de otras memorias **en el futuro**. | Offline primero; la meta comunitaria permanece desactivada antes de 1.0. |

Una referencia solo entra si ofrece *fuente previa visible → transformación jugable → efecto o lectura contextual → prueba de continuidad*. No añadir cameos por catálogo ni resolver respuestas fuera del expediente.

## Arquitectura del clímax: montaje que no decide

El clímax existente ya usa `ClimaxHastur`. La clase nueva `CronicasSieteEsferasMontaje` (en `godot/guion/cronicas_siete_esferas_montaje.gd`) consume el estado canónico *sin mutarlo* y construye un **plan de presentación**:

- Siempre incluye **OS98** y **vigilia** cuando existe un clímax en fase presentable: fallback obligatorio para quien no haya jugado Crónicas.
- Incluye **sueño** solo si la interacción y el recuerdo onírico se han verificado previamente.
- Incluye **Crónicas** solo si la persona realmente jugó a ese videojuego ficticio.
- El orden de capas es fijo: **OS98 → sueño (opcional) → Crónicas (opcional) → vigilia**.
- Usa `ClimaxHastur.estado_actual(estado, jornada)` para respetar la vuelta; no inventa clímax si no existe.
- Los modos `combate`, `transicion` y `epilogo` **representan** la fase existente. No cambian `Combate`, `SuenoCombate`, vidas, economía, firmas, cartas, veredicto ni final político.
- La fase interrumpida no genera un nuevo combate. Recargar el juego no puede duplicar el clímax.
- La presentación podrá insertar golpes jugables en el reino como **retroalimentación audiovisual de acciones canónicas** cuando haya pruebas de seguridad. No son un segundo resultado de batalla.

**Importante:** `visitas_verificadas` es un contrato de entrada, no un nuevo guardado. No se considera seguro cablearlo hasta encontrar quién registra el juego realmente ejecutado y quién registra el sueño observado en las fuentes actuales. Nunca inferirlo del hecho de poseer un icono o un libro, ni permitir que el jugador se salte SIGA.

## Primera vertical y corte siguiente

Un corte jugable de **12–20 minutos**, solo después de comprobar rutas y reservar ficheros, debería ofrecer:

1. Interacción en una superficie de ocio diegética ya existente para iniciar Crónicas, con nombre y controles originales.
2. **Tres estancias y un patio** de la fortaleza con disposición inédita, puzle de identidad/documento y salida reconocible; sin mundo abierto.
3. **Dos encuentros** con arquetipos ya implementados. Sin XP ni loot adicional, con esquiva/telegraphs legibles para teclado y mando.
4. Diálogo entre dos de las figuras originales donde las opciones son interpretaciones diferentes, no verdad documental.
5. Retorno claro a la vigilia; la semilla onírica exige juego realmente efectuado y solo transforma contenido previamente visto.
6. Validación reproducible de guardado/carga, salida por sueño, 1920×1080 y rendimiento en Beelink; Steam Deck como equipo de prueba posterior.

No conectar ninguna de esas piezas a `main` sin un PR específico y aprobación de integración: primero estudiar `main` vigente y `#1713` para evitar solapes.

## Tests del corte actual

`godot/pruebas/pruebas_cronicas_siete_esferas_2589.gd` protege:

- ausencia de montaje sin clímax oficial;
- fallback canónico con dos capas sin jugar Crónicas;
- cuatro capas solo al verificarse las dos visitas;
- no promover visitas falsas ni modificar estado/contexto;
- determinismo entre llamadas sucesivas;
- frontera de vuelta y epílogo sin recombate;
- interrupciones sin clímax alternativo.

Ejecución aislada desde raíz: `godot4 --headless --path godot --script res://pruebas/pruebas_cronicas_siete_esferas_2589.gd`. Este contrato **todavía no representa ni valida gráficamente** las escenas, el combate 3D o la UX.

## Auditoría de procedencia y privacidad

La campaña privada de rol y otros videojuegos sirven para estudiar **relaciones dramáticas abstractas, exploración y técnica de diseño**, no como fuente reutilizable de contenido. No copiar imágenes, personajes, nombres distintivos, diseños, biografías, iconografía, mapas, fichas, redacciones, reglas patentadas/protegidas, modelos, música ni código de campañas, suplementos o decompilaciones. Tampoco volcar wiki privada de Notion, partidas, identificadores personales o secretos a este repositorio público. Cambiar solo nombres o un porcentaje arbitrario **no elimina** por sí solo el riesgo de similitud sustancial.

Antes de arte/guion final hay que catalogar qué es original del creador, qué es creación de participantes con derechos propios, qué es contenido de terceros y qué pertenece al dominio público. El tratamiento de Hastur reutiliza solamente el canon propio que **ya tiene Expediente Legado**, sin incorporar material expresivo exclusivo de adaptaciones externas.

## Pendientes verificables

1. Inventariar en `main` interfaces de juego de PC, activación de `SemillasOniricas`, persistencia `Partida`, punto de inserción de `ClimaxHasturPanel` y sistema de cinematografía, sin modificarlos en este PR.
2. Identificar productores reales para `cronicas_jugadas` y `sueno_cronicas_visto`; fijar pruebas de que no son arbitrarios antes de cablear UI.
3. Crear vertical 3D en rama separada con un corte real y pruebas de comportamiento; reservar sus archivos en #1713.
4. Montar presentación multicapa opt-in sin alterar victoria/derrota/handoff actual y probar save/reload + reducción de movimiento + subtítulos.
5. Playtest humano E2E #9 y revisión de originalidad/licencias. Cerrar esta fase **solo** con evidencia, no por añadir módulos.
