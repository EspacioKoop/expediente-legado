## Montaje del Retro Urban Kit CC0 en la calle (#295).
##
## Vive como controller hijo para no alterar la raíz del día ni las reglas de
## jornada. La geometría está en `RetroUrbanAwning`/`RetroUrbanBench`/
## `RetroUrbanLamp`/`RetroUrbanBarrier`: este módulo solo decide dónde aparece
## en el espacio real del trayecto.
extends Node

# Ocho MeshInstance3D (toldos, banco, farola, barrera), sin sombras ni
# colisión: presupuesto deliberado para este corte = 8 draw calls del pase
# base del dressing urbano.
const INSTANCIAS_RETRO_URBAN := 8
const DRAW_CALLS_BASE_MAX := 8

var _mundo_montado_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	if String(dia.jornada.get("fase", "")) != "trayecto":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_mundo_montado_id = mundo_id
	_montar_toldos(mundo)
	_montar_banco(mundo)
	_montar_farolas(mundo)
	_montar_barreras(mundo)


func _montar_toldos(mundo: Node3D) -> void:
	# Dos piezas del mismo kit sobre el escaparate existente. No son carteles ni
	# pantallas: su función es dar espesor y silueta comercial a la fachada.
	_toldo(mundo, "ToldoRetroUrbanSur", Vector3(-5.34, 2.18, -3.30), Color(0.30, 0.22, 0.19))
	_toldo(mundo, "ToldoRetroUrbanNorte", Vector3(-5.34, 2.18, 0.25), Color(0.24, 0.27, 0.31))


func _toldo(mundo: Node3D, nombre: String, posicion: Vector3, color: Color) -> void:
	var soporte := Node3D.new()
	soporte.name = nombre
	soporte.position = posicion
	soporte.rotation_degrees.y = 90.0
	soporte.scale = Vector3.ONE * 3.2
	soporte.add_child(RetroUrbanAwning.crear(color))
	mundo.add_child(soporte)


func _montar_banco(mundo: Node3D) -> void:
	# Un banco en la acera, frente al escaparate: dressing de espera, sin
	# colisión ni interacción; no bloquea el paso del jugador.
	var soporte := Node3D.new()
	soporte.name = "BancoRetroUrban"
	soporte.position = Vector3(-3.10, 0, -1.50)
	soporte.rotation_degrees.y = 90.0
	soporte.scale = Vector3.ONE * 1.6
	soporte.add_child(RetroUrbanBench.crear(Color(0.22, 0.20, 0.18)))
	mundo.add_child(soporte)


func _montar_farolas(mundo: Node3D) -> void:
	# Dos farolas flanqueando el tramo del escaparate: dan escala vertical y
	# fuente de luz reconocible sin añadir OmniLight3D nuevas a este corte.
	_farola(mundo, "FarolaRetroUrbanSur", Vector3(-3.60, 0, -3.60))
	_farola(mundo, "FarolaRetroUrbanNorte", Vector3(-3.60, 0, 0.60))


func _farola(mundo: Node3D, nombre: String, posicion: Vector3) -> void:
	var soporte := Node3D.new()
	soporte.name = nombre
	soporte.position = posicion
	soporte.scale = Vector3.ONE * 1.3
	soporte.add_child(RetroUrbanLamp.crear(Color(0.12, 0.12, 0.13)))
	mundo.add_child(soporte)


func _montar_barreras(mundo: Node3D) -> void:
	# Tres barreras cortas marcando el borde de la acera hacia la calzada.
	_barrera(mundo, "BarreraRetroUrbanA", Vector3(-2.60, 0, -3.00))
	_barrera(mundo, "BarreraRetroUrbanB", Vector3(-2.60, 0, -1.90))
	_barrera(mundo, "BarreraRetroUrbanC", Vector3(-2.60, 0, -0.80))


func _barrera(mundo: Node3D, nombre: String, posicion: Vector3) -> void:
	var soporte := Node3D.new()
	soporte.name = nombre
	soporte.position = posicion
	soporte.scale = Vector3.ONE * 1.4
	soporte.add_child(RetroUrbanBarrier.crear(Color(0.35, 0.32, 0.10)))
	mundo.add_child(soporte)
