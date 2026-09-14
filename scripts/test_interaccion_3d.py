from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INTERACTUABLE = ROOT / "godot" / "guion" / "interactuable_3d.gd"
DETECTOR = ROOT / "godot" / "guion" / "detector_interaccion_3d.gd"
PREFERENCIAS = ROOT / "godot" / "guion" / "preferencias_siga.gd"
CAMINANTE = ROOT / "godot" / "guion" / "caminante.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_interactuable_declara_verbos_y_feedback_contextual() -> None:
    texto = fuente(INTERACTUABLE)
    for verbo in ("EXAMINAR", "USAR", "ABRIR", "COGER", "LEER", "DAR", "ENCENDER"):
        assert verbo in texto
    assert "signal activado(actor: Node)" in texto
    assert "func texto_accion() -> String:" in texto
    assert "func interactuar(actor: Node) -> bool:" in texto
    assert "if not habilitado:" in texto


def test_detector_usa_raycast_alcance_y_solo_objetos_validos() -> None:
    texto = fuente(DETECTOR)
    assert "extends RayCast3D" in texto
    assert "@export var alcance := 2.4" in texto
    assert "collide_with_areas = true" in texto
    assert "colision is Interactuable3D and colision.habilitado" in texto
    assert "objetivo_cambiado" in texto
    assert "objetivo_perdido" in texto


def test_interaccion_usa_accion_semantica_remapeable() -> None:
    detector = fuente(DETECTOR)
    preferencias = fuente(PREFERENCIAS)
    assert 'evento.is_action_pressed("interactuar")' in detector
    assert '"interactuar": {"teclado": 69, "mando": 0}' in preferencias
    assert "KEY_E" not in detector
    assert "InputEventKey" not in detector


def test_nucleo_no_acopla_reglas_de_jornada_ni_inventario() -> None:
    texto = fuente(INTERACTUABLE) + fuente(DETECTOR)
    for termino in ("Jornada", "Partida", "Inventario", "casos.json", "dia_app.gd"):
        assert termino not in texto


def test_caminante_monta_detector_bajo_la_camara() -> None:
    texto = fuente(CAMINANTE)
    assert "DetectorInteraccion3D.new()" in texto
    assert "_camara.add_child(_detector_interaccion)" in texto
    assert "objetivo_cambiado.connect(_mostrar_prompt_interaccion)" in texto
    assert "objetivo_perdido.connect(_ocultar_prompt_interaccion)" in texto


def test_prompt_es_contextual_remapeable_y_no_hardcodea_tecla() -> None:
    texto = fuente(CAMINANTE)
    assert "Control.PRESET_CENTER_BOTTOM" in texto
    assert "_prompt_interaccion.visible = false" in texto
    assert "_texto_interaccion_actual = texto" in texto
    assert '_prompt_interaccion.text = _texto_con_entrada("interactuar", _texto_interaccion_actual)' in texto
    assert "InputMap.action_get_events(accion)" in texto
    assert "_evento_pertenece_a_dispositivo(evento)" in texto
    assert "KEY_E" not in texto.split("func _montar_interaccion", 1)[1].split(
        "func _asegurar_controles_movimiento", 1
    )[0]
