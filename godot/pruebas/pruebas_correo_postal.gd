extends SceneTree

const CasaEstadoAmbientalScript := preload("res://guion/casa_estado_ambiental.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var catalogo := CorreoPostal.catalogo()
	_comprobar(catalogo.size() >= 8, "hay al menos ocho piezas de correo")
	var categorias := {}
	for pieza in catalogo:
		categorias[String(pieza.get("categoria", ""))] = true
	_comprobar(categorias.size() >= 8, "las ocho piezas cubren categorias distintas")

	var pieza_lectura: Dictionary = catalogo[0].duplicate(true)
	pieza_lectura["fecha"] = 1
	var modelo_lectura := CorreoPostalLector.modelo_resultado({"pieza": pieza_lectura})
	_comprobar(
		String(modelo_lectura.get("titulo", "")) == String(pieza_lectura.get("asunto", "")),
		"el lector conserva el asunto",
	)
	_comprobar(
		String(modelo_lectura.get("cabecera", "")).contains(
			String(pieza_lectura.get("remitente", ""))
		),
		"el lector muestra remitente",
	)
	_comprobar(
		String(modelo_lectura.get("cabecera", "")).contains("1"),
		"el lector muestra la jornada como fecha",
	)
	_comprobar(
		String(modelo_lectura.get("contenido", "")) == String(pieza_lectura.get("contenido", "")),
		"el lector muestra el contenido sin mutarlo",
	)
	_comprobar(
		not String(CorreoPostalLector.modelo_vacio().get("contenido", "")).is_empty(),
		"el buzon vacio tiene feedback legible",
	)

	var jornada := Jornada.nueva(672, 1)
	jornada["fase"] = "trayecto"
	var inventario := Inventario.nuevo()
	_comprobar(CorreoPostal.estado(jornada).has("recogidos"), "crea estado minimo de recogida")

	var dia_uno := Jornada.nueva(672, 1)
	dia_uno["fase"] = "trayecto"
	var dia_dos := Jornada.nueva(672, 1)
	dia_dos["dia"] = 2
	dia_dos["fase"] = "trayecto"
	_comprobar(
		_ids(CorreoPostal.disponibles(dia_uno)) != _ids(CorreoPostal.disponibles(dia_dos)),
		"el contenido cambia por jornada",
	)

	var buzon_sobre := BuzonPostalInteractivo3D.new()
	buzon_sobre.configurar(dia_uno, Inventario.nuevo())
	_comprobar(
		buzon_sobre.tipo_correo_visible() == "sobre",
		"el buzon representa el correo ordinario como sobre fisico",
	)

	var dia_paquete_visible := Jornada.nueva(672, 1)
	dia_paquete_visible["dia"] = 4
	dia_paquete_visible["fase"] = "trayecto"
	var recogidos_paquete: Array = CorreoPostal.estado(dia_paquete_visible)["recogidos"]
	for pieza in CorreoPostal.disponibles(dia_paquete_visible):
		if String(pieza.get("id", "")) != "paquete_calendario_magnetico":
			recogidos_paquete.append(String(pieza.get("id", "")))
	var buzon_paquete := BuzonPostalInteractivo3D.new()
	buzon_paquete.configurar(dia_paquete_visible, Inventario.nuevo())
	_comprobar(
		buzon_paquete.tipo_correo_visible() == "paquete",
		"el buzon distingue el paquete acolchado de un sobre",
	)

	var dia_vacio_visible := Jornada.nueva(672, 1)
	dia_vacio_visible["fase"] = "trayecto"
	var recogidos_vacio: Array = CorreoPostal.estado(dia_vacio_visible)["recogidos"]
	for pieza in CorreoPostal.disponibles(dia_vacio_visible):
		recogidos_vacio.append(String(pieza.get("id", "")))
	var buzon_vacio_visual := BuzonPostalInteractivo3D.new()
	buzon_vacio_visual.configurar(dia_vacio_visible, Inventario.nuevo())
	_comprobar(
		buzon_vacio_visual.tipo_correo_visible() == "vacio",
		"el indicador desaparece cuando no queda correo",
	)

	var dia_tres := Jornada.nueva(672, 1)
	dia_tres["dia"] = 3
	dia_tres["fase"] = "trayecto"
	_comprobar(
		not _contiene_id(CorreoPostal.disponibles(dia_tres), "certificado_siga"),
		"el certificado no aparece sin cierre previo",
	)
	dia_tres["cerrados_hoy"] = 1
	_comprobar(
		_contiene_id(CorreoPostal.disponibles(dia_tres), "certificado_siga"),
		"el estado del trabajo puede habilitar una pieza",
	)

	_comprobar(
		_contiene_id(CorreoPostal.disponibles(dia_dos), "carta_manuela"),
		"la carta vecinal aparece mientras el gato esta presente",
	)
	dia_dos["gato"]["presente"] = false
	_comprobar(
		not _contiene_id(CorreoPostal.disponibles(dia_dos), "carta_manuela"),
		"el correo tambien responde al estado domestico",
	)

	var dia_diez := Jornada.nueva(672, 1)
	dia_diez["dia"] = 10
	dia_diez["fase"] = "trayecto"
	_comprobar(
		_contiene_id(CorreoPostal.disponibles(dia_diez), "aviso_alquiler"),
		"el vencimiento pendiente produce un aviso",
	)
	dia_diez["alquiler"]["ultimo_resuelto"] = 10
	_comprobar(
		not _contiene_id(CorreoPostal.disponibles(dia_diez), "aviso_alquiler"),
		"el aviso desaparece cuando la economia ya resolvio el vencimiento",
	)

	var fuera := Jornada.nueva(672, 1)
	fuera["dia"] = 2
	fuera["fase"] = "archivo"
	var intento_fuera := CorreoPostal.recoger(fuera, Inventario.nuevo(), "factura_agua")
	_comprobar(not bool(intento_fuera.get("ok", false)), "solo se recoge desde el portal")
	_comprobar(
		not CorreoPostal.estado(fuera)["recogidos"].has("factura_agua"),
		"un intento fuera del portal no consume la pieza",
	)

	var factura := Jornada.nueva(672, 1)
	factura["dia"] = 2
	factura["fase"] = "trayecto"
	var dinero_antes := int(factura["dinero"])
	_comprobar(
		_contiene_id(CorreoPostal.disponibles(factura), "factura_agua"),
		"la factura informativa esta disponible",
	)
	var recibo := CorreoPostal.recoger(factura, Inventario.nuevo(), "factura_agua")
	_comprobar(bool(recibo.get("ok", false)), "se puede recoger una factura narrativa")
	_comprobar(int(factura["dinero"]) == dinero_antes, "recoger factura no toca la economia")
	_comprobar(
		CorreoPostal.estado(factura)["recogidos"].has("factura_agua"),
		"la pieza recogida queda registrada en la jornada",
	)

	var paquete := Jornada.nueva(672, 1)
	paquete["dia"] = 4
	paquete["fase"] = "trayecto"
	var inventario_paquete := Inventario.nuevo()
	_comprobar(
		_contiene_id(CorreoPostal.disponibles(paquete), "paquete_calendario_magnetico"),
		"el dia cuatro llega el paquete fisico",
	)
	var entrega := CorreoPostal.recoger(paquete, inventario_paquete, "paquete_calendario_magnetico")
	_comprobar(bool(entrega.get("ok", false)), "el paquete se recoge")
	_comprobar(bool(entrega.get("objeto_agregado", false)), "el paquete declara objeto fisico")
	_comprobar(
		Inventario.contiene(inventario_paquete, "postal_iman_calendario"),
		"el objeto se materializa mediante Inventario",
	)
	var objeto := _buscar_objeto(inventario_paquete, "postal_iman_calendario")
	_comprobar(String(objeto.get("origen", "")) == "correo_postal", "el origen queda trazado")
	var duplicado := CorreoPostal.recoger(
		paquete, inventario_paquete, "paquete_calendario_magnetico"
	)
	_comprobar(not bool(duplicado.get("ok", false)), "un paquete no puede recogerse dos veces")
	_comprobar(String(objeto.get("categoria", "")) == "papel", "el calendario usa familia visual")
	var modelo_paquete := CorreoPostalLector.modelo_resultado(entrega)
	_comprobar(
		String(modelo_paquete.get("detalle", "")).contains("Calendario magnético 1998"),
		"el lector confirma el objeto fisico sin crear recompensa",
	)
	_comprobar(
		Inventario.guardar_en_casa(inventario_paquete, "postal_iman_calendario"),
		"el calendario usa el traslado canonico a home_storage",
	)
	var ambiente := CasaEstadoAmbientalScript.derivar(paquete, inventario_paquete)
	_comprobar(
		ambiente.get("objetos_casa_ids", []).has("postal_iman_calendario"),
		"el contrato de casa #96 recibe el calendario desde home_storage",
	)
	_comprobar(
		CasaAcumulacion3D.firma(ambiente).contains("postal_iman_calendario"),
		"la materializacion #677 incluye el objeto postal",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _ids(piezas: Array[Dictionary]) -> Array[String]:
	var salida: Array[String] = []
	for pieza in piezas:
		salida.append(String(pieza.get("id", "")))
	return salida


func _contiene_id(piezas: Array[Dictionary], pieza_id: String) -> bool:
	return _ids(piezas).has(pieza_id)


func _buscar_objeto(inventario: Dictionary, objeto_id: String) -> Dictionary:
	for ubicacion in [Inventario.CARRIED, Inventario.HOME_STORAGE]:
		for objeto in inventario.get(ubicacion, []):
			if typeof(objeto) == TYPE_DICTIONARY and String(objeto.get("id", "")) == objeto_id:
				return objeto
	return {}


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
