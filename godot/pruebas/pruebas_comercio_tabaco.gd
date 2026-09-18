extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_tabaco_recurrente()
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


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO ComercioTabaco: " + nombre)
