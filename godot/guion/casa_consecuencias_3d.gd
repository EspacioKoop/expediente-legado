## Materialización diegética de consecuencias domésticas de #93/#96.
##
## No decide economía ni inventa severidades: consume únicamente la lista
## discreta `consecuencias_casa` de CasaEstadoAmbiental. Cada hecho deja una
## huella física reconocible sobre anclas que la casa ya posee.
class_name CasaConsecuencias3D
extends RefCounted

const NOMBRE_RAIZ := "ConsecuenciasCasa"
const CONSECUENCIAS := [
	"casa_luz_reducida",
	"casa_grifo_averiado",
	"casa_persiana_atascada",
	"casa_recibo_pendiente",
	"casa_multa_pendiente",
	"casa_sin_agua_caliente",
	"casa_electrodomestico_roto",
]


static func firma(estado_ambiental: Dictionary) -> String:
	var consecuencias := _normalizadas(estado_ambiental)
	return "|".join(consecuencias)


static func montar(raiz: Node3D, estado_ambiental: Dictionary) -> Node3D:
	var anterior := raiz.get_node_or_null(NOMBRE_RAIZ)
	if anterior != null:
		raiz.remove_child(anterior)
		anterior.queue_free()

	var capa := Node3D.new()
	capa.name = NOMBRE_RAIZ
	raiz.add_child(capa)

	for consecuencia in _normalizadas(estado_ambiental):
		match consecuencia:
			"casa_luz_reducida":
				_montar_bombilla_fundida(capa, raiz)
			"casa_grifo_averiado":
				_montar_goteo(capa, raiz)
			"casa_persiana_atascada":
				_montar_persiana(capa, raiz)
			"casa_recibo_pendiente":
				_montar_papel_pendiente(capa, raiz, "ReciboPendiente", Vector3(-0.08, 0.0, 0.0))
			"casa_multa_pendiente":
				_montar_papel_pendiente(capa, raiz, "MultaPendiente", Vector3(0.10, 0.01, 0.06))
			"casa_sin_agua_caliente":
				_montar_calentador(capa, raiz)
			"casa_electrodomestico_roto":
				_montar_electrodomestico(capa, raiz)
	return capa


static func _normalizadas(estado_ambiental: Dictionary) -> Array[String]:
	var salida: Array[String] = []
	var bruto = estado_ambiental.get("consecuencias_casa", [])
	if typeof(bruto) != TYPE_ARRAY:
		return salida
	for valor in bruto:
		var consecuencia := String(valor)
		if consecuencia in CONSECUENCIAS and not salida.has(consecuencia):
			salida.append(consecuencia)
	salida.sort()
	return salida


static func _montar_bombilla_fundida(capa: Node3D, casa: Node3D) -> void:
	var lampara := casa.find_child("LamparaPieCasa", true, false)
	if lampara != null and lampara.has_method("establecer_averiada"):
		lampara.establecer_averiada(true)
	var marca := Node3D.new()
	marca.name = "BombillaFundida"
	marca.position = _posicion(capa, lampara, Vector3(0.0, 1.62, 0.0), Vector3(-1.0, 1.62, 2.85))
	capa.add_child(marca)
	_agregar_esfera(marca, Vector3.ZERO, 0.105, Color(0.12, 0.11, 0.09))


static func _montar_goteo(capa: Node3D, casa: Node3D) -> void:
	var fregadero := casa.find_child("FregaderoCasa", true, false)
	var marca := Node3D.new()
	marca.name = "GrifoGoteando"
	marca.position = _posicion(
		capa, fregadero, Vector3(0.08, 0.19, 0.12), Vector3(4.85, 1.18, 0.20)
	)
	capa.add_child(marca)
	for i in 3:
		_agregar_esfera(
			marca,
			Vector3(0.0, -0.12 - float(i) * 0.12, 0.0),
			0.025 - float(i) * 0.004,
			Color(0.28, 0.46, 0.56)
		)


