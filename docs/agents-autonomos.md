# Agentes autónomos: autopilot, pool, Qwen + Gemini

El repositorio puede convertir issues autorizados en PRs draft usando Qwen Code o Gemini CLI sin entregar al modelo credenciales de push. La cola operativa entra por el dispatcher paralelo de hasta seis workers; `agent-autopilot.yml` se conserva como entrada manual para ejecutar un issue concreto.

## Configuración mínima

Una vez fusionados los workflows, solo hacen falta las claves de los proveedores.

### Gemini

1. Abre Google AI Studio → **API Keys**.
2. Crea o copia una API key válida para Gemini.
3. En este repositorio abre **Settings → Secrets and variables → Actions → New repository secret**.
4. Nombre: `GEMINI_API_KEY`.
5. Pega la clave como valor y guarda.

### Qwen

`QWEN_API_KEY` puede apuntar al proveedor configurado para Qwen Code. Con `QWEN_BASE_URL` y `QWEN_MODEL` se puede usar un backend OpenAI-compatible como FreeInference; si esas variables no existen, el workflow conserva la detección de Alibaba Cloud.

El workflow detecta automáticamente dos tipos habituales de clave:

- **Model Studio / DashScope internacional**: claves `sk-...`; usa el endpoint internacional compatible con OpenAI.
- **Coding Plan internacional**: claves `sk-sp-...`; usa automáticamente el endpoint de Coding Plan.

Pasos:

1. Abre Alibaba Cloud Model Studio / Qwen Code y crea o copia la API key.
2. En este repositorio abre **Settings → Secrets and variables → Actions → New repository secret**.
3. Nombre: `QWEN_API_KEY`.
4. Pega la clave como valor y guarda.

No pegues ninguna key en issues, comentarios, archivos, variables públicas ni logs.

Si solo configuras una clave, `agent:auto` usa ese proveedor. Con ambas disponibles, `agent:auto` prioriza Qwen; `agent:gemini` fuerza Gemini y `agent:qwen` fuerza Qwen.

### OmniRoute privado como backend preferente

El autopilot puede usar una instancia local de OmniRoute como primer backend de Qwen sin publicarla en Internet. El runner hospedado por GitHub entra en la tailnet con un nodo efímero usando OIDC, accede a `Tailscale Serve` por HTTPS privado y Serve reenvía únicamente al loopback de OmniRoute.

Configuración del repositorio:

| Tipo | Nombre | Uso |
| --- | --- | --- |
| Secret | `OMNIROUTE_API_KEY` | API key de endpoint creada en OmniRoute; no usar la contraseña del dashboard |
| Variable | `OMNIROUTE_BASE_URL` | URL privada Tailscale terminada en `/v1` |
| Variable | `OMNIROUTE_MODEL` | Modelo, alias o combo de OmniRoute; recomendado: `autopilot-code` |
| Secret | `TS_OAUTH_CLIENT_ID` | Client ID de Tailscale |
| Secret | `TS_OAUTH_SECRET` | OAuth secret preferente para el tag `github-autopilot` |
| Secret | `TS_AUDIENCE` | Audience usada solo como fallback OIDC |

El workflow usa `tailscale/github-action@v4` con `tag:github-autopilot`. OAuth (`TS_OAUTH_CLIENT_ID` + `TS_OAUTH_SECRET`) tiene prioridad; OIDC (`TS_OAUTH_CLIENT_ID` + `TS_AUDIENCE`) queda como fallback. Si Tailscale falla, OmniRoute se marca como no disponible y el worker continúa por los backends directos. La policy de la tailnet debe permitir al tag únicamente TCP/443 hacia el equipo que ejecuta OmniRoute. No usar Tailscale Funnel ni abrir los puertos 20128/20130/20131 en el router.

En la máquina que aloja OmniRoute, publica únicamente el puerto API local mediante `tailscale serve --bg http://127.0.0.1:<puerto>`, usa la URL MagicDNS resultante terminada en `/v1` como `OMNIROUTE_BASE_URL` y restringe la policy para que `tag:github-autopilot` solo pueda alcanzar TCP/443 de ese equipo.

Para varias cuentas de un mismo proveedor, mantener cada cuenta como conexión separada en OmniRoute. Un `429` debe enfriar solo esa conexión, permitiendo que las demás sigan disponibles. En Dashboard → Settings → Resilience conviene habilitar Rate Limit Auto-Detection y respetar los hints de `Retry-After`. Para cuentas free o con límites inciertos, empezar con `Max Concurrent Requests = 1`; si el proveedor publica un RPM conocido, usar un objetivo conservador y derivar `Min Time Between Requests ≈ 60000 / RPM_objetivo`. Subir concurrencia únicamente después de observar estabilidad.

