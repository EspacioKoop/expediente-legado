import os
from pathlib import Path
import subprocess

from scripts.godot_pruebas import importar_proyecto

ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "final_politico.gd"
PANEL = ROOT / "godot" / "guion" / "final_politico_panel.gd"
OWNER = ROOT / "godot" / "guion" / "dia_climax_hastur_app.gd"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_final_politico_1103.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_final_no_vuelve_al_desempate_por_enum() -> None:
    modelo = fuente(MODELO)
    assert "Prometeo.ejes_dominantes" in modelo
    assert "PATRON_PLURAL" in modelo
    assert "eje_ganador" not in modelo
    assert "calcularEjeGanador" not in modelo


def test_presentacion_muestra_hechos_y_es_navegable() -> None:
    panel = fuente(PANEL)
    assert 'resumen.get("ejemplos"' in panel
    assert "grab_focus()" in panel
    assert 'event.is_action_pressed("cancelar")' in panel
    assert "AnimationPlayer" not in panel


def test_owner_consume_contrato_y_persiste_cierre() -> None:
    owner = fuente(OWNER)
    assert "FinalPolitico.resumen" in owner
    assert "FinalPoliticoPanel.new()" in owner
    assert "FinalPolitico.confirmar_cierre" in owner
    assert 'actual["final_politico_pendiente"] = false' in owner


def test_modelo_no_accede_a_red_host_o_disco() -> None:
    codigo = fuente(MODELO)
    for prohibido in (
        "FileAccess",
        "DirAccess",
        "HTTPRequest",
        "HTTPClient",
        "OS.execute(",
        "OS.create_process(",
    ):
        assert prohibido not in codigo


def test_regresion_ejecutable_en_godot() -> None:
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
