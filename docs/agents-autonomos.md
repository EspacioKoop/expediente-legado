# Agentes autónomos: Qwen + Gemini

El repositorio puede convertir issues autorizados en PRs draft usando Qwen Code o Gemini CLI sin entregar al modelo credenciales de push.

## Configuración mínima

Una vez fusionados los workflows, solo hacen falta las claves de los proveedores.

### Gemini

1. Abre Google AI Studio y entra en **API Keys**.
2. Crea o copia una **auth API key** válida para Gemini.
3. En este repositorio abre **Settings → Secrets and variables → Actions → New repository secret**.
4. Nombre: `GEMINI_API_KEY`.
5. Pega la clave como valor y guarda.

### Qwen

La configuración por defecto del workflow usa **Alibaba Cloud Coding Plan internacional**, con el endpoint `https://coding-intl.dashscope.aliyuncs.com/v1` y el modelo `qwen3-coder-plus`.

1. Abre Alibaba Cloud Model Studio internacional → **Coding Plan**.
2. Crea o copia la clave del plan (normalmente empieza por `sk-sp-`).
3. En este repositorio abre **Settings → Secrets and variables → Actions → New repository secret**.
4. Nombre: `QWEN_API_KEY`.
5. Pega la clave como valor y guarda.

No pegues ninguna key en issues, comentarios, archivos, variables públicas ni logs.

## Único ajuste de GitHub que puede ser necesario

GitHub puede impedir por política que `GITHUB_TOKEN` cree PRs. Si el primer intento llega a implementar y hacer push pero falla al abrir el PR:

**Settings → Actions → General → Workflow permissions → Allow GitHub Actions to create and approve pull requests**.

El workflow nunca aprueba ni fusiona PRs; el ajuste solo permite que el token efímero abra el draft. Si la organización ya permite esta operación no hay que tocar nada.

## Cómo poner trabajo en cola

Los labels se crean automáticamente al activarse el workflow:

- `agent:auto`: entra en la cola automática; el scheduler revisa cada cuatro horas.
- `agent:qwen`: ejecución inmediata con Qwen.
- `agent:gemini`: ejecución inmediata con Gemini.
- `agent:working`: hay una ejecución activa.
- `agent:pr-open`: ya existe un PR generado para ese issue.
- `agent:needs-human`: hubo ambigüedad, conflicto, límite de reintentos o falta configuración.

También puede lanzarse manualmente desde **Actions → Agent autopilot → Run workflow**, indicando issue y proveedor.

## Flujo

1. El agente lee el issue, comentarios recientes, #181 y las reglas del repo.
2. Hace una fase de planificación sin conservar modificaciones.
3. Propone un máximo de 12 rutas.
4. El workflow registra el `CLAIM` en #182 y comprueba colisiones.
5. Solo entonces el modelo puede editar.
6. El workflow rechaza cualquier modificación fuera de las rutas reservadas.
7. Hace commit y push en una rama `agent/<proveedor>-<issue>-<run>`.
8. Abre un PR **draft**. No hay auto-merge.
9. Si CI falla, el seguimiento puede intentar corregirlo hasta dos veces, siempre dentro de la reserva.
10. Cuando CI pasa, el otro proveedor hace review cruzada si su API key existe; el PR pasa a ready y se registra `PR_READY` en #182.

Solo hay una ejecución de creación de PR a la vez para reducir conflictos.

## Variables opcionales

No son necesarias para empezar:

- `QWEN_BASE_URL`: sustituye el endpoint de Qwen.
- `QWEN_MODEL`: sustituye `qwen3-coder-plus`.
- `GEMINI_MODEL`: fija un modelo Gemini concreto.

Si usas un API key estándar de Model Studio o Token Plan en vez de Coding Plan, configura el endpoint/modelo compatibles mediante esas variables antes de usar Qwen.

## Límites deliberados

- nunca merge automático;
- máximo dos reparaciones automáticas de CI por PR;
- un review cruzado por SHA;
- cambios limitados a la reserva de #182;
- PRs externos/forks no activan el seguimiento privilegiado;
- si no hay una implementación segura y concreta, se usa `agent:needs-human`.
