## Hoyo jugable standalone del golf de pasillo (#158).
##
## Presenta GolfBola en 3D sin introducir física no determinista. La bola visual
## queda congelada y sigue el estado puro de GolfBola. La configuración permite
## reutilizar el mismo slice dentro de una partida de tres hoyos.
class_name GolfHoyoApp
extends Node3D

signal cerrado
signal hoyo_completado(golpes: int)

const BOLA_SCENE: PackedScene = preload("res://arte/golf_pasillo/modelos/bola_siga.tscn")
const LIMITE := Rect2(-1.15, -2.15, 2.30, 4.30)
const INICIO := Vector2(0.0, 1.72)
const OBJETIVO := Vector2(0.0, -1.72)
const RADIO_OBJETIVO := 0.12
const PASO_ANGULO := 5.0
const PASO_POTENCIA := 0.1
const MAX_GOLPES := 12

var limite: Rect2 = LIMITE
var inicio: Vector2 = INICIO
var objetivo: Vector2 = OBJETIVO
var radio_objetivo := RADIO_OBJETIVO
var obstaculos: Array = []
var numero_hoyo := 1

var estado_bola: Dictionary = {}
var angulo_grados := 0.0
var potencia := 0.45
var golpes := 0
var terminada := false

var _bola: RigidBody3D
var _estado: Label
var _ayuda: Label


func configurar(configuracion: Dictionary) -> bool:
	if is_node_ready():
		return false
	var candidato_limite = configuracion.get("limite", LIMITE)
	if typeof(candidato_limite) == TYPE_RECT2:
		limite = candidato_limite
	var candidato_inicio = configuracion.get("inicio", INICIO)
	if typeof(candidato_inicio) == TYPE_VECTOR2:
		inicio = candidato_inicio
	var candidato_objetivo = configuracion.get("objetivo", OBJETIVO)
	if typeof(candidato_objetivo) == TYPE_VECTOR2:
		objetivo = candidato_objetivo
	radio_objetivo = clampf(
		float(configuracion.get("radio_objetivo", RADIO_OBJETIVO)),
		GolfBola.RADIO_BOLA * 1.5,
		0.35,
	)
	var candidatos = configuracion.get("obstaculos", [])
	obstaculos = candidatos.duplicate(true) if candidatos is Array else []
	numero_hoyo = clampi(int(configuracion.get("numero_hoyo", 1)), 1, Golf.HOYOS)
	return true


func _ready() -> void:
	_construir_mundo()
	_construir_ui()
	_reiniciar_bola()
	_refrescar_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrado.emit()
		if cerrado.get_connections().is_empty():
			queue_free()
		return
	if terminada or not GolfBola.detenida(estado_bola):
		return
	if event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_ajustar_angulo(-PASO_ANGULO)
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_ajustar_angulo(PASO_ANGULO)
	elif event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_ajustar_potencia(PASO_POTENCIA)
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_ajustar_potencia(-PASO_POTENCIA)
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_golpear()


func _physics_process(delta: float) -> void:
	if estado_bola.is_empty() or GolfBola.detenida(estado_bola):
		return
	GolfBola.avanzar(estado_bola, delta)
	_sincronizar_bola_visual()
	if GolfBola.detenida(estado_bola):
		_resolver_reposo()


func _ajustar_angulo(delta: float) -> void:
	angulo_grados = clampf(angulo_grados + delta, -70.0, 70.0)
	_refrescar_ui()


func _ajustar_potencia(delta: float) -> void:
	potencia = clampf(snappedf(potencia + delta, 0.05), 0.10, 1.0)
	_refrescar_ui()


func _golpear() -> void:
	if terminada or not GolfBola.detenida(estado_bola):
		return
	var rad := deg_to_rad(angulo_grados)
	var direccion := Vector2(sin(rad), -cos(rad))
	GolfBola.golpear(estado_bola, direccion, potencia)
	if GolfBola.detenida(estado_bola):
		return
	golpes += 1
	_refrescar_ui()


func _resolver_reposo() -> void:
	if terminada:
		return
	var posicion: Vector2 = estado_bola.get("posicion", inicio)
	if posicion.distance_to(objetivo) <= radio_objetivo:
		terminada = true
		_refrescar_ui(tr("GOLF_HOYO_COMPLETADO"))
		hoyo_completado.emit(golpes)
		return
	if golpes >= MAX_GOLPES:
		terminada = true
		_refrescar_ui(tr("GOLF_HOYO_LIMITE"))
		hoyo_completado.emit(golpes)
		return
	_refrescar_ui()


