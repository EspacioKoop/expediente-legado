## Integra el golf de pasillo (#158) como pausa opcional de oficina.
##
## Reutiliza GolfPartidaApp y RankingGolf. No crea física, reglas ni ranking
## paralelos; este controller solo decide disponibilidad, entrada/salida segura y
## registro local del resultado completo.
class_name DiaGolfPasilloApp
extends Node

const ESCENA_GOLF := preload("res://escenas/golf_partida_standalone.tscn")
const POSICION_OFERTA := Vector3(-4.95, 0.18, 3.72)
const RADIO_OFERTA := 0.52
const PERIODO_DIAS := 4
const DIA_INICIAL := 3
const CLAVE_ULTIMO_DIA := "golf_pasillo_ultimo_dia"
const ALIAS_RANKING_LOCAL := "AUDITOR 4-B"

var ruta_ranking_local := RankingGolf.RUTA_LOCAL

var _mundo_id := 0
var _oferta: Interactuable3D
var _golf: GolfPartidaApp
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

	if is_instance_valid(_golf):
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
	var dia := maxi(1, int(jornada.get("dia", 1)))
	if int(jornada.get(CLAVE_ULTIMO_DIA, 0)) == dia:
		return false
	if dia < DIA_INICIAL:
		return false
	return posmod(dia - DIA_INICIAL, PERIODO_DIAS) == 0


static func marcar_jugado(jornada: Dictionary) -> void:
	if jornada.is_empty():
		return
	jornada[CLAVE_ULTIMO_DIA] = maxi(1, int(jornada.get("dia", 1)))


func _montar_oferta(mundo: Node3D) -> void:
	var oferta := Interactuable3D.new()
	oferta.name = "GolfPasilloOferta"
	oferta.position = POSICION_OFERTA
	oferta.verbo = Interactuable3D.Verbo.USAR
	oferta.nombre_objeto = "golf de pasillo"
	oferta.sonido = Interactuable3D.SIN_SONIDO

	var colision := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = RADIO_OFERTA
	colision.shape = esfera
	oferta.add_child(colision)

	var material_bola := StandardMaterial3D.new()
	material_bola.albedo_color = Color(0.82, 0.82, 0.76)
	material_bola.roughness = 0.82
	var bola := MeshInstance3D.new()
	var esfera_bola := SphereMesh.new()
	esfera_bola.radius = 0.08
	esfera_bola.height = 0.16
	bola.mesh = esfera_bola
	bola.material_override = material_bola
	bola.position = Vector3(-0.12, 0.03, 0.0)
	oferta.add_child(bola)

	var material_palo := StandardMaterial3D.new()
	material_palo.albedo_color = Color(0.22, 0.23, 0.23)
	material_palo.metallic = 0.45
	material_palo.roughness = 0.55
	var palo := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.025
	cilindro.bottom_radius = 0.025
	cilindro.height = 0.72
	palo.mesh = cilindro
	palo.material_override = material_palo
	palo.position = Vector3(0.14, 0.31, 0.02)
	palo.rotation_degrees.z = -18.0
	oferta.add_child(palo)

	oferta.activado.connect(_abrir)
	mundo.add_child(oferta)
	_oferta = oferta


func _retirar_oferta() -> void:
	if is_instance_valid(_oferta):
		_oferta.queue_free()
	_oferta = null


func _abrir(_actor: Node) -> void:
	if is_instance_valid(_golf) or _cerrando or get_tree().paused:
		return
	var dia := get_parent()
	if (
		dia == null
		or dia.get("_mundo") == null
		or dia.get("_pantalla") != null
		or not disponible(dia.jornada)
	):
		return

	var sesion := ESCENA_GOLF.instantiate() as GolfPartidaApp
	if sesion == null:
		return

	marcar_jugado(dia.jornada)
	if dia.has_method("_guardar_o_avisar"):
		dia.call("_guardar_o_avisar", "")

	_guardar_presentacion(dia)
	_golf = sesion
	_golf.name = "GolfPasilloSesion"
	_golf.partida_terminada.connect(_al_terminar)
	dia.add_child(_golf)

	if is_instance_valid(_mundo_sesion):
		_mundo_sesion.visible = false
	if is_instance_valid(_caminante_sesion):
		_caminante_sesion.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(_hud_sesion):
		_hud_sesion.visible = false
	var menu := _menu_global()
	if menu != null:
		menu.set_process_unhandled_input(false)


func _guardar_presentacion(dia: Node) -> void:
	_presentacion_guardada = true
	_mundo_sesion = dia._mundo
	_mundo_visible_previo = _mundo_sesion.visible
	_caminante_sesion = dia.get("_caminante")
	if is_instance_valid(_caminante_sesion):
		_modo_caminante_previo = _caminante_sesion.process_mode
	_camara_previa = get_viewport().get_camera_3d()
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
	if _cerrando or not is_instance_valid(_golf):
		return
	_golf._al_abandonar_hoyo()


func _cerrar_sesion(resultado: Dictionary) -> void:
	var dia := get_parent()
	if dia != null:
		dia.set_meta("ultimo_resultado_golf", resultado.duplicate(true))
	if is_instance_valid(_golf):
		_golf.queue_free()
	_golf = null
	_restaurar_presentacion()
	if bool(resultado.get("completa", false)):
		_registrar_ranking_local(dia, resultado)
	_cerrando = false


func _registrar_ranking_local(dia: Node, resultado: Dictionary) -> Array:
	var totales: Variant = resultado.get("totales", {})
	if not totales is Dictionary or not (totales as Dictionary).has(GolfPartidaApp.JUGADOR):
		return []
	var golpes := int((totales as Dictionary)[GolfPartidaApp.JUGADOR])
	var tabla := RankingGolf.registrar_local(ALIAS_RANKING_LOCAL, golpes, ruta_ranking_local)
	if dia != null:
		dia.set_meta("ultimo_ranking_golf_local", tabla.duplicate(true))
	return tabla


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
