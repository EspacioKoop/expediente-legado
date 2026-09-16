from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUTINAS = ROOT / "godot/guion/casa_rutinas.gd"
RUTINAS_3D = ROOT / "godot/guion/casa_rutinas_3d.gd"
INTERACCION = ROOT / "godot/guion/casa_rutina_interactiva_3d.gd"
AMBIENTAL = ROOT / "godot/guion/casa_estado_ambiental.gd"
CONTROLLER = ROOT / "godot/guion/dia_rutinas_casa_app.gd"
ESCENA = ROOT / "godot/escenas/dia.tscn"


def test_cinco_microinteracciones_domesticas():
    codigo = RUTINAS_3D.read_text(encoding="utf-8")
    assert "TOTAL_MICROINTERACCIONES := 5" in codigo
    for nombre in (
        "PersianaCasaInteractuable",
        "VentanaCasaInteractuable",
        "NeveraCasaInteractuable",
        "PlatosCasaInteractuables",
        "ToallaCasaInteractuable",
    ):
        assert nombre in codigo


def test_no_hay_barras_de_necesidades():
    codigo = (RUTINAS.read_text(encoding="utf-8") + RUTINAS_3D.read_text(encoding="utf-8")).lower()
    for prohibido in ("hambre", "higiene", "confort", "energia", "energía"):
        assert prohibido not in codigo


def test_reutiliza_estado_ambiental_y_anclas_existentes():
    ambiental = AMBIENTAL.read_text(encoding="utf-8")
    controller = CONTROLLER.read_text(encoding="utf-8")
    escena = ESCENA.read_text(encoding="utf-8")
    assert '"rutinas_casa": CasaRutinas.estado(jornada)' in ambiental
    assert "CasaEstadoAmbientalScript.derivar" in controller
    assert 'find_child("VentanaCasa"' in controller
    assert 'path="res://guion/dia_rutinas_casa_app.gd" id="29"' in escena
    assert '[node name="RutinasCasaController" type="Node" parent="."]' in escena


def test_reduccion_movimiento_conserva_estado_final_sin_tween():
    codigo = INTERACCION.read_text(encoding="utf-8")
    controller = CONTROLLER.read_text(encoding="utf-8")
    assert "_reduccion_movimiento" in codigo
    assert "or _reduccion_movimiento" in codigo
    assert 'PreferenciasSiga.cargar().get("reduccion_movimiento", false)' in controller


def test_persistencia_acotada_por_jornada():
    codigo = RUTINAS.read_text(encoding="utf-8")
    assert "PERSISTENTES := [PERSIANA_ABIERTA, PLATOS_RECOGIDOS, TOALLA_TENDIDA]" in codigo
    assert "DIARIAS := [VENTANA_ABIERTA, NEVERA_ABIERTA]" in codigo
