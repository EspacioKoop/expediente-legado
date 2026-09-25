import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "godot" / "datos" / "web98_indice.json"
BBS = ROOT / "godot" / "datos" / "bbs98.json"
MODELO_BBS = ROOT / "godot" / "guion" / "bbs98_modelo.gd"
INDICE = ROOT / "godot" / "guion" / "web98_indice.gd"
NAVEGADOR = ROOT / "godot" / "guion" / "navegador_siga.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
SOFTWARE = ROOT / "godot" / "guion" / "software_siga_modelo.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_web_y_bbs_referencian_paquetes_reales_del_catalogo() -> None:
    ids = set()
    for line in fuente(SOFTWARE).splitlines():
        line = line.strip()
        if line.startswith('"id":'):
            ids.add(line.split('"')[3])

    web = json.loads(fuente(WEB))
    becario = next(r for r in web["recursos"] if r["id"] == "pagina-becario")
    assert becario["paquete_software"] == "bannerlab-95"
    assert becario["paquete_software"] in ids

    bbs = json.loads(fuente(BBS))
    byte = next(t for t in bbs["tablones"] if t["id"] == "byte-local-bbs")
    assert byte["paquete_software"] == "archivazo-21"
    assert byte["paquete_software"] in ids


def test_indice_web_incorpora_bbs_sin_congelar_visibilidad() -> None:
    modelo = fuente(MODELO_BBS)
    indice = fuente(INDICE)
    assert "func recursos_web_catalogo()" in modelo
    assert '"disponible_desde_dia": int(tablon.get("visible_desde_dia", 1))' in modelo
    assert '"requiere_conocimiento": tablon.get("requiere_conocimiento", []).duplicate(true)' in modelo
    assert "func _cargar_bbs()" in indice
    assert "bbs.recursos_web_catalogo()" in indice
    assert '"byte-local-bbs"' in indice


def test_navegador_emite_adquisicion_con_boton_estandar_y_escalable() -> None:
    navegador = fuente(NAVEGADOR)
    assert "signal paquete_software_obtenido(id: String)" in navegador
    assert '_descargar_software = Button.new()' in navegador
    assert '_descargar_software.pressed.connect(_obtener_software_actual)' in navegador
    assert 'recurso.get("paquete_software", "")' in navegador
    assert "SoftwareSigaModelo.new().ficha(paquete_id)" in navegador
    assert "paquete_software_obtenido.emit(_paquete_software_actual)" in navegador
    assert '_descargar_software.add_theme_font_size_override("font_size", lista)' in navegador
    assert "NAVEGADOR_DESCARGAR_SOFTWARE,Descargar %s" in fuente(TEXTOS)


def test_adaptador_reutiliza_el_mismo_sink_de_correo_y_medios() -> None:
    adaptador = fuente(ADAPTADOR)
    conexion = (
        "navegador.paquete_software_obtenido.connect("
        "_registrar_paquete_software_obtenido)"
    )
    assert conexion in adaptador
    assert "func _registrar_paquete_software_obtenido(id: String) -> void:" in adaptador
    assert 'establecer_estado_local("estado", modelo.exportar_estado())' in adaptador


def test_corte_sigue_sin_red_ni_procesos_reales() -> None:
    codigo = "\n".join(
        [fuente(MODELO_BBS), fuente(INDICE), fuente(NAVEGADOR)]
    )
    for prohibido in (
        "HTTPRequest",
        "HTTPClient",
        "StreamPeerTCP",
        "WebSocketPeer",
        "OS.execute(",
        "OS.create_process(",
    ):
        assert prohibido not in codigo


def test_navegador_renderiza_bbs_y_rutas_de_hilo_sin_red_paralela() -> None:
    navegador = fuente(NAVEGADOR)
    assert "var _bbs := Bbs98Modelo.new()" in navegador
    assert "_bbs.configurar_contexto(_contexto)" in navegador
    assert 'elif tipo_recurso == "bbs":' in navegador
    assert "_renderizar_bbs(resultado, recurso, url)" in navegador
    assert 'find("#hilo=")' in navegador
    assert 'resultado["bbs_hilo_id"] = hilo_bbs' in navegador
    assert '_bbs.hilos_de(tablon_id)' in navegador
    assert '_bbs.mensajes_de(hilo_id)' in navegador
    assert '_bbs.referencia_de_mensaje(String(mensaje.get("id", "")))' in navegador
