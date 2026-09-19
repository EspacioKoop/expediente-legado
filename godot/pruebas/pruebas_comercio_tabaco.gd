extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_tabaco_recurrente()
	_probar_reventa_segunda_mano()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_tabaco_recurrente() -> void:
	var jornada := Jornada.nueva(93, 1)
	jornada["fase"] = "trayecto"
	jornada["dinero"] = 30
	var inventario := Inventario.nuevo()
	var acciones_antes := int(jornada["acciones"])
	var cierres_antes := int(jornada["cerrados_hoy"])

	var listado := ComercioBarrio.listar("quiosco", jornada, inventario)
	var tabaco: Dictionary = {}
	for entrada in listado:
		if String(entrada.get("id", "")) == "paquete_cigarrillos_98":
			tabaco = entrada
			break
	_comprobar(not tabaco.is_empty(), "el quiosco lista tabaco")
	_comprobar(bool(tabaco.get("repetible", false)), "el tabaco se declara repetible")
	_comprobar(not bool(tabaco.get("comprada", true)), "una compra no bloquea la siguiente")
	_comprobar(int(tabaco.get("precio", 0)) == 8, "el precio es pequeño y estable")

	var primera := ComercioBarrio.comprar(jornada, inventario, "quiosco", "paquete_cigarrillos_98")
	var segunda := ComercioBarrio.comprar(jornada, inventario, "quiosco", "paquete_cigarrillos_98")
	_comprobar(bool(primera.get("ok", false)), "la primera compra se acepta")
	_comprobar(bool(segunda.get("ok", false)), "la segunda compra también se acepta")
	_comprobar(int(jornada["dinero"]) == 14, "dos paquetes cobran dos veces")
	_comprobar(bool(primera.get("consumido", false)), "el paquete se consume en el acto")
	_comprobar(
		not Inventario.contiene(inventario, "paquete_cigarrillos_98"),
		"el tabaco no ocupa inventario"
	)
	_comprobar(int(jornada["acciones"]) == acciones_antes, "no concede acciones")
	_comprobar(int(jornada["cerrados_hoy"]) == cierres_antes, "no altera trabajo")

	jornada["dinero"] = 7
	var sin_saldo := ComercioBarrio.comprar(
		jornada, inventario, "quiosco", "paquete_cigarrillos_98"
	)
	_comprobar(not bool(sin_saldo.get("ok", true)), "sin saldo no compra")
	_comprobar(String(sin_saldo.get("motivo", "")) == "sin_dinero", "explica falta de dinero")
	_comprobar(int(jornada["dinero"]) == 7, "sin saldo no deja deuda")


func _probar_reventa_segunda_mano() -> void:
	var jornada := Jornada.nueva(97, 1)
	jornada["fase"] = "trayecto"
	jornada["dinero"] = 40
	var inventario := Inventario.nuevo()
	var acciones_antes := int(jornada["acciones"])
	var cierres_antes := int(jornada["cerrados_hoy"])

	var taza := {
		"id": "taza-reventa",
		"nombre": "Taza usada",
		"vendible": true,
		"precio": 12,
		"origen": "casa",
	}
	var marco := {
		"id": "marco-guardado",
		"nombre": "Marco guardado",
		"vendible": true,
		"precio": 6,
		"origen": "casa",
	}
	var llave_sueno := {
		"id": "llave-imposible",
		"nombre": "Llave imposible",
		"vendible": true,
		"precio": 999,
		"origen": "sueno",
	}
	_comprobar(Inventario.recoger(inventario, taza), "prepara objeto llevado")
	_comprobar(Inventario.recoger(inventario, marco), "prepara objeto doméstico")
	_comprobar(Inventario.guardar_en_casa(inventario, "marco-guardado"), "guarda marco en casa")
	_comprobar(Inventario.recoger(inventario, llave_sueno), "prepara objeto onírico")

	var superficie_incorrecta := ComercioBarrio.vender(
		jornada, inventario, "quiosco", "taza-reventa"
	)
	_comprobar(
		String(superficie_incorrecta.get("motivo", "")) == "superficie_sin_reventa",
		"solo segunda mano admite reventa"
	)
	_comprobar(Inventario.contiene(inventario, "taza-reventa"), "rechazo no consume el objeto")

	var guardado := ComercioBarrio.vender(jornada, inventario, "segunda_mano", "marco-guardado")
	_comprobar(String(guardado.get("motivo", "")) == "no_llevado", "no vende desde home_storage")
	_comprobar(Inventario.contiene(inventario, "marco-guardado"), "home_storage sigue intacto")

	var venta := ComercioBarrio.vender(jornada, inventario, "segunda_mano", "taza-reventa")
	_comprobar(bool(venta.get("ok", false)), "vende un objeto llevado")
	_comprobar(int(venta.get("importe", 0)) == 12, "respeta el precio de reventa del objeto")
	_comprobar(int(jornada["dinero"]) == 52, "la reventa suma al saldo real")
	_comprobar(not Inventario.contiene(inventario, "taza-reventa"), "vender consume el objeto")

	var saldo_antes_onirico := int(jornada["dinero"])
	var onirica := ComercioBarrio.vender(jornada, inventario, "segunda_mano", "llave-imposible")
	_comprobar(String(onirica.get("motivo", "")) == "onirico", "el origen onírico bloquea reventa")
	_comprobar(int(jornada["dinero"]) == saldo_antes_onirico, "lo onírico no da dinero")
	_comprobar(
		Inventario.contiene(inventario, "llave-imposible"), "rechazo onírico conserva objeto"
	)
	_comprobar(int(jornada["acciones"]) == acciones_antes, "reventa no concede acciones")
	_comprobar(int(jornada["cerrados_hoy"]) == cierres_antes, "reventa no altera trabajo")

	jornada["fase"] = "casa"
	var fuera := ComercioBarrio.vender(jornada, inventario, "segunda_mano", "llave-imposible")
	_comprobar(String(fuera.get("motivo", "")) == "fuera_del_trayecto", "solo se vende en trayecto")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO ComercioTabaco: " + nombre)
