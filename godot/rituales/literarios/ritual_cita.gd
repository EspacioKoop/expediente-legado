extends Control

signal ritual_aplicado(resultado: Dictionary)

@export var encuentro_id: String = "biblioteca:practica:01"
@export var fuente_ritual: String = "biblioteca:mesa_cita"

var modificador_activo: Dictionary = {}

@onready var selector: OptionButton = $Panel/VBoxContainer/ObraSelector
@onready var citar_btn: Button = $Panel/VBoxContainer/CitarButton
@onready var status: Label = $Panel/VBoxContainer/Status
@onready var close_btn: Button = $Panel/VBoxContainer/CloseButton


func _ready() -> void:
	_poblar_selector()
	citar_btn.pressed.connect(_on_citar_pressed)
	close_btn.pressed.connect(hide)
	visible = false


func _poblar_selector() -> void:
	selector.clear()
	var registro := GestorLiteratura.obtener_registro_literario()
	var vistas := {}
	for evento_bruto in LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_INSIGHT):
		if typeof(evento_bruto) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = evento_bruto
		var obra_id := String(evento.get("obra_id", ""))
		if obra_id.is_empty() or vistas.has(obra_id):
			continue
		var obra := LiteraturaCatalogo.obra(obra_id)
		if obra.is_empty():
			continue
		selector.add_item(String(obra.get("titulo", obra_id)))
		selector.set_item_metadata(selector.item_count - 1, obra_id)
		vistas[obra_id] = true

	citar_btn.disabled = selector.item_count == 0
	if selector.item_count == 0:
		status.text = "Completa una lectura para obtener un insight citable."
	else:
		status.text = "La cita cuesta 30 de momentum y dura este encuentro."


func _on_citar_pressed() -> void:
	var indice := selector.get_selected()
	if indice < 0:
		status.text = "No hay una obra citable."
		return
	var obra_id := String(selector.get_item_metadata(indice))
	_ejecutar_cita(obra_id)


func _ejecutar_cita(obra_id: String) -> Dictionary:
	var resultado := (
		GestorLiteratura
		. ejecutar_ritual_cita(
			obra_id,
			fuente_ritual,
			encuentro_id,
			0,
			GestorMomentum.momentum_actual,
		)
	)
	if not bool(resultado.get("aplicado", false)):
		_mostrar_fallo(String(resultado.get("motivo", "")))
		return resultado

	var costo := float(resultado.get("costo_momentum", 0.0))
	GestorMomentum.agregar_momentum(-costo)
	modificador_activo = (resultado.get("modificador", {}) as Dictionary).duplicate(true)
	status.text = _texto_modificador(modificador_activo)
	ritual_aplicado.emit(resultado.duplicate(true))
	return resultado


func _mostrar_fallo(motivo: String) -> void:
	match motivo:
		"momentum_insuficiente":
			status.text = "Momentum insuficiente para citar."
		"ya_ejecutado":
			status.text = "Esta cita ya se usó en el encuentro."
		"insight_requerido":
			status.text = "La obra todavía no produjo un insight."
		_:
			status.text = "La cita no puede ejecutarse en este contexto."


func _texto_modificador(modificador: Dictionary) -> String:
	if (
		String(modificador.get("tipo", "")) == "resistencia_estado"
		and String(modificador.get("estado", "")) == "miedo"
	):
		var porcentaje := roundi(float(modificador.get("delta", 0.0)) * 100.0)
		return "Inspiración activa: +%d%% resistencia al miedo (este encuentro)." % porcentaje
	return "Inspiración literaria activa durante este encuentro."


func show_ritual() -> void:
	_poblar_selector()
	visible = true
