## Regresión standalone del feedback ritual de #779.
##
##     godot4 --headless --path godot --script pruebas/issue_779_feedback_smoke.gd
extends SceneTree

var pasadas := 0
var fallos := 0


func _init() -> void:
	var sol := JuicioFeedbackRitual.estado_visual("robo_del_sol", 0.0, 0, 6, true, false, 7)
	_comprobar(bool(sol["sol"]), "Robo del Sol detecta una interrupcion con dano")
	var sol_sin_dano := JuicioFeedbackRitual.estado_visual(
		"robo_del_sol", 0.0, 0, 7, true, false, 7
	)
	_comprobar(not bool(sol_sin_dano["sol"]), "resolver sin dano no finge una interrupcion")

	var anansi := JuicioFeedbackRitual.estado_visual(
		"nudo_suspendido", 0.7, 0, 6, false, false, 6
	)
	_comprobar(bool(anansi["anansi"]), "el enredo activo muestra la telarana")
	var anansi_agotado := JuicioFeedbackRitual.estado_visual(
		"nudo_suspendido", 0.0, 0, 6, false, false, 6
	)
	_comprobar(not bool(anansi_agotado["anansi"]), "el enredo agotado oculta la telarana")

	var hidra := JuicioFeedbackRitual.estado_visual(
		"retorno_hidra", 0.0, 1, 2, false, false, 2
	)
	_comprobar(bool(hidra["hidra"]), "la segunda fase de Hidra queda marcada")
	var hidra_inicial := JuicioFeedbackRitual.estado_visual(
		"retorno_hidra", 0.0, 0, 8, false, false, 8
	)
	_comprobar(not bool(hidra_inicial["hidra"]), "la primera fase no adelanta el retorno")

	print("issue_779_feedback: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO #779 feedback: %s" % nombre)
