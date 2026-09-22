extends Node

# Autoload: GestorLiteratura
signal obra_conocida(obra_id)

var obras: Array = []
var obras_conocidas: Array = []
var autores_conocidos: Array = []
var insight_total: int = 0
var momentum_bonus: float = 0.0  # acumulativo temporal


func _ready() -> void:
	_cargar_catalogo()


func _cargar_catalogo() -> void:
	var archivo := FileAccess.open("res://datos/literatura/obras.json", FileAccess.READ)
	if archivo == null:
		return
	var data = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if not (data is Dictionary):
		return
	var obras_data = data.get("obras", [])
	obras = obras_data if obras_data is Array else []


func conocer_obra(obra_id: String) -> bool:
	if obra_id in obras_conocidas:
		return false
	obras_conocidas.append(obra_id)

	var efecto := _obtener_efecto_obra(obra_id)
	if efecto.has("bonus_insight"):
		insight_total += int(efecto.get("bonus_insight", 0))
	if efecto.has("bonus_momentum"):
		var bonus := float(efecto.get("bonus_momentum", 0.0))
		momentum_bonus += bonus
		GestorMomentum.momentum_actual = min(
			GestorMomentum.momentum_max,
			GestorMomentum.momentum_actual + bonus,
		)
	obra_conocida.emit(obra_id)
	return true


func obtener_insight_total() -> int:
	return insight_total


func obtener_momentum_bonus() -> float:
	return momentum_bonus


func _obtener_efecto_obra(obra_id: String) -> Dictionary:
	if obras.is_empty():
		_cargar_catalogo()
	for obra in obras:
		if obra is Dictionary and String(obra.get("id", "")) == obra_id:
			var efecto = obra.get("efecto", {})
			return efecto if efecto is Dictionary else {}
	return {}


func _arquetipo_desbloqueado(id: String):
	var arquetipo = GestorArquetipos.obtener_arquetipo(id)
	if arquetipo == null or not bool(arquetipo.desbloqueado):
		return null
	return arquetipo


func _aplicar_efecto_especial(_obra_id: String, efecto: String) -> void:
	match efecto:
		"revelacion":
			var persona = _arquetipo_desbloqueado("persona")
			if persona != null:
				GestorArquetipos.ganar_insight(20)
				persona.efecto_combate["evasion_temporal"] = 0.3
		"transformacion":
			var sombra = _arquetipo_desbloqueado("sombra")
			if sombra != null:
				sombra.efecto_combate["bonus_crit"] = (
					float(sombra.efecto_combate.get("bonus_crit", 0.0)) + 0.1
				)
		"no_linealidad":
			if _arquetipo_desbloqueado("self") != null:
				GestorArquetipos.ganar_insight(15)
		"ciclos_temporales":
			GestorMomentum.momentum_actual = min(
				GestorMomentum.momentum_max,
				GestorMomentum.momentum_actual + 15,
			)
		"corriente_conciencia":
			GestorArquetipos.ganar_insight(30)
			GestorMomentum.momentum_actual = max(0, GestorMomentum.momentum_actual - 20)


func _aplicar_cita_especial(_obra_id: String, efecto: String) -> void:
	match efecto:
		"revelacion":
			print("Revelacion: debilidad enemiga expuesta - Anima cura aliados")
			if _arquetipo_desbloqueado("anima") != null:
				pass
		"transformacion":
			print("Transformacion: forma alternativa activada - Sombra desatada")
			if _arquetipo_desbloqueado("sombra") != null:
				GestorMomentum.ejecutar_finisher("super")
		"no_linealidad":
			print("No linealidad: combos desordenados temporalmente - Persona adapta")
		"ciclos_temporales":
			print("Ciclos temporales: momentum regenera rapido")
			GestorMomentum.decay_rate = 2.0
		"corriente_conciencia":
			print("Corriente de conciencia: insight instantaneo")
			GestorArquetipos.ganar_insight(50)