Para el combo `autopilot-code`, usar solo modelos que soporten correctamente las herramientas requeridas por Qwen Code. `Least-Used` reparte carga entre candidatos; `Priority` es preferible si se quiere agotar primero una suscripción principal y usar el resto solo como fallback.

Orden efectivo del worker Qwen:

`OmniRoute privado → Qwen directo → fallback 1 → fallback 2 → fallback 3 → fallback 4`.

Si el equipo local, Tailscale u OmniRoute no están disponibles, el workflow continúa automáticamente por la cadena directa.

### Smoke aislado de proveedores

`.github/workflows/agent-provider-smoke.yml` valida cada slot sin crear trabajo ficticio ni dar permisos de escritura al modelo. El smoke usa Qwen Code únicamente con `read_file`, obliga a leer `AGENTS.md` y exige el marcador `AGENT_PROVIDER_SMOKE_OK file=AGENTS.md`.

Al integrarse o modificarse el workflow, el push a `main` comprueba automáticamente `qwen-fallback-1`. Después puede ejecutarse manualmente desde **Actions → Agent provider smoke** indicando el **número** de slot (1-12). Esto valida conjuntamente secret, URL, modelo, compatibilidad OpenAI y tool-calling básico. Un smoke verde cierra además el circuit breaker de ese slot en Deno KV, por lo que un backend recuperado vuelve a rotación sin esperar a que caduque su cooldown anterior.

### Cadena de fallback OpenAI-compatible

