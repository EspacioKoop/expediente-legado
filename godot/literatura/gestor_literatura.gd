extends Node

signal obra_conocida(obra_id: String)

var obras: Array = []
var obras_conocidas: Array[String] = []
var insight_total: int = 0
var momentum_bonus: float = 0.0


func _ready() -> void:
	var archivo := FileAccess.open("res://datos/literatura/obras.json", FileAccess.READ)
	if archivo == null:
		return
	var data = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if typeof(data) == TYPE_DICTIONARY:
		obras = data.get("obras", [])


func conocer_obra(obra_id: String) -> bool:
	if obra_id.is_empty() or obra_id in obras_conocidas:
		return false
	obras_conocidas.append(obra_id)

	var efecto := _obtener_efecto_obra(obra_id)
	var insight := int(efecto.get("bonus_insight", 0))
	if insight > 0:
		insight_total += insight
		var gestor_arquetipos := get_node_or_null("/root/GestorArquetipos")
		if gestor_arquetipos != null:
			gestor_arquetipos.call("ganar_insight", insight)

	var bonus := float(efecto.get("bonus_momentum", 0.0))
	if bonus > 0.0:
		momentum_bonus += bonus
		var gestor_momentum := get_node_or_null("/root/GestorMomentum")
		if gestor_momentum != null:
			gestor_momentum.call("agregar_momentum", bonus)

	obra_conocida.emit(obra_id)
	return true


func obtener_insight_total() -> int:
	return insight_total


func obtener_momentum_bonus() -> float:
	return momentum_bonus


func _obtener_efecto_obra(obra_id: String) -> Dictionary:
	for obra in obras:
		if typeof(obra) == TYPE_DICTIONARY and String(obra.get("id", "")) == obra_id:
			var efecto = obra.get("efecto", {})
			return efecto.duplicate(true) if typeof(efecto) == TYPE_DICTIONARY else {}
	return {}
