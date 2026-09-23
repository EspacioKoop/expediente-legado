from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "software_siga_modelo.gd"
VISTA = ROOT / "godot" / "guion" / "software_siga.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def bloque_funcion(texto: str, nombre: str) -> str:
    inicio = texto.index(f"func {nombre}(")
    siguiente = texto.find("\nfunc ", inicio + 1)
    return texto[inicio:] if siguiente == -1 else texto[inicio:siguiente]


def test_catalogo_declara_al_menos_cinco_paquetes_y_varias_superficies() -> None:
    modelo = fuente(MODELO)
    assert modelo.count('"id":') >= 5
    for tipo in ("Visor de imágenes", "Compresor", "Texto decorativo", "Salvapantallas", "Reloj / alarma"):
        assert tipo in modelo
    for superficie in ("bbs", "web", "disquete", "correo"):
        assert f'"origen_superficie": "{superficie}"' in modelo


def test_instalar_y_desinstalar_son_deterministas_y_persistibles() -> None:
    modelo = fuente(MODELO)
    instalar = bloque_funcion(modelo, "instalar")
    desinstalar = bloque_funcion(modelo, "desinstalar")
    exportar = bloque_funcion(modelo, "exportar_estado")
    importar = bloque_funcion(modelo, "importar_estado")
    assert "rand" not in instalar.lower()
    assert "random" not in instalar.lower()
    assert "_instalados.append(id)" in instalar
    assert "_instalados.erase(id)" in desinstalar
    assert '"instalados": _instalados.duplicate()' in exportar
    assert 'estado.get("instalados", [])' in importar


def test_benchmark_es_interaccion_breve_y_no_inspecciona_hardware() -> None:
    modelo = fuente(MODELO)
    vista = fuente(VISTA)
    assert '"id": "turboindice-98"' in modelo
    assert '"interaccion": "benchmark"' in modelo
    ejecutar = bloque_funcion(modelo, "ejecutar")
    assert "680 + numero * 13" in ejecutar
    assert "OS." not in ejecutar
    assert "RenderingServer" not in ejecutar
    assert "Performance" not in ejecutar
    assert "func _ejecutar_seleccion(" in vista
    assert "_modelo.ejecutar(id)" in vista


def test_seguridad_no_abre_procesos_red_ni_filesystem_del_host() -> None:
    codigo = fuente(MODELO) + "\n" + fuente(VISTA)
    for prohibido in (
        "OS.execute",
        "HTTPRequest",
        "HTTPClient",
        "StreamPeerTCP",
        "PacketPeerUDP",
        "DirAccess",
        "FileAccess",
    ):
        assert prohibido not in codigo


def test_ui_conserva_activacion_por_teclado_y_no_hardcodea_teclas() -> None:
    vista = fuente(VISTA)
    assert "_lista.item_activated.connect(_activar_indice)" in vista
    assert "_instalar.pressed.connect(_alternar_instalacion)" in vista
    assert "_ejecutar.pressed.connect(_ejecutar_seleccion)" in vista
    assert "Input.is_key" not in vista
    assert "KEY_" not in vista


def test_software_se_registra_por_el_contrato_comun_y_persiste_estado_local() -> None:
    adaptador = fuente(ADAPTADOR)
    assert "var _software_app: EscritorioSigaApp" in adaptador
    assert '"software-98", "Archivo de programas", Callable(self, "_crear_software"), "software"' in adaptador
    assert "_software_app.persistir_estado = true" in adaptador
    assert "_software_app.registrar_en(escritorio)" in adaptador
    assert "func _crear_software() -> Control:" in adaptador
    assert "var software := SoftwareSiga.new()" in adaptador
    assert 'software.configurar_estado(_software_app.obtener_estado_local("estado", {}))' in adaptador
    assert "software.estado_cambiado.connect(_registrar_estado_software)" in adaptador
    assert 'func _registrar_estado_software(estado: Dictionary) -> void:' in adaptador
    assert '_software_app.establecer_estado_local("estado", estado)' in adaptador


def test_catalogo_es_opcional_y_no_toca_estado_de_campana() -> None:
    codigo = fuente(MODELO) + "\n" + fuente(VISTA)
    for dominio in ("Partida", "jornada", "expediente", "Prometeo", "Hastur"):
        assert dominio not in codigo
