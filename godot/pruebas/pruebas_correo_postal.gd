extends SceneTree

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
