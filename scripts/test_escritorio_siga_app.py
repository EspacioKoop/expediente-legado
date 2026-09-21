from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRATO = ROOT / "godot" / "guion" / "escritorio_siga_app.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
SHELL = ROOT / "godot" / "guion" / "escritorio_siga.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_contrato_declara_identidad_capacidades_y_ciclo_de_vida() -> None:
    texto = fuente(CONTRATO)
    assert "class_name EscritorioSigaApp" in texto
    for campo in (
        "var id: String",
        "var titulo: String",
        "var creador: Callable",
        "var tamano_minimo",
        "var tamano_preferido",
        "var redimensionable",
        "var multiples_instancias",
        "var persistir_estado",
    ):
        assert campo in texto
    for operacion in (
        "func registrar_en(",
        "func adoptar_en(",
        "func abrir(",
        "func cerrar(",
        "func activar(",
        "func suspender(",
        "func restaurar(",
    ):
        assert operacion in texto


def test_contrato_delega_en_api_publica_del_shell() -> None:
    contrato = fuente(CONTRATO)
    shell = fuente(SHELL)
    delegaciones = {
        "registrar_aplicacion": "func registrar_aplicacion(",
        "adoptar_aplicacion": "func adoptar_aplicacion(",
        "abrir_aplicacion": "func abrir_aplicacion(",
        "cerrar": "func cerrar(",
        "enfocar": "func enfocar(",
        "minimizar": "func minimizar(",
        "restaurar": "func restaurar(",
    }
    for llamada, definicion in delegaciones.items():
        assert f"escritorio.{llamada}(" in contrato
        assert definicion in shell


def test_siga_98_es_primer_consumidor_real_del_contrato() -> None:
    texto = fuente(ADAPTADOR)
    assert "var _siga_app: EscritorioSigaApp" in texto
    assert 'EscritorioSigaApp.new("siga-98", titulo_siga, creador_visor, "siga")' in texto
    assert "_siga_app.tamano_minimo = Vector2(900, 620)" in texto
    assert "_siga_app.tamano_preferido = Vector2(1180, 800)" in texto
    assert "_siga_app.redimensionable = true" in texto
    assert "_siga_app.registrar_en(escritorio)" in texto
    assert "_siga_app.adoptar_en(escritorio, visor)" in texto
    assert 'load("res://escenas/visor.tscn")' in texto


def test_contrato_no_duplica_estado_de_campana() -> None:
    contrato = fuente(CONTRATO)
    assert "EstadoJuego" not in contrato
    assert "jornada" not in contrato.lower()
    assert "casos.json" not in contrato
    assert "persistir_estado := false" in contrato
    assert "if not persistir_estado" in contrato


def test_capacidades_son_declarativas_y_extensibles() -> None:
    texto = fuente(CONTRATO)
    assert "func describir_capacidades() -> Dictionary:" in texto
    for clave in (
        '"tamano_minimo"',
        '"tamano_preferido"',
        '"redimensionable"',
        '"multiples_instancias"',
        '"persistir_estado"',
    ):
        assert clave in texto
    assert 'has_method("registrar_identidad_visual")' in texto
