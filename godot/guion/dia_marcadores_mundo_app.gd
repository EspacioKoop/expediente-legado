## Integra los marcadores persistentes de #957 en el mundo activo de Dia.
##
## El segundo vertical añade una entrada desde MenuGlobal sin reescribirlo.
## Al elegir Marcadores, cierra el menú, resuelve el apuntado en physics_process
## (el espacio físico puede estar bloqueado durante input) y abre un selector
## modal. Las marcas siguen sin colisión: para borrar se toma la marca persistida
## más cercana al punto de la superficie que atraviesa la mira.
class_name DiaMarcadoresMundoApp
extends Node

const NOMBRE_RAIZ := "MarcadoresMundoPersistentes"
const PANEL_SCRIPT := preload("res://guion/marcadores_mundo_panel.gd")
const ALCANCE_APUNTADO := 4.0
const RADIO_BORRADO := 0.32
const OFFSET_SUPERFICIE := 0.006

var _host
var _mundo_id := 0
var _firma := ""
var _estres_presentacion := 0.0

var _menu: Node
var _boton_menu: Button
var _apertura_pendiente := false
var _punto_local := Vector3.ZERO
var _normal_local := Vector3.UP
var _marcador_apuntado_id := ""

var _capa_modal: CanvasLayer
var _modal_raiz: Control
var _panel
var _modal_abierto := false
var _pausa_previa := false
var _mouse_previo := Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_host = get_parent()
	call_deferred("_integrar_menu")


func _exit_tree() -> void:
	if _modal_abierto:
		get_tree().paused = _pausa_previa
		Input.mouse_mode = _mouse_previo
	if is_instance_valid(_boton_menu):
		_boton_menu.queue_free()


func _process(_delta: float) -> void:
	if _host == null or not is_instance_valid(_host):
		return
	if _host.jornada.is_empty() or not is_instance_valid(_host._mundo):
		return

	var mundo: Node3D = _host._mundo
	var zona := zona_actual()
	if zona.is_empty():
		return

	_sincronizar_estres()
	var marcadores := MarcadoresMundo.listar(_host.jornada, zona)
	var firma := JSON.stringify(marcadores) + "|%s|%.3f" % [zona, _estres_presentacion]
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_id and firma == _firma:
		return

	_mundo_id = mundo_id
	_firma = firma
	_remontar(mundo, marcadores)


func _physics_process(_delta: float) -> void:
	if not _apertura_pendiente:
		return
	_apertura_pendiente = false
	_resolver_apuntado_y_abrir()


func zona_actual() -> String:
	if _host == null or not is_instance_valid(_host):
		return ""
	return String(_host.jornada.get("fase", "")).strip_edges()


## #952: los marcadores no guardan estrés propio. Consumen la única fuente de
## Jornada y solo fuerzan un remontado si cambia su nivel de presentación.
func _sincronizar_estres() -> void:
	var nuevo := Estres.nivel(_host.jornada)
	if is_equal_approx(nuevo, _estres_presentacion):
		return
	_estres_presentacion = nuevo
	_firma = ""


func colocar(
	tipo: String,
	color: String,
	texto: String,
	posicion: Vector3,
	normal: Vector3,
	solo_sueno := false,
) -> Dictionary:
	if _host == null or not is_instance_valid(_host):
		return {"ok": false, "motivo": "dia_no_disponible"}
	var resultado := (
		MarcadoresMundo
		. colocar(
			_host.jornada,
			zona_actual(),
			tipo,
			color,
			texto,
			posicion,
			normal,
			solo_sueno,
		)
	)
	if bool(resultado.get("ok", false)):
		_firma = ""
		_guardar()
	return resultado


func eliminar(marcador_id: String) -> bool:
	if _host == null or not is_instance_valid(_host):
		return false
	var eliminado := MarcadoresMundo.eliminar(_host.jornada, zona_actual(), marcador_id)
	if eliminado:
		_firma = ""
		_guardar()
	return eliminado


