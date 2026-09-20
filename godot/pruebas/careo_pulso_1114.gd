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

	var racha := CareoPulso.racha_siguiente(0, "perfecto")
	_comprobar(racha == 1, "un perfecto arma media iniciativa")
	racha = CareoPulso.racha_siguiente(racha, "perfecto")
	_comprobar(CareoPulso.iniciativa_lista(racha), "dos perfectos conceden iniciativa")
	_comprobar(
		CareoPulso.racha_siguiente(racha, "normal") == 0,
		"una ejecucion normal corta la racha",
	)

	var combate := {
		"modo": "ciclo",
		"ronda": 1,
		"ultima_jugada_jugador": 0,
		"revelada": -1,
	}
	var ronda := {"terminado": false, "revelada": ""}
	var restante := CareoPulso.aplicar_iniciativa(
		combate, ronda, 1, "perfecto", func(): return 0.0
	)
	_comprobar(restante == 0 and combate["revelada"] == 1, "la racha gana iniciativa real")
	_comprobar(not String(ronda["revelada"]).is_empty(), "la iniciativa se comunica a la cronica")

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
