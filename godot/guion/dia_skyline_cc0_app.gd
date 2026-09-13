## Fondo urbano CC0 del trayecto (#218/#277/#398).
##
## Es un controller hijo: no conoce reglas de jornada ni toca la geometría jugable.
## Añade LODs sin colisión detrás de las fachadas actuales para que la calle tenga
## horizonte y segunda/tercera línea de edificios.
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
	_montar_skyline(mundo)


func _montar_skyline(mundo: Node3D) -> void:
	# Detrás de las fachadas existentes: ninguna pieza invade acera/calzada.
	_edificio(
		mundo,
		SkylineQuaternius.MODELO_BALCON,
		Vector3(-12.5, 0.0, -16.0),
		2.15,
		-18.0,
		Color(0.20, 0.19, 0.21)
	)
	_edificio(
		mundo,
		SkylineQuaternius.MODELO_CUATRO,
		Vector3(11.8, 0.0, -19.0),
		2.35,
		17.0,
		Color(0.18, 0.19, 0.21)
	)
	_edificio(
		mundo,
		SkylineQuaternius.MODELO_PILA,
		Vector3(-13.8, 0.0, 10.5),
		2.10,
		-10.0,
		Color(0.17, 0.18, 0.20)
	)
	_edificio(
		mundo,
		SkylineQuaternius.MODELO_BALCON,
		Vector3(13.2, 0.0, 12.5),
		1.95,
		22.0,
		Color(0.22, 0.20, 0.19)
	)
	_edificio(
		mundo,
		SkylineQuaternius.MODELO_CUATRO,
		Vector3(-8.8, 0.0, 25.0),
		1.80,
		8.0,
		Color(0.19, 0.18, 0.18)
	)
	_edificio(
		mundo,
		SkylineQuaternius.MODELO_PILA,
		Vector3(8.5, 0.0, 27.0),
		1.65,
		-14.0,
		Color(0.16, 0.17, 0.19)
	)


func _edificio(
	mundo: Node3D, modelo: String, posicion: Vector3, escala: float, giro_y: float, color: Color
) -> void:
	var edificio := SkylineQuaternius.crear(modelo, color)
	edificio.name = "Skyline_%s" % modelo.get_basename()
	edificio.position = posicion
	edificio.scale = Vector3.ONE * escala
	edificio.rotation_degrees.y = giro_y
	mundo.add_child(edificio)