func eliminar_zona_actual() -> int:
	if _host == null or not is_instance_valid(_host):
		return 0
	var cantidad := MarcadoresMundo.eliminar_zona(_host.jornada, zona_actual())
	if cantidad > 0:
		_firma = ""
		_guardar()
	return cantidad


## Entrada manual conservada para herramientas aisladas y compatibilidad de
## #957. En el recorrido real, _process() vuelve a sincronizar desde Estres.
func establecer_estres_presentacion(valor: float) -> void:
	var nuevo := clampf(valor, 0.0, 1.0)
	if is_equal_approx(nuevo, _estres_presentacion):
		return
	_estres_presentacion = nuevo
	_firma = ""


## Entrada diegética: se añade al mismo VBox de MenuGlobal que sus acciones
## principales, como otras extensiones del menú. Al salir de Dia se elimina.
func _integrar_menu() -> void:
	if is_instance_valid(_boton_menu):
		return
	var menu := get_node_or_null("/root/MenuGlobal")
	if menu == null:
		call_deferred("_integrar_menu")
		return
	var salir := menu.get("_salir") as Button
	if salir == null:
		call_deferred("_integrar_menu")
		return
	var caja := salir.get_parent() as VBoxContainer
	if caja == null:
		return

	_menu = menu
	_boton_menu = Button.new()
	_boton_menu.name = "MarcadoresMundo"
	_boton_menu.text = "Marcadores"
	_boton_menu.tooltip_text = "Colocar o retirar una marca en el mundo"
	_boton_menu.accessibility_name = _boton_menu.text
	_boton_menu.pressed.connect(_pedir_herramienta)
	caja.add_child(_boton_menu)
	caja.move_child(_boton_menu, salir.get_index())


func _pedir_herramienta() -> void:
	if _modal_abierto or _apertura_pendiente:
		return
	if is_instance_valid(_menu) and _menu.has_method("_cerrar"):
		_menu.call("_cerrar")
	_apertura_pendiente = true


## Godot recomienda resolver consultas al espacio físico en physics_process.
## Se proyecta el centro de la cámara, no la posición del ratón: el juego es FPS
## y la mira corresponde al centro del viewport también con mando.
func _resolver_apuntado_y_abrir() -> void:
	if _host == null or not is_instance_valid(_host) or not is_instance_valid(_host._mundo):
		_abrir_panel(false, "", 0)
		return

	var camara := get_viewport().get_camera_3d()
	var mundo := _host._mundo as Node3D
	if camara == null or mundo == null:
		_abrir_panel(false, "", 0)
		return

	var recta := get_viewport().get_visible_rect()
	var pantalla := recta.position + recta.size * 0.5
	var origen := camara.project_ray_origin(pantalla)
	var destino := origen + camara.project_ray_normal(pantalla) * ALCANCE_APUNTADO
	var consulta := PhysicsRayQueryParameters3D.create(origen, destino)
	consulta.collide_with_areas = false
	consulta.collide_with_bodies = true

	var caminante = _host.get("_caminante")
	if caminante is CollisionObject3D:
		consulta.exclude = [caminante.get_rid()]

	var golpe := camara.get_world_3d().direct_space_state.intersect_ray(consulta)
	var marcadores := MarcadoresMundo.listar(_host.jornada, zona_actual())
	if golpe.is_empty():
		_abrir_panel(false, "", marcadores.size())
		return
	var colisionador = golpe.get("collider")
	if colisionador is CharacterBody3D:
		_abrir_panel(false, "", marcadores.size())
		return

	var posicion_global: Vector3 = golpe.get("position", Vector3.ZERO)
	var normal_global: Vector3 = golpe.get("normal", Vector3.UP)
	_punto_local = mundo.to_local(posicion_global)
	_normal_local = mundo.global_transform.basis.inverse() * normal_global
	if _normal_local.length_squared() <= 0.000001:
		_normal_local = Vector3.UP
	else:
		_normal_local = _normal_local.normalized()

	_marcador_apuntado_id = marcador_cercano_a(marcadores, _punto_local, RADIO_BORRADO)
	_abrir_panel(true, _marcador_apuntado_id, marcadores.size())


