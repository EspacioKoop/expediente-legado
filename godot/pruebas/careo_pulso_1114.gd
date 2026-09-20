## Regresión standalone del pulso interactivo de Ventanilla (#1114).
##
##     godot4 --headless --path godot --script pruebas/careo_pulso_1114.gd
extends SceneTree

var pasadas := 0
var fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	var centro := CareoPulso.centro_para("objecion", 2, "rival")
	_comprobar(centro >= 0.26 and centro <= 0.74, "el objetivo nunca cae pegado al borde")
	_comprobar(
		is_equal_approx(centro, CareoPulso.centro_para("objecion", 2, "rival")),
		"el objetivo es determinista",
	)
	_comprobar(
		not is_equal_approx(centro, CareoPulso.centro_para("objecion", 3, "rival")),
		"la ronda desplaza la ventana",
	)

	var objecion := CareoPulso.perfil_para("objecion")
	var silencio := CareoPulso.perfil_para("silencio")
	var insistencia := CareoPulso.perfil_para("insistencia")
	_comprobar(
		float(objecion["periodo"]) < float(insistencia["periodo"])
		and float(insistencia["periodo"]) < float(silencio["periodo"]),
		"objecion es rapida, insistencia media y silencio lento",
	)
	_comprobar(
		float(objecion["perfecta"]) < float(insistencia["perfecta"])
		and float(insistencia["perfecta"]) < float(silencio["perfecta"]),
		"las ventanas perfectas distinguen precision, presion y control",
	)
	_comprobar(
		float(objecion["cursor"]) != float(insistencia["cursor"])
		and float(insistencia["cursor"]) != float(silencio["cursor"]),
		"el grosor del cursor hace legible el perfil activo",
	)
	var muestra := 0.28
	_comprobar(
		not is_equal_approx(
			CareoPulso.posicion_para(muestra, float(objecion["periodo"])),
			CareoPulso.posicion_para(muestra, float(silencio["periodo"])),
		),
		"la velocidad produce posiciones distintas con el mismo tiempo",
	)

	_comprobar(is_zero_approx(CareoPulso.posicion_para(0.0)), "el cursor parte del borde")
	_comprobar(
		is_equal_approx(CareoPulso.posicion_para(CareoPulso.PERIODO_SEGUNDOS), 1.0),
		"el cursor llega al extremo opuesto",
	)
	_comprobar(
		is_zero_approx(CareoPulso.posicion_para(CareoPulso.PERIODO_SEGUNDOS * 2.0)),
		"el cursor vuelve sin salto",
	)

	_comprobar(
		CareoPulso.calidad_para(centro, centro) == "perfecto",
		"acertar el centro es perfecto",
	)
	_comprobar(
		CareoPulso.calidad_para(centro + 0.12, centro) == "bien",
		"la corona exterior conserva un acierto bueno",
	)
	_comprobar(
		CareoPulso.calidad_para(centro + 0.30, centro) == "normal",
		"fallar la ventana no invalida la jugada",
	)
	_comprobar(
		CareoPulso.calidad_para(0.0, centro, true) == "perfecto",
		"reduccion de movimiento conserva la recompensa sin timing",
	)
	_comprobar(
		CareoPulso.calidad_de("objecion", centro + 0.08, centro) == "bien"
		and CareoPulso.calidad_de("silencio", centro + 0.08, centro) == "perfecto",
		"el mismo error exige precision en objecion y cabe en silencio",
	)
	_comprobar(
		CareoPulso.calidad_de("insistencia", centro + 0.08, centro) == "bien",
		"insistencia deja una corona util para sostener la presion",
	)
	_comprobar(
		CareoPulso.calidad_de("objecion", 0.0, centro, true) == "perfecto"
		and CareoPulso.calidad_de("silencio", 0.0, centro, true) == "perfecto"
		and CareoPulso.calidad_de("insistencia", 0.0, centro, true) == "perfecto",
		"reduccion de movimiento iguala el techo de los tres perfiles",
	)

	var racha := CareoPulso.racha_siguiente(0, "perfecto")
	_comprobar(racha == 1, "un perfecto arma media iniciativa")
	racha = CareoPulso.racha_siguiente(racha, "perfecto")
	_comprobar(CareoPulso.iniciativa_lista(racha), "dos perfectos conceden iniciativa")
	_comprobar(
		CareoPulso.racha_siguiente(racha, "normal") == 0,
		"una ejecucion normal corta la racha",
	)
	_comprobar(
		CareoPulso.racha_de("objecion", 0, "perfecto") == CareoPulso.META_INICIATIVA,
		"objecion premia una precision dificil con iniciativa inmediata",
	)
	_comprobar(
		CareoPulso.racha_de("silencio", 0, "perfecto") == 1,
		"silencio necesita encadenar dos ejecuciones",
	)
	_comprobar(
		CareoPulso.racha_de("insistencia", 1, "bien") == 1,
		"insistencia conserva presion con una ejecucion buena",
	)
	_comprobar(
		CareoPulso.racha_de("silencio", 1, "bien") == 0,
		"silencio no conserva racha fuera de perfecto",
	)

	var combate := {
		"modo": "ciclo",
		"ronda": 1,
		"ultima_jugada_jugador": 0,
		"revelada": -1,
	}
	var ronda := {"terminado": false, "revelada": ""}
	var restante := CareoPulso.aplicar_iniciativa(combate, ronda, 1, "perfecto", func(): return 0.0)
	_comprobar(restante == 0 and combate["revelada"] == 1, "la racha gana iniciativa real")
	_comprobar(not String(ronda["revelada"]).is_empty(), "la iniciativa se comunica a la cronica")

	var combate_objecion := {
		"modo": "ciclo",
		"ronda": 2,
		"ultima_jugada_jugador": 1,
		"revelada": -1,
	}
	var ronda_objecion := {"terminado": false, "revelada": ""}
	var restante_objecion := CareoPulso.aplicar_iniciativa(
		combate_objecion,
		ronda_objecion,
		0,
		"perfecto",
		func(): return 0.0,
		"objecion",
	)
	_comprobar(
		restante_objecion == 0 and combate_objecion["revelada"] >= 0,
		"un perfecto de objecion convierte el riesgo en iniciativa",
	)

	var pulso := CareoPulso.new()
	root.add_child(pulso)
	await process_frame
	pulso.armar("silencio", 0, "rival", true, 1)
	_comprobar(pulso.visible and pulso.activo(), "armar muestra y activa el comando")
	pulso.cancelar()
	_comprobar(not pulso.visible and not pulso.activo(), "cancelar lo limpia sin resolver ronda")
	pulso.queue_free()
	await process_frame

	print("careo_pulso_1114: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO #1114: %s" % nombre)
