## Controller de #671 para `dia.tscn`.
##
## Materializa el teléfono únicamente en casa. Si se abandona la fase con una
## llamada sin atender, la deriva al contestador antes de guardar: no existen
## ventanas de segundos ni contenido crítico que se pierda por no correr al aparato.
extends Node

const Telefono3D := preload("res://guion/telefono_fijo_interactivo_3d.gd")

var _mundo_id := 0
var _fase_previa := ""
var _telefono: TelefonoFijoInteractivo3D
var _panel: TelefonoFijoPanel
var _mouse_previo := Input.MOUSE_MODE_CAPTURED
var _timbre_emitido_dia := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var fase := String(dia.jornada.get("fase", ""))
	if _fase_previa == "casa" and fase != "casa":
		_al_abandonar_casa(dia)
	_fase_previa = fase

	if dia._mundo == null or fase != "casa":
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_id and is_instance_valid(_telefono):
		_telefono.actualizar_estado()
		return

	_mundo_id = mundo_id
	TelefonoFijo.preparar_casa(dia.jornada)
	_telefono = Telefono3D.new()
	_telefono.name = "TelefonoFijoCasa"
	# Encima de la estantería doméstica creada por CasaUtileria (#133/#400).
	# Si ese mueble cambia, el aparato sigue dentro del volumen de la casa y no
	# introduce colisión de navegación: su cuerpo interactivo es Area3D.
	_telefono.position = Vector3(1.25, 1.72, -3.04)
	_telefono.rotation_degrees.y = 180.0
	mundo.add_child(_telefono)
	_telefono.configurar(dia.jornada)
	_telefono.telefono_usado.connect(_al_usar_telefono)
	_emitir_timbre_si_procede(dia)


func _al_usar_telefono(_actor: Node) -> void:
	if get_tree().paused:
		return
	var dia := get_parent()
	if dia == null:
		return
	_asegurar_panel(dia)
	_mouse_previo = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_panel.abrir(dia.jornada)


func _asegurar_panel(dia: Node) -> void:
	if is_instance_valid(_panel):
		return
	_panel = TelefonoFijoPanel.new()
	_panel.name = "TelefonoFijoPanel"
	_panel.cerrada.connect(_cerrar_panel)
	_panel.estado_cambiado.connect(_al_cambiar_estado)
	dia.add_child(_panel)


func _al_cambiar_estado() -> void:
	var dia := get_parent()
	if dia == null:
		return
	if is_instance_valid(_telefono):
		_telefono.actualizar_estado()
	_guardar(dia)


func _cerrar_panel() -> void:
	if not is_instance_valid(_panel) or not _panel.visible:
		return
	_panel.hide()
	get_tree().paused = false
	Input.mouse_mode = _mouse_previo
	var dia := get_parent()
	if dia != null:
		_guardar(dia)


func _al_abandonar_casa(dia: Node) -> void:
	var resultado := TelefonoFijo.perder_activa(dia.jornada)
	if not resultado.is_empty():
		dia.set_meta("ultimo_mensaje_telefonico", resultado.duplicate(true))
		_guardar(dia)
	if bool(TelefonoFijo.estado(dia.jornada).get(TelefonoFijo.DESCOLGADO, false)):
		TelefonoFijo.colgar(dia.jornada)
		_guardar(dia)


func _emitir_timbre_si_procede(dia: Node) -> void:
	var llamada := TelefonoFijo.llamada_activa(dia.jornada)
	var numero_dia := int(dia.jornada.get("dia", 1))
	if llamada.is_empty() or _timbre_emitido_dia == numero_dia or not is_instance_valid(_telefono):
		return
	_timbre_emitido_dia = numero_dia
	# Los tests headless no tienen una escena audiovisual que consumir y una voz
	# 3D efímera puede seguir viva al destruir escenas deliberadamente en el mismo
	# frame. El juego normal conserva el timbre; el piloto visual es continuo.
	if DisplayServer.get_name() == "headless":
		return
	Sonido.sonar_en(_telefono, "marcar")


func _guardar(dia: Node) -> void:
	if dia.has_method("_guardar_o_avisar"):
		dia._guardar_o_avisar("")
