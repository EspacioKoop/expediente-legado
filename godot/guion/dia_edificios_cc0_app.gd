## Segundo corte de #218: geometría real del Ultimate Buildings Pack CC0.
##
## Controller hijo: complementa (no sustituye) el LOD procedural de
## SkylineCC0Controller/SkylineQuaternius ya mergeado en #404. Añade cuatro
## piezas reales -una por rol fijado en
## docs/assets/quaternius-ultimate-buildings.md- como tercera línea de
## fondo, más allá de las cajas procedurales. Sin colisión, navegación ni
## interacción; solo dressing lejano.
extends Node

var _mundo_montado_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_mundo_montado_id = mundo_id

	if String(dia.jornada.get("fase", "")) != "trayecto":
		return
	_montar_edificios(mundo)


func _montar_edificios(mundo: Node3D) -> void:
	# Tercera línea de fondo: detrás de la segunda línea procedural del
	# controller de skyline. Una pieza por rol del contrato de #218.
	_edificio(
		mundo,
		EdificiosCC0.RESIDENCIAL_MEDIO,
		Vector3(-25.0, 0.0, -22.0),
		1.35,
		-14.0,
		Color(0.105, 0.11, 0.13)
	)
	_edificio(
		mundo,
		EdificiosCC0.RESIDENCIAL_ALTO,
		Vector3(24.5, 0.0, -34.0),
		1.15,
		20.0,
		Color(0.085, 0.095, 0.12)
	)
	_edificio(
		mundo,
		EdificiosCC0.TERCIARIO,
		Vector3(-26.5, 0.0, 20.0),
		1.05,
		9.0,
		Color(0.10, 0.105, 0.125)
	)
	_edificio(
		mundo,
		EdificiosCC0.COMERCIAL,
		Vector3(25.5, 0.0, 6.0),
		1.55,
		-24.0,
		Color(0.115, 0.10, 0.10)
	)


func _edificio(
	mundo: Node3D, modelo: String, posicion: Vector3, escala: float, giro_y: float, color: Color
) -> void:
	var edificio := EdificiosCC0.crear(modelo, color)
	edificio.name = "EdificioCC0_%s" % modelo.get_basename()
	edificio.position = posicion
	edificio.scale = Vector3.ONE * escala
	edificio.rotation_degrees.y = giro_y
	mundo.add_child(edificio)
	CalleIdentidad.iluminar_ventanas(edificio, int(posicion.x * 10.0 + posicion.z))
