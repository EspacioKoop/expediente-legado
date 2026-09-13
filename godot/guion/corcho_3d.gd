## Tablón físico e interactivo del corcho de conceptos (#101).
##
## No deduce relaciones del contenido. Cada hilo existe únicamente porque el
## jugador activó dos fichas; volver a activar el mismo par lo retira.
class_name Corcho3D
extends Node3D

signal cambiado

const POSICION := Vector3(0.0, 1.72, -3.42)
const TAM_TABLON := Vector3(3.7, 2.15, 0.08)
const TAM_FICHA := Vector3(0.72, 0.38, 0.045)

var _jornada: Dictionary
var _conceptos := {}
var _seleccion := ""
var _hilos: Node3D


func configurar(jornada: Dictionary, conceptos: Array) -> void:
	_jornada = jornada
	for concepto in conceptos:
		var id := String(concepto.get("id", ""))
		if not id.is_empty():
			_conceptos[id] = concepto
	var cambio := Corcho.sincronizar(_jornada, conceptos)
	_montar()
	if cambio:
		cambiado.emit()


func _montar() -> void:
	position = POSICION
	_montar_tablero()
	_hilos = Node3D.new()
	_hilos.name = "Hilos"
	add_child(_hilos)
	var fichas: Dictionary = Corcho.estado(_jornada)["fichas"]
	for id in fichas:
		_montar_ficha(String(id), fichas[id])
	_redibujar_hilos()


func _montar_tablero() -> void:
	var fondo := MeshInstance3D.new()
	fondo.name = "TablonCorcho"
	var caja := BoxMesh.new()
	caja.size = TAM_TABLON
	fondo.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.48, 0.31, 0.18)
	material.roughness = 1.0
	fondo.material_override = material
	add_child(fondo)


func _montar_ficha(id: String, datos: Dictionary) -> void:
	if not _conceptos.has(id):
		return
	var pos = datos.get("pos", [0.0, 0.0])
	if typeof(pos) != TYPE_ARRAY or pos.size() < 2:
		pos = [0.0, 0.0]

	var ficha := Interactuable3D.new()
	ficha.name = "Ficha_%s" % id.validate_node_name()
	ficha.position = Vector3(float(pos[0]), float(pos[1]), 0.085)
	ficha.verbo = Interactuable3D.Verbo.USAR
	ficha.nombre_objeto = String(_conceptos[id].get("nombre", id))
	ficha.activado.connect(_activar_ficha.bind(id))
	add_child(ficha)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = TAM_FICHA
	colision.shape = forma
	ficha.add_child(colision)

	var papel := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = TAM_FICHA
	papel.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.88, 0.84, 0.70)
	material.roughness = 1.0
	papel.material_override = material
	ficha.add_child(papel)

	var nombre := Label3D.new()
	nombre.text = ficha.nombre_objeto
	nombre.position = Vector3(0, 0, 0.026)
	nombre.font_size = 20
	nombre.pixel_size = 0.0045
	nombre.modulate = Color(0.12, 0.10, 0.09)
	ficha.add_child(nombre)

	var chincheta := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.035
	esfera.height = 0.07
	chincheta.mesh = esfera
	chincheta.position = Vector3(0, TAM_FICHA.y * 0.35, 0.055)
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color(0.55, 0.08, 0.06)
	chincheta.material_override = rojo
	ficha.add_child(chincheta)


func _activar_ficha(_actor: Node, id: String) -> void:
	if _seleccion.is_empty():
		_seleccion = id
		return
	if _seleccion == id:
		_seleccion = ""
		return
	var anterior := _seleccion
	_seleccion = ""
	if Corcho.alternar_enlace(_jornada, anterior, id):
		_redibujar_hilos()
		cambiado.emit()


func _redibujar_hilos() -> void:
	for hijo in _hilos.get_children():
		hijo.queue_free()
	var tablero := Corcho.estado(_jornada)
	for enlace in tablero["enlaces"]:
		if typeof(enlace) != TYPE_ARRAY or enlace.size() != 2:
			continue
		var a := _posicion_de(String(enlace[0]))
		var b := _posicion_de(String(enlace[1]))
		if a == null or b == null:
			continue
		_montar_hilo(a, b)


func _posicion_de(id: String):
	var fichas: Dictionary = Corcho.estado(_jornada)["fichas"]
	if not fichas.has(id):
		return null
	var pos = fichas[id].get("pos", [])
	if typeof(pos) != TYPE_ARRAY or pos.size() < 2:
		return null
	return Vector3(float(pos[0]), float(pos[1]), 0.145)


func _montar_hilo(a: Vector3, b: Vector3) -> void:
	var delta := b - a
	if delta.length() <= 0.001:
		return
	var hilo := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.012
	cilindro.bottom_radius = 0.012
	cilindro.height = delta.length()
	hilo.mesh = cilindro
	hilo.position = (a + b) * 0.5
	hilo.quaternion = Quaternion(Vector3.UP, delta.normalized())
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.48, 0.04, 0.035)
	material.roughness = 0.9
	hilo.material_override = material
	_hilos.add_child(hilo)
