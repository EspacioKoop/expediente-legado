# Euriclea: revisión de los drafts del pool

Euriclea revisa de forma independiente cada PR que abre el pool (ramas `agent/*`) antes de que llegue a @eGurucharri. Es el artículo I de la [doctrina](doctrina.md): el mando revisa. No sustituye a la autorrevisión del worker, que usa el mismo modelo que implementó y solo informa. Tampoco sustituye al nivel 1, que sigue siendo el único que integra.

La lógica está en `scripts/agent_euriclea.py` y es la misma en los dos niveles. Lee el issue, su `AGENT_PLAN` y el diff por la API de GitHub; **nunca ejecuta código de la PR**. El texto de la PR entra al modelo marcado como datos, con la orden de ignorar cualquier instrucción que venga dentro. Contesta con el contrato de `scripts/agent_review_contract.py`.

## Niveles y autoridad

| Revisión | Sin hallazgos | Con hallazgos | Sin respuesta |
| --- | --- | --- | --- |
| **Principal** (Actions, `agent-review.yml`) | `revision:ok`: cuenta como revisión del artículo I | `revision:hallazgos` | `revision:pendiente` |
| **Respaldo** (PC local) | Comentario, pero sigue en `revision:pendiente`: el respaldo no puede aprobar | `revision:hallazgos` | Nada; lo reintenta en el siguiente barrido |

- `revision:ok` no autoriza el merge: solo dice que la revisión se hizo.
- `revision:pendiente` es una cola para el respaldo local y para cualquier agente de nivel 2.
- Cada revisión deja en su comentario una marca oculta con el SHA revisado. Un commit nuevo vuelve a entrar en la cola.
- Solo cuentan las marcas de las cuentas que ejecutan a Euriclea (`EURICLEA_AUTORES`): un comentario de otra persona no puede dar una PR por revisada.

## Principal: Actions

`agent-review.yml` barre cada 30 minutos y admite lanzarse a mano con `workflow_dispatch`, pasando `pr` para repetir la revisión de una PR concreta. Primero comprueba si hay candidatas usando solo la API de GitHub. Si no hay ninguna, termina sin conectar Tailscale ni llamar a ningún modelo.

La cadena es la del pool, en este orden, y se salta los proveedores sin credenciales:

1. OmniRoute por Tailscale con `vars.EURICLEA_MODELO` (por defecto `auto/reasoning`).
2. Qwen directo (`QWEN_API_KEY`, `vars.QWEN_BASE_URL`, `vars.QWEN_MODEL`).
3. Gemini por su endpoint compatible con OpenAI (`GEMINI_API_KEY`, `vars.GEMINI_MODEL`).

Si un proveedor falla o responde sin el contrato, se prueba el siguiente. Si no responde ninguno, la PR se marca como pendiente y ese SHA no se vuelve a intentar en Actions.

## Respaldo: PC local

El mismo script con `--nivel respaldo`. Solo toma PRs en `revision:pendiente` y usa los virtuales del router local en el orden de `EURICLEA_MODELOS_RESPALDO`. Ollama entra solo si se define `OLLAMA_MODELO`. Actions nunca llama al PC para esto: es el PC el que decide cuándo trabaja.

Lo medido el 2026-09-29, que explica los valores por defecto del respaldo:

- `auto/best-free` y `auto/coding:free` acababan en modelos de Cloudflare que no admiten chat (400/502).
- `auto/reasoning` respondió en unos 45-70 s y detectó un bug plantado, la prueba ausente y un intento de inyección que pedía aprobar.
- `qwen3:4b` en Ollama, sin GPU y con 15 GB de RAM, pasó de 15 minutos con un diff de 4 kB y dejó la máquina sin memoria libre. Por eso está desactivado por defecto; con `OLLAMA_MODELO` se usa la API nativa sin razonamiento (`think: false`) y con contexto de 16k.

El respaldo corre con un timer de systemd de usuario y no con el cron de Hermes: con Hermes en modo solo CLI no hay gateway que dispare los jobs. El envoltorio (`~/.local/bin/euriclea-respaldo`) extrae el script desde `origin/main`, así que nunca ejecuta lo que haya en la rama del checkout. Lee la clave del router de `~/.hermes/.env` sin mostrarla y comenta con la cuenta de `gh` del PC.

```ini
# ~/.config/systemd/user/euriclea-respaldo.timer
[Timer]
OnBootSec=10min
OnUnitActiveSec=30min
Persistent=true

[Install]
WantedBy=timers.target
```

Para probarlo sin publicar nada: `euriclea-respaldo --seco --pr <N>`. El modo `--seco` imprime el comentario que dejaría.

## Operación

- Revisión manual de una PR en Actions: `gh workflow run agent-review.yml -f pr=<N>`.
- Estado del respaldo: `systemctl --user list-timers euriclea-respaldo.timer` y `journalctl --user -u euriclea-respaldo`.
- Pausar el respaldo, por ejemplo mientras juegas: `systemctl --user stop euriclea-respaldo.timer`.
