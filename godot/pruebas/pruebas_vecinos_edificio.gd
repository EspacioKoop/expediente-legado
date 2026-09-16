extends SceneTree

const Vecinos := preload("res://guion/vecinos_edificio.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_roster_y_calendario()
	_probar_reduccion_movimiento()
	_probar_estado_portal()
	_probar_paquete_equivocado()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_roster_y_calendario() -> void:
	var vistos := {}
	var estados_por_id := {}
	for dia in range(1, 17):
		var jornada := {"dia": dia, "fase": "trayecto"}
		var primera := Vecinos.presencias(jornada)
		var segunda := Vecinos.presencias(jornada)
		_comprobar(primera == segunda, "día %d es reproducible" % dia)
		for presencia in primera:
			var id := String(presencia.get("id", ""))
			var estado := String(presencia.get("estado", ""))
			vistos[id] = true
			if not estados_por_id.has(id):
				estados_por_id[id] = {}
			estados_por_id[id][estado] = true

	for id in ["manuela_3b", "televisor_2a", "pasos_4a", "repartidor_confundido"]:
		_comprobar(vistos.has(id), "%s aparece en el calendario" % id)
		_comprobar(estados_por_id[id].size() >= 2, "%s alterna al menos dos estados" % id)

	_comprobar(
		Vecinos.presencias({"dia": 3, "fase": "casa"}).is_empty(),
		"las rutinas del portal no invaden la fase casa"
	)


func _probar_reduccion_movimiento() -> void:
	var jornada := {"dia": 1, "fase": "trayecto"}
	var normal := Vecinos.presencias(jornada)
	var reducida := Vecinos.presencias(jornada, true)
	var manuela_normal := _buscar(normal, "manuela_3b")
	var manuela_reducida := _buscar(reducida, "manuela_3b")
	_comprobar(not manuela_normal.is_empty(), "Manuela es visible el día 1")
	_comprobar(
		String(manuela_normal.get("movimiento", "")) != "estatico",
		"la presentación normal conserva el gesto ambiental"
	)
	_comprobar(
		String(manuela_reducida.get("movimiento", "")) == "estatico",
		"reducción de movimiento conserva la presencia sin animarla"
	)


func _probar_estado_portal() -> void:
	var dia_1 := Vecinos.estado_portal({"dia": 1, "fase": "trayecto"})
	var dia_2 := Vecinos.estado_portal({"dia": 2, "fase": "trayecto"})
	_comprobar(dia_1["felpudo"] != dia_2["felpudo"], "el felpudo acusa el paso de los días")
	_comprobar(dia_1["tablon_id"] != dia_2["tablon_id"], "el tablón rota avisos comunes")
	_comprobar(dia_1["puerta_2a"] == "cerrada", "2º A está silencioso el día 1")
	_comprobar(dia_2["puerta_2a"] == "entornada", "2º A deja oír el televisor el día 2")
	_comprobar(dia_2["sonidos"].has("televisor_murmullos"), "la ausencia de NPC se oye")
	var reducido := Vecinos.estado_portal({"dia": 2, "fase": "trayecto"}, true)
	_comprobar(bool(reducido["reduccion_movimiento"]), "el estado ambiental expone accesibilidad")


func _probar_paquete_equivocado() -> void:
	var temprano := {"dia": 4, "fase": "trayecto"}
	_comprobar(
		Vecinos.interacciones(temprano).is_empty(),
		"la primera visita del repartidor no fuerza una interacción"
	)

	var jornada := {"dia": 8, "fase": "trayecto"}
	var acciones := Vecinos.interacciones(jornada)
	_comprobar(acciones.size() == 1, "la segunda visita deja un único paquete equivocado")
	var accion: Dictionary = acciones[0]
	_comprobar(String(accion["id"]) == Vecinos.ID_PAQUETE_EQUIVOCADO, "el paquete tiene id estable")
	_comprobar(not bool(accion["dialogo"]), "recolocar el paquete no abre diálogo")
	_comprobar(String(accion["verbo"]) == "coger", "la acción declara un verbo semántico")
	_comprobar(String(accion["correo_postal"]) == "buzon_portal", "comparte ancla con #672")

	var resultado := Vecinos.resolver_interaccion(jornada, Vecinos.ID_PAQUETE_EQUIVOCADO)
	_comprobar(bool(resultado["ok"]), "recolocar el paquete se resuelve")
	_comprobar(not bool(resultado["bloquea_campana"]), "el gesto vecinal nunca bloquea campaña")
	_comprobar(Vecinos.interacciones(jornada).is_empty(), "la resolución es persistente durante el día")
	var repetido := Vecinos.resolver_interaccion(jornada, Vecinos.ID_PAQUETE_EQUIVOCADO)
	_comprobar(bool(repetido["ok"]) and bool(repetido["ya_resuelta"]), "resolver dos veces es idempotente")
	_comprobar(not resultado.has("dinero"), "el gesto no crea una economía vecinal")


func _buscar(presencias: Array[Dictionary], id: String) -> Dictionary:
	for presencia in presencias:
		if String(presencia.get("id", "")) == id:
			return presencia
	return {}


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO VecinosEdificio: " + nombre)
