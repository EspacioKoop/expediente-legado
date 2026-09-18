## Huellas domésticas de cómo va la vida (#96).
##
## Esta capa no calcula una situación ni posee estado: consume hechos discretos
## de CasaEstadoAmbiental y los convierte en objetos cotidianos. Una casa con
## comida, un recibo resuelto o una pila de carpetas son información sin HUD.
class_name CasaHuellaVida3D
extends RefCounted

const CasaEstadoAmbientalScript := preload("res://guion/casa_estado_ambiental.gd")
const NOMBRE_RAIZ := "HuellaVidaCasa"


static func firma(estado_ambiental: Dictionary) -> String:
	return (
		"%s|%s|%d"
		% [
			String(estado_ambiental.get("comida_estado", "")),
			String(estado_ambiental.get("alquiler_estado", "")),
			maxi(1, int(estado_ambiental.get("vuelta", 1))),
		]
	)


static func montar(raiz: Node3D, estado_ambiental: Dictionary) -> Node3D:
	var anterior := raiz.get_node_or_null(NOMBRE_RAIZ)
	if anterior != null:
		raiz.remove_child(anterior)
		anterior.queue_free()

	var capa := Node3D.new()
	capa.name = NOMBRE_RAIZ
	raiz.add_child(capa)

	_montar_comida(capa, raiz, String(estado_ambiental.get("comida_estado", "")))
	_montar_alquiler(capa, raiz, String(estado_ambiental.get("alquiler_estado", "")))
	_montar_vueltas(capa, raiz, maxi(1, int(estado_ambiental.get("vuelta", 1))))
	return capa


static func _montar_comida(capa: Node3D, casa: Node3D, estado: String) -> void:
	var cocina := casa.find_child("CocinaCasa", true, false)
	var marca := Node3D.new()
	if estado == CasaEstadoAmbientalScript.COMIDA_RECIENTE:
		marca.name = "DespensaConComida"
	else:
		marca.name = "DespensaEscasa"
	marca.position = _posicion(capa, cocina, Vector3(-0.22, 1.04, 0.58), Vector3(4.58, 1.04, 0.43))
	capa.add_child(marca)

	if estado == CasaEstadoAmbientalScript.COMIDA_RECIENTE:
		_caja(marca, Vector3(-0.08, 0.055, 0.0), Vector3(0.20, 0.11, 0.16), Color(0.54, 0.38, 0.20))
		_cilindro(marca, Vector3(0.09, 0.07, 0.0), 0.055, 0.14, Color(0.52, 0.47, 0.35))
		_caja(
			marca, Vector3(-0.08, 0.12, -0.01), Vector3(0.12, 0.025, 0.09), Color(0.72, 0.66, 0.48)
		)
	else:
		# El envoltorio vacío es una consecuencia del hecho "lleva días sin
		# comer", no una barra de hambre disfrazada.
		_caja(marca, Vector3.ZERO, Vector3(0.24, 0.018, 0.17), Color(0.46, 0.42, 0.34))
		_caja(
			marca, Vector3(0.04, 0.014, -0.02), Vector3(0.12, 0.012, 0.08), Color(0.34, 0.31, 0.26)
		)


static func _montar_alquiler(capa: Node3D, casa: Node3D, estado: String) -> void:
	if estado == CasaEstadoAmbientalScript.ALQUILER_SIN_HISTORIAL:
		return

	var mesita := casa.find_child("MesitaCasa", true, false)
	var papel := Node3D.new()
	papel.name = (
		"ReciboAlquilerPagado"
		if estado == CasaEstadoAmbientalScript.ALQUILER_PAGADO
		else "AvisoAlquilerImpagado"
	)
	papel.position = _posicion(capa, mesita, Vector3(0.18, 0.64, 0.10), Vector3(-0.92, 0.64, -2.95))
	papel.rotation_degrees.y = -9.0
	capa.add_child(papel)

	_caja(papel, Vector3.ZERO, Vector3(0.32, 0.014, 0.22), Color(0.70, 0.67, 0.56))
	if estado == CasaEstadoAmbientalScript.ALQUILER_PAGADO:
		_caja(
			papel, Vector3(0.06, 0.010, 0.02), Vector3(0.10, 0.007, 0.055), Color(0.24, 0.38, 0.24)
		)
	else:
		_caja(
			papel, Vector3(0.0, 0.010, -0.06), Vector3(0.24, 0.007, 0.035), Color(0.48, 0.16, 0.13)
		)
		_caja(
			papel, Vector3(0.0, 0.012, 0.02), Vector3(0.18, 0.006, 0.020), Color(0.24, 0.20, 0.18)
		)


static func _montar_vueltas(capa: Node3D, casa: Node3D, vuelta: int) -> void:
	var completadas := maxi(0, vuelta - 1)
	if completadas == 0:
		return

	var estanteria := casa.find_child("EstanteriaComprasCasa", true, false)
	var pila := Node3D.new()
	pila.name = "VueltasCasa"
	pila.position = _posicion(
		capa, estanteria, Vector3(0.22, 1.72, 0.0), Vector3(1.47, 1.72, -3.22)
	)
	capa.add_child(pila)

	for indice in range(completadas):
		var carpeta := Node3D.new()
		carpeta.name = "CarpetaVuelta%02d" % (indice + 1)
		carpeta.position = Vector3(
			0.012 if indice % 2 == 0 else -0.012,
			float(indice) * 0.026,
			0.006 if indice % 3 == 0 else 0.0
		)
		carpeta.rotation_degrees.y = 2.0 if indice % 2 == 0 else -2.0
		pila.add_child(carpeta)
		_caja(carpeta, Vector3.ZERO, Vector3(0.30, 0.022, 0.21), Color(0.39, 0.31, 0.22))
		_caja(
			carpeta,
			Vector3(-0.08, 0.014, -0.075),
			Vector3(0.10, 0.009, 0.045),
			Color(0.57, 0.52, 0.40)
		)


static func _posicion(capa: Node3D, ancla: Node, local: Vector3, fallback: Vector3) -> Vector3:
	if ancla is Node3D and ancla.is_inside_tree() and capa.is_inside_tree():
		var ancla_3d := ancla as Node3D
		return capa.to_local(ancla_3d.to_global(local))
	return fallback


static func _caja(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)


static func _cilindro(raiz: Node3D, pos: Vector3, radio: float, alto: float, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	malla.mesh = cilindro
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)
