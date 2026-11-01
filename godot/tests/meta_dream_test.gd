extends SceneTree

# Prueba automatizada del MetaDreamController
# Verifica secuencia de fases, aparición del intruso y liberación de recursos.

const CONTROLLER_PATH := "res://dreams/meta_dream_controller.gd"
const SEGUNDOS_POR_FASE := 3.0

var _terminado := false


func _init() -> void:
	_probar_meta_dream()
	print("MetaDream test: OK")
	quit(0)


func _probar_meta_dream() -> void:
	var controller := preload(CONTROLLER_PATH).new()
	# crear nodos requeridos
	var material := Node3D.new()
	material.name = "Materializacion"
	var ecos := Node3D.new()
	ecos.name = "Ecos"
	var spawn := Marker3D.new()
	spawn.name = "IntrusoSpawn"
	var salida := Area3D.new()
	salida.name = "Salida"
	# añadir al árbol
	controller.add_child(material)
	controller.add_child(ecos)
	controller.add_child(spawn)
	controller.add_child(salida)
	# conectar señal de terminado para observar
	controller.terminado.connect(func() -> void: _terminado = true)
	# añadir controlador al árbol para que _ready se ejecute
	add_child(controller)
	controller._ready()
	# fase inicial debe ser GREYBOX (1)
	_assert(controller.fase_actual() == 1, "fase inicial debe ser 1 (GREYBOX)")
	_assert(not controller.asset_intruso_visible(), "intruso no debe estar visible al inicio")
	# avanzar tres fases
	for i in range(3):
		controller._process(SEGUNDOS_POR_FASE)
	_assert(controller.fase_actual() == 4, "fase final debe ser 4 (INTRUSO)")
	_assert(controller.asset_intruso_visible(), "intruso debe estar visible en fase INTRUSO")
	# simular salida del jugador
	controller.abandonar()
	_assert(_terminado, "se debe emitir señal terminado al abandonar")
	_assert(not controller.asset_intruso_visible(), "intruso debe limpiarse después de abandonar")


func _assert(condicion: bool, mensaje: String) -> void:
	if not condicion:
		push_error("MetaDream test fallido: %s" % mensaje)
		quit(1)
