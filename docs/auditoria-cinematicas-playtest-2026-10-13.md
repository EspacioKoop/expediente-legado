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
