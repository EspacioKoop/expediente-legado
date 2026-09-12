from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "visor_anotaciones_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "visor.tscn"


def fuente() -> str:
    return CAPA.read_text(encoding="utf-8")


def test_la_escena_activa_la_capa_sobre_combinaciones() -> None:
    texto = fuente()
    escena = ESCENA.read_text(encoding="utf-8")
    assert 'res://guion/visor_anotaciones_app.gd' in escena
    assert 'extends "res://guion/visor_combinaciones_app.gd"' in texto


def test_solo_se_puede_marcar_un_folio_leido() -> None:
    texto = fuente()
    assert "not _esta_leido(registro_id)" in texto
    assert '_marcar.disabled = registro_id.is_empty() or not _esta_leido(registro_id)' in texto


def test_marcar_y_desmarcar_es_idempotente() -> None:
    texto = fuente()
    assert "if marcadores.has(registro_id):" in texto
    assert "marcadores.erase(registro_id)" in texto
    assert "marcadores.append(registro_id)" in texto
    assert "_guardar_marcadores_del_caso(marcadores)" in texto


def test_los_marcadores_se_aislan_por_caso_y_no_descubren_pistas() -> None:
    texto = fuente()
    assert 'const CLAVE_MARCADORES := "marcadores_folios"' in texto
    assert 'todos.get(String(caso["id"]), []).duplicate()' in texto
    assert 'var caso_id := String(caso["id"])' in texto
    assert "descubiertas.append" not in texto
    assert "_buscar_relacion" not in texto


def test_el_estado_se_guarda_con_la_partida_existente() -> None:
    texto = fuente()
    assert "jornada[CLAVE_MARCADORES] = todos" in texto
    assert "_guardar_o_avisar()" in texto
