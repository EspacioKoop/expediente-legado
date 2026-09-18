class_name PruebasImprevistos
extends RefCounted


static func todo(comprobar: Callable) -> void:
	var primera := _con_plan(9301)
	comprobar.call("existe una semilla cercana con imprevistos", primera.is_empty(), false)
	if primera.is_empty():
		return
	var segunda := Jornada.nueva(int(primera["raiz"]), int(primera["vuelta"]))
	var plan: Array = primera["imprevistos"]["plan"]
	comprobar.call("imprevistos reproducibles", plan, segunda["imprevistos"]["plan"])
	comprobar.call(
		"una vuelta con imprevistos trae de dos a cuatro",
		plan.size() >= Imprevistos.MIN_POR_VUELTA and plan.size() <= Imprevistos.MAX_POR_VUELTA,
		true
	)

	var ids: Array[String] = []
	var ultimo_dia := -100
	var fuertes := 0
	for programado in plan:
		var id_evento := String(programado["id"])
		var dia := int(programado["dia"])
		comprobar.call("imprevisto no repetido " + id_evento, ids.has(id_evento), false)
		ids.append(id_evento)
		comprobar.call("imprevistos separados", dia - ultimo_dia >= 2, true)
		ultimo_dia = dia
		var evento := Imprevistos.detalle(id_evento)
		if bool(evento.get("fuerte", false)):
			fuertes += 1
	comprobar.call("como máximo un imprevisto fuerte", fuertes <= Imprevistos.MAX_FUERTES, true)

	var estado_json = JSON.parse_string(JSON.stringify(primera["imprevistos"]))
	var jornada_recargada := {
		"raiz": int(primera["raiz"]),
		"vuelta": int(primera["vuelta"]),
		"imprevistos": estado_json,
	}
	Imprevistos.completar(jornada_recargada)
	comprobar.call(
		"recargar normaliza el plan", jornada_recargada["imprevistos"], primera["imprevistos"]
	)

	var cobro := _con_plan(9401)
	var primero: Dictionary = cobro["imprevistos"]["plan"][0]
	var detalle := Imprevistos.detalle(String(primero["id"]))
	cobro["dia"] = int(primero["dia"])
	cobro["fase"] = "casa"
	cobro["dinero"] = 100
	var antes := int(cobro["dinero"])
	var resultado := Jornada.resolver_imprevisto_del_dia(cobro)
	comprobar.call("imprevisto pagable se paga", resultado.get("pagado", false), true)
	comprobar.call("imprevisto descuenta su coste", cobro["dinero"], antes - int(detalle["coste"]))
	comprobar.call(
		"resolver dos veces es idempotente", Jornada.resolver_imprevisto_del_dia(cobro), {}
	)

	var pobre := _con_plan(9501)
	var programado: Dictionary = pobre["imprevistos"]["plan"][0]
	var evento_pobre := Imprevistos.detalle(String(programado["id"]))
	pobre["dia"] = int(programado["dia"])
	pobre["fase"] = "casa"
	pobre["dinero"] = maxi(0, int(evento_pobre["coste"]) - 1)
	var saldo := int(pobre["dinero"])
	var impagado := Jornada.resolver_imprevisto_del_dia(pobre)
	comprobar.call("un imprevisto nunca crea deuda", pobre["dinero"], saldo)
	comprobar.call("si no alcanza queda impagado", impagado.get("pagado", true), false)
	comprobar.call(
		"el impago deja consecuencia ambiental",
		Imprevistos.consecuencias(pobre).has(String(evento_pobre["consecuencia"])),
		true
	)


static func _con_plan(desde: int) -> Dictionary:
	for raiz in range(desde, desde + 100):
		var jornada := Jornada.nueva(raiz, 1)
		if not jornada["imprevistos"]["plan"].is_empty():
			return jornada
	return {}
