extends Node

signal obra_conocida(obra_id: String)

var obras: Array = []
var obras_conocidas: Array[String] = []
var autores_conocidos: Array[String] = []
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

	var obra := obtener_obra(obra_id)
	var autor := String(obra.get("autor", ""))
	if not autor.is_empty() and autor not in autores_conocidos:
		autores_conocidos.append(autor)

	var efecto := obtener_efecto_obra(obra_id)
	var insight := int(efecto.get("bonus_insight", 0))
	if insight > 0:
		insight_total += insight
		var gestor_arquetipos := _gestor("GestorArquetipos")
		if gestor_arquetipos != null:
			gestor_arquetipos.call("ganar_insight", insight)

	var bonus := float(efecto.get("bonus_momentum", 0.0))
	if bonus > 0.0:
		momentum_bonus += bonus
		var gestor_momentum := _gestor("GestorMomentum")
		if gestor_momentum != null:
			gestor_momentum.call("agregar_momentum", bonus)

	var efecto_especial := String(efecto.get("efecto_especial", ""))
	if not efecto_especial.is_empty():
		aplicar_efecto_especial(efecto_especial)

	obra_conocida.emit(obra_id)
	return true


func obtener_insight_total() -> int:
	return insight_total


func obtener_momentum_bonus() -> float:
	return momentum_bonus


func obtener_obra(obra_id: String) -> Dictionary:
	for obra in obras:
		if typeof(obra) == TYPE_DICTIONARY and String(obra.get("id", "")) == obra_id:
			return obra.duplicate(true)
	return {}


func obtener_efecto_obra(obra_id: String) -> Dictionary:
	var obra := obtener_obra(obra_id)
	var efecto = obra.get("efecto", {})
	return efecto.duplicate(true) if typeof(efecto) == TYPE_DICTIONARY else {}


func aplicar_efecto_especial(efecto: String) -> void:
	var arquetipos := _gestor("GestorArquetipos")
	var momentum := _gestor("GestorMomentum")
	match efecto:
		"revelacion":
			if _arquetipo_desbloqueado(arquetipos, "persona"):
				arquetipos.call("ganar_insight", 20)
				_sumar_efecto_arquetipo(arquetipos, "persona", "evasion_temporal", 0.3)
		"transformacion":
			if _arquetipo_desbloqueado(arquetipos, "sombra"):
				_sumar_efecto_arquetipo(arquetipos, "sombra", "bonus_crit", 0.1)
		"no_linealidad":
			if _arquetipo_desbloqueado(arquetipos, "self"):
				arquetipos.call("ganar_insight", 15)
		"ciclos_temporales":
			if momentum != null:
				momentum.call("agregar_momentum", 15.0)
		"corriente_conciencia":
			if arquetipos != null:
				arquetipos.call("ganar_insight", 30)
			if momentum != null:
				momentum.set(
					"momentum_actual",
					maxf(0.0, float(momentum.get("momentum_actual")) - 20.0)
				)


func aplicar_cita_especial(efecto: String) -> void:
	var arquetipos := _gestor("GestorArquetipos")
	var momentum := _gestor("GestorMomentum")
	match efecto:
		"revelacion":
			if _arquetipo_desbloqueado(arquetipos, "anima"):
				_mostrar_cita("Revelación: Anima reconoce la debilidad")
		"transformacion":
			if _arquetipo_desbloqueado(arquetipos, "sombra") and momentum != null:
				momentum.call("agregar_momentum", 20.0)
				_mostrar_cita("Transformación: la Sombra alimenta el momentum")
		"no_linealidad":
			_mostrar_cita("No linealidad: Persona adapta la secuencia")
		"ciclos_temporales":
			if momentum != null:
				momentum.set("decay_rate", minf(float(momentum.get("decay_rate")), 2.0))
			_mostrar_cita("Ciclos temporales: el momentum decae más despacio")
		"corriente_conciencia":
			if arquetipos != null:
				arquetipos.call("ganar_insight", 50)
			_mostrar_cita("Corriente de conciencia: insight instantáneo")


func _gestor(nombre: String) -> Node:
	return get_node_or_null("/root/" + nombre)


func _arquetipo_desbloqueado(gestor: Node, arquetipo_id: String) -> bool:
	if gestor == null:
		return false
	var arquetipo = gestor.call("obtener_arquetipo", arquetipo_id)
	return arquetipo != null and bool(arquetipo.get("desbloqueado"))


func _sumar_efecto_arquetipo(
	gestor: Node, arquetipo_id: String, clave: String, cantidad: float
) -> void:
	if gestor == null:
		return
	var arquetipo = gestor.call("obtener_arquetipo", arquetipo_id)
	if arquetipo == null:
		return
	var efectos = arquetipo.get("efecto_combate")
	if typeof(efectos) != TYPE_DICTIONARY:
		return
	efectos[clave] = float(efectos.get(clave, 0.0)) + cantidad
	arquetipo.set("efecto_combate", efectos)


func _mostrar_cita(mensaje: String) -> void:
	print(mensaje)
