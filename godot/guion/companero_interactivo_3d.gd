## Compañero conversable del mundo 3D (#397).
##
## No habla por proximidad ni elige frases al azar. Solo expone una señal visual
## cuando el detector de interacción lo tiene en foco y solicita conversación
## cuando el jugador activa la acción semántica `interactuar`.
class_name CompaneroInteractivo3D
extends Interactuable3D

signal conversacion_solicitada(
	companero: CompaneroInteractivo3D,
	actor: Node,
	clave_dialogo: String,
)

@export var nombre_visible := ""
@export var clave_dialogo := ""
@export var altura_indicador := 2.05

var _indicador: Label3D


func _ready() -> void:
	_indicador = Label3D.new()
	_indicador.name = "IndicadorConversacion"
	_indicador.position = Vector3(0.0, altura_indicador, 0.0)
	_indicador.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_indicador.fixed_size = true
	_indicador.no_depth_test = true
	_indicador.font_size = 24
	_indicador.outline_size = 8
	_indicador.visible = false
	add_child(_indicador)
	_refrescar_indicador()


func texto_accion() -> String:
	var nombre := nombre_visible.strip_edges()
	if nombre.is_empty():
		return "Hablar"
	return "Hablar con %s" % nombre


func interactuar(actor: Node) -> bool:
	if not habilitado:
		return false
	activado.emit(actor)
	conversacion_solicitada.emit(self, actor, clave_dialogo)
	return true


func marcar_en_foco(en_foco: bool) -> void:
	if not is_instance_valid(_indicador):
		return
	_indicador.visible = en_foco and habilitado


func _refrescar_indicador() -> void:
	if not is_instance_valid(_indicador):
		return
	var nombre := nombre_visible.strip_edges()
	_indicador.text = "◆" if nombre.is_empty() else "◆ %s" % nombre
