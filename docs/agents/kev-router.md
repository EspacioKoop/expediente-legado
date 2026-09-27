# Router Kev para agentes

Este corte prepara una capa de decisión **opcional** para el autopilot. Kev no edita
archivos, no ejecuta herramientas y no recibe credenciales de GitHub: únicamente
puede proponer qué worker disponible conviene usar para una tarea.

La implementación vive en `scripts/kev_router.py` y usa solo la biblioteca estándar
de Python. No se versionan pesos, checkpoints ni SDKs de Kev.

## Contrato

El cliente llama a `POST /v1/systemone` y formula una única pregunta `choice`
con los workers realmente disponibles. El resultado solo se acepta cuando:

- el proveedor devuelto está entre los disponibles;
- `confidence` es numérico y está entre 0 y 1;
- alcanza `KEV_ROUTER_MIN_CONFIDENCE`.

El valor por defecto del umbral es `0.45`. Es un **guardarraíl operativo**, no una
estimación de precisión. Antes de darle más autoridad al router hay que medirlo con
decisiones reales del repositorio.

Las etiquetas explícitas `agent:qwen` y `agent:gemini`, así como una selección
manual de proveedor, tienen prioridad sobre Kev. Si solo existe un worker
configurado tampoco se consulta Kev.

## Fallos y fallback

Kev nunca debe bloquear el autopilot. Timeout, error HTTP, JSON inválido, respuesta
incompatible o confianza insuficiente conservan el comportamiento determinista:

1. Qwen si está disponible;
2. Gemini en caso contrario;
3. sin worker si ninguno está configurado.

La salida JSON indica el origen en `source`:

- `explicit`;
- `single-provider`;
- `kev`;
- `fallback:no-kev`;
- `fallback:low-confidence`;
- `fallback:error`;
- `unavailable`.

## Ejecución local

Con un servidor Kev en `http://127.0.0.1:8009`:

```bash
printf '%s\n' '{"title":"Corregir una regresión de CI","body":"El test falla tras un cambio pequeño"}' |
  KEV_BASE_URL=http://127.0.0.1:8009 \
  python3 scripts/kev_router.py --has-qwen --has-gemini
```

Si el servidor exige autenticación, define `KEV_API_KEY` solo en el entorno o en un
secret. `KEV_MODEL` permite sustituir `kev-latest`, `KEV_TIMEOUT_SECONDS` ajusta
el timeout y `KEV_ROUTER_MIN_CONFIDENCE` cambia el umbral.

El servidor oficial de Kev documenta `POST /v1/systemone`, `kev-latest` y
autenticación Bearer opcional mediante `KEV_API_KEY`:
https://github.com/jaredpalmer/kev

## Integración con GitHub Actions

El enganche directo en `.github/workflows/agent-autopilot.yml` se deja para el
siguiente corte porque #1559 mantiene una reserva activa sobre ese archivo.

Cuando quede libre, el paso de selección puede construir un estado compacto a partir
del issue y ejecutar el router antes del fallback actual. No debe entregarse a Kev el
`GITHUB_TOKEN`, secretos de proveedores, logs completos ni memoria sin filtrar.

Configuración prevista:

- repository variable `KEV_BASE_URL`;
- repository variable opcional `KEV_MODEL`;
- repository variable opcional `KEV_ROUTER_MIN_CONFIDENCE`;
- Actions secret `KEV_API_KEY` únicamente si el endpoint lo exige.

La ausencia de todas estas variables debe equivaler exactamente al comportamiento
actual del autopilot.

## Validación

```bash
python3 -m unittest scripts.test_kev_router
```

Los tests usan dobles en memoria; no necesitan red ni un proceso Kev real.

Refs #1538 #1551 #1553 #1559 #1562
