extends Interactuable3D

@export var ritual_ui_path: NodePath

@onready var label: Label = get_node_or_null("InteractionLabel")


func _ready() -> void:
	verbo = Verbo.USAR
	nombre_objeto = "mesa de cita"
	if label != null:
		label.visible = false


func interactuar(actor: Node) -> bool:
	if not super.interactuar(actor):
		return false
	return abrir_ritual()


func abrir_ritual() -> bool:
	var ritual := get_node_or_null(ritual_ui_path)
	if ritual == null or not ritual.has_method("show_ritual"):
		return false
	ritual.call("show_ritual")
	return true
