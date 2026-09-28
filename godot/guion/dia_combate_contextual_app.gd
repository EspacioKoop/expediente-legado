## Presentación y ciclo de vida del hack & slash contextual de #1752.
##
## DiaApp decide cuándo se puede combatir y qué transición narrativa sigue.
## Este nodo se limita a aislar el mundo caminable, montar JuicioCombate3D y
## devolver el resultado ya resuelto en el caso onírico.
class_name DiaCombateContextualApp
extends Node3D

signal terminado(
	gano: bool,
	objetivo: Dictionary,
	zona: Area3D,
	decision: Dictionary,
	resultado: Dictionary,
)

var _combate: JuicioCombate3D
var _caminante: CharacterBody3D
var _mundo: Node3D
var _hud: CanvasLayer
var _ambiente: Environment


func abrir(
	objetivo: Dictionary,
	decision: Dictionary,
	zona: Area3D,
	caminante: CharacterBody3D,
	mundo: Node3D,
	hud: CanvasLayer,
	ambiente: Environment,
	partida_estado: Dictionary,
	jornada: Dictionary,
	raiz: int,
) -> bool:
	if _combate != null:
		return false
	_caminante = caminante
	_mundo = mundo
	_hud = hud
	_ambiente = ambiente
	_preparar_mundo()

	_combate = JuicioCombate3D.new()
	(
		_combate
		. configurar(
			objetivo,
			0,
			bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false)),
			raiz,
		)
	)
	_combate.perfil_jugador = partida_estado.get("perfil_jugador", {})
	_combate.terminado.connect(
		_cerrar.bind(
			objetivo,
			zona,
			decision.duplicate(true),
			partida_estado,
			jornada,
		)
	)
	add_child(_combate)
	_hacer_actual_camara()
	return true


func _cerrar(
	gano: bool,
	objetivo: Dictionary,
	zona: Area3D,
	decision: Dictionary,
	partida_estado: Dictionary,
	jornada: Dictionary,
) -> void:
	var resultado: Dictionary = {}
	if String(decision.get("plano", "")) == CombateContextual.PLANO_SUENO:
		if not gano:
			Auditorias.resolver_fin_sueno(partida_estado, false)
		resultado = SuenoCombate.resolver(partida_estado, jornada, objetivo, gano)

	var combate := _combate
	_combate = null
	if is_instance_valid(combate):
		remove_child(combate)
		combate.queue_free()
	_restaurar_mundo()
	terminado.emit(gano, objetivo, zona, decision, resultado)


func _preparar_mundo() -> void:
	_caminante.set_physics_process(false)
	_caminante.visible = false
	if is_instance_valid(_mundo):
		_mundo.visible = false
	if is_instance_valid(_hud):
		_hud.visible = false
	var entorno := _entorno_del_dia()
	if entorno != null:
		entorno.environment = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _restaurar_mundo() -> void:
	var entorno := _entorno_del_dia()
	if entorno != null:
		entorno.environment = _ambiente
	if is_instance_valid(_mundo):
		_mundo.visible = true
	if is_instance_valid(_hud):
		_hud.visible = true
	if is_instance_valid(_caminante):
		_caminante.visible = true
		_caminante.set_physics_process(true)
		var camara := _caminante.get_node_or_null("Camara") as Camera3D
		if camara != null:
			camara.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _entorno_del_dia() -> WorldEnvironment:
	var anfitrion := get_parent()
	if anfitrion == null:
		return null
	for hijo in anfitrion.get_children():
		if hijo is WorldEnvironment:
			return hijo
	return null


func _hacer_actual_camara() -> void:
	for hijo in _combate.get_children():
		if hijo is Camera3D:
			hijo.current = true
			return
