from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = ROOT / "godot" / "guion" / "escritorio_siga.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_shell_es_unico_dueno_del_ciclo_de_ventanas() -> None:
    texto = fuente(SHELL)
    assert "class_name EscritorioSiga" in texto
    assert "var _ventanas: Dictionary = {}" in texto
    for operacion in (
        "func abrir_aplicacion(",
        "func minimizar(",
        "func restaurar(",
        "func cerrar(",
        "func enfocar(",
    ):
        assert operacion in texto
    assert "panel.z_index = _z_siguiente" in texto
    assert "func _limitar_ventana(" in texto
    assert "ANCHO_TITULO_RECUPERABLE" in texto


def test_escritorio_tiene_barra_menu_reloj_y_dos_lanzadores() -> None:
    texto = fuente(SHELL)
    assert 'name = "BarraInferior"' in texto
    assert 'name = "MenuSistema"' in texto
    assert 'name = "RelojNarrativo"' in texto
    assert 'registrar_aplicacion("ayuda-sistema", "Ayuda"' in texto

    adaptador = fuente(ADAPTADOR)
    assert 'registrar_aplicacion("siga-98", "SIGA-98"' in adaptador
    assert "activar_ayuda_sistema()" in adaptador
    assert 'adoptar_aplicacion("siga-98", "SIGA-98", visor' in adaptador


def test_lanzadores_requieren_doble_clic_o_teclado() -> None:
    texto = fuente(SHELL)
    assert "raton.double_click" in texto
    assert "KEY_ENTER" in texto
    assert "KEY_SPACE" in texto
    assert "focus_mode = Control.FOCUS_ALL" in texto
    assert "grab_focus()" in texto


def test_barra_refleja_minimizar_restaurar_y_cerrar() -> None:
    texto = fuente(SHELL)
    assert 'datos["minimizada"] = true' in texto
    assert 'datos["minimizada"] = false' in texto
    assert "tarea.queue_free()" in texto
    assert "_actualizar_boton_tarea(id)" in texto
    assert "_al_pulsar_tarea" in texto


def test_adaptador_solo_envuelve_el_visor_del_puesto() -> None:
    texto = fuente(ADAPTADOR)
    assert 'get_node_or_null("Visor")' in texto
    assert "dia._pantalla" in texto
    assert 'load("res://escenas/visor.tscn")' in texto
    assert "dia._cerrar_expediente()" in texto
    assert "duelo" not in texto.lower()


def test_reduccion_movimiento_reutiliza_preferencia_existente() -> None:
    shell = fuente(SHELL)
    adaptador = fuente(ADAPTADOR)
    assert "configurar_reduccion_movimiento" in shell
    assert "PreferenciasSiga.cargar()" in adaptador
    assert 'preferencias.get("reduccion_movimiento", false)' in adaptador


def test_reloj_no_usa_hora_real_del_equipo() -> None:
    shell = fuente(SHELL)
    adaptador = fuente(ADAPTADOR)
    combinado = shell + adaptador
    assert "Time.get_" not in combinado
    assert "OS.get_" not in combinado
    assert 'dia.jornada.get("dia", 1)' in adaptador


def test_dia_monta_controller_sin_cambiar_su_raiz_historica() -> None:
    escena = fuente(DIA)
    assert 'path="res://guion/dia_clima_app.gd" id="1"' in escena
    assert 'path="res://guion/dia_escritorio_siga_app.gd" id="12"' in escena
    assert '[node name="EscritorioSigaController" type="Node" parent="."]' in escena
    assert 'script = ExtResource("12")' in escena
