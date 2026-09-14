extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_original_desconocido()
	_probar_frase_incompleta()
	_probar_umbral_estricto_de_encuadre()
	_probar_camara_detectada()
	_probar_interrupcion()
	_probar_toma_valida()
	_probar_consumo_y_no_sobregrabado()
	_probar_rechazo_por_falta_de_metraje()
	_probar_costura_de_proyeccion()

	if _fallos.is_empty():
		print("OK prueba_grabacion_onirica: 9 casos")
		quit(0)
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _toma_valida() -> Dictionary:
	return {
		"original_id": "original-01",
		"original_identificado": true,
		"duracion_total_segundos": 10.0,
		"duracion_en_cuadro_segundos": 5.1,
		"frase_completa": true,
		"interrumpida": false,
		"camara_detectada": false,
	}


func _estado(toma: Dictionary) -> String:
	return String(GrabacionOnirica.evaluar_toma(toma).get("estado", ""))


func _probar_original_desconocido() -> void:
	var toma := _toma_valida()
	toma["original_identificado"] = false
	_comprobar(
		_estado(toma) == GrabacionOnirica.ESTADO_CONTAMINADA,
		"original desconocido debe contaminar la toma"
	)


func _probar_frase_incompleta() -> void:
	var toma := _toma_valida()
	toma["frase_completa"] = false
	_comprobar(
		_estado(toma) == GrabacionOnirica.ESTADO_CONTAMINADA,
		"frase incompleta debe contaminar la toma"
	)


func _probar_umbral_estricto_de_encuadre() -> void:
	var toma := _toma_valida()
	toma["duracion_en_cuadro_segundos"] = 5.0
	_comprobar(
		_estado(toma) == GrabacionOnirica.ESTADO_CONTAMINADA,
		"50 por ciento exacto no debe ser valido"
	)
	toma["duracion_en_cuadro_segundos"] = 5.0001
	_comprobar(
		_estado(toma) == GrabacionOnirica.ESTADO_VALIDA,
		"mas del 50 por ciento debe poder ser valido"
	)


func _probar_camara_detectada() -> void:
	var toma := _toma_valida()
	toma["camara_detectada"] = true
	_comprobar(
		_estado(toma) == GrabacionOnirica.ESTADO_CONTAMINADA,
		"deteccion de camara debe contaminar la toma"
	)


func _probar_interrupcion() -> void:
	var toma := _toma_valida()
	toma["interrumpida"] = true
	_comprobar(
		_estado(toma) == GrabacionOnirica.ESTADO_CONTAMINADA,
		"corte o interrupcion debe contaminar la toma"
	)


func _probar_toma_valida() -> void:
	var evaluacion := GrabacionOnirica.evaluar_toma(_toma_valida())
	_comprobar(
		evaluacion.get("estado") == GrabacionOnirica.ESTADO_VALIDA,
		"una toma que cumple todas las reglas debe ser valida"
	)
	_comprobar(evaluacion.get("motivos", []).is_empty(), "una toma valida no debe tener motivos")


func _probar_consumo_y_no_sobregrabado() -> void:
	var original := GrabacionOnirica.nueva_cinta(25.0)
	var primera := GrabacionOnirica.registrar_toma(original, _toma_valida())
	var segunda_toma := _toma_valida()
	segunda_toma["original_id"] = "original-02"
	segunda_toma["duracion_total_segundos"] = 5.0
	segunda_toma["duracion_en_cuadro_segundos"] = 3.0
	var segunda := GrabacionOnirica.registrar_toma(primera.get("cinta", {}), segunda_toma)
	var cinta_final: Dictionary = segunda.get("cinta", {})

	_comprobar(float(original.get("restante_segundos", -1.0)) == 25.0, "registrar no debe mutar cinta origen")
	_comprobar(float(cinta_final.get("restante_segundos", -1.0)) == 10.0, "dos tomas deben consumir su metraje")
	_comprobar(cinta_final.get("tomas", []).size() == 2, "la segunda toma debe anexarse sin reemplazar la primera")
	var tomas: Array = cinta_final.get("tomas", [])
	if tomas.size() == 2:
		_comprobar(
			String(tomas[0].get("toma", {}).get("original_id", "")) == "original-01",
			"la primera toma debe conservarse"
		)


func _probar_rechazo_por_falta_de_metraje() -> void:
	var cinta := GrabacionOnirica.nueva_cinta(9.0)
	var resultado := GrabacionOnirica.registrar_toma(cinta, _toma_valida())
	var devuelta: Dictionary = resultado.get("cinta", {})
	_comprobar(not bool(resultado.get("ok", true)), "no debe grabarse una toma que excede el metraje")
	_comprobar(
		resultado.get("error") == GrabacionOnirica.ERROR_METRAJE_INSUFICIENTE,
		"el rechazo debe distinguir metraje insuficiente"
	)
	_comprobar(float(devuelta.get("restante_segundos", -1.0)) == 9.0, "un rechazo no debe consumir cinta")
	_comprobar(devuelta.get("tomas", []).is_empty(), "un rechazo no debe crear ni sobregrabar tomas")


func _probar_costura_de_proyeccion() -> void:
	var evaluacion := GrabacionOnirica.evaluar_toma(_toma_valida())
	var cinta_onirica := GrabacionOnirica.para_proyeccion(evaluacion)
	_comprobar(
		cinta_onirica.get("estado") == "valida",
		"la salida debe poder alimentar directamente cinta_onirica.estado"
	)
	_comprobar(
		cinta_onirica.get("estado") != "blanco" and cinta_onirica.get("estado") != "caos",
		"este contrato no debe derivar blanco ni caos"
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
