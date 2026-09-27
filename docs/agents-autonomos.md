# Agentes autónomos: Qwen + Gemini

El repositorio puede convertir issues autorizados en PRs draft usando Qwen Code o Gemini CLI sin entregar al modelo credenciales de push.

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

## Único ajuste de GitHub que puede ser necesario

GitHub puede impedir por política que `GITHUB_TOKEN` cree PRs. Si el primer intento implementa y hace push pero falla al abrir el draft:

**Settings → Actions → General → Workflow permissions → Allow GitHub Actions to create and approve pull requests**.

El workflow nunca aprueba ni fusiona PRs; el ajuste solo permite crear el draft. Si la organización ya lo permite, no hay que tocar nada.

## Cola de trabajo

Los labels se crean automáticamente al integrarse el workflow:

- `agent:auto`: entra en la cola automática;
- `agent:qwen`: ejecución inmediata con Qwen;
- `agent:gemini`: ejecución inmediata con Gemini;
- `agent:working`: hay una ejecución activa;
- `agent:pr-open`: ya existe un PR generado;
- `agent:needs-human`: hubo ambigüedad, conflicto, falta de configuración o se agotó la reparación automática.

Etiquetar un issue con `agent:auto`, `agent:qwen` o `agent:gemini` lo dispara. Además, cada hora el scheduler recoge el primer `agent:auto` que siga pendiente. También se puede lanzar **Agent autopilot** manualmente desde Actions indicando issue y proveedor.

## Normas Platino, wiki y memoria

Cada ejecución carga una copia fresca de `EspacioKoop/normas_platino` y debe leer sus fuentes operativas antes de planificar o reparar. Si esa carga falla, el agente no continúa: las reglas son obligatorias y no se sustituyen por memoria.

La jerarquía de contexto es:

1. repositorio, issue, #181, #182 y Normas Platino;
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

La URL de memoria se deriva de la variable ya existente `SIGA98_FEEDBACK_FALLBACK_URL`, sustituyendo `/api/report` por `/api/agent-memory/*`. No hay otra credencial que copiar.

## Flujo de seguridad y coordinación

1. El proveedor lee el issue y sus comentarios recientes.
2. Hace una fase de planificación **solo lectura** y propone como máximo 12 rutas concretas.
3. El workflow publica el `CLAIM` en #182.
4. Relee #182 y rechaza el trabajo si una reserva anterior solapa alguna ruta.
5. Solo entonces crea la rama `agent/<proveedor>-<issue>-<run>`.
6. El modelo recibe herramientas de archivos, pero no shell, GitHub API ni credenciales Git.
7. El workflow rechaza cualquier modificación fuera de las rutas del `CLAIM`.
8. Ejecuta preflight proporcional.
9. El workflow hace commit/push y abre un PR **draft** con `Refs #N`.
10. Lanza `CI` explícitamente sobre la rama. Nunca hay auto-merge.

La API key solo se inyecta en la Action oficial del proveedor correspondiente. Los pasos Git/GitHub usan el `GITHUB_TOKEN` efímero después de que el modelo haya terminado.

## Reparación automática de CI

`Agent CI repair` escucha el resultado del workflow `CI` para ramas generadas por el autopilot.

Si CI falla:

1. recupera el `CLAIM` activo de #182;
2. descarga los logs fallidos;
3. entrega logs + rutas reservadas al mismo proveedor;
4. vuelve a bloquear cambios fuera del `CLAIM`;
5. ejecuta preflight, hace commit y relanza `CI`.

Hay un máximo de **2 commits de reparación automática** por rama. Después se aplica `agent:needs-human`.

Cuando CI pasa, se registra `PR_READY` en #182 con el SHA y el PR permanece draft para revisión humana.

## Variables opcionales

No son necesarias para empezar:

- `QWEN_BASE_URL`: sustituye el endpoint detectado automáticamente; por ejemplo, el endpoint OpenAI-compatible de FreeInference.
- `QWEN_MODEL`: sustituye `qwen3-coder-plus`; debe ser un ID de modelo válido en el backend elegido.
- `QWEN_CLI_VERSION`: fija una versión concreta del CLI.
- `GEMINI_MODEL`: fija un modelo Gemini.
- `GEMINI_CLI_VERSION`: fija una versión concreta del CLI.

## Límites deliberados

- nunca merge automático;
- una sola creación autónoma a la vez para reducir colisiones;
- máximo 12 rutas por corte;
- máximo dos reparaciones automáticas de CI;
- no se automatizan validaciones humanas visuales, mando físico ni decisiones narrativas;
- PRs externos/forks no activan el seguimiento privilegiado;
- si no existe un corte seguro y concreto, se usa `agent:needs-human`.
