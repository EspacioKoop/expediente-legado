extends Node

# Arquetipo Jungiano base - se desbloquea via interacción documental
signal activado

var id: String
var nombre: String
var descripcion: String
var efecto_combate: Dictionary
var desbloqueado: bool = false
var puntos_insight_requeridos: int = 100


func _init(
	p_id: String,
	p_nombre: String,
	p_descripcion: String,
	p_efecto: Dictionary,
	p_puntos: int,
) -> void:
	id = p_id
	nombre = p_nombre
	descripcion = p_descripcion
	efecto_combate = p_efecto
	puntos_insight_requeridos = p_puntos


func desbloquear() -> void:
	desbloqueado = true
	activado.emit()
	print("Arquetipo %s desbloqueado: %s" % [nombre, efecto_combate])


func obtener_efecto() -> Dictionary:
	return efecto_combate if desbloqueado else {}
