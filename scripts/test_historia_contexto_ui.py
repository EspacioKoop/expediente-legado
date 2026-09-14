import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "historia_posponer_app.gd"
CONTRATO = ROOT / "godot" / "guion" / "historia_contexto.gd"
ESCENA = ROOT / "godot" / "escenas" / "historia.tscn"
TEXTOS = ROOT / "godot" / "datos" / "historia_contexto_textos.json"


def test_la_escena_conserva_la_capa_de_posponer() -> None:
    escena = ESCENA.read_text(encoding="utf-8")
    assert 'path="res://guion/historia_posponer_app.gd"' in escena


def test_el_contexto_se_congela_con_evidencia_real_y_no_con_un_contador() -> None:
    codigo = CONTRATO.read_text(encoding="utf-8")
    assert '"leidos": _leidos(estado)' in codigo
    assert '"pistas": _pistas(estado)' in codigo
    assert 'jornada.get("leidos_total", [])' in codigo
    assert 'estado.get("pistas_descubiertas", [])' in codigo
    assert "_hay_nuevo(_leidos(estado)" in codigo
    assert "_hay_nuevo(\n\t\t_pistas(estado)" in codigo
    assert "Time." not in codigo
    assert "RandomNumberGenerator" not in codigo
    assert ">=" not in codigo


def test_una_partida_antigua_sin_instantanea_no_queda_bloqueada() -> None:
    codigo = CONTRATO.read_text(encoding="utf-8")
    bloque = codigo.split("static func maduro", 1)[1].split("static func _registros", 1)[0]
    assert "if not registros.has(carta_id):" in bloque
    assert "return true" in bloque


def test_la_primera_exposicion_guarda_contexto_y_oculta_opciones() -> None:
    codigo = CAPA.read_text(encoding="utf-8")
    assert "HISTORIA_CONTEXTO.tiene_registro" in codigo
    assert "HISTORIA_CONTEXTO.registrar(partida.estado, carta_id)" in codigo
    assert "_guardar()" in codigo
    assert "HISTORIA_CONTEXTO.maduro(partida.estado, carta_id)" in codigo
    assert "boton.visible = mostrar_opciones" in codigo
    assert "boton.disabled = _sin_guardar or not mostrar_opciones" in codigo


def test_posponer_sigue_disponible_y_el_foco_ignora_opciones_ocultas() -> None:
    codigo = CAPA.read_text(encoding="utf-8")
    assert "_historias.postergar(partida.estado, carta_id)" in codigo
    assert "opcion.visible and not opcion.disabled" in codigo
    assert "botones.append(_posponer)" in codigo
    assert "botones.append(_reintentar)" in codigo
    assert "botones.append(_volver)" in codigo


def test_el_aviso_es_neutral_y_vive_fuera_del_gdscript() -> None:
    codigo = CAPA.read_text(encoding="utf-8")
    textos = json.loads(TEXTOS.read_text(encoding="utf-8"))
    assert "vuelve al expediente" in textos["pendiente"]
    assert "otro documento" in textos["tooltip"]
    assert "correct" not in textos["pendiente"].lower()
    assert "ideolog" not in textos["pendiente"].lower()
    assert '_contexto_aviso.text = _texto_contexto("pendiente")' in codigo
    assert "La carta queda registrada" not in codigo