static func _montar_persiana(capa: Node3D, casa: Node3D) -> void:
	var ventana := casa.find_child("VentanaCasa", true, false)
	var marca := Node3D.new()
	marca.name = "PersianaAtascada"
	marca.position = _posicion(capa, ventana, Vector3(0.0, 0.0, 0.03), Vector3(-2.10, 1.65, -3.31))
	capa.add_child(marca)
	for i in 5:
		var lama := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(1.58, 0.12, 0.055)
		lama.mesh = caja
		lama.position = Vector3(0.0, 0.36 - float(i) * 0.18, 0.0)
		if i == 2:
			lama.rotation_degrees.z = 11.0
		Modelos._pintar(lama, Color(0.30, 0.28, 0.24))
		marca.add_child(lama)


static func _montar_papel_pendiente(
	capa: Node3D, casa: Node3D, nombre: String, desfase: Vector3
) -> void:
	var mesita := casa.find_child("MesitaCasa", true, false)
	var marca := Node3D.new()
	marca.name = nombre
	marca.position = _posicion(capa, mesita, Vector3(0.0, 0.63, 0.0), Vector3(-1.1, 0.64, -3.05))
	marca.position += desfase
	marca.rotation_degrees.y = 8.0 if nombre == "ReciboPendiente" else -13.0
	capa.add_child(marca)
	_agregar_caja(marca, Vector3.ZERO, Vector3(0.30, 0.012, 0.21), Color(0.70, 0.67, 0.57))
	_agregar_caja(
		marca, Vector3(0.0, 0.008, -0.055), Vector3(0.20, 0.006, 0.025), Color(0.18, 0.17, 0.15)
	)


static func _montar_calentador(capa: Node3D, casa: Node3D) -> void:
	var cocina := casa.find_child("CocinaCasa", true, false)
	var marca := Node3D.new()
	marca.name = "CalentadorAveriado"
	marca.position = _posicion(capa, cocina, Vector3(-0.18, 1.58, 0.72), Vector3(4.62, 1.58, 0.57))
	capa.add_child(marca)
	_agregar_caja(marca, Vector3.ZERO, Vector3(0.38, 0.58, 0.20), Color(0.34, 0.33, 0.30))
	_agregar_cilindro(marca, Vector3(-0.10, -0.40, 0.0), 0.025, 0.32, Color(0.25, 0.24, 0.22))
	_agregar_cilindro(marca, Vector3(0.10, -0.40, 0.0), 0.025, 0.32, Color(0.25, 0.24, 0.22))
	_agregar_esfera(marca, Vector3(0.11, 0.10, -0.11), 0.035, Color(0.16, 0.05, 0.04))


static func _montar_electrodomestico(capa: Node3D, casa: Node3D) -> void:
	var televisor := casa.find_child("TelevisorCasaInteractuable", true, false)
	var marca := Node3D.new()
	marca.name = "ElectrodomesticoRoto"
	marca.position = _posicion(
		capa, televisor, Vector3(0.48, -0.32, 0.18), Vector3(-3.15, 0.25, 2.15)
	)
	marca.rotation_degrees = Vector3(0.0, -18.0, 7.0)
	capa.add_child(marca)
	_agregar_caja(marca, Vector3.ZERO, Vector3(0.52, 0.30, 0.38), Color(0.15, 0.15, 0.14))
	_agregar_cilindro(marca, Vector3(0.34, -0.08, 0.02), 0.018, 0.42, Color(0.08, 0.08, 0.07))


static func _posicion(capa: Node3D, ancla: Node, local: Vector3, fallback: Vector3) -> Vector3:
	if ancla is Node3D and ancla.is_inside_tree() and capa.is_inside_tree():
		var ancla_3d := ancla as Node3D
		return capa.to_local(ancla_3d.to_global(local))
	return fallback


static func _agregar_caja(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)


static func _agregar_cilindro(
	raiz: Node3D, pos: Vector3, radio: float, alto: float, color: Color
) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	malla.mesh = cilindro
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)


static func _agregar_esfera(raiz: Node3D, pos: Vector3, radio: float, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = radio
	esfera.height = radio * 2.0
	malla.mesh = esfera
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)
