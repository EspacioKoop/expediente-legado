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

const TAM_COLISION := Vector3(0.9, 1.8, 0.9)

@export var nombre_visible := ""
@export var clave_dialogo := ""
@export var altura_indicador := 1.35

var _indicador: Label3D


func _ready() -> void:
	var colision := CollisionShape3D.new()
	colision.name = "ColisionConversacion"
	var forma := BoxShape3D.new()
	forma.size = TAM_COLISION
	colision.shape = forma
	add_child(colision)

	_indicador = Label3D.new()
	_indicador.name = "IndicadorConversacion"
	_indicador.position = Vector3(0.0, altura_indicador, 0.0)
	_indicador.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_indicador.fixed_size = true
	_indicador.no_depth_test = true
	_indicador.font_size = 28
	_indicador.outline_size = 8
	_indicador.text = "◆"
	_indicador.visible = false
	add_child(_indicador)


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
