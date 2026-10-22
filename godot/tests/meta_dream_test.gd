extends SceneTree

# Pruebas automatizadas para MetaDreamController
# Verifican la secuencia de fases, la aparición del asset intruso y la limpieza al terminar.

const MetaDreamController = preload("res://dreams/meta_dream_controller.gd")
const SEGUNDOS_POR_FASE = 3.0

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_inicio()
	_probar_secuencia_fases()
	_probar_liberacion()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])


func _probar_inicio() -> void:
	var controller := MetaDreamController.new()
	controller._ready()
	_comprobar("fase inicial es GREYBOX", controller.fase_actual(), 1)
	_comprobar("intruso no visible al inicio", controller.asset_intruso_visible(), false)


func _probar_secuencia_fases() -> void:
	var controller := MetaDreamController.new()
	controller._ready()
	# avanzar a fase 2 (materiales)
	controller._process(SEGUNDOS_POR_FASE)
	_comprobar("fase después de 1ª transición es MATERIALES", controller.fase_actual(), 2)
	# avanzar a fase 3 (ecos)
	controller._process(SEGUNDOS_POR_FASE)
	_comprobar("fase después de 2ª transición es ECOS", controller.fase_actual(), 3)
	# avanzar a fase 4 (intruso)
	controller._process(SEGUNDOS_POR_FASE)
	_comprobar("fase final es INTRUSO", controller.fase_actual(), 4)
	_comprobar("intruso visible en fase INTRUSO", controller.asset_intruso_visible(), true)


func _probar_liberacion() -> void:
	var controller := MetaDreamController.new()
	controller._ready()
	# llevar a fase intruso
	controller._process(SEGUNDOS_POR_FASE)
	controller._process(SEGUNDOS_POR_FASE)
	controller._process(SEGUNDOS_POR_FASE)
	_comprobar("intruso visible antes de abandonar", controller.asset_intruso_visible(), true)
	controller.abandonar()
	_comprobar("intruso limpiado tras abandonar", controller.asset_intruso_visible(), false)
	# la fase no debe cambiar después de abandonar
	var fase_antes := controller.fase_actual()
	controller._process(SEGUNDOS_POR_FASE * 2)
	_comprobar("fase permanece después de abandonar", controller.fase_actual(), fase_antes)
