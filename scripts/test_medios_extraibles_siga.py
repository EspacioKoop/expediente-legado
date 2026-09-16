from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEDIOS = ROOT / "godot" / "guion" / "medios_extraibles_siga_modelo.gd"
EXPLORADOR = ROOT / "godot" / "guion" / "explorador_siga.gd"
SOFTWARE = ROOT / "godot" / "guion" / "software_siga_modelo.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def bloque_funcion(texto: str, nombre: str) -> str:
    inicio = texto.index(f"func {nombre}(")
    siguiente = texto.find("\nfunc ", inicio + 1)
    return texto[inicio:] if siguiente == -1 else texto[inicio:siguiente]


def test_catalogo_declara_tres_medios_con_contrato_completo() -> None:
    medios = fuente(MEDIOS)
    for medio_id in (
        "disquete_trabajo_97",
        "disquete_personal",
        "cd_byte_lunar_06",
    ):
        assert f'"id": "{medio_id}"' in medios
    for campo in (
        '"etiqueta"',
        '"tipo"',
        '"capacidad"',
        '"unidad"',
        '"solo_lectura"',
        '"icono"',
        '"procedencia"',
        '"obtener_si"',
        '"entradas"',
    ):
        assert campo in medios
    assert '"tipo": "Disquete 3½"' in medios
    assert '"tipo": "CD-ROM"' in medios
    assert '"capacidad": "1,44 MB"' in medios
    assert '"capacidad": "650 MB"' in medios
    assert '"solo_lectura": false' in medios
    assert medios.count('"solo_lectura": true') >= 2


def test_montaje_es_determinista_y_respeta_ranuras() -> None:
    medios = fuente(MEDIOS)
    montar = bloque_funcion(medios, "montar")
    desmontar = bloque_funcion(medios, "desmontar")
    assert medios.count('"unidad": "a"') == 2
    assert medios.count('"unidad": "d"') == 1
    assert 'String(otro.get("unidad", "")) == unidad' in montar
    assert "_montados.erase(String(otro_id))" in montar
    assert "_montados.append(id)" in montar
    assert "_montados.erase(id)" in desmontar
    assert '"unidad_persistente": true' in medios
    assert '"unidad_persistente": false' in medios


def test_contenido_bloqueado_no_aparece_antes_de_tiempo() -> None:
    medios = fuente(MEDIOS)
    assert (
        '"obtener_si": {"clave": "jornada", "op": ">=", "valor": 2}'
        in medios
    )
    assert (
        '"visible_si": {"clave": "jornada", "op": ">=", "valor": 3}'
        in medios
    )
    disponibles = bloque_funcion(medios, "medios_disponibles")
    resolver = bloque_funcion(medios, "resolver_ruta")
    listar = bloque_funcion(medios, "listar_ruta")
    condicion = bloque_funcion(medios, "_cumple_condicion")
    assert 'medio.get("disponible", false)' in disponibles
    assert '_cumple_condicion(entrada.get("visible_si", {}) as Dictionary)' in resolver
    assert '_cumple_condicion(entrada.get("visible_si", {}) as Dictionary)' in listar
    assert 'not _contexto.has(clave)' in condicion
    assert 'float(actual) >= float(esperado)' in condicion


def test_medios_distribuyen_paquetes_reales_del_catalogo_663() -> None:
    medios = fuente(MEDIOS)
    explorador = fuente(EXPLORADOR)
    software = fuente(SOFTWARE)
    for paquete_id in ("nebulosa-scr", "astro-topo-demo", "pixelvista-14"):
        assert f'"paquete_id": "{paquete_id}"' in medios
        assert f'"id": "{paquete_id}"' in software
    assert '"accion": "mostrar_paquete_software"' in medios
    assert "SoftwareSigaModelo.new().ficha(paquete_id)" in explorador
    assert "func _abrir_paquete_software(" in explorador


def test_explorador_monta_desmonta_y_sobrevive_a_retirada() -> None:
    explorador = fuente(EXPLORADOR)
    alternar = bloque_funcion(explorador, "_alternar_medio")
    resolver = bloque_funcion(explorador, "_resolver_ruta")
    atras = bloque_funcion(explorador, "_ir_atras")
    adelante = bloque_funcion(explorador, "_ir_adelante")
    assert "_medios.desmontar(id)" in alternar
    assert "_medios.montar(id)" in alternar
    assert "_medios.ruta_pertenece_a_medio(_ruta_actual, id)" in alternar
    assert "_navegar_a(destino, true)" in alternar
    assert "Medio retirado; la ventana permanece abierta" in alternar
    assert "return _medios.resolver_ruta(ruta)" in resolver
    assert "_resolver_ruta(_historial[destino]).is_empty()" in atras
    assert "_resolver_ruta(_historial[destino]).is_empty()" in adelante


def test_ui_de_medios_conserva_controles_de_teclado_y_foco() -> None:
    explorador = fuente(EXPLORADOR)
    assert "OptionButton.new()" in explorador
    assert "Button.new()" in explorador
    assert "_selector_medio.item_selected.connect(_medio_seleccionado)" in explorador
    assert "_boton_medio.pressed.connect(_alternar_medio)" in explorador
    assert "_lista.item_activated.connect(_activar_indice)" in explorador
    assert "_ruta.text_submitted.connect(_ruta_introducida)" in explorador
    assert "size_flags_horizontal = Control.SIZE_EXPAND_FILL" in explorador
    assert "size_flags_vertical = Control.SIZE_EXPAND_FILL" in explorador


def test_simulacion_no_toca_filesystem_dispositivos_ni_progreso_real() -> None:
    medios = fuente(MEDIOS)
    explorador = fuente(EXPLORADOR)
    combinado = medios + "\n" + explorador
    for api_prohibida in (
        "DirAccess",
        "FileAccess",
        "OS.execute",
        "HTTPRequest",
        "HTTPClient",
        "TCPServer",
        "StreamPeerTCP",
        "JavaScriptBridge",
    ):
        assert api_prohibida not in combinado
    assert "Partida" not in medios
    assert "guardar(" not in medios
    assert "jornada =" not in medios
    assert "progreso" not in medios.lower()


def test_medios_son_opcionales_y_no_alteran_el_modelo_base() -> None:
    explorador = fuente(EXPLORADOR)
    resolver = bloque_funcion(explorador, "_resolver_ruta")
    listar = bloque_funcion(explorador, "_listar_ruta")
    assert "var entrada := _modelo.resolver_ruta(ruta)" in resolver
    assert "if not entrada.is_empty():" in resolver
    assert "return entrada" in resolver
    assert "var resultado := _modelo.listar_ruta(ruta)" in listar
    assert "resultado.append_array(_medios.listar_ruta(ruta))" in listar
