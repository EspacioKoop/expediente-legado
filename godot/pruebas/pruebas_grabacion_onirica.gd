## Prueba aislada del contrato de grabación onírica (#454).
extends SceneTree

const Contrato = preload("res://guion/grabacion_onirica_contrato.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	var valida := {
		"original_id": "original-01",
		"original_identificado": true,
		"frase_completa": true,
		"tiempo_sujeto": 60.0,
		"duracion_total": 100.0,
		"figura_detecto_camara": false,
		"hubo_corte": false,
	}

	_comprobar("toma válida", Contrato.evaluar_toma(valida), Contrato.EstadoGrabacion.VALIDA)

	var sin_original := valida.duplicate(true)
	sin_original["original_identificado"] = false
	_comprobar(
		"original no identificado",
		Contrato.evaluar_toma(sin_original),
		Contrato.EstadoGrabacion.CONTAMINADA
	)

	var frase_incompleta := valida.duplicate(true)
	frase_incompleta["frase_completa"] = false
	_comprobar(
		"frase incompleta",
		Contrato.evaluar_toma(frase_incompleta),
		Contrato.EstadoGrabacion.CONTAMINADA
	)

	var sujeto_insuficiente := valida.duplicate(true)
	sujeto_insuficiente["tiempo_sujeto"] = 50.0
	_comprobar(
		"sujeto al cincuenta por ciento",
		Contrato.evaluar_toma(sujeto_insuficiente),
		Contrato.EstadoGrabacion.CONTAMINADA
	)

	var detectada := valida.duplicate(true)
	detectada["figura_detecto_camara"] = true
	_comprobar(
		"figura detecta la cámara",
		Contrato.evaluar_toma(detectada),
		Contrato.EstadoGrabacion.CONTAMINADA
	)

	var cortada := valida.duplicate(true)
	cortada["hubo_corte"] = true
	_comprobar("toma cortada", Contrato.evaluar_toma(cortada), Contrato.EstadoGrabacion.CONTAMINADA)

	var sin_duracion := valida.duplicate(true)
	sin_duracion["duracion_total"] = 0.0
	_comprobar(
		"duración inválida",
		Contrato.evaluar_toma(sin_duracion),
		Contrato.EstadoGrabacion.CONTAMINADA
	)

	var incompleta := valida.duplicate(true)
	incompleta.erase("original_identificado")
	_comprobar(
		"falta una clave requerida",
		Contrato.evaluar_toma(incompleta),
		Contrato.EstadoGrabacion.CONTAMINADA
	)

	var sin_id := valida.duplicate(true)
	sin_id["original_id"] = ""
	_comprobar(
		"identificador vacío",
		Contrato.evaluar_toma(sin_id),
		Contrato.EstadoGrabacion.CONTAMINADA
	)

	var detallada := Contrato.evaluar_toma_detallada(valida)
	_comprobar("estado textual válido", detallada.get("estado"), "valida")
	var proyeccion := Contrato.para_proyeccion(detallada)
	_comprobar("costura de proyección", proyeccion.get("estado"), "valida")
	_comprobar(
		"no deriva blanco ni caos",
		proyeccion.get("estado") != "blanco" and proyeccion.get("estado") != "caos",
		true
	)

	_probar_metraje(valida)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_metraje(plantilla: Dictionary) -> void:
	var cinta := Contrato.nueva_cinta(15.0)
	var toma_10 := plantilla.duplicate(true)
	toma_10["duracion_total"] = 10.0
	toma_10["tiempo_sujeto"] = 6.0
	var primera := Contrato.registrar_toma(cinta, toma_10)
	var tras_primera: Dictionary = primera.get("cinta", {})

	_comprobar("primera toma cabe", primera.get("ok"), true)
	_comprobar("consume metraje", tras_primera.get("metraje_restante"), 5.0)
	_comprobar("no muta cinta origen", cinta.get("metraje_restante"), 15.0)
	_comprobar("anexa primera toma", tras_primera.get("tomas", []).size(), 1)

	var demasiado_larga := Contrato.registrar_toma(tras_primera, toma_10)
	var tras_rechazo: Dictionary = demasiado_larga.get("cinta", {})
	_comprobar("rechaza sobregrabar", demasiado_larga.get("ok"), false)
	_comprobar(
		"motivo metraje insuficiente",
		demasiado_larga.get("error"),
		Contrato.ERROR_METRAJE_INSUFICIENTE
	)
	_comprobar("rechazo no consume", tras_rechazo.get("metraje_restante"), 5.0)
	_comprobar("rechazo conserva tomas", tras_rechazo.get("tomas", []).size(), 1)

	var toma_4 := plantilla.duplicate(true)
	toma_4["original_id"] = "original-02"
	toma_4["duracion_total"] = 4.0
	toma_4["tiempo_sujeto"] = 3.0
	var segunda := Contrato.registrar_toma(tras_rechazo, toma_4)
	var final: Dictionary = segunda.get("cinta", {})
	_comprobar("segunda toma cabe", segunda.get("ok"), true)
	_comprobar("restante final", final.get("metraje_restante"), 1.0)
	_comprobar("no sustituye primera toma", final.get("tomas", []).size(), 2)
	var tomas: Array = final.get("tomas", [])
	if tomas.size() == 2:
		_comprobar(
			"primera toma intacta",
			tomas[0].get("toma", {}).get("original_id"),
			"original-01"
		)


func _comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		_pasadas += 1
		return
	_fallos += 1
	printerr("FALLO %s: esperado=%s obtenido=%s" % [nombre, esperado, obtenido])
