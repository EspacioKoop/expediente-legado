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

- `QWEN_BASE_URL`: sustituye el endpoint detectado automáticamente.
- `QWEN_MODEL`: sustituye `qwen3-coder-plus`.
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
