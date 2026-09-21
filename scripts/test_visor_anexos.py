import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "visor_anexos_app.gd"
CATALOGO = ROOT / "godot" / "datos" / "anexos_documentales.json"
ESCENA = ROOT / "godot" / "escenas" / "visor.tscn"
PRONOSTICOS = ROOT / "godot" / "guion" / "visor_pronosticos_app.gd"


def test_la_escena_activa_la_capa_de_anexos() -> None:
    escena = ESCENA.read_text(encoding="utf-8")
    capa = CAPA.read_text(encoding="utf-8")
    superior = PRONOSTICOS.read_text(encoding="utf-8")
    assert 'res://guion/visor_pronosticos_app.gd' in escena
    assert 'extends "res://guion/visor_anexos_app.gd"' in superior
    assert 'extends "res://guion/visor_metadatos_app.gd"' in capa


def test_el_primer_anexo_no_inventa_contenido_clinico() -> None:
    datos = json.loads(CATALOGO.read_text(encoding="utf-8"))
    anexos = datos["oficio2@2"]
    assert len(anexos) == 1
    anexo = anexos[0]
    assert anexo["id"] == "prescripcion-medica@2"
    assert anexo["tipo"] == "metadato"
    assert anexo["contextual"] is True
    assert "no conserva su contenido clínico" in anexo["contenido"]


def test_abrir_anexo_no_toca_progreso_ni_decisiones() -> None:
    capa = CAPA.read_text(encoding="utf-8")
    for prohibido in (
        "pistas_descubiertas",
        "descubiertas.append",
        "Acusacion",
        "partida.estado",
        "_guardar_o_avisar",
        "acciones",
    ):
        assert prohibido not in capa


def test_el_anexo_empieza_cerrado_y_se_oculta_si_no_existe() -> None:
    capa = CAPA.read_text(encoding="utf-8")
    assert "var _anexo_abierto := false" in capa
    assert "_detalle_anexo.visible = false" in capa
    assert "_boton_anexo.visible = false" in capa
    assert "AnexosDocumentales.es_valido" in capa