static func marcador_cercano_a(marcadores: Array, punto: Vector3, radio: float) -> String:
	if radio <= 0.0:
		return ""
	var mejor_id := ""
	var mejor_distancia := radio * radio
	for datos in marcadores:
		if not datos is Dictionary:
			continue
		var distancia := MarcadoresMundo.posicion_de(datos).distance_squared_to(punto)
		if distancia > mejor_distancia:
			continue
		mejor_distancia = distancia
		mejor_id = String(datos.get("id", ""))
	return mejor_id


func _asegurar_panel() -> void:
	if is_instance_valid(_panel):
		return

	_capa_modal = CanvasLayer.new()
	_capa_modal.name = "MarcadoresMundoModal"
	_capa_modal.layer = 110
	add_child(_capa_modal)

	_modal_raiz = Control.new()
	_modal_raiz.name = "MarcadoresMundoModalRaiz"
	_modal_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_raiz.visible = false
	_capa_modal.add_child(_modal_raiz)

	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.0, 0.0, 0.0, 0.64)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_raiz.add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_raiz.add_child(centro)

	_panel = PANEL_SCRIPT.new()
	centro.add_child(_panel)
	_panel.connect("colocar_solicitado", _confirmar_colocacion)
	_panel.connect("eliminar_solicitado", _confirmar_eliminacion)
	_panel.connect("eliminar_zona_solicitado", _confirmar_eliminacion_zona)
	_panel.connect("cancelar_solicitado", _cerrar_panel)


func _abrir_panel(puede_colocar: bool, marcador_id: String, cantidad: int) -> void:
	_asegurar_panel()
	_marcador_apuntado_id = marcador_id
	_pausa_previa = get_tree().paused
	_mouse_previo = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_modal_abierto = true
	_modal_raiz.visible = true
	_panel.call("abrir", puede_colocar, not marcador_id.is_empty(), cantidad)


func _cerrar_panel() -> void:
	if not _modal_abierto:
		return
	_modal_abierto = false
	_modal_raiz.visible = false
	get_tree().paused = _pausa_previa
	Input.mouse_mode = _mouse_previo


func _confirmar_colocacion(tipo: String, color: String, texto: String) -> void:
	var resultado := colocar(
		tipo,
		color,
		texto,
		_punto_local + _normal_local * OFFSET_SUPERFICIE,
		_normal_local,
	)
	if bool(resultado.get("ok", false)):
		_cerrar_panel()
		return
	_panel.call("mostrar_error", _mensaje_error(String(resultado.get("motivo", ""))))


func _confirmar_eliminacion() -> void:
	if _marcador_apuntado_id.is_empty():
		return
	if eliminar(_marcador_apuntado_id):
		_cerrar_panel()
	else:
		_panel.call("mostrar_error", "La marca ya no está disponible.")


func _confirmar_eliminacion_zona() -> void:
	if eliminar_zona_actual() > 0:
		_cerrar_panel()
	else:
		_panel.call("mostrar_error", "Esta zona ya no tiene marcas.")


func _mensaje_error(motivo: String) -> String:
	match motivo:
		"limite_zona":
			return "Límite de marcas alcanzado en esta zona."
		"zona_invalida":
			return "No se puede marcar esta zona."
		"transformacion_invalida":
			return "La superficie apuntada no es válida."
		_:
			return "No se pudo colocar la marca."


func _remontar(mundo: Node3D, marcadores: Array) -> void:
	var anterior := mundo.get_node_or_null(NOMBRE_RAIZ)
	if anterior != null:
		mundo.remove_child(anterior)
		anterior.queue_free()

	var raiz := Node3D.new()
	raiz.name = NOMBRE_RAIZ
	mundo.add_child(raiz)

	var en_sueno := zona_actual() == "sueño"
	for datos in marcadores:
		if not MarcadoresMundo.visible_en(datos, en_sueno):
			continue
		var visual := MarcadorMundo3D.new()
		raiz.add_child(visual)
		visual.configurar(datos, en_sueno, _estres_presentacion)


func _guardar() -> void:
	if _host != null and _host.has_method("_guardar_o_avisar"):
		_host._guardar_o_avisar("")
