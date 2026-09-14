from pathlib import Path


RUTA = Path("godot/guion/auditorias.gd")


def texto() -> str:
    return RUTA.read_text(encoding="utf-8")


def test_catalogo_minimo_y_determinista():
    contenido = texto()
    for identificador in (
        '"sin_releer"',
        '"accion_sobrante"',
        '"gato_diario"',
        '"sueno_completo"',
    ):
        assert identificador in contenido
    assert "RandomNumberGenerator" not in contenido
    assert ".sort()" in contenido


def test_estado_guardable_sin_recompensas_de_juego():
    contenido = texto()
    assert '"activas"' in contenido
    assert '"fallidas"' in contenido
    assert '"completadas"' in contenido
    for termino in ("dinero", "acciones +=", "vidas", "pistas_descubiertas"):
        assert termino not in contenido


def test_no_se_acopla_a_jornada_ni_ui():
    contenido = texto()
    for termino in ("Jornada.", "Partida.", "Control", "Button", "Label"):
        assert termino not in contenido


def test_fallo_y_completado_son_terminales():
    contenido = texto()
    assert 'estado(auditoria, id) != "activa"' in contenido
    assert 'return "fallida"' in contenido
    assert 'return "completada"' in contenido
