# Runbook: Qwen Code mediante FreeInference

Este documento describe cómo ejecutar Qwen Code usando FreeInference como backend OpenAI-compatible en el repositorio expediente-legado, sin tocar lógica de juego.

## Resumen

FreeInference es un servicio que expone un endpoint compatible con la API de OpenAI. Este repositorio lo utiliza para invocar modelos Qwen Code (p. ej. `qwen3-coder-plus`) desde los workflows de autopilot sin registrar credenciales en el código ni alterar las rutas de juego.

## Variables y secretos

| Variable / secreto | Dónde | Propósito |
| --- | --- | --- |
| `QWEN_API_KEY` | **Repository Secrets** (`Settings → Secrets and variables → Actions`) | Autentica las peticiones al endpoint de FreeInference. Nunca pegues la clave en issues, comentarios, archivos públicos ni logs. |
| `QWEN_BASE_URL` | **Repository Variables** (`Settings → Secrets and variables → Actions`) | Sustituye el endpoint que el workflow detecta automáticamente. El workflow leerá esta variable antes que cualquier detección heurística. |
| `QWEN_MODEL` | **Repository Variables** | Sustituye el modelo por defecto (`qwen3-coder-plus`). Útil para probar versiones distintas sin modificar el workflow. |
| `QWEN_CLI_VERSION` | **Repository Variables** (opcional) | Fija la versión del CLI de Qwen Code. Si no se indica, el workflow descarga `latest`. |

### `QWEN_BASE_URL`

Debe apuntar al endpoint de FreeInference que actúe como proxy OpenAI-compatible, p. ej.:

```
https://tu-instancia.freeinference.ai/v1
```

El workflow lee `QWEN_BASE_URL` antes que cualquier detección automática. Si no se define, el workflow detecta automáticamente:

- **Model Studio / DashScope internacional**: claves `sk-...` → endpoint `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`.
- **Coding Plan internacional**: claves `sk-sp-...` → endpoint `https://coding-intl.dashscope.aliyuncs.com/v1`.

Al definir `QWEN_BASE_URL`, sobrescribes ambos comportamientos: el workflow usa tu URL tal cual.

### Usar FreeInference u otro gateway como fallback

No es necesario reemplazar el backend principal. También puedes configurarlo como uno de los cuatro slots de reserva:

- secret: `QWEN_FALLBACK_1_API_KEY`;
- variable: `QWEN_FALLBACK_1_BASE_URL`;
- variable: `QWEN_FALLBACK_1_MODEL`.

Los slots 2–4 usan el mismo patrón. El autopilot prueba el primario y después los fallbacks configurados, en orden. La reparación automática de CI reutiliza exactamente la misma cadena.

### `QWEN_MODEL`

Si se define `QWEN_MODEL`, el workflow lo pasa como `openai_model` al CLI de Qwen. Si no se define, el workflow usa `qwen3-coder-plus`. Este campo permite probar modelos distintos sin modificar el workflow ni crear nuevas variables.

## Lanzamiento con `agent:qwen`

Etiqueta un issue abierto con `agent:qwen`. El workflow `agent-autopilot.yml` se disparará de inmediato (también hay un scheduler cada hora para `agent:auto`).

El flujo de lanzamiento es:

1. El workflow lee el issue, sus comentarios recientes y `.agent-task.md`.
2. Inicia Qwen Code con `openai_base_url` apuntando a FreeInference y `openai_model` al valor de `QWEN_MODEL` (o `qwen3-coder-plus`).
3. El modelo inspecciona sin editar, propone un plan como JSON, y el workflow valida las rutas contra #182 + #1713 y publica la reserva nueva en #1713.
4. Tras la reserva, se relanza Qwen Code con herramientas de escritura para implementar solo el plan.

### Requisitos de permisos

GitHub puede impedir por política que `GITHUB_TOKEN` cree PRs. En ese caso:

**Settings → Actions → General → Workflow permissions → Allow GitHub Actions to create and approve pull requests**.

El workflow nunca aprueba ni fusiona PRs; el ajuste solo permite crear el draft.

## Señales esperadas

### #1713 (registro activo de reservas)

Durante la ejecución, el workflow publicará comentarios nuevos en #1713 con este formato:

```text
CLAIM issue=#1545 agent=Autopilot-qwen branch=agent/qwen-1545-12345 files=docs/agents/qwen-freeinference.md goal=runbook-Qwen-via-FreeInference lease=48h
```

Al finalizar con CI verde:

