from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CAMINANTE = ROOT / "godot" / "guion" / "caminante.gd"
PREFERENCIAS = ROOT / "godot" / "guion" / "preferencias_siga.gd"


def test_camara_consumidora_de_preferencias_persistentes() -> None:
    caminante = CAMINANTE.read_text(encoding="utf-8")
    preferencias = PREFERENCIAS.read_text(encoding="utf-8")

    assert "PreferenciasSiga.cargar()" in caminante
    for clave in (
        "sensibilidad_camara_raton",
        "sensibilidad_camara_mando",
        "invertir_camara_y",
    ):
        assert clave in caminante
        assert clave in preferencias


def test_raton_y_stick_comparten_pitch_acotado_y_deadzone() -> None:
    texto = CAMINANTE.read_text(encoding="utf-8")

    assert "InputEventMouseMotion" in texto
    assert '"mirar_izquierda", "mirar_derecha", "mirar_arriba", "mirar_abajo"' in texto
    assert "const TOPE_VERTICAL := deg_to_rad(85.0)" in texto
    assert texto.count("-TOPE_VERTICAL") >= 2
    assert texto.count("TOPE_VERTICAL") >= 3
    assert "const ZONA_MUERTA := 0.12" in texto
    assert "(magnitud - ZONA_MUERTA) / (1.0 - ZONA_MUERTA)" in texto


def test_movimiento_tiene_aceleracion_frenado_y_analogico_real() -> None:
    texto = CAMINANTE.read_text(encoding="utf-8")

    assert "const ACELERACION := 10.0" in texto
    assert "const FRENADO := 14.0" in texto
    assert "move_toward(velocity.x, objetivo.x, respuesta * delta)" in texto
    assert "move_toward(velocity.z, objetivo.z, respuesta * delta)" in texto
    assert "Vector3(entrada.x, 0, entrada.y)" in texto
    assert ".normalized()" not in texto.split("func _physics_process", 1)[1].split(
        "func _mirar_con_mando", 1
    )[0]


def test_escape_no_tiene_dos_duenos_y_detector_sigue_la_camara() -> None:
    texto = CAMINANTE.read_text(encoding="utf-8")

    assert 'evento.is_action_pressed("ui_cancel")' not in texto
    assert "Input.MOUSE_MODE_CAPTURED" in texto
    assert "_camara.add_child(_detector_interaccion)" in texto

