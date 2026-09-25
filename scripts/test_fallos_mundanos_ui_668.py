from pathlib import Path

from scripts.godot_pruebas import ejecutar_script

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "godot" / "guion" / "fallo_mundano_siga_panel.gd"
SOFTWARE = ROOT / "godot" / "guion" / "software_siga.gd"
MODELO_SOFTWARE = ROOT / "godot" / "guion" / "software_siga_modelo.gd"
EXPLORADOR = ROOT / "godot" / "guion" / "explorador_siga.gd"
PRUEBA_GODOT = "pruebas/pruebas_fallos_mundanos_ui.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_panel_es_inline_cerrable_y_sin_movimiento() -> None:
    panel = fuente(PANEL)
    assert "extends VBoxContainer" in panel
    assert 'visible = false' in panel
    assert "Control.FOCUS_ALL" in panel
    assert "grab_focus.call_deferred()" in panel
    assert "gui_get_focus_owner()" in panel
    assert "AnimationPlayer" not in panel
    assert "Tween" not in panel
    assert "create_tween" not in panel


def test_shareware_expira_de_forma_determinista_y_persistible() -> None:
    modelo = fuente(MODELO_SOFTWARE)
    assert 'id == "relojito-pro" and numero >= 3' in modelo
    assert '"id": "shareware_expirado"' in modelo
    assert '"evento": "licencia_expirada"' in modelo
    assert '"ejecuciones": _ejecuciones.duplicate(true)' in modelo
    assert "RandomNumberGenerator" not in modelo


def test_software_y_explorador_reutilizan_el_mismo_panel() -> None:
    software = fuente(SOFTWARE)
    explorador = fuente(EXPLORADOR)
    for codigo in (software, explorador):
        assert "FalloMundanoSigaPanel.new()" in codigo
        assert ".presentar(" in codigo
    assert '"shareware_expirado"' in software
    assert '"licencia_expirada"' in software
    assert '"medio_retirado"' in explorador
    assert '"ruta_medio_retirado"' in explorador


def test_no_se_introduce_estado_de_campana_ni_api_host() -> None:
    codigo = "\n".join(
        fuente(path)
        for path in (PANEL, SOFTWARE, MODELO_SOFTWARE, EXPLORADOR)
    )
    for prohibido in (
        "OS.execute",
        "OS.create_process",
        "HTTPRequest",
        "HTTPClient",
        "StreamPeerTCP",
        "PacketPeerUDP",
    ):
        assert prohibido not in codigo


def test_panel_ejecutable_en_godot() -> None:
    resultado = ejecutar_script(PRUEBA_GODOT)
    assert resultado.returncode == 0, resultado.stdout
    assert "0 fallos" in resultado.stdout
    assert "Parse Error:" not in resultado.stdout
    assert "SCRIPT ERROR:" not in resultado.stdout
