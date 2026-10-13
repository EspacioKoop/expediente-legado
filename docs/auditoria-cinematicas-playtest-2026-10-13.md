# Auditoría de cinemáticas y apertura — playtest Beelink, 13/10/2026

Este registro separa **código integrado**, **trabajo publicado en PR**, **uso en la escena principal** y **validación visual humana**. No confundir «planos 3D declarados» con «vídeo terminado» ni «tests verdes» con «visible y legible». El playtest #2597 describe una alpha con textos ilegibles, montaje ausente, incoherencia artística y softlocks.

## Rama `main`: infraestructura y secuencias existentes

| Familia | Fuente | Función / estado de integración |
|---|---|---|
| Prólogo de poemas | `godot/guion/epigrafes_inicio.gd` | Se ejecuta antes de créditos desde `inicio_app.gd` (#2574 merge); **fallo visual real**: texto como columna vertical. |
| Créditos y título 3D | `creditos_inicio_cinematica.gd`, `creditos_inicio.gd`, `inicio_app.gd` | Reproductor activo al entrar, **fallo humano conocido** (#795): letra pequeña, planos repetitivos. |
| Reproductor / óptica | `cinematica.gd`, `cinematica_app.gd`, `lenguaje_cine.gd`, `mesa_cinematica.gd` | Planos dinámicos 3D/2D, skip, profundidad de campo, franjas; recuperar encabezado del error `_ajustar_optica` del playtest. |
| Entrada y jornada | `entrada_cinematica.gd`, `inicio_jornada_cinematica.gd` | Transiciones 3D ligadas a fases, **no** a la apertura antes del menú. |
| Oficina → trayecto | `dia_transicion_app.gd` | Integración de fases; revisar desencadenantes, tiempo y escena real. |
| Ascensor | `ascensor_cinematica.gd` + `ascensor_3d_app.gd` | Secuencia local al ascensor, no intro. |
| Casa → sueño | `sueno_cinematica.gd`, `entrada_sueno_cinematica.gd`, `dia_cinematica_sueno_controller.gd` | Probadas técnicamente en export para #395, **no validadas por playtest humano completo**. |
| Cierre de expediente / careo | `sello_cinematica.gd`, `careo_cinematica.gd`, `duelo_remate_cinematica.gd` | Momentos propios del gameplay, no abrir automáticamente al iniciar. |
| Tarot / derrota / proyección | `tarot_cinematica.gd`, `despido_cinematica.gd`, `remate_vida_cinematica.gd`, `proyeccion_onirica_cinematica.gd`, `evaluacion_desempeno_cinematica.gd` | Guiones existentes; falta auditar rutas concretas de reproducción, skip y continuidad jugable. |
| Capturas de evidencia | `docs/validacion-cinematica-395.md`, `docs/capturas/cinematica-395-*.svg` | Dos secuencias prioritarias ejecutadas en export, **no** aceptación artística del montaje actual. |

## PRs que NO se ven en `main` (estado revisado el 13/10)

| PR | Qué contiene realmente | Problema para integrar |
|---|---|---|
| [#2577](https://github.com/EspacioKoop/expediente-legado/pull/2577) | Apertura onírica **24 planos 3D**, ~80 s; secuencia propuesta: epígrafes → montaje → créditos → menú. | **Abierta, no fusionada**. Reutiliza solamente `EspaciosCatalogo.OFICINA`, `CALLE`, `CASA`, sin monstruos/personajes específicos ni audio final. Puede ser una prueba de cámara más que una intro artísticamente resuelta. Revisar plano a plano en export antes de fusionar. |
| [#2575](https://github.com/EspacioKoop/expediente-legado/pull/2575) | Variante anterior de apertura onírica 24 planos. | Abierta aunque sustituida por #2577; **no fusionar ambas**. |
| [#2576](https://github.com/EspacioKoop/expediente-legado/pull/2576) | Efectos opt-in CRT, grano no estroboscópico, superposición tipográfica y audio. | **Abierta** y **contaminada**: también cambia `infra/feedback-deno/*` y workflow. Separar estos ficheros antes de integrar. Colisiona en `cinematica_app.gd` con #2517. |
| [#2517](https://github.com/EspacioKoop/expediente-legado/pull/2517) | Catálogo `CinematicasPsicodelicas` con **9 IDs** en el script de rama, e incluye un módulo `CinematicasPsicodelicasImposibles`. Figuras Rocketbox / sets 3D. | **Abierta**. El PR dice expresamente «sin autoplay»: no hay prueba de conexión a las fases jugadas. Muchas piezas siguen siendo geometría primitiva mezclada con packs reales. Se requiere valoración de dirección de arte. |
| [#2515](https://github.com/EspacioKoop/expediente-legado/pull/2515) | Catálogo `CinematicasUmbral` con **5 IDs** en el script de rama (expediente, SIGA, llamada, archivo, regreso). | **Abierta**. Sin autoplay ni disparadores de gameplay; predominan decorados simplificados. |
| [#2526](https://github.com/EspacioKoop/expediente-legado/pull/2526) | Soporte de `Espacio3D` para montar escenas `.tscn` completas en plató; prueba con **11 verticales de sueño**. | **Abierta**. Reutilizable para #795 pero no convierte por sí sola la apertura en 35–45 planos distintos; requiere prueba visual y secuenciación. |
| [#2535](https://github.com/EspacioKoop/expediente-legado/pull/2535) | Pantalla de créditos completa desde el menú y ajustes de letra 32/24 px. | **Abierta**. Compite sobre `inicio_app.gd` con #2577; coordinar integración y navegación por mando. |
| [#2574](https://github.com/EspacioKoop/expediente-legado/pull/2574) | Epígrafes Eliot y Dylan. | **Fusionada**; a pesar de pruebas automáticas, el Beelink mostró columnas ilegibles. |

## No atribuir al juego trabajo solo propuesto

- #2526 cita como **siguiente corte** un rodaje de 35–45 planos aprovechando verticales; verificar que exista PR/commit real antes de contarlo como entregado.
- #2517 y #2515 contienen catálogos, pero **no eventos jugables integrados**. Solo se verán cuando un sistema invoque sus IDs en un momento concreto y el reproductor funcione.
- Que `main` incluya decenas de ficheros con sufijo `_cinematica.gd` **no garantiza** que cada ruta se ejecute en el recorrido inicial.
- Los 24 planos de #2577 usan tres decorados base. No son 24 escenarios diferentes ni prueba de actuación, animación o personajes.
- `main` no tiene un directorio de clips `.mp4/.webm` para intro; las secuencias están definidas en GDScript y se renderizan en tiempo real.

## Orden operativo para recuperar el material sin provocar nuevas regresiones

1. **No añadir más cinemáticas ni mezclar PRs** hasta reconciliar #2575/#2577 y los conflictos sobre `inicio_app.gd`, `cinematica_app.gd`.
2. Revisar CI/diff y dependencias de #2526; probar una vertical real con Godot exportado. Si es seguro, preparar integración por separado.
3. Capturar #2577 **en su propia rama**, escena por escena con resolución 1920×1080, timings, cámara/objetivo visible, texto en marco y audio; corregir allí los defectos, no construir una intro alternativa.
4. Revisar la parte exclusivamente audiovisual de #2576; excluir expresamente `infra/feedback-deno/*` y `feedback-deno.yml` de esta entrega.
5. Verificar #2517 y #2515 por ID en una escena de prueba, luego definir **disparadores narrativos coherentes**, nunca autoplay indiscriminado ni sustitución del primer tutorial.
6. Probar `main` con perfil de partidas aislado y **Forward+** (el pase con Compatibility emitió errores de sombras/SSIL atribuibles a ese override). Mantener logs completos con SHA y etiquetar cada softlock.
7. Gate de aceptación humana: prólogo legible → intro narrativa que realmente se vea → créditos legibles → menú comprensible → instrucciones persistentes → SIGA → jornada → casa → sueño **sin intervención de consola**. No cerrar #9/#395/#795/#2596/#2597 antes de esa prueba.

Esta auditoría enumera **entregas localizadas**, no una afirmación de cobertura total de ramas externas, artefactos no publicados o assets locales del Beelink (acceso remoto no disponible al revisarla).


## Auditoría ampliada · audio, gráficos y UI (13/10)

Los recuentos proceden del árbol recursivo de `main` (4.163 entradas); son **archivos existentes**, no pruebas de su presentación en el build. Sin acceso al Beelink y sin grabación de una sesión no se puede verificar audible/visible.

| Área | Localizado en `main` | Integración concreta y huecos |
|---|---|---|
| Audio | **52 archivos** `godot/assets/audio/*.ogg|wav|mp3`; `sonido.gd`, `ambiente.gd`, `mezcla_audio.gd`, `musica.gd`, audio específico de varios sueños. | `dia_clima_app.gd` llama a `Ambiente.reproducir` al entrar en cada fase. `Sonido` soporta familias chip/fallback. **Pero `Musica.CATALOGO` define `"careo": ""` y `"final": ""`**: `Musica.stream()` devuelve nulo para ambos. Esto es música silenciosa por diseño del catálogo, NO un fallo de volumen o mezclador. Falta fichero musical con procedencia verificable o síntesis aprobada. |
| Gráficos | **197 archivos** `.glb/.gltf/.fbx/.obj/.tscn`, **255 imágenes** `.png/.jpg/.webp/.svg`, **21 shaders**. | `efectos_ligeros.gd` monta lluvia, polvo, chispas, charcos y vapor, llamado desde `dia_clima_app.gd`. `inicio_diorama_3d.gd` crea fondo 3D de menú con CRT. Diversas escenas y modelos están presentes, pero pueden verse como placeholders o quedar sin montar. Evaluar modelos y materiales en contexto real, no por nombre de fichero. |
| Interfaz | **10 fuentes** empaquetadas, **43 scripts** relacionados con HUD, OS98, menú, visores y presentación. | `EstiloSiga.tema().default_font_size = 14`; `EstiloJuego.tema().default_font_size = 16`; `inicio_app.gd` asigna 16 px a cabecera y 380×40 a botones. Son **datos del código** compatibles con la queja de texto minúsculo. `dia_onboarding_app.gd` solo enseñaba pista del puesto en primera visita y la retiraba al abrir SIGA: no había guía persistente del objetivo al cambiar de fase. La rama de esta auditoría incluye corrección aislada y no integrada aún. |

### Cambios de audio/UI/arte que **sí** llegaron a `main` (no reimplementarlos a ciegas)

- [#2309](https://github.com/EspacioKoop/expediente-legado/pull/2309) — enrutado chip con fallback, fusionada en lugar de #2304 (cerrada sin merge).
- [#2288](https://github.com/EspacioKoop/expediente-legado/pull/2288), [#2275](https://github.com/EspacioKoop/expediente-legado/pull/2275), [#2246](https://github.com/EspacioKoop/expediente-legado/pull/2246), [#2347](https://github.com/EspacioKoop/expediente-legado/pull/2347), [#2355](https://github.com/EspacioKoop/expediente-legado/pull/2355) — foley y eventos chip integrados; verificar disparadores y balance audible.
- [#2418](https://github.com/EspacioKoop/expediente-legado/pull/2418) — pasos y audio común movidos a presentación de jornada.
- [#1760](https://github.com/EspacioKoop/expediente-legado/pull/1760) y [#1469](https://github.com/EspacioKoop/expediente-legado/pull/1469) — pulido de menús y escalado de 4K; **el pase 1080p real los contradice**, revisar jerarquía de tamaños y reversiones posteriores.
- [#1367](https://github.com/EspacioKoop/expediente-legado/pull/1367), [#1401](https://github.com/EspacioKoop/expediente-legado/pull/1401), [#1735](https://github.com/EspacioKoop/expediente-legado/pull/1735) — contraste de menús y HUD contextual con tests de prioridad. Falta gate de lectura visual.
- [#1380](https://github.com/EspacioKoop/expediente-legado/pull/1380), [#1382](https://github.com/EspacioKoop/expediente-legado/pull/1382), [#1370](https://github.com/EspacioKoop/expediente-legado/pull/1370), [#1315](https://github.com/EspacioKoop/expediente-legado/pull/1315) — partículas, props 3D PBR y ventana: integrados en código, **sin garantía de aspecto correcto en tu escena actual**.

### Qué no se debe clasificar como trabajo perdido sin investigar

- [#2326](https://github.com/EspacioKoop/expediente-legado/pull/2326) cerrada sin merge, pero [#2331](https://github.com/EspacioKoop/expediente-legado/pull/2331) sí incorporó regresión de interfaz chip. Comparar diffs antes de reabrir.
- [#2304](https://github.com/EspacioKoop/expediente-legado/pull/2304) cerrada sin merge, sustituida por la entrega fusionada #2309.
- [#2362](https://github.com/EspacioKoop/expediente-legado/pull/2362) (generador de música de careo) cerrada sin integrar: revisar si el fichero/idea fue sustituido; no asumir que existe una pista real.
- Las cinemáticas en #2515/#2517 no tienen autoplay, no aparecen automáticamente en la partida y no deben usarse como maquillaje de un tutorial roto.

### Reconciliación de trabajo necesaria

1. Extraer un manifiesto `asset → fuente/licencia → ruta → consumidor runtime → fase → pruebas/captura o escucha` para **sonido**, **materiales/modelos** y **pantallas**.
2. Asegurar que cada recurso prioritario tiene una llamada real; **si falta música**, seleccionar una pieza autorizada o solución original sin inventar licencias ni rutas. No poner una ruta inexistente en `Musica.CATALOGO` para simular integración.
3. Probar mezcla efectiva de efectos/ambiente/música en una build exportada, con umbrales de volumen y capturas espectrales o grabación; en gráficos, inspeccionar cámara, escala, coherencia de materiales y luces, incluido menú y primer espacio.
4. Corregir primero el primer recorrido. Una escena fantástica deliberada puede ser extraña, pero el jugador siempre debe poder leer instrucciones, identificar acciones y completar su objetivo.
5. Considerar #2597 un gate de producto y evitar abrir expansiones de arte/audio antes de demostrar avances jugables.


### Inventario de ramas y precisión sobre trabajo supuestamente perdido

El listado paginado de ramas devolvió **1.494 ramas remotas** (15 páginas, último lote de 94). Los nombres contienen numerosas líneas históricas de audio, arte, menú, tipografías, shaders, HUD y animaciones. **No se puede asumir que 1.494 ramas sean 1.494 cambios pendientes:** las ramas fusionadas por squash pueden conservar commits propios no alcanzables desde `main`. Un `compare_commits` que diga `diverged` o `ahead>0` tampoco prueba que el contenido no exista ya.

Muestras auditadas con comparación de commits:
- `audio/2356-careo-tracker`: diverged, 1 commit adelante, 77 detrás; afecta `scripts/laboratorio_sonoro_1475.py`. **Su función `generar_careo_tracker` y el CLI `--careo-tracker` YA ESTÁN EN MAIN** (confirmado comparando el contenido de ambos ficheros), pese a que #2362 se cerró sin merge. La parte realmente pendiente es convertir/aprobar/instalar un fichero musical bajo `assets/audio/musica`, registrar procedencia y conectarlo en `Musica.CATALOGO`, como documenta #76.
- `feature/567-menu-inicio-visual`, `feature/515-profundidad-visual-siga`, `odiseo/780-tipografia-siga-legible`, `fix/1449-menu-ancho`: ramas históricas con commits fuera de la ancestría actual y muchos commits de atraso. **Solo revisar diffs de lógica concreta**, no restaurar versiones completas porque destruiría meses de cambios.
- `feature/701-previsualizacion-personaje-3d` y `feature/779-feedback-audiovisual-rondas`: lo mismo para avatares/escenas, que podrían estar presentes bajo implementaciones fusionadas por otras PR.

**Reconciliación correcta**: para una entrega sospechosa, localizar issue/PR sustitutiva → comparar ficheros y consumidor entre rama histórica y `main` → determinar qué comportamiento no existe hoy → abrir PR de *mínimo cambio* con evidencia runtime. Nunca hacer un merge masivo de ramas antiguas.

Con esto, el diagnóstico distingue tres estados: (A) integrado pero no visible/legible; (B) aún en PR abierta, no ejecutado; (C) pieza preparada pero no activada por decisión deliberada (por ejemplo música sin OGG autorizada).
