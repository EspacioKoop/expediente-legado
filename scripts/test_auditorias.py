from pathlib import Path


RUTA = Path("godot/guion/auditorias.gd")
PARTIDA = Path("godot/guion/partida.gd")
PROMETEO = Path("godot/guion/prometeo.gd")
DIA = Path("godot/guion/dia_app.gd")
ASCENSOR = Path("godot/guion/dia_ascensor_app.gd")
SUENO = Path("godot/guion/dia_sueno_app.gd")
CREADOR = Path("godot/guion/creador_personaje_app.gd")
NUEVA_VIDA = Path("godot/guion/auditorias_nueva_vida_app.gd")
VISOR = Path("godot/guion/visor_expediente.gd")
GATO = Path("godot/guion/dia_gato_app.gd")


def texto() -> str:
    return RUTA.read_text(encoding="utf-8")


def test_catalogo_minimo_y_determinista():
    contenido = texto()
    for identificador in (
        '"sin_releer"',
        '"accion_sobrante"',
        '"gato_diario"',
        '"sueno_completo"',
    ):
        assert identificador in contenido
    assert "RandomNumberGenerator" not in contenido
    assert ".sort()" in contenido


def test_estado_guardable_sin_recompensas_de_juego():
    contenido = texto()
    assert '"activas"' in contenido
    assert '"fallidas"' in contenido
    assert '"completadas"' in contenido
    for termino in ("dinero", "acciones +=", "vidas", "pistas_descubiertas"):
        assert termino not in contenido


def test_no_se_acopla_a_jornada_ni_ui():
    contenido = texto()
    for termino in ("Jornada.", "Partida.", "Control", "Button", "Label"):
        assert termino not in contenido


def test_fallo_y_completado_son_terminales():
    contenido = texto()
    assert 'estado(auditoria, id) != "activa"' in contenido
    assert 'return "fallida"' in contenido
    assert 'return "completada"' in contenido


def test_persistencia_y_migracion_viven_en_partida():
    partida = PARTIDA.read_text(encoding="utf-8")
    assert "Auditorias.CLAVE_ESTADO: Auditorias.nueva()" in partida
    assert "Auditorias.validar(guardado[Auditorias.CLAVE_ESTADO])" in partida
    assert "Auditorias.asegurar_en_estado(fusionado)" in partida


def test_accion_sobrante_se_evalua_antes_de_fichar_en_ambas_rutas():
    llamada = "Auditorias.resolver_fin_archivo(partida.estado)"
    fichar = "Jornada.fichar_salida(jornada)"
    for ruta in (DIA, ASCENSOR):
        contenido = ruta.read_text(encoding="utf-8")
        assert llamada in contenido
        assert contenido.index(llamada) < contenido.index(fichar)


def test_reasignacion_limpia_la_condicion_de_la_vuelta():
    prometeo = PROMETEO.read_text(encoding="utf-8")
    assert "Auditorias.reiniciar_vuelta(estado)" in prometeo


def test_el_predicado_no_bloquea_ni_recompensa():
    contenido = texto()
    assert '"sin_accion_al_fichar"' in contenido
    assert "resolver_fin_archivo" in contenido
    for termino in ("Jornada.fichar_salida", "guardar(", "Sellos.", "Steam", "dinero +="):
        assert termino not in contenido


def test_seleccion_de_vuelta_tiene_estado_persistible_y_unico():
    contenido = texto()
    assert 'const CLAVE_SELECCION_RESUELTA := "seleccion_resuelta"' in contenido
    assert "static func seleccion_pendiente(" in contenido
    assert "static func resolver_seleccion(" in contenido
    assert "nueva([], historial_previo, false)" in contenido


def test_alta_y_reasignacion_resuelven_antes_de_empezar():
    creador = CREADOR.read_text(encoding="utf-8")
    dia = DIA.read_text(encoding="utf-8")
    assert "Auditorias.resolver_seleccion(_partida.estado, _auditorias.seleccion())" in creador
    assert "Auditorias.seleccion_pendiente(partida.estado)" in dia
    assert "AuditoriasNuevaVidaApp.new()" in dia
    assert "Auditorias.resolver_seleccion(partida.estado, seleccion)" in dia
    abrir = dia.split("func _abrir_vuelta() -> void:", 1)[1].split(
        "func _abrir_auditorias_nueva_vida", 1
    )[0]
    assert abrir.index("Auditorias.seleccion_pendiente(partida.estado)") < abrir.index(
        "_registrar_reincorporacion()"
    )


