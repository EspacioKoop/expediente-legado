"""Label de cola para una subtarea que se acaba de desbloquear (#2553).

Jules (≈100 tareas/día, PR en minutos) apenas se usaba porque al cerrarse las
dependencias todo iba a `agent:auto`, el pool. Lo que no toca Godot (ASM de las
ROM, Python, documentación, workflows) va a Jules, que lo hace mejor: ARIADNE
#2370 salió bien con él, mientras que el pool dejó bugs de registro en #1985 y
#2016. El pool sigue con GDScript y escenas.

Uso desde el workflow: BODY="$body" python3 scripts/agent_unblock_destino.py
"""
from __future__ import annotations

import json
import os
import re

SIN_GODOT = (".asm", ".py", ".md", ".yml", ".yaml", ".json", ".sh", ".inc", ".mk")
EXPLICITOS = {"qwen": "agent:qwen", "gemini": "agent:gemini", "jules": "jules"}


def ficheros_del_plan(cuerpo: str) -> list[str]:
    planes = re.findall(r"AGENT_PLAN_BEGIN\s*(\{.*?\})\s*AGENT_PLAN_END", cuerpo, re.S)
    if not planes:
        return []
    try:
        return [str(f) for f in json.loads(planes[-1]).get("files", [])]
    except json.JSONDecodeError:
        return []


def destino(cuerpo: str) -> str:
    explicito = re.search(r"<!--\s*agent-provider:\s*(\w+)\s*-->", cuerpo)
    proveedor = explicito.group(1) if explicito else "auto"
    if proveedor in EXPLICITOS:
        return EXPLICITOS[proveedor]
    ficheros = ficheros_del_plan(cuerpo)
    if ficheros and all(f.endswith(SIN_GODOT) for f in ficheros):
        return "jules"
    return "agent:auto"


if __name__ == "__main__":
    print(destino(os.environ.get("BODY", "")))