```text
PR_READY issue=#1545 pr=#1548 sha=abcdef1234 pruebas=CI-canónico-verde limites=PR-draft;sin-validación-humana provider=qwen
```

Si se agotan las reparaciones automáticas:

```text
RELEASE issue=#1545 branch=agent/qwen-1545-12345 motivo=colision-autopilot
```
(o `motivo=autopilot-fallo-antes-de-PR`, `motivo=abandonado`, etc.)

### PR draft

El workflow crea un PR **draft** a `main` con:

- Título: `agent(qwen): #1545 <título-del-issue>`
- Cuerpo: `Refs #1545` + mención al plan en #1713 y al preflight ejecutado.
- **Sin auto-merge**: el PR queda draft para revisión humana.

### CI

Tras publicar la rama, el workflow lanza `CI` explícitamente sobre ella. Nunca hay auto-merge. Si CI falla, el workflow `agent-ci-repair.yml` intenta reparar automáticamente.

## Límites deliberados

| Límite | Detalle |
| --- | --- |
| Sin shell para el modelo | El modelo recibe herramientas de archivos (`read_file`, `write_file`, `edit`, etc.), pero nunca shell ni GitHub API. |
| Sin auto-merge | Todos los PRs quedan en estado draft para revisión humana. |
| Máximo 2 reparaciones de CI | `agent-ci-repair.yml` cuenta los commits de reparación en la rama. Tras 2 intentos, se aplica `agent:needs-human`. |
| Máximo 12 rutas por corte | El plan JSON solo acepta hasta 12 archivos; usa `files: []` si no hay corte seguro. |
| Solo el issue asignado | El workflow rechaza cualquier modificación fuera de las rutas reservadas en el CLAIM. |
| Sin validación humana automatizada | No se automatizan validaciones visuales, de mando físico ni decisiones narrativas. |

## Advertencia: no registrar secretos

- Nunca pegues `QWEN_API_KEY` ni `QWEN_BASE_URL` en issues, comentarios, archivos ni logs.
- Las claves solo se inyectan en la Action oficial del proveedor (`QwenLM/qwen-code-action@v1`).
- Los pasos Git/GitHub usan el `GITHUB_TOKEN` efímero después de que el modelo haya terminado.
- Trabaja con `.env.example` y datos sintéticos; nunca con secretos o credenciales reales.

## Resolución de problemas

| Síntoma | Causa probable | Solución |
| --- | --- | --- |
| CI no se lanza sobre la rama | Workflow `agent-autopilot.yml` no disparó | Verificar que el issue tiene label `agent:qwen`; revisar `Actions` para ver el historial del runner. |
| Plan no parseable en el workflow | El modelo no generó `AGENT_PLAN_BEGIN ... AGENT_PLAN_END` | Revisar `.agent-task.md` y el prompt; asegurarse de que el modelo responde con el formato JSON requerido. |
| `sin-corte-seguro` | El modelo generó `files: []` | El workflow aplica `agent:needs-human`; revisar manualmente el issue. |
| `solape` en reserva | Otra reserva activa protege una ruta del plan | Publicar `RELEASE` en #1713 o acordar con el titular de la reserva activa según las Normas Platino. |
| CI falla tras 2 reparaciones | `agent-ci-repair` agotó intentos | El workflow aplica `agent:needs-human`; revisión humana obligatoria. |
| PR no se crea (push ok, PR falla) | Permisos `GITHUB_TOKEN` insuficientes | Activar "Allow GitHub Actions to create and approve pull requests" en Settings → Actions. |

## Validación end-to-end

Este issue (#1545) sirve como primera validación end-to-end de Qwen vía FreeInference:

1. Verificar que `QWEN_BASE_URL` apunta a FreeInference.
2. Etiquetar con `agent:qwen` y observar el flujo completo.
3. Comprobar el CLAIM en #1713, el PR draft y CI verde.
4. Confirmar que no se modificaron rutas fuera del plan.

Si todo pasa, este documento queda como referencia para futuras ejecuciones con FreeInference.

## Referencias

- [agents-autonomos.md](../agents-autonomos.md) — Configuración de Qwen + Gemini en el repositorio.
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — Flujo de ramas y gates.
- [AGENTS.md](../../AGENTS.md) — Instrucciones para agentes.
- [QWEN.md](../../QWEN.md) — Contrato del autopilot Qwen Code.
- Issue #1713 — Registro activo de reservas; #182 queda como histórico de transición.
- Issue #181 — Plan maestro y prioridad.