El worker Qwen admite hasta **12 backends de reserva** (#1685). Esto permite trasladar al repositorio conexiones de OmniRoute, FreeInference, NVIDIA u otros gateways siempre que expongan una API compatible con OpenAI y *tool calling*.

Cada slot `N` (1-12) usa:

| Qué | Dónde | Nombre |
| --- | --- | --- |
| Clave | Actions **Secret** | `QWEN_FALLBACK_N_API_KEY` |
| Endpoint | Actions **Variable** | `QWEN_FALLBACK_N_BASE_URL` |
| Modelo | Actions **Variable** | `QWEN_FALLBACK_N_MODEL` |
| Tier (opcional) | Actions **Variable** | `QWEN_FALLBACK_N_TIER` (entero ≥ 1; 1 por defecto) |
| Clave heredada (opcional) | Actions **Variable** | `QWEN_FALLBACK_N_KEY_FROM`: otro slot (`2`) o un proveedor base (`qwen`, `gemini`) |

Para añadir un slot basta con crear esas tres entradas: `scripts/agent_slots.py` descubre las variables desde `toJSON(vars)` y el worker toma la clave con `secrets[format('QWEN_FALLBACK_{0}_API_KEY', N)]`. Los secretos no se pueden enumerar, así que el pool tiene **una única tabla** (`FALLBACK_KEYS` en `agent-pool.yml`) que dice qué slots tienen clave; es el único sitio con números de slot. Para pasar de 12, añade líneas a esa tabla y sube `MAX_FALLBACKS` en el script: un test exige que coincidan.

**Tiers.** Todos los workers tienen tier: los slots con `QWEN_FALLBACK_N_TIER`, y `qwen-primary` y `gemini` con `QWEN_PRIMARY_TIER` y `GEMINI_TIER` (1 por defecto). El dispatcher agota el tier más bajo antes de usar el siguiente; dentro de un tier decide el score histórico (#1621). Así se deja de último recurso un backend flojo o caro sin quitarlo (hoy `QWEN_FALLBACK_1_TIER=2` para Cohere). La cascada de `qwen-primary` sin clave también empieza por el tier más bajo. Se pueden usar tantos niveles como se quiera.

**Más modelos y proveedores sin nuevos secretos.** Un slot sirve para cualquier proveedor compatible con OpenAI: NVIDIA, OpenRouter, DeepSeek o Gemini por `https://generativelanguage.googleapis.com/v1beta/openai/`. Para añadir otro modelo de una cuenta que ya existe, crea un slot con su URL y modelo y `QWEN_FALLBACK_N_KEY_FROM` apuntando a esa cuenta. Por ejemplo, Nemotron Ultra con la clave del slot 2 (`KEY_FROM=2`) o Gemini Flash-Lite en tier 3 con la clave de Gemini (`KEY_FROM=gemini`). `KEY_FROM` solo acepta otro slot, `qwen` o `gemini`: una variable nunca puede enviar un secret arbitrario (OmniRoute, Kev, Tailscale…) a una URL cualquiera. Todo el inventario de workers (`qwen-primary`, `gemini` y slots, con su tier) lo construye `scripts/agent_slots.py workers`.

Un slot con URL pero sin clave no recibe trabajo, así que se puede preparar el endpoint antes de tener la cuenta. Cada slot es un worker propio del pool (`qwen-fallback-N`). Si `qwen-primary` no tiene clave ni OmniRoute, usa el primer fallback con clave. Antes de confiar en un slot, valida el smoke y después un issue real con plan delegado: el smoke comprueba *tool calling*, pero no que el modelo sepa implementar.

No apuntes estos slots a `127.0.0.1` o `localhost`: los runners hospedados por GitHub no pueden alcanzar el OmniRoute local de tu PC. Para reutilizar una conexión de OmniRoute hay que copiar al repo el endpoint público del proveedor/gateway, el modelo y su key; alternativamente habría que usar un runner self-hosted con acceso a OmniRoute.

## Único ajuste de GitHub que puede ser necesario

GitHub puede impedir por política que `GITHUB_TOKEN` cree PRs. Si el primer intento implementa y hace push pero falla al abrir el draft:

**Settings → Actions → General → Workflow permissions → Allow GitHub Actions to create and approve pull requests**.

El workflow nunca aprueba ni fusiona PRs; el ajuste solo permite crear el draft. Si la organización ya lo permite, no hay que tocar nada.

## Registro de reservas activo

El registro operativo pasó de **#182** a **[#1713](https://github.com/EspacioKoop/expediente-legado/issues/1713)** al alcanzar #182 el límite de comentarios de GitHub. Los workflows deben publicar nuevas reservas en #1713 y, durante el rollover, leer también #182 para no perder reservas heredadas aún vivas.

## Cola de trabajo

Los labels se crean automáticamente al integrarse el workflow:

- `agent:auto`: cola automática, proveedor elegido por disponibilidad/Kev;
- `agent:pool`: alias compatible de la misma cola paralela;
- `agent:qwen`: cola con Qwen obligatorio;
- `agent:gemini`: cola con Gemini obligatorio;
- `agent:working`: hay una ejecución activa;
- `agent:pr-open`: ya existe un PR generado;
- `agent:needs-human`: hubo ambigüedad, conflicto, falta de configuración o se agotó la reparación automática.

Etiquetar un issue con `agent:auto`, `agent:pool`, `agent:qwen` o `agent:gemini` lo mete en el dispatcher común. El pool hace además un barrido cada 15 minutos y deduplica issues encontrados por varias etiquetas. **Agent autopilot** queda disponible desde Actions para ejecutar manualmente un issue concreto y un proveedor (`auto`, Qwen o Gemini).

### Selección automática y contexto acotado

En la cola unificada, el dispatcher consulta `scripts/kev_router.py` para obtener una **preferencia blanda** cuando no existe proveedor explícito. `agent:qwen` y `agent:gemini` son obligatorios; para `agent:auto`/`agent:pool`, si el proveedor sugerido no tiene slot libre se usa otro worker disponible. La ejecución manual de `agent-autopilot.yml` mantiene el router cuando se selecciona `provider=auto`. Sin `KEV_BASE_URL`, con timeout, baja confianza o respuesta inválida, se conserva una selección determinista.

Kev recibe únicamente título, cuerpo y labels del issue. No recibe `GITHUB_TOKEN`, secretos de proveedores, logs completos ni memorias sin filtrar.

El autopilot y el pool usan además `scripts/agent_context_pack.py`: generan un `.agent-context.md` acotado desde la wiki antes del plan y lo regeneran tras el CLAIM incorporando las rutas reservadas. La wiki completa queda como respaldo local; el pack nunca desplaza al repositorio, issue, #181/#1713 ni a las Normas Platino como fuentes de autoridad.

### Pool paralelo

El dispatcher documentado en [`agents/parallel-pool.md`](agents/parallel-pool.md) es la cola operativa común para `agent:auto`, `agent:pool`, `agent:qwen` y `agent:gemini`. `agent:pool` se conserva como alias compatible y ya puede coexistir con `agent:auto`: el selector deduplica por issue.

El dispatcher:

- reúne hasta seis issues elegibles y usa como máximo un trabajo por slot/proveedor en cada tanda;
- separa Qwen primario, Gemini y los slots OpenAI-compatible configurados;
- consulta el **control-plane Deno KV** y excluye issues con un lease activo antes de construir la matrix;
- consulta el health de workers en Deno KV y deja fuera slots en cooldown; solo si ese endpoint no responde reconstruye temporalmente el estado desde los marcadores históricos de #1713;
- cada worker adquiere atómicamente un lease por issue antes de marcar `agent:working`; el lease dura 30 minutos y se renueva al entrar en planificación, implementación, validación y publicación;
- mantiene `concurrency` por issue y los CLAIMs de #1713 como barreras redundantes durante la migración;
- si Deno/OIDC no están disponibles, falla abierto al mecanismo histórico de GitHub; un HTTP 409 por lease vivo sí evita arrancar un duplicado;
- los 429/503 abren un circuit breaker por worker con TTL configurable (mínimo 5 min, máximo 6 h); el marcador `AGENT_POOL_SLOT_UNHEALTHY` en #1713 queda únicamente como fallback si el reporte KV falla;
- ejecuta context packer, memoria Deno y CI brain antes de abrir un PR draft;
- ante cambios fuera del CLAIM, restaura el intento, libera la reserva y replantea hasta dos veces antes de escalar a `agent:needs-human`;
- al terminar una tanda comprueba si siguen quedando issues elegibles y, si los hay, programa inmediatamente la siguiente tanda para mantener ocupados los slots.

El barrido cada 15 minutos queda como red de seguridad; el drenado tras cada tanda evita esperar al siguiente cron cuando aún hay cola. `agent-autopilot.yml` ya no hace polling ni escucha labels: queda únicamente como ejecución manual.

### Feeder conservador de backlog

`agent-feeder.yml` evita que una pool sana se quede ociosa cuando no existe ninguna tarea en `agent:auto`/`agent:pool`/provider. Una vez por hora, y solo si la cola/planificación está vacía, selecciona como máximo **un** issue y lo envía primero a `agent:decompose`; nunca lo manda directamente a implementación.

El selector excluye cualquier issue con labels `agent:*`, `estado:validacion-humana`, `prioridad:P0` o `agent:no-auto`, títulos de playtest/épica, registros de reservas, gates humanos detectados en el propio cuerpo (`Gate de validación humana`, `validación pendiente`, `pase humano`, `mando físico`), issues actualizados en los últimos 90 minutos y issues ya cubiertos por un PR abierto (`Refs/Fixes/Closes/Resolves #N`). Prioriza bugs, infraestructura/tests y prioridades P2/P3. `agent:no-auto` es el opt-out explícito.

El feeder ejecuta `agent-decompose.yml` mediante `workflow_dispatch` porque los eventos creados por `GITHUB_TOKEN` no encadenan workflows. Del mismo modo, `agent-decompose.yml` despacha `agent-pool.yml` explícitamente cuando devuelve el padre a cola o crea subtareas independientes. El contrato de `agent-decompose` admite además `needs_human=true`: si el planner determina que solo queda gate/playtest físico o no hay cambio de código justificable, marca `agent:needs-human` y no crea ni encola trabajo.

## Normas Platino, wiki y memoria

Cada ejecución carga una copia fresca de `EspacioKoop/normas_platino` y debe leer sus fuentes operativas antes de planificar o reparar. Si esa carga falla, el agente no continúa: las reglas son obligatorias y no se sustituyen por memoria.

La jerarquía de contexto es:

1. repositorio, issue, #181, #1713 y Normas Platino;
2. wiki de Expediente Legado como memoria consolidada en solo lectura;
3. Deno KV como memoria operativa temporal;\n4. SQLite/Turso del CI brain como memoria histórica de fallos y workarounds.

La wiki, Deno KV y SQLite/Turso **no son fuentes de autoridad**. Un recuerdo puede orientar búsquedas, pero debe contrastarse con el código, el issue y CI actuales.

La memoria temporal reutiliza el Deno KV del gateway F9 y no necesita un secret nuevo. GitHub Actions solicita un token OIDC de corta duración con audiencia `siga98-agent-memory`; el gateway valida firma, repositorio y workflow antes de leer o escribir. Solo se aceptan `agent-autopilot.yml` y `agent-ci-repair.yml`.

Cada recuerdo:
- caduca a los 30 días;
- tiene un resumen de hasta 1200 caracteres;
- admite como máximo 8 tags y 12 rutas;
- se rechaza si parece contener tokens o credenciales;
- solo se guarda tras una implementación o reparación validada por el preflight;
- nunca contiene prompts completos, secretos ni datos privados.

La búsqueda revisa como máximo los 50 recuerdos recientes y devuelve hasta 8 por coincidencia de issue, rutas o tags. Si Deno no está disponible, el agente sigue sin memoria temporal; si Normas Platino no pueden cargarse, se detiene.

Además, cada ejecución intenta recuperar el último snapshot del **CI brain**.
Antes del plan se seleccionan recuerdos históricos por el texto del issue; tras
reservar, se refinan por rutas. En reparación, el selector usa el log fallido y
las rutas del CLAIM. Los logs no se guardan completos: el CI brain persiste solo
fingerprints normalizados y metadatos compactos.

La URL de memoria y del control-plane se deriva de la variable ya existente `SIGA98_FEEDBACK_FALLBACK_URL`, sustituyendo `/api/report` por `/api/agent-memory/*` o `/api/agent-pool/*`. Ambos usan OIDC de corta duración y no requieren otra credencial en GitHub.

## Flujo de seguridad y coordinación

1. El worker adquiere un lease atómico del issue en Deno KV; si otro run lo posee, termina sin tocar labels ni código.
2. El proveedor lee el issue y sus comentarios recientes.
3. Hace una fase de planificación **solo lectura** y propone como máximo 12 rutas concretas.
4. El workflow publica el `CLAIM` en #1713.
5. Relee #1713 y rechaza el trabajo si una reserva anterior solapa alguna ruta.
6. Solo entonces crea la rama `agent/<proveedor>-<issue>-<run>`.
7. El modelo recibe herramientas de archivos, pero no shell, GitHub API ni credenciales Git.
8. El workflow rechaza cualquier modificación fuera de las rutas del `CLAIM`.
9. Ejecuta preflight proporcional.
10. El workflow hace commit/push y abre un PR **draft** con `Refs #N`, lanza `CI` y libera el lease al terminar el job. Nunca hay auto-merge.

La API key solo se inyecta en la Action oficial del proveedor correspondiente. Los pasos Git/GitHub usan el `GITHUB_TOKEN` efímero después de que el modelo haya terminado.

## Reparación automática de CI

`Agent CI repair` escucha el resultado del workflow `CI` para ramas generadas por el autopilot.

Si CI falla:

1. recupera el `CLAIM` activo de #1713;
2. descarga los logs fallidos;
3. entrega logs + rutas reservadas al mismo proveedor;
4. vuelve a bloquear cambios fuera del `CLAIM`;
5. ejecuta preflight, hace commit y relanza `CI`.

Hay un máximo de **2 commits de reparación automática** por rama. Después se aplica `agent:needs-human`.

Cuando CI pasa, se registra `PR_READY` en #1713 con el SHA y el PR permanece draft para revisión humana.

## Variables opcionales

No son necesarias para empezar:

- `QWEN_BASE_URL`: sustituye el endpoint detectado automáticamente; por ejemplo, el endpoint OpenAI-compatible de FreeInference.
- `QWEN_MODEL`: sustituye `qwen3-coder-plus`; debe ser un ID de modelo válido en el backend elegido.
- `QWEN_CLI_VERSION`: fija una versión concreta del CLI.
- `QWEN_FALLBACK_1_BASE_URL` … `QWEN_FALLBACK_4_BASE_URL`: endpoints OpenAI-compatible de reserva.
- `QWEN_FALLBACK_1_MODEL` … `QWEN_FALLBACK_4_MODEL`: modelos usados por cada endpoint de reserva.
- `GEMINI_MODEL`: fija un modelo Gemini.
- `GEMINI_CLI_VERSION`: fija una versión concreta del CLI.

## Fast-path de CI para infraestructura de agentes

El check requerido sigue llamándose `CI / godot`, pero `scripts/ci_scope.py` clasifica el diff antes de descargar LFS, RGBDS o Godot. Solo usa fast-path cuando **todas** las rutas pertenecen a workflows/scripts/docs de agentes o al gateway Deno. En ese caso ejecuta la suite Python completa y deja la validación TypeScript al workflow específico de Deno.

Cualquier ruta de juego, GBC, backend, script genérico o el propio `ci.yml` fuerza el recorrido completo. Un diff vacío también fuerza full. Así se conservan las reglas de branch protection mientras las PRs puramente operativas dejan de ocupar runners con ROMs y arranques headless innecesarios.

## Límites deliberados

- nunca merge automático;
- la cola automática usa el pool de hasta seis workers, uno por slot y nunca dos simultáneos sobre el mismo issue; el autopilot manual conserva una ejecución concreta por invocación;
- máximo dos replans automáticos cuando un intento sale de las rutas del CLAIM;
- máximo 12 rutas por corte;
- máximo dos reparaciones automáticas de CI;
- no se automatizan validaciones humanas visuales, mando físico ni decisiones narrativas;
- PRs externos/forks no activan el seguimiento privilegiado;
- si no existe un corte seguro y concreto, se usa `agent:needs-human`.
