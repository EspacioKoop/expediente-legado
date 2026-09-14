extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var estado := Inventario.nuevo()
	var taza := {
		"id": "taza",
		"nombre": "Taza",
		"vendible": true,
		"precio": 12,
		"origen": "casa",
	}
	var sello := {
		"id": "sello",
		"nombre": "Sello",
		"vendible": false,
		"precio": 0,
		"origen": "archivo",
	}
	var llave_sueno := {
		"id": "llave-sueno",
		"nombre": "Llave imposible",
		"vendible": true,
		"precio": 999,
		"origen": "sueno",
	}

	_comprobar(Inventario.recoger(estado, taza), "recoge en carried")
	_comprobar(estado[Inventario.CARRIED].size() == 1, "recogido queda encima")
	_comprobar(not Inventario.recoger(estado, taza), "no duplica por id")
	_comprobar(Inventario.guardar_en_casa(estado, "taza"), "guarda en casa")
	_comprobar(estado[Inventario.CARRIED].is_empty(), "guardar saca de carried")
	_comprobar(estado[Inventario.HOME_STORAGE].size() == 1, "guardar entra en home_storage")
	_comprobar(Inventario.visibles(estado, false).is_empty(), "fuera no ve almacen de casa")
	_comprobar(Inventario.visibles(estado, true).size() == 1, "en casa ve todo")
	_comprobar(Inventario.sacar_de_casa(estado, "taza"), "saca de casa")

	_comprobar(Inventario.recoger(estado, sello), "recoge segundo objeto")
	var no_vendible := Inventario.vender(estado, "sello")
	_comprobar(
		not no_vendible["vendido"] and no_vendible["dinero"] == 0, "no vendible no da dinero"
	)
	var venta := Inventario.vender(estado, "taza")
	_comprobar(venta["vendido"] and venta["dinero"] == 12, "venta devuelve precio")
	_comprobar(not Inventario.contiene(estado, "taza"), "venta elimina objeto")

	_comprobar(Inventario.recoger(estado, llave_sueno), "recoge recompensa onirica")
	var venta_onirica := Inventario.vender(estado, "llave-sueno")
	_comprobar(not venta_onirica["vendido"], "objeto onirico no se vende")
	_comprobar(venta_onirica["dinero"] == 0, "objeto onirico nunca da dinero")
	_comprobar(
		Inventario.contiene(estado, "llave-sueno"), "venta onirica rechazada conserva objeto"
	)

	_comprobar(Inventario.guardar_en_casa(estado, "sello"), "prepara objeto guardado")
	var perdidos := Inventario.perder_casa(estado)
	_comprobar(
		perdidos.size() == 1 and perdidos[0]["id"] == "sello", "perder casa devuelve lo perdido"
	)
	_comprobar(estado[Inventario.HOME_STORAGE].is_empty(), "perder casa vacia almacen")
	_comprobar(Inventario.contiene(estado, "llave-sueno"), "perder casa conserva carried")

	_comprobar(Inventario.completar({}).has(Inventario.CARRIED), "migra carried ausente")
	_comprobar(Inventario.completar({}).has(Inventario.HOME_STORAGE), "migra home_storage ausente")

	var lleno := Inventario.nuevo()
	_comprobar(Inventario.CAPACIDAD == 10, "capacidad base es diez")
	_comprobar(Inventario.tiene_hueco(lleno), "inventario nuevo tiene hueco")
	var lleno_hasta_limite := true
	for i in Inventario.CAPACIDAD:
		lleno_hasta_limite = Inventario.recoger(lleno, {"id": "cupo-%d" % i}) and lleno_hasta_limite
	_comprobar(lleno_hasta_limite, "acepta objetos hasta el limite")
	_comprobar(lleno[Inventario.CARRIED].size() == Inventario.CAPACIDAD, "carried queda en diez")
	_comprobar(not Inventario.tiene_hueco(lleno), "inventario lleno no anuncia hueco")
	_comprobar(not Inventario.recoger(lleno, {"id": "undecimo"}), "rechaza el undecimo objeto")
	_comprobar(lleno[Inventario.CARRIED].size() == Inventario.CAPACIDAD, "rechazo no muta carried")

	var desde_casa := Inventario.nuevo()
	Inventario.recoger(desde_casa, {"id": "guardado"})
	Inventario.guardar_en_casa(desde_casa, "guardado")
	for i in Inventario.CAPACIDAD:
		Inventario.recoger(desde_casa, {"id": "bolsillo-%d" % i})
	_comprobar(not Inventario.sacar_de_casa(desde_casa, "guardado"), "lleno no saca de casa")
	_comprobar(
		desde_casa[Inventario.HOME_STORAGE].size() == 1,
		"rechazar sacar conserva el objeto almacenado"
	)
	_comprobar(
		desde_casa[Inventario.CARRIED].size() == Inventario.CAPACIDAD,
		"rechazar sacar no desborda carried"
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
