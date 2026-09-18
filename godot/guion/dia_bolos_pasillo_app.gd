## Integra los bolos de pasillo (#159) como pausa opcional de oficina.
##
## Este controller solo decide cuándo y cómo se entra/sale del vertical. El
## tanteo sigue en Bolos y la simulación en BolosPasillo3D. No persiste estado:
## el resultado queda como metadata efímera de Dia hasta que #114 defina el
## premio cosmético idempotente.
class_name DiaBolosPasilloApp
extends Node

const ESCENA_BOLOS := preload("res://escenas/bolos_pasillo.tscn")
const POSICION_OFERTA := Vector3(3.35, 0.22, 2.65)
const RADIO_OFERTA := 0.52
const PERIODO_DIAS := 3
const DIA_INICIAL := 2
const DURACION_MARCADOR := 3.5

var _mundo_id := 0
var _oferta: Interactuable3D
var _bolos: BolosPasillo3D
var _marcador_resultado: CanvasLayer
var _cerrando := false

var _mundo_sesion: Node3D
var _mundo_visible_previo := true
var _caminante_sesion: Node
var _modo_caminante_previo := Node.PROCESS_MODE_INHERIT
var _camara_previa: Camera3D
var _hud_sesion: CanvasLayer
var _hud_visible_previo := true
var _menu_unhandled_previo := true
var _mouse_previo := Input.MOUSE_MODE_CAPTURED
var _presentacion_guardada := false


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia.get("_mundo") == null:
		return

	if is_instance_valid(_bolos):
		if String(dia.jornada.get("fase", "")) != "archivo" or dia._mundo != _mundo_sesion:
			_abandonar_sesion()
		return

	var mundo: Node3D = dia._mundo
	var id := mundo.get_instance_id()
	if id != _mundo_id:
		_mundo_id = id
		_oferta = null

	if not disponible(dia.jornada):
		_retirar_oferta()
		return
	if not is_instance_valid(_oferta):
		_montar_oferta(mundo)


func _exit_tree() -> void:
	if _presentacion_guardada:
		_restaurar_presentacion()


static func disponible(jornada: Dictionary) -> bool:
	if String(jornada.get("fase", "")) != "archivo":
		return false
	var dia := int(jornada.get("dia", 1))
	if dia < DIA_INICIAL:
		return false
	return posmod(dia - DIA_INICIAL, PERIODO_DIAS) == 0


func _montar_oferta(mundo: Node3D) -> void:
	var oferta := Interactuable3D.new()
	oferta.name = "BolosPasilloOferta"
	oferta.position = POSICION_OFERTA
	oferta.verbo = Interactuable3D.Verbo.USAR
	oferta.nombre_objeto = ""
	oferta.sonido = Interactuable3D.SIN_SONIDO

	var colision := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = RADIO_OFERTA
	colision.shape = esfera
	oferta.add_child(colision)

	var material_bola := StandardMaterial3D.new()
	material_bola.albedo_color = Color(0.20, 0.26, 0.30)
	material_bola.roughness = 0.78
	var bola := MeshInstance3D.new()
	var malla_bola := SphereMesh.new()
	malla_bola.radius = 0.13
	malla_bola.height = 0.26
	bola.mesh = malla_bola
	bola.material_override = material_bola
	bola.position = Vector3(-0.28, 0.0, 0.0)
	oferta.add_child(bola)

	var material_bolo := StandardMaterial3D.new()
	material_bolo.albedo_color = Color(0.82, 0.80, 0.72)
	material_bolo.roughness = 0.72
	for x in [-0.06, 0.18]:
		var posicion_x := float(x)
		var bolo := MeshInstance3D.new()
		var malla := CapsuleMesh.new()
		malla.radius = 0.07
		malla.height = 0.30
		bolo.mesh = malla
		bolo.material_override = material_bolo
		bolo.position = Vector3(posicion_x, 0.05, -0.12)
		oferta.add_child(bolo)

	oferta.activado.connect(_abrir)
	mundo.add_child(oferta)
	_oferta = oferta


func _retirar_oferta() -> void:
	if is_instance_valid(_oferta):
		_oferta.queue_free()
	_oferta = null


func _abrir(_actor: Node) -> void:
	if is_instance_valid(_bolos) or _cerrando or get_tree().paused:
		return
	var dia := get_parent()
	if dia == null or dia.get("_mundo") == null or not disponible(dia.jornada):
		return
	if dia.get("_pantalla") != null:
		return

	var sesion := ESCENA_BOLOS.instantiate() as BolosPasillo3D
	if sesion == null:
		return

	_guardar_presentacion(dia)
	_bolos = sesion
	_bolos.name = "BolosPasilloSesion"
	_bolos.actividad_terminada.connect(_al_terminar)
	dia.add_child(_bolos)

	if is_instance_valid(_mundo_sesion):
		_mundo_sesion.visible = false
	if is_instance_valid(_caminante_sesion):
		_caminante_sesion.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(_hud_sesion):
		_hud_sesion.visible = false
	var menu := _menu_global()
	if menu != null:
		menu.set_process_unhandled_input(false)

	var camara := _bolos.get_node_or_null("Camara") as Camera3D
	if camara != null:
		camara.make_current()


