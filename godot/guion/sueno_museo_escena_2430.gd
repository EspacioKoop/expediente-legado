## Superficie interactiva del museo (#2430). El modelo de elecciones sigue
## siendo RefCounted; solo este controlador se adjunta al Node3D de la escena.
## No escribe en Partida/Jornada ni convierte las vidas posibles en canon.
class_name SuenoMuseoEscena2430
extends Node3D

signal posibilidad_leida(id: String)
signal exploracion_iniciada(id: String)
signal exploracion_terminada(id: String)

const MODELO = preload("res://guion/sueno_museo_vidas_no_ocurridas.gd")
const ETIQUETAS := ["I", "II", "III"]

var _opciones: Array = []
var _seleccion := -1
var _explorando := false
var _actor: Node3D
var _retorno_actor := Transform3D.IDENTITY
var _panel: PanelContainer
var _lectura: Label
var _portal: Interactuable3D
var _salida: Interactuable3D
var _sala: Node3D


func configurar(contexto: Dictionary, semilla: int) -> void:
	# Duplicar aquí evita almacenar referencias mutables del estado del juego.
	_opciones = MODELO.posibilidades(contexto.duplicate(true), semilla)
	if is_node_ready():
		_montar()


func _ready() -> void:
	if _opciones.is_empty():
		configurar({}, 0)
	_montar()


func opciones() -> Array:
	return _opciones.duplicate(true)


func indice_seleccionado() -> int:
	return _seleccion


func explorando() -> bool:
	return _explorando


func _montar() -> void:
	for viejo in get_children():
		if viejo.name in ["InteraccionesMuseo", "SalaPosible", "VisorMuseo"]:
			remove_child(viejo)
			viejo.queue_free()
	_seleccion = -1
	_explorando = false
	var interacciones := Node3D.new()
	interacciones.name = "InteraccionesMuseo"
	add_child(interacciones)

	for indice in range(3):
		var vitrina := get_node_or_null("Vitrina%d" % (indice + 1)) as MeshInstance3D
		if vitrina == null:
			push_error("Falta la vitrina %d del museo" % (indice + 1))
			return
		var zona := _zona(
			interacciones,
			"Examinar%d" % (indice + 1),
			vitrina.position,
			Vector3(2.0, 2.2, 2.0),
			"posibilidad " + ETIQUETAS[indice],
		)
		zona.activado.connect(_examinar.bind(indice))

		var numero := Label3D.new()
		numero.name = "Cartel%d" % (indice + 1)
		numero.text = "POSIBILIDAD " + ETIQUETAS[indice]
		numero.font_size = 42
		numero.pixel_size = 0.004
		numero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		numero.position = vitrina.position + Vector3(0.0, 1.65, 0.0)
		interacciones.add_child(numero)

	var exposicion := get_node_or_null("VitrinaExplorable") as MeshInstance3D
	if exposicion != null:
		exposicion.visible = false
		_portal = _zona(
			interacciones,
			"EntrarVidaPosible",
			exposicion.position,
			Vector3(2.0, 2.2, 2.0),
			"en una vida que no ocurrió",
		)
		_portal.habilitado = false
		_portal.activado.connect(_entrar)
	_montar_sala()
	_montar_lector()


func _zona(
	padre: Node3D,
	nombre: String,
	posicion: Vector3,
	tamano: Vector3,
	descripcion: String,
) -> Interactuable3D:
	var zona := Interactuable3D.new()
	zona.name = nombre
	zona.verbo = Interactuable3D.Verbo.EXAMINAR
	zona.nombre_objeto = descripcion
	zona.sonido = Interactuable3D.SIN_SONIDO
	zona.position = posicion
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamano
	colision.shape = forma
	zona.add_child(colision)
	padre.add_child(zona)
	return zona


func _montar_lector() -> void:
	var capa := CanvasLayer.new()
	capa.name = "VisorMuseo"
	add_child(capa)
	_panel = PanelContainer.new()
	_panel.name = "FichaNoCanonica"
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 32.0
	_panel.offset_right = -32.0
	_panel.offset_top = -206.0
	_panel.offset_bottom = -28.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	capa.add_child(_panel)
	_lectura = Label.new()
	_lectura.name = "TextoPosibilidad"
	_lectura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lectura.add_theme_font_size_override("font_size", 22)
	_panel.add_child(_lectura)


func _montar_sala() -> void:
	_sala = Node3D.new()
	_sala.name = "SalaPosible"
	_sala.position = Vector3(0.0, 0.0, 11.0)
	_sala.visible = false
	add_child(_sala)

	var suelo := MeshInstance3D.new()
	suelo.name = "SueloVidaPosible"
	var malla := BoxMesh.new()
	malla.size = Vector3(6.0, 0.2, 6.0)
	suelo.mesh = malla
	suelo.position.y = -0.1
	_sala.add_child(suelo)

	var suelo_fisico := StaticBody3D.new()
	suelo_fisico.name = "ColisionSala"
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(6.0, 0.2, 6.0)
	colision.shape = forma
	colision.position.y = -0.1
	suelo_fisico.add_child(colision)
	_sala.add_child(suelo_fisico)

	var inscripcion := Label3D.new()
	inscripcion.name = "InscripcionNoCanonica"
	inscripcion.text = "LO QUE NO OCURRIÓ"
	inscripcion.font_size = 48
	inscripcion.pixel_size = 0.005
	inscripcion.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	inscripcion.position = Vector3(0.0, 1.7, 0.0)
	_sala.add_child(inscripcion)

	_salida = _zona(
		_sala,
		"RegresarMuseo",
		Vector3(0.0, 1.0, 2.0),
		Vector3(2.0, 2.0, 1.0),
		"al museo",
	)
	_salida.habilitado = false
	_salida.activado.connect(_salir)


func _examinar(_actor_ignorado: Node, indice: int) -> void:
	if _explorando or indice < 0 or indice >= _opciones.size():
		return
	_seleccion = indice
	var opcion: Dictionary = _opciones[indice]
	_lectura.text = "VIDA POSIBLE · NO CONSTA EN EL EXPEDIENTE\n\n" + tr(
		String(opcion.get("clave_texto", ""))
	)
	_panel.visible = true
	var disponible := bool(opcion.get("explorable", false))
	_portal.habilitado = disponible
	(get_node("VitrinaExplorable") as MeshInstance3D).visible = disponible
	posibilidad_leida.emit(String(opcion.get("id", "")))


func _entrar(actor: Node) -> void:
	if _seleccion < 0 or _explorando:
		return
	var opcion: Dictionary = _opciones[_seleccion]
	if not bool(opcion.get("explorable", false)):
		return
	_explorando = true
	_panel.visible = false
	_portal.habilitado = false
	_sala.visible = true
	_salida.habilitado = true
	_actor = actor as Node3D
	if _actor != null:
		_retorno_actor = _actor.global_transform
		_actor.global_position = _sala.to_global(Vector3(0.0, 0.1, -1.0))
	exploracion_iniciada.emit(String(opcion.get("id", "")))


func _salir(_actor_ignorado: Node) -> void:
	if not _explorando:
		return
	_explorando = false
	_salida.habilitado = false
	_sala.visible = false
	_portal.habilitado = true
	if _actor != null and is_instance_valid(_actor):
		_actor.global_transform = _retorno_actor
	_actor = null
	exploracion_terminada.emit(String(_opciones[_seleccion].get("id", "")))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancelar") and _panel != null and _panel.visible:
		_panel.visible = false
		get_viewport().set_input_as_handled()
