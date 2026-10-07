from pathlib import Path
import re

TEXT = Path("godot/guion/cinematicas_psicodelicas.gd").read_text(encoding="utf-8")

IDS = [
    "psico-expediente-suena",
    "psico-comite-imposible",
    "psico-archivo-bajo-ciudad",
    "psico-jardin-colgante-siga",
    "psico-identidades-superpuestas",
    "psico-gran-ruptura-siga",
    "psico-procesion-archivados",
    "psico-ciudad-bajo-archivo",
]

FUNCS = [
    "_expediente_suena",
    "_comite_imposible",
    "_archivo_bajo_la_ciudad",
    "_jardin_colgante_siga",
    "_identidades_superpuestas",
    "_gran_ruptura_siga",
    "_procesion_de_los_archivados",
    "_ciudad_bajo_el_archivo",
]


def _chunk(name: str) -> str:
    start = TEXT.index(f"static func {name}()")
    end = TEXT.find("\n\nstatic func ", start + 1)
    return TEXT[start:] if end < 0 else TEXT[start:end]


def test_ids_estables_y_motor_comun():
    for cinematic_id in IDS:
        assert cinematic_id in TEXT
    assert "Cinematica.validar(declarados)" in TEXT
    assert "Cinematica.resolver(declarados, datos, vistas)" in TEXT


def test_todas_son_largas_y_multiescenario():
    for name in FUNCS:
        chunk = _chunk(name)
        assert chunk.count("_plano(") >= 8, name
        escenarios = sum(chunk.count(token) for token in (
            "_oficina(", "_archivo(", "_escuela(", "_desierto(", "_castillo(", "_vacio("
        ))
        assert escenarios >= 4, name


def test_figuras_humanas_forman_parte_del_montaje():
    assert "static func _figura(" in TEXT
    for name in FUNCS:
        chunk = _chunk(name)
        assert "_figura(" in chunk or "figura" in chunk or "operador" in chunk


def test_no_hay_autoplay_ni_mutacion_de_partida():
    for token in ("change_scene", "Partida.", "get_tree().", ".reproducir("):
        assert token not in TEXT


def test_nuevas_piezas_extienden_montaje_y_personajes():
    assert "static func _jardin_colgante(" in TEXT
    assert "static func _faro(" in TEXT
    assert "CAMBIOS GUARDADOS" in TEXT
    assert "IDENTIDAD PROVISIONAL" in TEXT


def test_gran_ruptura_combina_historia_edades_y_gato():
    chunk = _chunk("_gran_ruptura_siga")
    assert chunk.count("_plano(") >= 14
    assert "Puyi" in chunk
    assert "Pessoa" in chunk
    assert "_gato_os98(" in chunk
    assert "jubilación" in chunk
    assert "Babilonia" in chunk
    assert "Alejandría" in chunk


def test_procesion_es_coral_y_cruza_todos_los_mundos():
    chunk = _chunk("_procesion_de_los_archivados")
    assert chunk.count("_plano(") >= 11
    assert "Cuatro personas esperan" in chunk
    assert "Babilonia" in chunk
    assert "Alejandría" in chunk
    assert "gato OS98" in chunk
    assert "TURNO ACTUAL" in chunk


def test_personajes_largos_usan_rocketbox_y_no_maniquies_de_cajas():
    assert '"rocketbox/male_adult_13"' in TEXT
    assert '"rocketbox/business_male_02"' in TEXT
    assert '"rocketbox/business_male_03"' in TEXT
    figura = TEXT[TEXT.index("static func _figura("):TEXT.index("static func _decorado(")]
    assert '"modelo": modelo' in figura
    assert "_pieza(pos + Vector3" not in figura


def test_plato_admite_personas_y_modelos_3d_reales():
    puente = Path("godot/guion/cinematica_personas_3d.gd").read_text(encoding="utf-8")
    app = Path("godot/guion/cinematica_app.gd").read_text(encoding="utf-8")
    assert "Modelos.persona(" in puente
    assert 'decorado.get("modelos", [])' in puente
    assert "Modelos.cargar(nombre)" in puente
    assert "CinematicaPersonas3D.montar(_decorado, decorado)" in app


def test_decorados_cotidianos_reutilizan_props_3d_del_repo():
    for modelo in (
        "oficina_psx/desk1",
        "oficina_psx/file_cabinet_large",
        "styloo_school/principal_office_desk",
        "styloo_school/computer_pc_old",
    ):
        assert modelo in TEXT
    assert 'decorado["modelos"] = modelos' in TEXT


def test_ciudad_imposible_usa_props_reales_y_gravedad_invertida():
    chunk = _chunk("_ciudad_bajo_el_archivo")
    assert chunk.count("_plano(") >= 10
    assert "_archivo_infinito(" in chunk
    assert "_oficina_vertical(" in chunk
    assert "_calle_subterranea(" in chunk
    assert "PLANTA ACTUAL: -∞" in chunk
    for modelo in (
        "traffic_road/Manhole_Cover",
        "street_furniture/TrashCan",
        "psx_cars/Car03",
        "oficina_psx/file_cabinet_large",
    ):
        assert modelo in TEXT
