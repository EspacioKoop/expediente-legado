## Integra los aviones de papel (#160) como descanso físico en la planta 4.
##
## El controller solo aporta el punto de entrada y el ciclo de presentación.
## Reutiliza la escena/jornada existente: disponibilidad, resultado y consumo de
## la oportunidad siguen perteneciendo a AvionesPapelDescanso y al adaptador.
class_name DiaAvionesPapelApp
extends Node

const ESCENA_AVIONES := preload("res://escenas/minijuego_aviones_papel_jornada.tscn")
const POSICION_OFERTA := Vector3(3.6, 0.82, 0.0)
const RADIO_OFERTA := 0.55
const DURACION_COMENTARIO := 4.0

var _mundo_id := 0
var _oferta: Interactuable3D
var _capa_sesion: CanvasLayer
var _sesion: Control
var _cerrando := false

var _caminante_sesion: Node
var _modo_caminante_previo := Node.PROCESS_MODE_INHERIT
var _hud_sesion: CanvasLayer
var _hud_visible_previo := true
var _menu_unhandled_previo := true
var _mouse_previo := Input.MOUSE_MODE_CAPTURED
var _presentacion_guardada := false
var _comentario: CanvasLayer


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia.get("_mundo") == null:
		return

	if is_instance_valid(_sesion):
		if String(dia.jornada.get("fase", "")) != "archivo":
			_abandonar_sesion()
		return

	var mundo: Node3D = dia._mundo
	var id := mundo.get_instance_id()
	if id != _mundo_id:
		_mundo_id = id
		_oferta = null

	if not AvionesPapelDescanso.disponible(dia.jornada):
		_retirar_oferta()
		return
	if not is_instance_valid(_oferta):
		_montar_oferta(mundo)


func _exit_tree() -> void:
	if _presentacion_guardada:
		_restaurar_presentacion()


func _montar_oferta(mundo: Node3D) -> void:
	var oferta := Interactuable3D.new()
	oferta.name = "AvionesPapelOferta"
	oferta.position = POSICION_OFERTA
	oferta.verbo = Interactuable3D.Verbo.USAR
	oferta.nombre_objeto = tr("AVIONES_TITULO")
	oferta.sonido = Interactuable3D.SIN_SONIDO

	var colision := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = RADIO_OFERTA
	colision.shape = esfera
	oferta.add_child(colision)

	var papel := StandardMaterial3D.new()
	papel.albedo_color = Color(0.84, 0.82, 0.74)
	papel.roughness = 0.92
	for datos in [
		{"pos": Vector3(-0.09, 0.0, 0.0), "rot": -0.32},
		{"pos": Vector3(0.09, 0.0, 0.0), "rot": 0.32},
	]:
		var ala := MeshInstance3D.new()
		var malla := BoxMesh.new()
		malla.size = Vector3(0.22, 0.015, 0.42)
		ala.mesh = malla
		ala.material_override = papel
		ala.position = datos["pos"]
		ala.rotation.y = float(datos["rot"])
		oferta.add_child(ala)

	oferta.activado.connect(_abrir)
	mundo.add_child(oferta)
	_oferta = oferta


func _retirar_oferta() -> void:
	if is_instance_valid(_oferta):
		_oferta.queue_free()
	_oferta = null


