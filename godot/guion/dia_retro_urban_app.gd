## Montaje mínimo del Retro Urban Kit CC0 en la calle (#295).
##
## Vive como controller hijo para no alterar la raíz del día ni las reglas de
## jornada. La geometría está en `RetroUrbanAwning`: este módulo solo decide
## dónde aparece en el espacio real del trayecto.
extends Node

# Dos MeshInstance3D de una superficie, sin sombras ni colisión: presupuesto
# deliberado para este corte = 2 draw calls del pase base del dressing urbano.
const INSTANCIAS_RETRO_URBAN := 2
const DRAW_CALLS_BASE_MAX := 2

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
