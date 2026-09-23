import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "software_siga_modelo.gd"
VISTA = ROOT / "godot" / "guion" / "software_siga.gd"
EXPLORADOR = ROOT / "godot" / "guion" / "explorador_siga.gd"
CORREO = ROOT / "godot" / "guion" / "correo_siga.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
CATALOGO_CORREO = ROOT / "godot" / "datos" / "correo_corporativo.json"
TEXTOS_CORREO = ROOT / "godot" / "datos" / "correo_siga_textos.json"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def bloque_funcion(texto: str, nombre: str) -> str:
    inicio = texto.index(f"func {nombre}(")
    siguiente = texto.find("\nfunc ", inicio + 1)
    return texto[inicio:] if siguiente == -1 else texto[inicio:siguiente]


def test_modelo_persiste_paquetes_obtenidos_y_migra_instalados() -> None:
    modelo = fuente(MODELO)
    exportar = bloque_funcion(modelo, "exportar_estado")
    importar = bloque_funcion(modelo, "importar_estado")
    registrar = bloque_funcion(modelo, "registrar_obtencion")
    assert "var _obtenidos: Array[String]" in modelo
    assert '"obtenidos": _obtenidos.duplicate()' in exportar
    assert 'estado.get("obtenidos", [])' in importar
    assert "if not _obtenidos.has(id):" in importar
    assert "_obtenidos.append(id)" in registrar
    assert "rand" not in registrar.lower()


def test_medios_extraibles_entregan_paquete_al_archivo_de_programas() -> None:
    explorador = fuente(EXPLORADOR)
    assert "signal paquete_software_obtenido(id: String)" in explorador
    bloque = bloque_funcion(explorador, "_abrir_paquete_software")
    assert "SoftwareSigaModelo.new().ficha(paquete_id)" in bloque
    assert "paquete_software_obtenido.emit(paquete_id)" in bloque


def test_correo_controlado_entrega_relojito_pro() -> None:
    mensajes = json.loads(CATALOGO_CORREO.read_text(encoding="utf-8"))["mensajes"]
    mensaje = next(m for m in mensajes if m["id"] == "spam-relojito-pro")
    assert mensaje["adjunto"] == "RELOJ18.ZIP"
    assert mensaje["paquete_software"] == "relojito-pro"
    assert mensaje["importancia_narrativa"] is False

    correo = fuente(CORREO)
    textos = json.loads(TEXTOS_CORREO.read_text(encoding="utf-8"))
    assert textos["abrir_adjunto"] == "Abrir adjunto: %s"
    assert "signal paquete_software_obtenido(id: String)" in correo
    assert 'mensaje.get("paquete_software", "")' in correo
    assert "paquete_software_obtenido.emit(_adjunto_paquete_id)" in correo


def test_adaptador_unifica_correo_y_explorador_sin_tocar_campana() -> None:
    adaptador = fuente(ADAPTADOR)
    assert (
        "explorador.paquete_software_obtenido.connect(_registrar_paquete_software_obtenido)"
        in adaptador
    )
    assert (
        "correo.paquete_software_obtenido.connect(_registrar_paquete_software_obtenido)"
        in adaptador
    )
    bloque = bloque_funcion(adaptador, "_registrar_paquete_software_obtenido")
    assert "SoftwareSigaModelo.new()" in bloque
    assert 'obtener_estado_local("estado", {})' in bloque
    assert 'establecer_estado_local("estado", modelo.exportar_estado())' in bloque
    for prohibido in ("Partida", "jornada", "Prometeo", "Hastur"):
        assert prohibido not in bloque


def test_vista_marca_fuentes_sin_bloquear_instalacion_legacy() -> None:
    vista = fuente(VISTA)
    assert "func registrar_obtencion(id: String) -> bool:" in vista
    assert 'SoftwareSigaTextos.texto("fuente_marca")' in vista
    assert '"fuente_obtenida" if _modelo.esta_obtenido(id) else "fuente_pendiente"' in vista
    instalar = bloque_funcion(vista, "_alternar_instalacion")
    assert "_modelo.instalar(id)" in instalar
