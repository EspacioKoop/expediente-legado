from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INICIO = ROOT / "godot/guion/inicio_app.gd"
MENU = ROOT / "godot/guion/menu_global.gd"


def test_inicio_usa_tema_de_juego_y_feedback_visible() -> None:
    codigo = INICIO.read_text(encoding="utf-8")
    assert "theme = EstiloJuego.tema()" in codigo
    assert "boton.flat = false" in codigo
    assert 'font_hover_color", EstiloJuego.ACENTO' in codigo
    assert 'font_focus_color", EstiloJuego.ACENTO' in codigo
    assert 'add_theme_stylebox_override("focus", EstiloJuego.caja_foco())' in codigo
    assert "COLOR_FONDO_ITEM_HOVER" in codigo
    assert "COLOR_FONDO_ITEM_PULSADO" in codigo


def test_menu_global_respeta_margen_seguro_y_viewport() -> None:
    codigo = MENU.read_text(encoding="utf-8")
    assert "const MARGEN_SEGURO_PANEL := 48.0" in codigo
    assert "get_viewport().get_visible_rect().size" in codigo
    assert "minf(ANCHO_PANEL, ancho_disponible)" in codigo
    assert "minf(ALTO_MAXIMO_PANEL, alto_disponible)" in codigo
    assert 'margen.add_theme_constant_override("margin_" + lado, 16)' in codigo
    assert 'caja.add_theme_constant_override("separation", 16)' in codigo


def test_cancelar_retrocede_antes_de_cerrar_el_menu() -> None:
    codigo = MENU.read_text(encoding="utf-8")
    assert "func _volver_un_nivel() -> bool:" in codigo
    assert "if not _volver_un_nivel():" in codigo
    assert "_mostrar_principal(_opciones)" in codigo
    assert "_mostrar_principal(_sellos)" in codigo
    assert "_mostrar_principal(_historial_boton)" in codigo


def test_diorama_responde_al_foco_y_al_hover() -> None:
    codigo = INICIO.read_text(encoding="utf-8")
    assert "boton.focus_entered.connect(_diorama.enfocar.bind(zona))" in codigo
    assert "boton.mouse_entered.connect(_diorama.enfocar.bind(zona))" in codigo
