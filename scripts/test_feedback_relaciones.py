from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "visor_combinaciones_app.gd"


def fuente() -> str:
    return CAPA.read_text(encoding="utf-8")


def test_el_feedback_identifica_los_dos_folios_y_el_resultado() -> None:
    texto = fuente()
    assert 'var segundo := String(registro_actual.get("folio", actual))' in texto
    assert 'return "%s ↔ %s\\n%s" % [primero, segundo, mensaje]' in texto


def test_exito_y_repeticion_reutilizan_el_feedback_comun() -> None:
    texto = fuente()
    assert texto.count("_feedback_relacion(") >= 3
    assert 'tr("VISOR_RELACION_REGISTRADA") % relacion["descripcion"]' in texto
    assert 'tr("VISOR_RELACION_YA_REGISTRADA") % relacion["descripcion"]' in texto


def test_el_fallo_sigue_siendo_especifico_y_no_inventa_conclusion() -> None:
    texto = fuente()
    assert 'tr("VISOR_RELACION_NO_DEMOSTRADA") % [primero, segundo]' in texto
    assert "descubiertas.append(pista_id)" in texto
    assert "if relacion.is_empty():" in texto
