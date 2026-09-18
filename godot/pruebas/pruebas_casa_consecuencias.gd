extends SceneTree

const CasaConsecuencias := preload("res://guion/casa_consecuencias_3d.gd")
const CasaEstadoAmbiental := preload("res://guion/casa_estado_ambiental.gd")
const CasaUtileriaScript := preload("res://guion/casa_utileria.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var casa := Node3D.new()
	root.add_child(casa)
	CasaUtileriaScript.montar(casa)

	var jornada := Jornada.nueva(9396, 1)
	jornada["imprevistos"]["consecuencias"] = [
		"casa_luz_reducida",
		"casa_grifo_averiado",
		"casa_persiana_atascada",
		"casa_recibo_pendiente",
		"casa_multa_pendiente",
		"casa_sin_agua_caliente",
		"casa_electrodomestico_roto",
		"no_domestica",
		"casa_grifo_averiado",
	]
	var estado := CasaEstadoAmbiental.derivar(jornada, Inventario.nuevo())
	_comprobar(estado["consecuencias_casa"].size() == 7, "filtra y deduplica consecuencias casa")
	_comprobar(not estado["consecuencias_casa"].has("no_domestica"), "ignora consecuencias ajenas")
	_comprobar(
		CasaConsecuencias.firma(estado).contains("casa_grifo_averiado"), "firma incluye averias"
	)

	var capa := CasaConsecuencias.montar(casa, estado)
	_comprobar(capa != null, "monta capa de consecuencias")
	for nombre in [
		"BombillaFundida",
		"GrifoGoteando",
		"PersianaAtascada",
		"ReciboPendiente",
		"MultaPendiente",
		"CalentadorAveriado",
		"ElectrodomesticoRoto",
	]:
		_comprobar(capa.get_node_or_null(nombre) != null, "materializa " + nombre)

	var goteo := capa.get_node_or_null("GrifoGoteando/GoteoGrifo") as AudioStreamPlayer3D
	_comprobar(goteo != null, "grifo averiado tiene fuente sonora localizada")
	if goteo != null:
		_comprobar(goteo.stream != null, "goteo usa stream procedural")
		_comprobar(goteo.bus == &"Ambiente", "goteo entra por bus de ambiente")
		_comprobar(goteo.max_distance <= 7.0, "goteo no se oye desde toda la casa")
		_comprobar(goteo.playing, "goteo arranca con la consecuencia")

	var lampara := casa.find_child("LamparaPieCasa", true, false) as LamparaInteractiva3D
	_comprobar(lampara != null, "usa la lampara real")
	lampara._alternar(null)
	_comprobar(not lampara.esta_encendida(), "bombilla fundida bloquea encendido")

	var firma := CasaConsecuencias.firma(estado)
	var repetida := CasaConsecuencias.montar(casa, estado)
	_comprobar(CasaConsecuencias.firma(estado) == firma, "firma estable")
	_comprobar(
		repetida.name == CasaConsecuencias.NOMBRE_RAIZ, "montaje idempotente conserva nombre"
	)
	_comprobar(
		casa.find_children(CasaConsecuencias.NOMBRE_RAIZ, "Node3D", false, false).size() == 1,
		"una sola capa"
	)

	var sin_averias := CasaEstadoAmbiental.derivar(Jornada.nueva(9397, 1), Inventario.nuevo())
	var limpia := CasaConsecuencias.montar(casa, sin_averias)
	_comprobar(limpia.get_child_count() == 0, "sin hechos no inventa degradacion")
	_comprobar(
		casa.find_child("GoteoGrifo", true, false) == null,
		"resolver la consecuencia retira también su fuente sonora"
	)
	_comprobar(CasaConsecuencias.firma(sin_averias).is_empty(), "sin hechos no hay firma")

	casa.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
