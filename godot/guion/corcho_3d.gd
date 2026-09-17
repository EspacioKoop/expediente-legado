## Tablón físico del corcho de conceptos (#101).
##
## No deduce relaciones del contenido. Cada hilo existe únicamente porque el
## jugador unió dos fichas; volver a unir el mismo par lo retira.
##
## Desde #785 es un corcho de tamaño real colgado en el salón. En la pared solo
## se ve: fichas e hilos se ordenan en la interfaz propia (`CorchoPanel`), que
## se pide al usar el tablón, y al cerrarla la pared vuelve a dibujarse.
class_name Corcho3D
extends Node3D

signal cambiado
signal abrir_pedido

## En la cara del tabique del dormitorio que da al salón, lejos de la ventana.
const POSICION := Vector3(-2.3, 1.45, -0.52)
## El tablón a escala única del área lógica: ≈ 0,90 × 0,53 m.
const ESCALA := 0.34
const TAM_TABLON := Vector3(Corcho.AREA.x * ESCALA, Corcho.AREA.y * ESCALA, 0.03)
const MARCO := 0.035
const GROSOR_FICHA := 0.004
const COLOR_FICHA := Color(0.88, 0.84, 0.70)

var _jornada: Dictionary
var _conceptos := {}
var _fichas: Node3D
var _hilos: Node3D


func configurar(jornada: Dictionary, conceptos: Array) -> void:
	_jornada = jornada
	_conceptos.clear()
	for concepto in conceptos:
		var id := String(concepto.get("id", ""))
		if not id.is_empty():
			_conceptos[id] = concepto
	var cambio := Corcho.sincronizar(_jornada, conceptos)
	cambio = Corcho.limitar_posiciones(_jornada, Corcho.limite()) or cambio
	_montar()
	if cambio:
		cambiado.emit()


func conceptos() -> Dictionary:
	return _conceptos


## Vuelve a clavar fichas e hilos según el estado guardado.
func refrescar() -> void:
	if _fichas == null:
		return
	for hijo in _fichas.get_children():
		_fichas.remove_child(hijo)
		hijo.queue_free()
	for hijo in _hilos.get_children():
		_hilos.remove_child(hijo)
		hijo.queue_free()
	var fichas: Dictionary = Corcho.estado(_jornada)["fichas"]
	for id in fichas:
		_montar_ficha(String(id), fichas[id])
	_redibujar_hilos()


func _montar() -> void:
	position = POSICION
	if _fichas == null:
		_montar_tablero()
		_fichas = Node3D.new()
		_fichas.name = "Fichas"
		add_child(_fichas)
		_hilos = Node3D.new()
		_hilos.name = "Hilos"
		add_child(_hilos)
	refrescar()


func _montar_tablero() -> void:
	var marco := MeshInstance3D.new()
	marco.name = "MarcoCorcho"
	var caja_marco := BoxMesh.new()
	caja_marco.size = TAM_TABLON + Vector3(MARCO * 2.0, MARCO * 2.0, 0.02)
	marco.mesh = caja_marco
	marco.position.z = -0.01
	var madera := StandardMaterial3D.new()
	madera.albedo_color = Color(0.25, 0.14, 0.075)
	madera.roughness = 0.86
	marco.material_override = madera
	add_child(marco)

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

	# Todo el tablón es el objeto: se usa entero, no ficha a ficha.
	var uso := Interactuable3D.new()
	uso.name = "UsarCorcho"
	uso.verbo = Interactuable3D.Verbo.USAR
	uso.nombre_objeto = "corcho de conceptos"
	uso.activado.connect(func(_actor: Node) -> void: abrir_pedido.emit())
	add_child(uso)
	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	var forma := BoxShape3D.new()
	forma.size = caja_marco.size + Vector3(0.0, 0.0, 0.06)
	colision.shape = forma
	uso.add_child(colision)


func _a_pared(pos: Vector2, z: float) -> Vector3:
	return Vector3(pos.x * ESCALA, pos.y * ESCALA, z)


func _montar_ficha(id: String, datos) -> void:
	if not _conceptos.has(id) or typeof(datos) != TYPE_DICTIONARY:
		return
	var pos = datos.get("pos", [0.0, 0.0])
	if typeof(pos) != TYPE_ARRAY or pos.size() < 2:
		pos = [0.0, 0.0]

	var ficha := Node3D.new()
	ficha.name = "Ficha_%s" % id.validate_node_name()
	var base := TAM_TABLON.z * 0.5 + GROSOR_FICHA * 0.5
	ficha.position = _a_pared(Vector2(float(pos[0]), float(pos[1])), base)
	_fichas.add_child(ficha)

	var papel := MeshInstance3D.new()
	papel.name = "Papel"
	var caja := BoxMesh.new()
	caja.size = Vector3(Corcho.TAM_FICHA.x * ESCALA, Corcho.TAM_FICHA.y * ESCALA, GROSOR_FICHA)
	papel.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_FICHA
	material.roughness = 1.0
	papel.material_override = material
	ficha.add_child(papel)

	var nombre := Label3D.new()
	nombre.name = "Nombre"
	nombre.text = String(_conceptos[id].get("nombre", id))
	nombre.position = Vector3(0, -0.008, GROSOR_FICHA * 0.5 + 0.001)
	nombre.font_size = 16
	nombre.pixel_size = 0.0011
	nombre.width = Corcho.TAM_FICHA.x * ESCALA / nombre.pixel_size * 0.92
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nombre.modulate = Color(0.12, 0.10, 0.09)
	nombre.outline_size = 0
	ficha.add_child(nombre)

	var chincheta := MeshInstance3D.new()
	chincheta.name = "Chincheta"
	var esfera := SphereMesh.new()
	esfera.radius = 0.008
	esfera.height = 0.016
	chincheta.mesh = esfera
	chincheta.position = Vector3(0, Corcho.TAM_FICHA.y * ESCALA * 0.32, 0.006)
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color(0.55, 0.08, 0.06)
	chincheta.material_override = rojo
	ficha.add_child(chincheta)


func _redibujar_hilos() -> void:
	var tablero := Corcho.estado(_jornada)
	for enlace in tablero["enlaces"]:
		if typeof(enlace) != TYPE_ARRAY or enlace.size() != 2:
			continue
		var a: Variant = _posicion_de(String(enlace[0]))
		var b: Variant = _posicion_de(String(enlace[1]))
		if a == null or b == null:
			continue
		_montar_hilo(a, b)


func _posicion_de(id: String):
	if not _conceptos.has(id):
		return null
	var fichas: Dictionary = Corcho.estado(_jornada)["fichas"]
	if not fichas.has(id) or typeof(fichas[id]) != TYPE_DICTIONARY:
		return null
	var pos = fichas[id].get("pos", [])
	if typeof(pos) != TYPE_ARRAY or pos.size() < 2:
		return null
	var altura_chincheta := Corcho.TAM_FICHA.y * 0.32
	return _a_pared(Vector2(float(pos[0]), float(pos[1]) + altura_chincheta), 0.03)


func _montar_hilo(a: Vector3, b: Vector3) -> void:
	var delta := b - a
	if delta.length() <= 0.001:
		return
	var hilo := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.0025
	cilindro.bottom_radius = 0.0025
	cilindro.height = delta.length()
	cilindro.radial_segments = 6
	hilo.mesh = cilindro
	hilo.position = (a + b) * 0.5
	hilo.quaternion = Quaternion(Vector3.UP, delta.normalized())
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.48, 0.04, 0.035)
	material.roughness = 0.9
	hilo.material_override = material
	_hilos.add_child(hilo)
