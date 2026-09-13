from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAMINANTE = ROOT / "godot" / "guion" / "caminante.gd"


def fuente() -> str:
    return CAMINANTE.read_text(encoding="utf-8")


def test_movimiento_usa_acciones_propias() -> None:
    texto = fuente()
    for accion in (
        "mover_izquierda",
        "mover_derecha",
        "mover_adelante",
        "mover_atras",
    ):
        assert accion in texto
    assert 'Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")' not in texto


def test_wasd_y_flechas_quedan_emparejados() -> None:
    texto = fuente()
    assert "MOVER_IZQUIERDA, KEY_A, KEY_LEFT" in texto
    assert "MOVER_DERECHA, KEY_D, KEY_RIGHT" in texto
    assert "MOVER_ADELANTE, KEY_W, KEY_UP" in texto
    assert "MOVER_ATRAS, KEY_S, KEY_DOWN" in texto
    assert "if InputMap.has_action(accion):" in texto
    assert "InputMap.add_action(accion)" in texto
    assert "wasd.physical_keycode = tecla_fisica" in texto
    assert "cursor.keycode = flecha" in texto


def test_raton_y_mando_se_conservan_sin_cancelacion_paralela() -> None:
    texto = fuente()
    assert "InputEventMouseMotion" in texto
    assert 'evento.is_action_pressed("ui_cancel")' not in texto
    assert '"mirar_izquierda", "mirar_derecha", "mirar_arriba", "mirar_abajo"' in texto
    assert "Input.MOUSE_MODE_CAPTURED" in texto


def test_pisadas_quedan_atenuadas_sin_tocar_pitch() -> None:
    caminante = fuente()
    dia = (ROOT / "godot" / "guion" / "dia_app.gd").read_text(encoding="utf-8")
    assert "const VOLUMEN_PISADA_DB := -8.0" in caminante
    assert "hijo.volume_db = VOLUMEN_PISADA_DB" in caminante
    assert 'call_deferred("_ajustar_volumen_pisadas")' in caminante
    assert "_pisada.pitch_scale = randf_range(0.94, 1.06)" in dia
