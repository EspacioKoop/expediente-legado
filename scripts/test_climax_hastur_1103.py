import os
from pathlib import Path
import subprocess

from scripts.godot_pruebas import importar_proyecto

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "godot" / "guion" / "climax_hastur.gd"
PANEL = ROOT / "godot" / "guion" / "climax_hastur_panel.gd"
OWNER = ROOT / "godot" / "guion" / "dia_climax_hastur_app.gd"
HANDOFF = ROOT / "godot" / "guion" / "dia_climax_os98_app.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
PARTIDA = ROOT / "godot" / "guion" / "partida.gd"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_climax_hastur_1103.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_handoff_sigue_siendo_transporte_y_tiene_dueno_externo() -> None:
    handoff = fuente(HANDOFF)
    owner = fuente(OWNER)
    adaptador = fuente(ADAPTADOR)

    assert "signal climax_hastur_pendiente" in handoff
    assert "ClimaxHastur" not in handoff
    assert "Combate" not in handoff
    assert "Acusacion" not in handoff

    assert 'get_node_or_null("ClimaxOs98Controller")' in owner
    assert '"climax_hastur_pendiente"' in owner
    assert "ClimaxHastur.iniciar" in owner
    assert "ClimaxHasturOwnerController" in adaptador
    assert "dia_climax_hastur_app.gd" in adaptador


def test_estado_es_persistente_por_partida_y_vuelta() -> None:
    core = fuente(CORE)
    partida = fuente(PARTIDA)

    assert 'const CLAVE_ESTADO := "climax_hastur"' in core
    assert "clave_vuelta(jornada" in core
    assert '"climax_hastur": {}' in partida
    assert "FASE_VICTORIA" in core
    assert "FASE_DERROTA" in core
    assert "FASE_FINAL" in core


def test_confrontacion_reutiliza_motor_y_final_politico_vigentes() -> None:
    core = fuente(CORE)
    panel = fuente(PANEL)

    assert 'Combate.nuevo("ciclo"' in core
    assert "Combate.jugar" in core
    assert "Acusacion.perder_vida" in core
    assert "Prometeo.ejes_dominantes" in core
    assert "Prometeo.elecciones_ideologicas" in core
    assert "ClimaxHasturPanel" in panel
    assert "grab_focus()" in panel
    assert "Input.is_key_pressed" not in panel


def test_climax_no_toca_host_red_ni_sistema_de_ficheros() -> None:
    codigo = "\n".join(fuente(path) for path in (CORE, PANEL, OWNER))
    for prohibido in (
        "FileAccess",
        "DirAccess",
        "HTTPRequest",
        "HTTPClient",
        "OS.execute(",
        "OS.create_process(",
    ):
        assert prohibido not in codigo


def test_contrato_ejecutable_en_godot() -> None:
    motor = os.environ.get("GODOT_BIN", "godot4")
    importar_proyecto()
    resultado = subprocess.run(
        [
            motor,
            "--headless",
            "--path",
            str(ROOT / "godot"),
            "--script",
            str(PRUEBA.relative_to(ROOT / "godot")),
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=30,
        check=False,
    )
    assert resultado.returncode == 0, resultado.stdout
    assert "0 fallos" in resultado.stdout
    assert "Parse Error:" not in resultado.stdout
    assert "SCRIPT ERROR:" not in resultado.stdout
