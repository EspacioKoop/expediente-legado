## Regresión standalone del segundo vertical de #936: cablear los compromisos
## religiosos ya contratados por ReligionConflicto (#1117) al Juicio por
## Combate 3D real.
##
##     godot4 --headless --path godot --script pruebas/issue_936_combate_smoke.gd
extends SceneTree

const Eventos = preload("res://guion/religion_eventos.gd")
const Conflicto = preload("res://guion/religion_conflicto.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_bloqueo_estatico()
	_probar_resolucion_simbolica()
	await _probar_runtime_combate()
	# Sonidos, tweens y queue_free del HUD son efímeros del SceneTree.
	await create_timer(1.0).timeout
	await process_frame
	print("issue_936: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_bloqueo_estatico() -> void:
	var registro := Eventos.nuevo()
	Eventos.registrar(
		registro,
		Eventos.crear_evento(
			"voto-936",
			Eventos.CANAL_PRACTICA,
			"escena:fixture",
			"juicio:acusado-936",
			1,
			"tradicion_fixture",
			[],
			[Conflicto.REGLA_NO_INICIAR]
		)
	)
	var compromiso: Dictionary = (
		Conflicto.compromisos_disponibles(registro, "juicio:acusado-936")[0]
	)

	_comprobar(
		not JuicioCombate3D.compromiso_religion_bloqueante([compromiso], false).is_empty(),
		"sin iniciativa rival previa el compromiso sigue bloqueando",
	)
	_comprobar(
		JuicioCombate3D.compromiso_religion_bloqueante([compromiso], true).is_empty(),
		"tras la iniciativa rival el compromiso deja de bloquear",
	)
	_comprobar(
		JuicioCombate3D.compromiso_religion_bloqueante([], false).is_empty(),
		"sin compromisos no hay bloqueo que inventar",
	)


func _probar_resolucion_simbolica() -> void:
	var registro := Eventos.nuevo()
	(
		Eventos
		. registrar(
			registro,
			(
				Eventos
				. crear_evento(
					"voto-simbolico-936",
					Eventos.CANAL_CONVICCION,
					"dialogo:fixture",
					"juicio:acusado-a",
					1,
					"tradicion_fixture",
					[],
					[Conflicto.REGLA_NO_INICIAR],
					false,
					[],
					{"declaracion": Eventos.DECLARACION_AFIRMACION},
				)
			)
		)
	)
	var estado := {Eventos.CLAVE_ESTADO: registro}

	_comprobar(
		JuicioCombateSimbolico.compromisos_religion(estado, "acusado-a").size() == 1,
		"la capa simbólica traduce un hecho catalogado a un compromiso del acusado correcto",
	)
	_comprobar(
		JuicioCombateSimbolico.compromisos_religion(estado, "acusado-b").is_empty(),
		"el compromiso no se filtra a un acusado sin ese contexto",
	)
	_comprobar(
		JuicioCombateSimbolico.compromisos_religion({}, "acusado-a").is_empty(),
		"sin partida con registro religioso no se inventan compromisos",
	)


func _probar_runtime_combate() -> void:
	var registro := Eventos.nuevo()
	Eventos.registrar(
		registro,
		Eventos.crear_evento(
			"voto-runtime-936",
			Eventos.CANAL_PRACTICA,
			"escena:fixture",
			"juicio:runtime-936",
			1,
			"tradicion_fixture",
			[],
			[Conflicto.REGLA_NO_INICIAR]
		)
	)
	var compromiso: Dictionary = (
		Conflicto.compromisos_disponibles(registro, "juicio:runtime-936")[0]
	)

	var voto := await _nuevo_juicio()
	_acercar(voto)
	voto._compromisos_religion = [compromiso]
	voto._recarga_jugador = 0.0
	voto._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	_comprobar(
		voto._determinacion_rival == JuicioCombate3D.DETERMINACION_BASE,
		"un voto vigente impide que el jugador abra la agresión",
	)
	_comprobar(
		voto._texto_ritual().contains(tr("JUICIO_RELIGION_COMPROMISO")),
		"el HUD refleja el compromiso mientras cede la iniciativa",
	)

	voto._iniciar_ataque_rival()
	voto._recarga_jugador = 0.0
	voto._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	_comprobar(
		voto._determinacion_rival == JuicioCombate3D.DETERMINACION_BASE - 1,
		"tras la iniciativa rival el jugador puede responder con normalidad",
	)
	voto.free()

	var registro_tregua := Eventos.nuevo()
	(
		Eventos
		. registrar(
			registro_tregua,
			(
				Eventos
				. crear_evento(
					"tregua-runtime-936",
					Eventos.CANAL_PRACTICA,
					"escena:fixture",
					"juicio:runtime-936",
					1,
					"tradicion_fixture",
					[],
					[Conflicto.REGLA_TREGUA_MUTUA],
					true,
					["runtime-936"],
				)
			)
		)
	)
	var tregua_compromiso: Dictionary = (
		Conflicto
		. compromisos_disponibles(
			registro_tregua,
			"juicio:runtime-936",
			"runtime-936",
		)[0]
	)
	_comprobar(
		not JuicioCombateSimbolico.tregua_religion_activa([tregua_compromiso]).is_empty(),
		"la capa simbólica reconoce una tregua bilateral ya validada",
	)

	var tregua := await _nuevo_juicio()
	_acercar(tregua)
	tregua._compromisos_religion = [tregua_compromiso]
	tregua._tregua_religion_restante = float(tregua_compromiso["duracion"])
	tregua._recarga_jugador = 0.0
	tregua._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	_comprobar(
		tregua._determinacion_rival == JuicioCombate3D.DETERMINACION_BASE,
		"durante la tregua el jugador no puede iniciar agresión",
	)
	tregua._iniciar_ataque_rival()
	_comprobar(
		not tregua._ataque_rival_pendiente and not tregua._rival_inicio_agresion,
		"durante la tregua el rival tampoco puede iniciar agresión",
	)
	_comprobar(
		tregua._texto_ritual().contains(tr("JUICIO_RELIGION_TREGUA")),
		"el HUD distingue la tregua del voto unilateral",
	)
	tregua._descontar_tregua_religion(float(tregua_compromiso["duracion"]) + 0.01)
	tregua._recarga_jugador = 0.0
	tregua._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	_comprobar(
		tregua._determinacion_rival == JuicioCombate3D.DETERMINACION_BASE - 1,
		"al terminar la ventana de tregua vuelve el combate base",
	)
	tregua.free()

	var base := await _nuevo_juicio()
	_acercar(base)
	base._recarga_jugador = 0.0
	base._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	_comprobar(
		base._determinacion_rival == JuicioCombate3D.DETERMINACION_BASE - 1,
		"sin compromisos religiosos el combate base conserva la iniciativa",
	)
	base.free()


func _nuevo_juicio() -> JuicioCombate3D:
	var juicio := JuicioCombate3D.new()
	juicio.configurar({"id": "prueba_936", "nombre": "PRUEBA #936"}, 0, true)
	root.add_child(juicio)
	await process_frame
	return juicio


func _acercar(juicio: JuicioCombate3D) -> void:
	juicio._jugador.position = Vector3.ZERO
	juicio._rival.position = Vector3(0.0, 0.0, -1.0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO #936: %s" % nombre)
