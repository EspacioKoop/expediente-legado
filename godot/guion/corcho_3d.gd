## Tablón físico e interactivo del corcho de conceptos (#101).
##
## No deduce relaciones del contenido. Cada hilo existe únicamente porque el
## jugador activó dos fichas; volver a activar el mismo par lo retira.
class_name Corcho3D
extends Node3D

signal cambiado

const POSICION := Vector3(0.0, 1.55, -3.42)
const TAM_TABLON := Vector3(2.65, 1.55, 0.07)
const TAM_FICHA := Vector3(0.44, 0.25, 0.035)
const MARGEN_FICHAS := Vector2(0.07, 0.08)
const COLOR_FICHA := Color(0.88, 0.84, 0.70)
const COLOR_FICHA_SELECCIONADA := Color(0.97, 0.88, 0.48)

var _jornada: Dictionary
var _conceptos := {}
var _seleccion := ""
var _hilos: Node3D
var _papeles := {}


func configurar(jornada: Dictionary, conceptos: Array) -> void:
	_jornada = jornada
	_conceptos.clear()
	_papeles.clear()
	for concepto in conceptos:
		var id := String(concepto.get("id", ""))
		if not id.is_empty():
			_conceptos[id] = concepto
	var cambio := Corcho.sincronizar(_jornada, conceptos)
	cambio = Corcho.limitar_posiciones(_jornada, _limite_fichas()) or cambio
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


func _limite_fichas() -> Vector2:
	return Vector2(
		TAM_TABLON.x * 0.5 - TAM_FICHA.x * 0.5 - MARGEN_FICHAS.x,
		TAM_TABLON.y * 0.5 - TAM_FICHA.y * 0.5 - MARGEN_FICHAS.y,
	)


func _montar_tablero() -> void:
	var marco := MeshInstance3D.new()
	marco.name = "MarcoCorcho"
	var caja_marco := BoxMesh.new()
	caja_marco.size = TAM_TABLON + Vector3(0.14, 0.14, 0.035)
	marco.mesh = caja_marco
	marco.position.z = -0.025
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

	_montar_rotulo(
		"EtiquetaCorcho",
		"CORCHO DE CONCEPTOS",
		Vector3(0.0, TAM_TABLON.y * 0.5 + 0.105, 0.05),
		Vector3(1.18, 0.18, 0.025),
		18,
	)
	_montar_rotulo(
		"InstruccionCorcho",
		"USA DOS FICHAS PARA PONER / QUITAR HILO",
		Vector3(0.0, -TAM_TABLON.y * 0.5 - 0.09, 0.05),
		Vector3(1.58, 0.15, 0.022),
		11,
	)


func _montar_rotulo(nombre_nodo: String, texto: String, pos: Vector3, tam: Vector3, fuente: int) -> void:
	var placa := MeshInstance3D.new()
	placa.name = nombre_nodo
	placa.position = pos
	var caja := BoxMesh.new()
	caja.size = tam
	placa.mesh = caja
	var papel := StandardMaterial3D.new()
	papel.albedo_color = Color(0.83, 0.78, 0.63)
	papel.roughness = 1.0
	placa.material_override = papel
	add_child(placa)

	var etiqueta := Label3D.new()
	etiqueta.name = "Texto"
	etiqueta.text = texto
	etiqueta.position = Vector3(0.0, 0.0, tam.z * 0.55)
	etiqueta.font_size = fuente
	etiqueta.pixel_size = 0.0027
	etiqueta.modulate = Color(0.12, 0.10, 0.09)
	placa.add_child(etiqueta)


func _montar_ficha(id: String, datos: Dictionary) -> void:
	if not _conceptos.has(id):
		return
	var pos = datos.get("pos", [0.0, 0.0])
	if typeof(pos) != TYPE_ARRAY or pos.size() < 2:
		pos = [0.0, 0.0]

	var ficha := Interactuable3D.new()
	ficha.name = "Ficha_%s" % id.validate_node_name()
	ficha.position = Vector3(float(pos[0]), float(pos[1]), 0.072)
	ficha.verbo = Interactuable3D.Verbo.USAR
	var nombre_visible := String(_conceptos[id].get("nombre", id))
	ficha.nombre_objeto = "ficha «%s»" % nombre_visible
	ficha.activado.connect(_activar_ficha.bind(id))
	add_child(ficha)

	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	var forma := BoxShape3D.new()
	forma.size = TAM_FICHA
	colision.shape = forma
	ficha.add_child(colision)

	var papel := MeshInstance3D.new()
	papel.name = "Papel"
	var caja := BoxMesh.new()
	caja.size = TAM_FICHA
	papel.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_FICHA
	material.roughness = 1.0
	papel.material_override = material
	ficha.add_child(papel)
	_papeles[id] = papel

	var nombre := Label3D.new()
	nombre.name = "Nombre"
	nombre.text = nombre_visible
	nombre.position = Vector3(0, 0, 0.022)
	nombre.font_size = 17
	nombre.pixel_size = 0.0038
	nombre.modulate = Color(0.12, 0.10, 0.09)
	ficha.add_child(nombre)

	var chincheta := MeshInstance3D.new()
	chincheta.name = "Chincheta"
	var esfera := SphereMesh.new()
	esfera.radius = 0.026
	esfera.height = 0.052
	chincheta.mesh = esfera
	chincheta.position = Vector3(0, TAM_FICHA.y * 0.35, 0.043)
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color(0.55, 0.08, 0.06)
	chincheta.material_override = rojo
	ficha.add_child(chincheta)


func _activar_ficha(_actor: Node, id: String) -> void:
	if _seleccion.is_empty():
		_seleccion = id
		_actualizar_seleccion()
		return
	if _seleccion == id:
		_seleccion = ""
		_actualizar_seleccion()
		return
	var anterior := _seleccion
	_seleccion = ""
	_actualizar_seleccion()
	if Corcho.alternar_enlace(_jornada, anterior, id):
		_redibujar_hilos()
		cambiado.emit()


func _actualizar_seleccion() -> void:
	for id in _papeles:
		var papel := _papeles[id] as MeshInstance3D
		if papel == null:
			continue
		var material := papel.material_override as StandardMaterial3D
		if material == null:
			continue
		material.albedo_color = COLOR_FICHA
		if String(id) == _seleccion:
			material.albedo_color = COLOR_FICHA_SELECCIONADA


func _redibujar_hilos() -> void:
	for hijo in _hilos.get_children():
		hijo.queue_free()
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
	var fichas: Dictionary = Corcho.estado(_jornada)["fichas"]
	if not fichas.has(id):
		return null
	var pos = fichas[id].get("pos", [])
	if typeof(pos) != TYPE_ARRAY or pos.size() < 2:
		return null
	return Vector3(float(pos[0]), float(pos[1]), 0.118)


func _montar_hilo(a: Vector3, b: Vector3) -> void:
	var delta := b - a
	if delta.length() <= 0.001:
		return
	var hilo := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.009
	cilindro.bottom_radius = 0.009
	cilindro.height = delta.length()
	hilo.mesh = cilindro
	hilo.position = (a + b) * 0.5
	hilo.quaternion = Quaternion(Vector3.UP, delta.normalized())
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.48, 0.04, 0.035)
	material.roughness = 0.9
	hilo.material_override = material
	_hilos.add_child(hilo)
