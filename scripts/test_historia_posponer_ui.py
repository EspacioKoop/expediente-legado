from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "historia_posponer_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "historia.tscn"


def test_la_escena_activa_la_capa_de_posponer() -> None:
    escena = ESCENA.read_text(encoding="utf-8")
    assert 'path="res://guion/historia_posponer_app.gd"' in escena


def test_posponer_reutiliza_el_contrato_y_guarda_antes_de_cerrar() -> None:
    codigo = CAPA.read_text(encoding="utf-8")
    assert "_historias.postergar(partida.estado, carta_id)" in codigo
    bloque = codigo.split("func _posponer_decision() -> void:", 1)[1]
    assert "_guardar()" in bloque
    assert "if not _sin_guardar:" in bloque
    assert "_cerrar()" in bloque


def test_el_boton_es_explicito_traducible_y_entra_en_el_circuito_de_foco() -> None:
    codigo = CAPA.read_text(encoding="utf-8")
    assert '_posponer.text = tr("A7_VOLVER")' in codigo
    assert "botones.append(_posponer)" in codigo
    assert "focus_neighbor_top" in codigo
    assert "focus_neighbor_bottom" in codigo


def test_la_capa_no_resuelve_ni_modifica_consecuencias() -> None:
    codigo = CAPA.read_text(encoding="utf-8")
    for prohibido in [
        "_historias.resolver(",
        "Prometeo.",
        "cargas",
        "pistas_descubiertas",
        "veredictos",
        "Combate",
    ]:
        assert prohibido not in codigo