def test_modal_de_reasignacion_solo_emite_intencion():
    contenido = NUEVA_VIDA.read_text(encoding="utf-8")
    assert "signal seleccion_confirmada(seleccion: Array)" in contenido
    assert "AuditoriasSiga.new()" in contenido
    for prohibido in ("Partida.", "guardar(", "Auditorias.resolver_seleccion", "Jornada."):
        assert prohibido not in contenido


def test_gato_diario_se_evalua_antes_de_dormir_en_ambas_rutas():
    llamada = "Auditorias.resolver_fin_casa(partida.estado)"
    dormir = "Jornada.dormir(jornada)"
    for ruta in (DIA, SUENO):
        contenido = ruta.read_text(encoding="utf-8")
        assert llamada in contenido
        assert contenido.index(llamada) < contenido.index(dormir)


def test_gato_diario_usa_solo_estado_existente_y_no_recompensa():
    contenido = texto()
    bloque = contenido.split("static func resolver_fin_casa", 1)[1].split(
        "static func validar", 1
    )[0]
    assert 'gato.get("dias_sin_comer", 0)' in bloque
    assert '"gato_sin_comer_al_dormir"' in bloque
    assert '"gato_ausente_al_dormir"' in bloque
    for termino in ("Jornada.", "Sellos.", "Steam", "guardar(", "dinero +=", "acciones +="):
        assert termino not in bloque


def test_sin_releer_se_evalua_solo_tras_una_apertura_admitida():
    visor = VISOR.read_text(encoding="utf-8")
    bloque = visor.split("func _al_elegir_documento", 1)[1].split(
        "func _mostrar_registro", 1
    )[0]
    llamada = "Auditorias.resolver_apertura_documento(partida.estado, ya_visto)"
    denegacion = "if not Jornada.gastar_lectura"
    mostrar = "_mostrar_registro(registro)"
    assert llamada in bloque
    assert bloque.index(denegacion) < bloque.index(llamada)
    assert bloque.index(llamada) < bloque.index(mostrar)
    assert 'var auditoria_mutada := bool(auditoria_lectura.get("cambio", false))' in bloque
    assert "or auditoria_mutada" in bloque


def test_sin_releer_no_bloquea_ni_duplica_reglas_de_jornada():
    contenido = texto()
    bloque = contenido.split("static func resolver_apertura_documento", 1)[1].split(
        "static func validar", 1
    )[0]
    assert '"documento_releido"' in bloque
    assert "ya_visto_hoy" in bloque
    for termino in ("Jornada.", "guardar(", "Sellos.", "Steam", "dinero", "acciones"):
        assert termino not in bloque


def test_sueno_completo_distingue_salidas_normales_y_forzadas():
    dia = DIA.read_text(encoding="utf-8")
    gato = GATO.read_text(encoding="utf-8")

    normal = dia.split('match jornada["fase"]:', 1)[1].split(
        "## Reconoce una noche completada", 1
    )[0]
    sello = "_registrar_despertar_reglamentario()"
    resolver_ok = "Auditorias.resolver_fin_sueno(partida.estado, true)"
    despertar = "Jornada.despertar(jornada)"
    assert sello in normal and resolver_ok in normal and despertar in normal
    assert normal.index(sello) < normal.index(resolver_ok) < normal.index(despertar)

    objetivos = gato.split("func _resolver_objetivos_sueno", 1)[1].split(
        "func registrar_objetivo_puzzle_onirico", 1
    )[0]
    assert resolver_ok in objetivos
    assert objetivos.index(resolver_ok) < objetivos.index(despertar)

    proceso = dia.split("func _process(delta: float) -> void:", 1)[1].split(
        "func _guardar_o_avisar", 1
    )[0]
    resolver_fallo = "Auditorias.resolver_fin_sueno(partida.estado, false)"
    despertar_forzado = "Jornada.despertar_de_golpe(jornada)"
    assert resolver_fallo in proceso
    assert proceso.index(resolver_fallo) < proceso.index(despertar_forzado)

    duelo = dia.split("func _cerrar_duelo", 1)[1].split(
        "func _cerrar_expediente", 1
    )[0]
    assert "if not gano:" in duelo
    assert resolver_fallo in duelo
    assert duelo.index(resolver_fallo) < duelo.index("SuenoCombate.resolver")


def test_sueno_completo_recibe_un_hecho_y_no_duplica_sistemas():
    contenido = texto()
    bloque = contenido.split("static func resolver_fin_sueno", 1)[1].split(
        "static func validar", 1
    )[0]
    assert '"sueno_interrumpido"' in bloque
    assert "completado: bool" in bloque
    for termino in (
        "Jornada.",
        "Sueno.",
        "SuenoCombate.",
        "Sellos.",
        "Steam",
        "guardar(",
        "dinero",
        "acciones",
        "vida",
    ):
        assert termino not in bloque
