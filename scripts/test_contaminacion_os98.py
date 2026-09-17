import json
import os
from pathlib import Path
import subprocess

from scripts.godot_pruebas import importar_proyecto

ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "contaminacion_os98.gd"
EXPLORADOR = ROOT / "godot" / "guion" / "explorador_siga_modelo.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
CATALOGO = ROOT / "godot" / "datos" / "web98_indice.json"
PRUEBA_GODOT = ROOT / "godot" / "pruebas" / "pruebas_contaminacion_os98.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_progresion_tiene_hitos_deterministas_y_no_toca_host() -> None:
    modelo = fuente(MODELO)
    assert "EXPEDIENTES_PRINCIPALES := 5" in modelo
    assert 'const CREDENCIAL := "enlace13"' in modelo
    assert 'const REGISTRO_IMPOSIBLE_ID := "registro_imposible_13"' in modelo
    assert "static func memorandum_disponible(" in modelo
    assert '"memorandum_leido"' in modelo
    assert '"diagnostico_restringido_leido"' in modelo
    assert '"registro_imposible_leido"' in modelo
    assert "RandomNumberGenerator" not in modelo
    for prohibido in (
        "FileAccess",
        "DirAccess",
        "HTTPRequest",
        "HTTPClient",
        "OS.execute(",
        "OS.create_process(",
    ):
        assert prohibido not in modelo


def test_estado_se_persiste_por_partida_y_vuelta_y_se_comparte_entre_apps() -> None:
    adaptador = fuente(ADAPTADOR)
    assert "_explorador_app.persistir_estado = true" in adaptador
    assert '"contaminacion_por_vuelta"' in adaptador
    assert "func _clave_vuelta(" in adaptador
    assert 'dia.jornada.get("vuelta", 1)' in adaptador
    assert "ContaminacionOs98.contexto(" in adaptador
    assert "_explorador_vista.configurar_contexto(contexto)" in adaptador
    assert "_navegador_vista.configurar_contexto(contexto)" in adaptador


def test_incoherencia_cruza_explorador_y_web98_sin_icono_obvio() -> None:
    modelo = fuente(MODELO)
    explorador = fuente(EXPLORADOR)
    datos = json.loads(CATALOGO.read_text(encoding="utf-8"))
    recursos = {recurso["id"]: recurso for recurso in datos["recursos"]}
    assert '"id": "registro_imposible_13"' in explorador
    assert '"04/01/1999"' in explorador
    assert '"http://intranet.dgai/cache/diag-13/"' in explorador

    imposible = recursos["volcado-cache-13"]
    assert imposible["indexado"] is False
    assert imposible["requiere_conocimiento"] == ["os98_incoherencia"]
    assert imposible["cache"]["capturada_dia"] == 99
    assert "PROMETEO" not in imposible["titulo"].upper()
    assert "HASTUR" not in imposible["titulo"].upper()

    diagnostico = recursos["diagnostico-enlace13"]
    assert diagnostico["url"] == "http://intranet.dgai/diag/enlace13/"
    assert 'const URL_DIAGNOSTICO := "http://intranet.dgai/diag/enlace13/"' in modelo
    assert "fase >= FASE_CONTAMINACION_CRUZADA" in modelo
    assert "urls_caidas.append(URL_DIAGNOSTICO)" in modelo


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
            str(PRUEBA_GODOT.relative_to(ROOT / "godot")),
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
