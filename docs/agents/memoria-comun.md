# Memoria común de agentes

La memoria de agentes vive en Deno KV, detrás del gateway `infra/feedback-deno` (`/api/agent-memory/*`). Desde #1756 la comparten los dos niveles:

- **Pool (nivel 3).** Se autentica con OIDC de GitHub Actions, audiencia `siga98-agent-memory`, y escribe como `qwen` o `gemini`. Sigue igual que antes.
- **Asistidos (nivel 2).** Se autentican con un token de portador y escriben como `claude`, `codex`, `hermes` u `odiseo`.

Los dos pueden buscar en todo; solo el nivel 2 puede fijar lecciones.

## Tipos de recuerdo

| Tipo | Quién lo escribe | Caducidad | Para qué |
| --- | --- | --- | --- |
| `episodio` | pool y nivel 2 | 30 días | Lo que pasó en un issue concreto (`issue` > 0 obligatorio). |
| `leccion` | solo nivel 2 | nunca | Conocimiento estable: trampas, decisiones, convenciones (`issue` opcional, 0 si no aplica). |

Una lección no sustituye a la documentación versionada. Si la regla es del proyecto, va a `AGENTS.md`, a `docs/` o a la wiki; la lección guarda lo operativo que todavía no merece un cambio en el repo. Nunca se guardan secretos, partidas personales ni rutas privadas: el servidor rechaza resúmenes con forma de token.

## API

Todas las rutas son `POST` con JSON y `Authorization: Bearer <token>`.

- `remember`: `{"schema": 1, "kind": "leccion", "provider": "claude", "summary": "…", "tags": [...], "paths": [...], "issue": 0}`. El resumen tiene entre 20 y 1200 caracteres; hasta 8 etiquetas y 12 rutas relativas.
- `search`: `{"schema": 1, "issue": N, "paths": [...], "tags": [...], "query": "palabras clave"}`. Puntúa por issue, rutas solapadas, etiquetas y palabras de 4 letras o más del resumen. Devuelve como mucho 8 resultados.
- `forget` (solo nivel 2): `{"schema": 1, "id": "<id de la lección>"}`. Retira una lección equivocada u obsoleta.

## Configuración

El token de nivel 2 es la variable de entorno `AGENT_MEMORY_NIVEL2_TOKEN` del proyecto `siga98-feedback-deno` en Deno Deploy, de al menos 32 caracteres. No es un secret de GitHub: el pool no lo necesita. Si falta o es corto, el nivel 2 queda cerrado y el pool sigue funcionando.

Para generarlo, en local:

```bash
openssl rand -base64 48
```

Guárdalo fuera del repo, en el gestor de secretos o el `.env` local de cada herramienta. Para rotarlo, cambia la variable en Deno Deploy y en los clientes.

## Pruebas

`deno task test`, desde `infra/feedback-deno`, ejecuta `agent_memory_test.ts` con KV en memoria y sin red. El workflow `feedback-deno.yml` lo lanza en cada PR que toca el gateway.

## Siguiente corte

Un MCP local con `recordar` y `buscar` que conecte Claude Code, Codex y Hermes a esta API. Vive fuera del repo porque lleva el token de cada máquina.
