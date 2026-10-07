# SIGA-98 · Playtest end-to-end #9 · 2026-10-07

Guion de una sola página para el pase humano de #9 sobre el `main` actual. Se juega con el build exportado, no desde el motor: el rendimiento y el empaquetado son los reales.

**Build:** `playtest-latest`, `main` en `35a2f362bc62c3b61194081baf661f3a43714bcf` (tras #2495). Comprobado el 2026-10-07:
- el SHA de `BUILD-INFO.txt` coincide con `origin/main`;
- el checksum es correcto;
- la build lleva `qa_tools=1`.

**Arranque comprobado en GPU real** (Intel ADL-N, Vulkan Forward+): sin `SCRIPT ERROR` y sin los errores de señales de #801. Solo salen avisos inofensivos de formato RGB8 y del cargador de Vulkan.

**Parte de incidencias (F9):** el gateway Cloudflare y el respaldo Deno responden `ok` en `/health`.

**Entrada:** teclado y ratón. El mando queda para una pasada aparte, así que **#113 y #98 no se cubren en este pase**.

Este pase no cierra por sí solo ningún gate: cada casilla es una observación humana que se traslada a su issue.

## Antes de empezar

- Lánzalo con un perfil de datos aislado, para que tus partidas no se toquen y el registro de consola quede guardado para el triaje.
- **Apertura de créditos (#795): fallo conocido.** Los nombres salen en letra pequeña en la franja inferior, y 11 planos casi iguales parecen la misma cinemática repetida. Se rehace como montaje de localizaciones y personajes distintos (ver #795). Sáltala con **Enter** o **Esc**.

## Controles

| Acción | Tecla |
| --- | --- |
| Moverse | W A S D (correr: Shift; agacharse: Ctrl; saltar: Espacio) |
| Mirar | Ratón |
| Interactuar | E |
| Inventario | I |
| Cancelar / menú | Esc |
| Parte de incidencias (incluye el SHA del build) | F9 |
| Consola de QA | º |

**Si algo bloquea, la consola de QA ayuda a seguir.** Apunta antes qué pasó.

| Comando | Para qué |
| --- | --- |
| `estado` | Jornada, sueño, guardado y rivales |
| `desatascar` | Vuelve a la entrada del espacio |
| `guardar` | Fuerza el guardado |
| `fase archivo\|trayecto\|casa\|sueño` | Cambia de espacio |
| `sueno <s>` | Ajusta el tiempo de sueño |
| `diagnostico` | Semilla para reproducir |

Usar la consola invalida el tramo afectado como prueba end-to-end. Anótalo junto a la casilla.

## Recorrido canónico (#9)

En cada paso, entre corchetes, los gates humanos que toca. Marca la casilla solo si se pudo hacer **sin consola**.

1. [ ] **Nueva partida**: ¿se entiende el archivo, el puesto y la primera acción sin contexto previo? *[#395 cinemáticas 3D, #398 identidad del espacio, #399 materiales, #397 HUD]*
2. [ ] **SIGA**: abrir y leer un expediente; probar relaciones, marcadores, metadatos y anexos. ¿El gato reacciona sin resolver? *[#431 profundidad documental]*
3. [ ] **Firmar** cuando corresponda.
4. [ ] **Careo**: llegar y resolverlo. ¿Llega el contexto descubierto? ¿El careo A-7 con habilidades es legible? *[#912 Juicio por Combate: ritmo y sensación]*
5. [ ] **Cobrar y salir** de la oficina: ascensor, y en otra pasada escaleras. ¿Los compañeros parecen personas? *[#275 NPCs]*
6. [ ] **Trayecto hasta casa**: exterior, profundidad urbana, comercios con horario. *[#398, #119 ambiente sonoro]*
7. [ ] **Decisión doméstica** relevante: cómoda, objetos, teléfono, gato.
8. [ ] **Dormir y entrar en el sueño**: ¿se entiende la transición casa → sueño? *[#395]*
9. [ ] **Reconocer solo información ya vista** durante el día. Nada inventado.
10. [ ] **Objetivos oníricos 0/2 → 1/2 → 2/2** sin salida física oculta. Si aparece combate onírico, probar esquiva, postura y objetivo. *[#1889 combate contextual]*
11. [ ] **Despertar y continuar** la jornada (ecos al despertar).
12. [ ] **Vencimiento del alquiler.**
13. [ ] **Pagar o sufrir el impago.**
14. [ ] **Guardar, cerrar el juego, volver a abrir con Continuar**: día, dinero, acciones, firmas, vivienda y consecuencias deben persistir.
15. [ ] Continuar hasta **clímax/final** (Hastur y cierre político), si se llega.

## Novedades desde el último playtest local (2026-09-24)

Son 981 commits. Lo que puede aparecer en el recorrido:

- **Combate onírico:**
  - arquetipos nuevos: Embestidor, enjambre, Constructor, Gárgola, Mimético y Falso Luminar;
  - esquiva perfecta, *soft-targeting*, postura y *stagger*, magnetismo cuerpo a cuerpo;
  - arenas 2+1;
  - combate contextual con props (volcar, empujar).
- **Oficina viva:** impresora atascada, ventana floja, palanca calzada y cultura institucional cotidiana.
- **Careo A-7** con habilidades.
- **Sueño:** mutadores nocturnos, ecos efímeros al despertar y selector determinista de habitaciones (#2486).
- **Foley chip sintetizado:** papel, archivador, teclado, eventos CRT.
- **OS98 y minijuegos:**
  - Rebote Postal 98, Turno Serpiente 98 y ARIADNE 98;
  - accesibilidad del shell, la Ventanilla, la calculadora y el bloc;
  - el menú OS98 ya no invade la barra de tareas (#781).

## Cómo anotar

- **Bloqueo o regresión:** F9 en el momento, con una frase de qué esperabas.
- **Impresión o sensación** (ritmo, legibilidad, «no entiendo qué hacer»): una nota corta con el número de paso.
- **Al terminar:** las notas, los F9 y el registro de `registros/` se convierten en issues de un solo fichero con plan delegado para el pool. Así cada fallo encontrado entra directamente en la cola.
