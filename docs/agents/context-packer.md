# Context packer para agentes

`scripts/agent_context_pack.py` convierte una copia local de la wiki en un paquete pequeño de contexto para Qwen, Gemini u otros agentes.

No decide prioridad, no reserva archivos y no es una fuente de verdad. La jerarquía sigue siendo:

1. repositorio, issue, #181/#182 y Normas Platino;
2. wiki como memoria consolidada;
3. memoria temporal Deno KV / CI Brain.

## Por qué existe

El autopilot puede clonar la wiki completa, pero entregar toda la wiki al modelo añade ruido y consume ventana de contexto. El packer selecciona únicamente las páginas que tienen afinidad con:

- texto del issue;
- rutas reservadas;
- título y headings de cada página;
- términos repetidos dentro del contenido.

El ranking y los desempates son deterministas.

## Uso

Con la wiki ya clonada en `.agent-wiki` y el issue materializado en `.agent-task.md`:

```bash
python3 scripts/agent_context_pack.py \
  --wiki-dir .agent-wiki \
  --issue-file .agent-task.md \
  --path godot/guion/siga_terminal.gd \
  --path scripts/test_terminal_siga.py \
  --max-pages 8 \
  --max-bytes 24000 \
  --output .agent-context.md
```

El resultado incluye un inventario con score y motivos de selección antes del contenido elegido. Si no hay coincidencias y existe `Home.md` o `README.md`, usa esa página como fallback explícito.

## Límites deliberados

- no usa red;
- no ejecuta shell ni Git;
- solo lee Markdown dentro del directorio indicado;
- ignora rutas ocultas, symlinks y páginas de más de 256 KiB;
- máximo configurable de páginas y bytes;
- nunca promueve la wiki por encima del repositorio o las Normas Platino;
- no resume ni reescribe: conserva el texto fuente seleccionado y solo puede truncarlo por presupuesto.

## Integración en los workflows

Tanto `agent-worker.yml` (pool) como `agent-autopilot.yml` generan
`.agent-context.md` después de clonar la wiki. El primer pack usa el issue como
consulta; tras publicar y validar el CLAIM, se vuelve a generar incorporando las rutas
reservadas.

Los prompts de planificación e implementación leen primero ese pack acotado. La wiki
completa sigue disponible localmente para una consulta adicional explícita cuando el
pack no baste. El contexto seleccionado nunca cambia la jerarquía de autoridad:
repositorio/issue/#181/#182 y Normas Platino siguen prevaleciendo.

Refs #1538 #1551 #1559 #1566.
