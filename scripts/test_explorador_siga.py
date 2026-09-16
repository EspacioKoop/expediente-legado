from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "explorador_siga_modelo.gd"
VISTA = ROOT / "godot" / "guion" / "explorador_siga.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def bloque_funcion(texto: str, nombre: str) -> str:
    inicio = texto.index(f"func {nombre}(")
    siguiente = texto.find("\nfunc ", inicio + 1)
    return texto[inicio:] if siguiente == -1 else texto[inicio:siguiente]


def test_modelo_declara_jerarquia_fuera_de_la_ui() -> None:
    modelo = fuente(MODELO)
    vista = fuente(VISTA)
    for campo in (
        '"id"',
        '"ruta"',
        '"nombre"',
        '"tipo"',
        '"contenido"',
        '"fecha_narrativa"',
        '"visible_si"',
        '"acceso_si"',
        '"accion"',
        '"persistencia"',
    ):
        assert campo in modelo
    assert '"equipo/c"' in modelo
    assert '"equipo/red"' in modelo
    assert '"equipo/documentos"' in modelo
    assert '"equipo/papelera"' in modelo
    assert "var _entradas" not in vista


def test_resolucion_normaliza_y_busca_rutas_estables() -> None:
    modelo = fuente(MODELO)
    normalizar = bloque_funcion(modelo, "normalizar_ruta")
    resolver = bloque_funcion(modelo, "resolver_ruta")
    padre = bloque_funcion(modelo, "ruta_padre")
    assert '.replace("\\\\", "/")' in normalizar
    assert ".to_lower()" in normalizar
    assert 'String(entrada.get("ruta", "")) == normalizada' in resolver
    assert "RUTA_RAIZ" in padre
    assert '"/".join(partes)' in padre


def test_visibilidad_reactiva_depende_de_jornada_real() -> None:
    modelo = fuente(MODELO)
    adaptador = fuente(ADAPTADOR)
    assert '"id": "registro_jornada_anterior"' in modelo
    assert '"visible_si": {"clave": "jornada", "op": ">=", "valor": 2}' in modelo
    condicion = bloque_funcion(modelo, "_cumple_condicion")
    assert 'not _contexto.has(clave)' in condicion
    mayor_igual = bloque_funcion(modelo, "_cumple_mayor_igual")
    assert 'return float(actual) >= float(esperado)' in mayor_igual
    assert 'int(dia.jornada.get("dia", 1))' in adaptador
    assert 'ContaminacionOs98.contexto(' in adaptador


def test_enlace13_se_activa_desde_estado_os98_persistente() -> None:
    modelo = fuente(MODELO)
    vista = fuente(VISTA)
    adaptador = fuente(ADAPTADOR)
    assert '"id": "memorandum_enlace13"' in modelo
    assert '"id": "enlace13_reservado"' in modelo
    assert '"acceso_si": {"clave": "credenciales", "op": "incluye", "valor": "enlace13"}' in modelo
    assert 'signal documento_abierto(id: String)' in vista
    assert 'signal ruta_abierta(ruta: String)' in vista
    assert "_explorador_app.persistir_estado = true" in adaptador
    assert '"contaminacion_por_vuelta"' in adaptador
    assert "func _clave_vuelta(" in adaptador
    assert "ContaminacionOs98.contexto(" in adaptador
    incluye = bloque_funcion(modelo, "_cumple_incluye")
    assert '(actual as Array).has(esperado)' in incluye


def test_primera_incoherencia_esta_gobernada_por_fase() -> None:
    modelo = fuente(MODELO)
    assert '"id": "diagnostico_enlace13"' in modelo
    assert '"id": "registro_imposible_13"' in modelo
    assert '"visible_si": {"clave": "fase_contaminacion", "op": ">=", "valor": 2}' in modelo
    assert '"04/01/1999"' in modelo
    assert '"http://intranet.dgai/cache/diag-13/"' in modelo


def test_tres_tipos_documentales_tienen_accion_de_apertura() -> None:
    modelo = fuente(MODELO)
    vista = fuente(VISTA)
    for tipo in ("texto", "circular", "formulario"):
        assert f'"tipo": "{tipo}"' in modelo
        assert f'"{tipo}":' in vista
    assert modelo.count('"accion": "mostrar_contenido"') >= 3
    assert "func _abrir_documento(" in vista
    assert "_modelo.registrar_apertura(documento_id)" in vista


def test_recientes_refleja_documentos_abiertos_y_papelera_no_es_obligatoria() -> None:
    modelo = fuente(MODELO)
    vista = fuente(VISTA)
    assert 'const RUTA_RECIENTES := "equipo/recientes"' in modelo
    assert 'const RUTA_PAPELERA := "equipo/papelera"' in modelo
    recientes = bloque_funcion(modelo, "registrar_apertura")
    assert "_recientes.erase(id)" in recientes
    assert "_recientes.push_front(id)" in recientes
    assert "_recientes.resize(8)" in recientes
    assert "RUTA_RECIENTES" in vista
    assert '"Papelera"' in modelo
    assert "borrar" not in vista.lower()


def test_ui_ofrece_doble_clic_enter_historial_y_ruta() -> None:
    vista = fuente(VISTA)
    assert "_lista.item_activated.connect(_activar_indice)" in vista
    assert "func _ir_atras(" in vista
    assert "func _ir_adelante(" in vista
    assert "func _ir_arriba(" in vista
    assert "_ruta.text_submitted.connect(_ruta_introducida)" in vista
    assert "Acceso denegado" in vista


def test_explorador_se_registra_mediante_contrato_535() -> None:
    adaptador = fuente(ADAPTADOR)
    assert "var _explorador_app: EscritorioSigaApp" in adaptador
    assert '"explorador", "Explorador", Callable(self, "_crear_explorador"), "equipo"' in adaptador
    assert "_explorador_app.registrar_en(escritorio)" in adaptador
    assert "func _crear_explorador() -> Control:" in adaptador
    assert "var explorador := ExploradorSiga.new()" in adaptador
