## Presentación transitoria del expediente SIGA dentro de la jornada (#2264 / #1761).
##
## Solo posee nodos/estado visual de la pantalla. Partida, Jornada, literatura,
## guardado y reasignación siguen siendo responsabilidad de DiaApp.
class_name DiaExpedienteApp
extends RefCounted


static func abrir(
	anfitrion: Node,
	caminante: Node,
	nomina: Label,
	cerrar: Callable,
	traducir: Callable,
	estado: Dictionary,
	guardar: Callable,
) -> CanvasLayer:
	if anfitrion == null or not cerrar.is_valid() or not traducir.is_valid():
		return null
	if caminante != null:
		caminante.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var pantalla := CanvasLayer.new()
	anfitrion.add_child(pantalla)
	pantalla.add_child(load("res://escenas/visor.tscn").instantiate())
	Entrada49Panel.montar(pantalla, estado, guardar)

	var volver := Button.new()
	volver.theme = EstiloSiga.tema()
	volver.text = String(traducir.call("PUESTO_LEVANTARSE"))
	volver.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	volver.offset_left = -190
	volver.offset_top = 4
	volver.offset_right = -8
	volver.pressed.connect(cerrar)
	pantalla.add_child(volver)

	if nomina != null:
		nomina.text = String(traducir.call("DIA_EN_EL_PUESTO"))
	return pantalla


static func cerrar(
	pantalla: CanvasLayer,
	caminante: Node,
	nomina: Label,
	sonar: Callable,
) -> void:
	if pantalla != null and is_instance_valid(pantalla):
		pantalla.queue_free()
	if sonar.is_valid():
		sonar.call("puerta_cierra")
	if caminante != null:
		caminante.set_physics_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if nomina != null:
		# #1451: el rótulo describe solo el estado mientras SIGA está abierto.
		nomina.text = ""