func _guardar_presentacion(dia: Node) -> void:
	_presentacion_guardada = true
	_mundo_sesion = dia._mundo
	_mundo_visible_previo = _mundo_sesion.visible
	_caminante_sesion = dia.get("_caminante")
	if is_instance_valid(_caminante_sesion):
		_modo_caminante_previo = _caminante_sesion.process_mode
	_camara_previa = get_viewport().get_camera_3d()
	var menu := _menu_global()
	_menu_unhandled_previo = menu.is_processing_unhandled_input() if menu != null else true
	_mouse_previo = Input.mouse_mode

	var hud: Variant = dia.get("_hud_prioridades")
	if hud is CanvasLayer:
		_hud_sesion = hud
		_hud_visible_previo = _hud_sesion.visible


func _al_terminar(resultado: Dictionary) -> void:
	if _cerrando:
		return
	_cerrando = true
	call_deferred("_cerrar_sesion", resultado.duplicate(true))


func _abandonar_sesion() -> void:
	if _cerrando or not is_instance_valid(_bolos):
		return
	_bolos.abandonar()


func _cerrar_sesion(resultado: Dictionary) -> void:
	var dia := get_parent()
	if dia != null:
		dia.set_meta("ultimo_resultado_bolos", resultado.duplicate(true))
	if is_instance_valid(_bolos):
		_bolos.queue_free()
	_bolos = null
	_restaurar_presentacion()
	if bool(resultado.get("completa", false)):
		_mostrar_marcador(resultado)
	_cerrando = false


func _mostrar_marcador(resultado: Dictionary) -> void:
	_retirar_marcador_resultado()
	var puntuaciones: Array = resultado.get("puntuaciones", [])
	if puntuaciones.is_empty():
		return

	var mayor := 0
	for puntos in puntuaciones:
		mayor = maxi(mayor, int(puntos))

	var capa := CanvasLayer.new()
	capa.name = "BolosResultado"
	capa.layer = 40
	add_child(capa)
	_marcador_resultado = capa

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.theme = EstiloSiga.tema()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -286.0
	panel.offset_top = 24.0
	panel.offset_right = -24.0
	panel.offset_bottom = 128.0
	capa.add_child(panel)

	var fila := HBoxContainer.new()
	fila.name = "Puntuaciones"
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 18)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fila)

	var colores := [
		Color(0.86, 0.83, 0.72),
		Color(0.48, 0.67, 0.76),
		Color(0.72, 0.48, 0.55),
		Color(0.55, 0.66, 0.45),
	]
	for indice in puntuaciones.size():
		var columna := VBoxContainer.new()
		columna.name = "Turno%d" % indice
		columna.alignment = BoxContainer.ALIGNMENT_CENTER
		columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(columna)

		var marcador := ColorRect.new()
		marcador.name = "Marca%d" % indice
		var lado := 28.0 if indice == 0 else 20.0
		marcador.custom_minimum_size = Vector2(lado, lado)
		marcador.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marcador.color = colores[indice % colores.size()]
		if int(puntuaciones[indice]) < mayor:
			marcador.modulate.a = 0.45
		columna.add_child(marcador)

		var etiqueta := Label.new()
		etiqueta.name = "Puntos%d" % indice
		etiqueta.text = str(int(puntuaciones[indice])).pad_zeros(2)
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		columna.add_child(etiqueta)

	var temporizador := Timer.new()
	temporizador.name = "Ocultar"
	temporizador.wait_time = DURACION_MARCADOR
	temporizador.one_shot = true
	temporizador.timeout.connect(_retirar_marcador_resultado)
	capa.add_child(temporizador)
	temporizador.start()


func _retirar_marcador_resultado() -> void:
	if is_instance_valid(_marcador_resultado):
		_marcador_resultado.queue_free()
	_marcador_resultado = null


func _restaurar_presentacion() -> void:
	if not _presentacion_guardada:
		return
	if is_instance_valid(_mundo_sesion):
		_mundo_sesion.visible = _mundo_visible_previo
	if is_instance_valid(_caminante_sesion):
		_caminante_sesion.process_mode = _modo_caminante_previo
	if is_instance_valid(_hud_sesion):
		_hud_sesion.visible = _hud_visible_previo
	var menu := _menu_global()
	if menu != null:
		menu.set_process_unhandled_input(_menu_unhandled_previo)
	if is_instance_valid(_camara_previa):
		_camara_previa.make_current()
	Input.mouse_mode = _mouse_previo

	_mundo_sesion = null
	_caminante_sesion = null
	_camara_previa = null
	_hud_sesion = null
	_presentacion_guardada = false


func _menu_global() -> Node:
	return get_node_or_null("/root/MenuGlobal")