func _reiniciar_bola() -> void:
	estado_bola = GolfBola.nueva(inicio, limite, obstaculos)
	_sincronizar_bola_visual()


func _sincronizar_bola_visual() -> void:
	if not is_instance_valid(_bola):
		return
	var p: Vector2 = estado_bola.get("posicion", inicio)
	_bola.position = Vector3(p.x, GolfBola.RADIO_BOLA, p.y)


func _construir_mundo() -> void:
	var entorno := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.04, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.72, 0.62)
	env.ambient_light_energy = 0.55
	entorno.environment = env
	add_child(entorno)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-58.0, -18.0, 0.0)
	luz.light_energy = 1.5
	luz.shadow_enabled = true
	add_child(luz)

	var suelo := MeshInstance3D.new()
	var malla_suelo := BoxMesh.new()
	malla_suelo.size = Vector3(limite.size.x, 0.05, limite.size.y)
	suelo.mesh = malla_suelo
	var centro := limite.get_center()
	suelo.position = Vector3(centro.x, -0.025, centro.y)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.28, 0.25)
	material.roughness = 0.92
	suelo.material_override = material
	add_child(suelo)

	var objetivo_visual := MeshInstance3D.new()
	objetivo_visual.name = "Objetivo"
	var disco := CylinderMesh.new()
	disco.top_radius = radio_objetivo
	disco.bottom_radius = radio_objetivo
	disco.height = 0.008
	objetivo_visual.mesh = disco
	objetivo_visual.position = Vector3(objetivo.x, 0.006, objetivo.y)
	var material_objetivo := StandardMaterial3D.new()
	material_objetivo.albedo_color = Color(0.08, 0.08, 0.08)
	material_objetivo.roughness = 1.0
	objetivo_visual.material_override = material_objetivo
	add_child(objetivo_visual)

	_montar_obstaculos()

	_bola = BOLA_SCENE.instantiate()
	_bola.name = "Bola"
	_bola.freeze = true
	_bola.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	add_child(_bola)

	var camara := Camera3D.new()
	camara.position = Vector3(0.0, 4.4, 4.3)
	camara.look_at_from_position(camara.position, Vector3(0.0, 0.0, -0.25), Vector3.UP)
	camara.current = true
	add_child(camara)


func _montar_obstaculos() -> void:
	for i in obstaculos.size():
		var valor = obstaculos[i]
		if typeof(valor) != TYPE_RECT2:
			continue
		var recta: Rect2 = valor
		var obstaculo := MeshInstance3D.new()
		obstaculo.name = "Obstaculo%d" % (i + 1)
		var caja := BoxMesh.new()
		caja.size = Vector3(recta.size.x, 0.18, recta.size.y)
		obstaculo.mesh = caja
		var centro := recta.get_center()
		obstaculo.position = Vector3(centro.x, 0.09, centro.y)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.30, 0.27, 0.22)
		material.roughness = 0.9
		obstaculo.material_override = material
		add_child(obstaculo)


func _construir_ui() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	var caja := VBoxContainer.new()
	caja.offset_left = 24
	caja.offset_top = 24
	caja.offset_right = 700
	caja.offset_bottom = 150
	caja.add_theme_constant_override("separation", 6)
	capa.add_child(caja)

	var titulo := Label.new()
	titulo.text = "%s · %d/%d" % [tr("GOLF_HOYO_TITULO"), numero_hoyo, Golf.HOYOS]
	titulo.add_theme_font_size_override("font_size", 22)
	caja.add_child(titulo)

	_estado = Label.new()
	_estado.add_theme_font_size_override("font_size", 18)
	caja.add_child(_estado)

	_ayuda = Label.new()
	_ayuda.text = tr("GOLF_HOYO_AYUDA")
	caja.add_child(_ayuda)


func _refrescar_ui(mensaje: String = "") -> void:
	if not is_instance_valid(_estado):
		return
	if not mensaje.is_empty():
		_estado.text = tr("GOLF_HOYO_RESULTADO") % [mensaje, golpes]
		return
	_estado.text = (
		tr("GOLF_HOYO_ESTADO")
		% [
			angulo_grados,
			roundi(potencia * 100.0),
			golpes,
			MAX_GOLPES,
		]
	)
