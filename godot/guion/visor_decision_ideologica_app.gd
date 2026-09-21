## Superficie visible del primer cierre ideológico de expediente (#924).
##
## El contrato de datos vive en DecisionIdeologicaExpediente. Esta capa solo
## presenta, después de la firma real, las opciones que ese contexto declara y
## persiste la elección. No recalcula hechos, pistas, responsables ni veredictos.
extends "res://guion/visor_pronosticos_app.gd"

const TEXTO_OPCION := {
	"responsabilidad_compartida": "VISOR_DECISION_924_RESPONSABILIDAD",
	"revision_procedimental": "VISOR_DECISION_924_REVISION",
	"conciliacion_interna": "VISOR_DECISION_924_CONCILIACION",
}

var _decision_bloque: VBoxContainer
var _decision_estado: Label
var _decision_opciones: VBoxContainer


func _ready() -> void:
	super._ready()
	_actualizar_decision()


func _columna_indice() -> Control:
	var columna: Control = super._columna_indice()
	columna.add_child(HSeparator.new())

	_decision_bloque = VBoxContainer.new()
	_decision_bloque.name = "DecisionIdeologicaExpediente"
	_decision_bloque.add_theme_constant_override("separation", 4)
	columna.add_child(_decision_bloque)

	var titulo := Label.new()
	titulo.text = tr("VISOR_DECISION_924_TITULO")
	_decision_bloque.add_child(titulo)

	_decision_estado = Label.new()
	_decision_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_decision_bloque.add_child(_decision_estado)

	_decision_opciones = VBoxContainer.new()
	_decision_opciones.add_theme_constant_override("separation", 3)
	_decision_bloque.add_child(_decision_opciones)
	return columna


func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_actualizar_decision()


func _mostrar_cierre(acusacion: Dictionary, duelo: Dictionary = {}) -> void:
	super._mostrar_cierre(acusacion, duelo)
	_actualizar_decision()


func _actualizar_decision() -> void:
	if _decision_bloque == null or _decision_estado == null or _decision_opciones == null:
		return
	var caso_id := String(caso.get("id", ""))
	var definicion := DecisionIdeologicaExpediente.definicion(caso_id)
	_decision_bloque.visible = not definicion.is_empty()
	_limpiar_opciones()
	if definicion.is_empty():
		return

	var registrada := DecisionIdeologicaExpediente.opcion_registrada(partida.estado, caso_id)
	if not registrada.is_empty():
		_decision_estado.text = (
			tr("VISOR_DECISION_924_REGISTRADA") % _texto_opcion(registrada)
		)
		return

	if not DecisionIdeologicaExpediente.disponible(partida.estado, caso_id):
		_decision_estado.text = tr("VISOR_DECISION_924_BLOQUEADA")
		return

	_decision_estado.text = tr("VISOR_DECISION_924_AYUDA")
	for opcion in DecisionIdeologicaExpediente.opciones(caso_id):
		var opcion_id := String(opcion.get("id", ""))
		if opcion_id.is_empty():
			continue
		var boton := Button.new()
		boton.text = _texto_opcion(opcion_id)
		boton.pressed.connect(_resolver_decision.bind(opcion_id))
		_decision_opciones.add_child(boton)


func _limpiar_opciones() -> void:
	for hijo in _decision_opciones.get_children():
		_decision_opciones.remove_child(hijo)
		hijo.queue_free()


func _resolver_decision(opcion_id: String) -> void:
	if _hay_guardado_a_medias():
		return
	var caso_id := String(caso.get("id", ""))
	var resultado := DecisionIdeologicaExpediente.resolver(partida.estado, caso_id, opcion_id)
	if String(resultado.get("resultado", "")) == "registrada":
		Sonido.sonar(self, "pulsar")
		_guardar_o_avisar()
	_actualizar_decision()


func _texto_opcion(opcion_id: String) -> String:
	var clave := String(TEXTO_OPCION.get(opcion_id, ""))
	return tr(clave) if not clave.is_empty() else opcion_id
