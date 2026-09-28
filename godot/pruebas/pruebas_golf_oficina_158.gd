extends SceneTree

const Controller = preload("res://guion/dia_golf_pasillo_app.gd")

var _pasadas := 0
var _fallos := 0


class DiaFalso:
	extends Node3D

	var jornada: Dictionary = {}
	var _mundo: Node3D
	var _caminante: Node
	var _hud_prioridades: CanvasLayer
	var _pantalla: Variant = null
	var guardados := 0

	func _guardar_o_avisar(_mensaje: String) -> void:
		guardados += 1


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_disponibilidad()
	await _probar_partida_completa()
	await _probar_abandono()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_disponibilidad() -> void:
	_comprobar(
		not Controller.disponible({"fase": "casa", "dia": 3}),
		"el golf solo se ofrece en archivo",
	)
	_comprobar(
		Controller.disponible({"fase": "archivo", "dia": 3}),
		"el primer día elegible ofrece golf",
	)
	_comprobar(
		not Controller.disponible({"fase": "archivo", "dia": 4}),
		"la actividad no aparece todos los días",
	)
	var jornada := {"fase": "archivo", "dia": 3}
	Controller.marcar_jugado(jornada)
	_comprobar(
		not Controller.disponible(jornada),
		"entrar consume la oportunidad de esa jornada",
	)


func _probar_partida_completa() -> void:
	var ruta := "user://ranking_golf_oficina_158_completa.json"
	_borrar(ruta)
	var datos := _nuevo_dia(3, ruta)
	var dia: DiaFalso = datos["dia"]
	var controller: DiaGolfPasilloApp = datos["controller"]
	controller._process(0.0)
	_comprobar(is_instance_valid(controller._oferta), "la oferta aparece físicamente en oficina")

	controller._abrir(null)
	await process_frame
	_comprobar(is_instance_valid(controller._golf), "la oferta abre la partida real de tres hoyos")
	_comprobar(
		int(dia.jornada.get(Controller.CLAVE_ULTIMO_DIA, 0)) == 3,
		"abrir marca la jornada para que recargar no repita la oferta",
	)
	_comprobar(dia.guardados == 1, "el consumo de la oferta se guarda una sola vez")
	_comprobar(not dia._mundo.visible, "durante el golf se oculta la oficina")
	_comprobar(
		dia._caminante.process_mode == Node.PROCESS_MODE_DISABLED,
		"durante el golf el caminante no procesa movimiento",
	)

	for _hoyo in range(Golf.HOYOS):
		controller._golf._al_completar_hoyo(2)
		await process_frame
	await process_frame

	_comprobar(not is_instance_valid(controller._golf), "terminar devuelve al recorrido de oficina")
	_comprobar(dia._mundo.visible, "terminar restaura el mundo")
	_comprobar(
		dia._caminante.process_mode == Node.PROCESS_MODE_INHERIT,
		"terminar restaura el modo del caminante",
	)
	var resultado: Dictionary = dia.get_meta("ultimo_resultado_golf", {})
	_comprobar(bool(resultado.get("completa", false)), "el resultado completo llega al controller")
	var tabla := RankingGolf.cargar_local(ruta)
	_comprobar(tabla.size() == 1, "una partida completa entra en el ranking local")
	if not tabla.is_empty():
		_comprobar(
			String(tabla[0].get("alias", "")) == Controller.ALIAS_RANKING_LOCAL,
			"el ranking usa un alias diegético y no identidad personal",
		)
		_comprobar(int(tabla[0].get("golpes", 0)) == 6, "el ranking recibe los golpes reales")

	dia.queue_free()
	await process_frame
	_borrar(ruta)


func _probar_abandono() -> void:
	var ruta := "user://ranking_golf_oficina_158_abandono.json"
	_borrar(ruta)
	var datos := _nuevo_dia(7, ruta)
	var dia: DiaFalso = datos["dia"]
	var controller: DiaGolfPasilloApp = datos["controller"]
	controller._process(0.0)
	controller._abrir(null)
	await process_frame
	controller._golf._al_abandonar_hoyo()
	await process_frame
	await process_frame

	var resultado: Dictionary = dia.get_meta("ultimo_resultado_golf", {})
	_comprobar(bool(resultado.get("abandonada", false)), "abandonar conserva un resultado explícito")
	_comprobar(not bool(resultado.get("completa", true)), "abandonar no cuenta como partida completa")
	_comprobar(not FileAccess.file_exists(ruta), "abandonar no escribe el ranking")
	_comprobar(dia._mundo.visible, "abandonar restaura la oficina")
	_comprobar(not is_instance_valid(controller._golf), "abandonar cierra la sesión")

	dia.queue_free()
	await process_frame
	_borrar(ruta)


func _nuevo_dia(numero: int, ruta_ranking: String) -> Dictionary:
	var dia := DiaFalso.new()
	dia.jornada = {"fase": "archivo", "dia": numero}
	dia._mundo = Node3D.new()
	dia._mundo.name = "Mundo"
	dia._caminante = Node.new()
	dia._caminante.name = "Caminante"
	dia._hud_prioridades = CanvasLayer.new()
	dia._hud_prioridades.name = "HUD"
	dia.add_child(dia._mundo)
	dia.add_child(dia._caminante)
	dia.add_child(dia._hud_prioridades)
	root.add_child(dia)

	var controller := Controller.new()
	controller.name = "GolfPasilloController"
	controller.ruta_ranking_local = ruta_ranking
	dia.add_child(controller)
	return {"dia": dia, "controller": controller}


func _borrar(ruta: String) -> void:
	if not FileAccess.file_exists(ruta):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO golf oficina #158: " + nombre)
