# Doctrina de agentes

Reglas de reparto de trabajo entre los agentes del proyecto: quién hace qué, dónde se ejecuta, con qué capa de modelos y qué pasa cuando alguien se queda sin cuota. Complementa a [AGENTS.md](../../AGENTS.md), que sigue mandando en reservas, ramas y gates. Si esta página y `AGENTS.md` se contradicen, vale `AGENTS.md` y se corrige esta.

## Cadena de mando

```text
@eGurucharri ordena
  → nivel 2 planifica, corta y delega (o implementa el corte él mismo)
  → el pool ejecuta en Actions el plan delegado
  → un agente de nivel 2 revisa el draft
  → @eGurucharri integra
```

- **Nivel 1: @eGurucharri.** Decide prioridad, valida en playtest y es el único que integra.
- **Nivel 2: agentes asistidos** (Claude Code, Codex, ChatGPT/Odiseo). Investigan, escriben el `AGENT_PLAN`, implementan los cortes que no conviene delegar y revisan lo que vuelve del pool.
- **Nivel 3: el pool** ([parallel-pool.md](parallel-pool.md)). Ejecuta issues delegados con plan y rutas concretas; no decide qué hacer.

## Dónde se trabaja

| Sitio | Qué corre ahí |
| --- | --- |
| Deno Deploy | Estado ligero y 24/7: leases del pool, [memoria común](memoria-comun.md), feedback de F9, sala de mando. |
| GitHub Actions | Todo el trabajo pesado: pool, CI canónico, evidencias automatizables. |
| Máquina local | Lo que exige GPU real o manos: capturas y medidas en Godot (nunca con xvfb), playtest, modelos locales. |

## Artículos

**I. El mando revisa.** Ningún draft del pool pasa a `PR_READY` sin una revisión independiente: la de [Euriclea](euriclea.md) en su nivel principal (`revision:ok`) o la de un agente de nivel 2 que no sea su autor. El respaldo local de Euriclea solo filtra: puede señalar hallazgos, pero una PR en `revision:pendiente` sigue esperando al nivel principal o al nivel 2. La autorrevisión del propio worker (`scripts/agent_review_contract.py`) informa, pero no cuenta como revisión.

**II. El trabajo pesado, fuera.** Suites largas, builds y lotes del pool van a Actions. La máquina local se reserva para lo que solo ella puede hacer: GPU, playtest y lo que no debe salir de casa.

**III. Vigilar gratis.** Cada servicio tiene un solo vigilante. Vigilar y explorar usa la capa libre. Si no hay novedades, no se hace ninguna petición de pago.

**IV. Siempre hay relevo.** Ningún trabajo depende de un único proveedor. El orden es top → obrera → libre → local; el pool ya lo aplica con sus tiers y fallbacks, y la sección [Relevo](#relevo) lo aplica al nivel 2.

## Arsenal por capas

Las capas se definen por función, no por modelo. Los modelos concretos rotan y se degradan, así que ni los perfiles ni los scripts fijan listas de IDs: apuntan a los virtuales `auto/*` del router, que eligen entre lo disponible en cada momento.

| Capa | Qué usa | Para qué |
| --- | --- | --- |
| Top | El modelo más capaz de cada cliente de nivel 2 | Planificar, cortar, revisar y los cortes delicados. |
| Obrera | `auto/coding`, `auto/reasoning`, `auto/fast` y los slots de pago del pool | Volumen: ejecutar planes delegados. |
| Libre | `auto/best-free`, `auto/coding:free` | Vigilancia, exploración y triaje barato. |
| Local | Modelos en Ollama | Datos que no salen de casa y último relevo. Nunca en CI. |

Trampa conocida: con herramientas activadas, `auto/best-free` puede elegir modelos que no entran en el plan gratuito del proveedor y responder 403. No lo uses todavía para trabajo con tools sin un relevo detrás.

## Relevo

Cuando un agente de nivel 2 agota su cuota o su sesión a mitad de un corte, el siguiente tiene que poder retomarlo sin preguntar:

1. **Deja el trabajo en la rama.** Commit y push, aunque sea un WIP. Lo que queda solo en un disco local no existe para el relevo.
2. **Publica el estado en #1713.**

   ```text
   HEARTBEAT issue=#N branch=<rama> estado=<hecho>;<pendiente> relevo=<agente-o-libre>
   ```

   La reserva sigue siendo del titular hasta que la libere o venza la lease. Si otro agente continúa, publica su propio `CLAIM` de esas rutas con el acuerdo registrado, como indica `AGENTS.md`.
3. **Guarda un `episodio` en la memoria común** con el issue, las rutas y lo que sabes que no está en el diff: hipótesis descartadas, trampas y el siguiente paso.

Orden de relevo:

- **Entre agentes de nivel 2 (Claude ↔ Codex ↔ Odiseo)**, antes que bajar de capa.
- **Si no queda ninguno de nivel 2**, el corte se delega al pool con plan y label de cola, según [parallel-pool.md](parallel-pool.md); no se deja a medias en local.
- **Las capas libre y local** solo toman vigilancia, exploración o borradores que alguien de nivel 2 revisará. Nunca publican `PR_READY`.

## Secretos

El gate `secretos.yml` y `scripts/escanear_secretos.sh` pasan gitleaks por cada PR y cada push a `main`, con salida redactada. Ningún agente pega tokens en issues, comentarios, memoria común ni logs. Un secreto que ya se empujó se rota: borrarlo con otro commit no basta.