func _abrir(_actor: Node) -> void:
	if is_instance_valid(_sesion) or _cerrando or get_tree().paused:
		return
	var dia := get_parent()
	if (
		dia == null
		or dia.get("_mundo") == null
		or not AvionesPapelDescanso.disponible(dia.jornada)
		or dia.get("_pantalla") != null
	):
		return

	var sesion := ESCENA_AVIONES.instantiate() as Control
	if sesion == null or not sesion.has_method("configurar_jornada"):
		return
	sesion.call("configurar_jornada", dia.jornada)

	_guardar_presentacion(dia)
	var capa := CanvasLayer.new()
	capa.name = "AvionesPapelSesion"
	capa.layer = 45
	dia.add_child(capa)
	_capa_sesion = capa
	_sesion = sesion
	_sesion.theme = EstiloSiga.tema()
	_capa_sesion.add_child(_sesion)
	_sesion.connect("finalizada", Callable(self, "_al_terminar"))

	if is_instance_valid(_caminante_sesion):
		_caminante_sesion.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(_hud_sesion):
		_hud_sesion.visible = false
	var menu := _menu_global()
	if menu != null:
		menu.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _guardar_presentacion(dia: Node) -> void:
	_presentacion_guardada = true
	_caminante_sesion = dia.get("_caminante")
	if is_instance_valid(_caminante_sesion):
		_modo_caminante_previo = _caminante_sesion.process_mode
	var hud: Variant = dia.get("_hud_prioridades")
	if hud is CanvasLayer:
		_hud_sesion = hud
		_hud_visible_previo = _hud_sesion.visible
	var menu := _menu_global()
	_menu_unhandled_previo = menu.is_processing_unhandled_input() if menu != null else true
	_mouse_previo = Input.mouse_mode


func _al_terminar(resultado: Dictionary) -> void:
	if _cerrando:
		return
	_cerrando = true
	call_deferred("_cerrar_sesion", resultado.duplicate(true))


func _abandonar_sesion() -> void:
	if _cerrando or not is_instance_valid(_sesion):
		return
	var minijuego := _sesion.get_node_or_null("MinijuegoAvionesPapel")
	if minijuego != null and minijuego.has_method("_al_abandonar"):
		minijuego.call("_al_abandonar")
	else:
		_cerrar_sesion({"abandonada": true, "descanso": {"comentario": "", "jugado": true}})


func _cerrar_sesion(resultado: Dictionary) -> void:
	var dia := get_parent()
	if dia != null:
		dia.set_meta("ultimo_resultado_aviones_papel", resultado.duplicate(true))
	if is_instance_valid(_capa_sesion):
		_capa_sesion.queue_free()
	_capa_sesion = null
	_sesion = null
	_restaurar_presentacion()
	_mostrar_comentario(resultado)
	_cerrando = false


func _mostrar_comentario(resultado: Dictionary) -> void:
	_retirar_comentario()
	var descanso: Variant = resultado.get("descanso", {})
	if not descanso is Dictionary:
		return
	var texto := String((descanso as Dictionary).get("comentario", ""))
	if texto.is_empty():
		return

	var capa := CanvasLayer.new()
	capa.name = "AvionesPapelComentario"
	capa.layer = 40
	add_child(capa)
	_comentario = capa

	var panel := PanelContainer.new()
	panel.theme = EstiloSiga.tema()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 160.0
	panel.offset_right = -160.0
	panel.offset_top = -110.0
	panel.offset_bottom = -34.0
	capa.add_child(panel)

	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(etiqueta)

	var temporizador := Timer.new()
	temporizador.one_shot = true
	temporizador.wait_time = DURACION_COMENTARIO
	temporizador.timeout.connect(_retirar_comentario)
	capa.add_child(temporizador)
	temporizador.start()


func _retirar_comentario() -> void:
	if is_instance_valid(_comentario):
		_comentario.queue_free()
	_comentario = null


func _restaurar_presentacion() -> void:
	if not _presentacion_guardada:
		return
	if is_instance_valid(_caminante_sesion):
		_caminante_sesion.process_mode = _modo_caminante_previo
	if is_instance_valid(_hud_sesion):
		_hud_sesion.visible = _hud_visible_previo
	var menu := _menu_global()
	if menu != null:
		menu.set_process_unhandled_input(_menu_unhandled_previo)
	Input.mouse_mode = _mouse_previo
	_caminante_sesion = null
	_hud_sesion = null
	_presentacion_guardada = false


func _menu_global() -> Node:
	return get_node_or_null("/root/MenuGlobal")
