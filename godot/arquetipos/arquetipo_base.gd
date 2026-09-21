extends Node

signal activado(arquetipo_id: String)

var id: String = ""
var nombre: String = ""
var descripcion: String = ""
var efecto_combate: Dictionary = {}
var desbloqueado: bool = false
var puntos_insight_requeridos: int = 100


func configurar(
	p_id: String,
	p_nombre: String,
	p_descripcion: String,
	p_efecto: Dictionary,
	p_puntos: int
) -> void:
	id = p_id
	nombre = p_nombre
	descripcion = p_descripcion
	efecto_combate = p_efecto.duplicate(true)
	puntos_insight_requeridos = maxi(0, p_puntos)


func desbloquear() -> bool:
	if desbloqueado:
		return false
	desbloqueado = true
	activado.emit(id)
	return true


func obtener_efecto() -> Dictionary:
	return efecto_combate.duplicate(true) if desbloqueado else {}
