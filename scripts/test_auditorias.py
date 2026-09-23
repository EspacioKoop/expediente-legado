from pathlib import Path


RUTA = Path("godot/guion/auditorias.gd")
PARTIDA = Path("godot/guion/partida.gd")
PROMETEO = Path("godot/guion/prometeo.gd")
DIA = Path("godot/guion/dia_app.gd")
ASCENSOR = Path("godot/guion/dia_ascensor_app.gd")
CREADOR = Path("godot/guion/creador_personaje_app.gd")
NUEVA_VIDA = Path("godot/guion/auditorias_nueva_vida_app.gd")


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
