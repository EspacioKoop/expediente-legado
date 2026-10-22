## Sueño meta #2432: el espacio se materializa de forma deliberada, no por
## errores del motor. Cada fase conserva la salida; no escribe Partida/Jornada.
class_name MetaDreamController
extends Node3D

signal fase_cambiada(fase: int)
signal terminado

const REGISTRO_INTRUSO := "res://assets/registry.json"
const FASE_GREYBOX := 1
const FASE_MATERIALES := 2
const FASE_ECOS := 3
const FASE_INTRUSO := 4
const SEGUNDOS_POR_FASE := 3.0

@export var semilla := 2432
@export var reduccion_movimiento := false

var _fase := 0
var _tiempo := 0.0
var _activo := false
var _salida_emitida := false
var _intruso: Node3D

@onready var _materializacion: Node3D = get_node_or_null("Materializacion") as Node3D
@onready var _ecos: Node3D = get_node_or_null("Ecos") as Node3D
@onready var _spawn: Marker3D = get_node_or_null("IntrusoSpawn") as Marker3D
@onready var _salida: Area3D = get_node_or_null("Salida") as Area3D


func _ready() -> void:
	if _salida != null:
		_salida.body_entered.connect(_al_entrar_salida)
	iniciar(semilla)


## Repetir la misma semilla da las mismas fases, sin reloj global ni RNG.
## El contenido no cambia de orden aunque los fotogramas tengan distinta duración.
func iniciar(raiz: int) -> void:
	semilla = raiz
	_fase = 0
	_tiempo = 0.0
	_activo = true
	_salida_emitida = false
	_limpiar_intruso()
	Sonido.detener(self)
	if _materializacion != null:
		_materializacion.visible = false
	if _ecos != null:
		_ecos.visible = false
	_activar_fase(FASE_GREYBOX)
	set_process(true)


func fase_actual() -> int:
	return _fase


func asset_intruso_visible() -> bool:
	return is_instance_valid(_intruso)


func _process(delta: float) -> void:
	if not _activo or _fase >= FASE_INTRUSO:
		return
	_tiempo += maxf(0.0, delta)
	if _tiempo < SEGUNDOS_POR_FASE:
		return
	_tiempo -= SEGUNDOS_POR_FASE
	_activar_fase(_fase + 1)


func _activar_fase(nueva: int) -> void:
	if nueva < FASE_GREYBOX or nueva > FASE_INTRUSO or nueva != _fase + 1:
		return
	_fase = nueva
	match _fase:
		FASE_MATERIALES:
			if _materializacion != null:
				_materializacion.visible = true
		FASE_ECOS:
			if _ecos != null:
				_ecos.visible = true
			Sonido.sonar(self, "crt_interrupcion")
		FASE_INTRUSO:
			_montar_intruso()
	# Sin shaders intermitentes, cambios de cámara ni alteración de colisiones:
	# la reducción de movimiento mantiene idéntica lógica y duración.
	fase_cambiada.emit(_fase)


## El registro fue versionado con su ficha de procedencia en #2439.
## Solo permite una escena 3D de arte ya registrada en el proyecto.
func _montar_intruso() -> void:
	var ruta := _ruta_intruso_registrada()
	if ruta.is_empty() or not ResourceLoader.exists(ruta, "PackedScene"):
		return
	var recurso := ResourceLoader.load(ruta) as PackedScene
	if recurso == null:
		return
	var instancia := recurso.instantiate()
	if not instancia is Node3D:
		instancia.free()
		return
	_intruso = instancia as Node3D
	_intruso.name = "IntrusoDeOtroSueno"
	add_child(_intruso)
	if _spawn != null:
		_intruso.global_transform = _spawn.global_transform


func _ruta_intruso_registrada() -> String:
	if not FileAccess.file_exists(REGISTRO_INTRUSO):
		return ""
	var registro: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGISTRO_INTRUSO))
	if not (registro is Dictionary):
		return ""
	var assets: Dictionary = (registro as Dictionary).get("assets", {})
	var entrada: Dictionary = assets.get("intruso", {})
	if int(entrada.get("phase", 0)) != FASE_INTRUSO:
		return ""
	var ruta := String(entrada.get("path", ""))
	return ruta if ruta.begins_with("res://arte/sueno_fotorrealista/") else ""


func _limpiar_intruso() -> void:
	if is_instance_valid(_intruso):
		_intruso.queue_free()
	_intruso = null


func _al_entrar_salida(cuerpo: Node3D) -> void:
	if cuerpo is CharacterBody3D and cuerpo.name == "Caminante":
		abandonar()


func _unhandled_input(evento: InputEvent) -> void:
	if _activo and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		abandonar()


## Escape y el umbral están disponibles desde la primera fase.
func abandonar() -> void:
	if _salida_emitida:
		return
	_salida_emitida = true
	_activo = false
	set_process(false)
	Sonido.detener(self)
	_limpiar_intruso()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	terminado.emit()
	# La escena también se puede ejecutar por separado desde el editor.
	# Dentro de Dia, el anfitrión escucha terminado y decide el retorno.
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://escenas/inicio.tscn")
