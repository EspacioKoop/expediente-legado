extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_sin_memoria_legitima()
	_probar_una_sola_sala_no_fabrica_recurrencia()
	_probar_retorno_entre_tres_salas()
	_probar_tarot_valido_ancla_ciclo()
	_probar_reproducibilidad()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_sin_memoria_legitima() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var firma := SuenoRecurrenciaSimbolica.montar(mundo, [], 0, 3, 888, 8)
	_comprobar(firma == null, "#888: sin anomalías legítimas no aparece recurrencia")
	_comprobar(
		mundo.find_child("RecurrenciaSimbolica", false, false) == null,
		"#888: el vacío no deja una firma huérfana",
	)

	var desconocida := _anomalia("desconocido", Vector3.ZERO)
	mundo.add_child(desconocida)
	firma = SuenoRecurrenciaSimbolica.montar(mundo, [desconocida], 0, 3, 888, 8)
	_comprobar(firma == null, "#888: un motivo ajeno no fabrica simbolismo")
	mundo.queue_free()


func _probar_una_sola_sala_no_fabrica_recurrencia() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var conocida := _anomalia("doble", Vector3(1.0, 0.0, 1.0))
	mundo.add_child(conocida)
	var firma := SuenoRecurrenciaSimbolica.montar(mundo, [conocida], 0, 1, 888, 8)
	_comprobar(firma == null, "#888: una noche de una sola sala no finge un retorno")
	mundo.queue_free()


func _probar_retorno_entre_tres_salas() -> void:
	var giros := []
	for indice in range(3):
		var mundo := Node3D.new()
		root.add_child(mundo)
		var anomalias := [
			_anomalia("umbral", Vector3(-1.0, 0.0, 0.0)),
			_anomalia("doble", Vector3(0.0, 0.0, 0.0)),
			_anomalia("laberinto", Vector3(1.0, 0.0, 0.0)),
		]
		for anomalia in anomalias:
			mundo.add_child(anomalia)
		var firma := SuenoRecurrenciaSimbolica.montar(mundo, anomalias, indice, 3, 1200, 9)
		_comprobar(firma != null, "#888: cada sala de la secuencia recibe la firma")
		if firma != null:
			_comprobar(
				String(firma.get_meta("motivo_simbolico", "")) == "laberinto",
				"#888: las tres salas conservan el mismo motivo ancla",
			)
			_comprobar(
				String(firma.get_meta("firma_simbolica", "")) == "retorno:laberinto",
				"#888: la firma compartida no depende del índice de sala",
			)
			_comprobar(
				int(firma.get_meta("indice_escena", -1)) == indice,
				"#888: la transformación conoce su posición en la noche",
			)
			_comprobar(
				firma.find_children("*", "MeshInstance3D", true, false).size() == 5,
				"#888: laberinto conserva una huella acotada de cinco trazos",
			)
			_comprobar(
				firma.find_children("*", "CollisionShape3D", true, false).is_empty(),
				"#888: la recurrencia no cambia colisiones",
			)
			_comprobar(
				firma.find_children("*", "Control", true, false).is_empty(),
				"#888: la recurrencia no añade HUD ni rótulos",
			)
			giros.append(firma.rotation_degrees.y)
		mundo.queue_free()
	_comprobar(giros.size() == 3, "#888: se observan tres fases de la misma firma")
	if giros.size() == 3:
		_comprobar(
			(
				not is_equal_approx(float(giros[0]), float(giros[1]))
				and not is_equal_approx(float(giros[1]), float(giros[2]))
			),
			"#888: cada sala transforma el retorno sin cambiar su identidad",
		)


func _probar_tarot_valido_ancla_ciclo() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var tarot := _anomalia("ciclo-centro", Vector3(0.5, 0.0, -0.5))
	var objeto := _anomalia("laberinto", Vector3(-0.5, 0.0, 0.5))
	mundo.add_child(tarot)
	mundo.add_child(objeto)
	var firma := SuenoRecurrenciaSimbolica.montar(mundo, [objeto, tarot], 1, 3, 777, 4)
	_comprobar(firma != null, "#888: tarot ya legitimado puede anclar una recurrencia")
	if firma != null:
		_comprobar(
			String(firma.get_meta("motivo_simbolico", "")) == "ciclo-centro",
			"#888: ciclo/centro prima cuando la carta ya existe en la sala",
		)
		_comprobar(
			firma.find_children("*", "MeshInstance3D", true, false).size() == 6,
			"#888: ciclo/centro retorna como seis marcas discretas",
		)
	mundo.queue_free()


func _probar_reproducibilidad() -> void:
	var mundo_a := Node3D.new()
	var mundo_b := Node3D.new()
	root.add_child(mundo_a)
	root.add_child(mundo_b)
	var anomalia_a := _anomalia("doble", Vector3(1.25, 0.0, -0.75))
	var anomalia_b := _anomalia("doble", Vector3(1.25, 0.0, -0.75))
	mundo_a.add_child(anomalia_a)
	mundo_b.add_child(anomalia_b)
	var firma_a := SuenoRecurrenciaSimbolica.montar(mundo_a, [anomalia_a], 1, 3, 4321, 6)
	var firma_b := SuenoRecurrenciaSimbolica.montar(mundo_b, [anomalia_b], 1, 3, 4321, 6)
	_comprobar(firma_a != null and firma_b != null, "#888: la misma noche monta ambas firmas")
	if firma_a != null and firma_b != null:
		_comprobar(firma_a.transform == firma_b.transform, "#888: la fase es reproducible")
		var mallas_a := firma_a.find_children("*", "MeshInstance3D", true, false)
		var mallas_b := firma_b.find_children("*", "MeshInstance3D", true, false)
		_comprobar(mallas_a.size() == mallas_b.size(), "#888: la geometría mantiene densidad")
		for i in range(mallas_a.size()):
			_comprobar(
				(mallas_a[i] as Node3D).transform == (mallas_b[i] as Node3D).transform,
				"#888: trazo reproducible %d" % i,
			)
	mundo_a.queue_free()
	mundo_b.queue_free()


func _anomalia(motivo: String, posicion: Vector3) -> AnomaliaSueno3D:
	var anomalia := AnomaliaSueno3D.new()
	anomalia.position = posicion
	anomalia.set_meta("motivo_simbolico", motivo)
	return anomalia


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SuenoRecurrencia: " + nombre)
