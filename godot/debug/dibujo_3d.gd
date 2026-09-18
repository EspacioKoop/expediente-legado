## Superposición 3D de QA para inspeccionar la geometría deducida (#116).
##
## Vive bajo debug/**: no altera colisiones, navegación, partida ni export público.
## Compara el contrato lógico (celdas/contorno de Planta) con el contorno físico
## poligonal cuando existe, y marca entrada, salidas y figuras del espacio actual.
extends Node3D

const ALTURA_CELDA := 0.035
const ALTURA_CONTORNO := 0.075
const ALTURA_MARCA := 0.12
const LARGO_NORMAL := 0.85
const NOMBRE_MALLA := "Trazos"

const COLOR_CELDA := Color(0.15, 0.78, 1.0, 0.58)
const COLOR_MURO := Color(1.0, 0.64, 0.12, 0.95)
const COLOR_NORMAL := Color(1.0, 0.94, 0.24, 0.95)
const COLOR_CONTORNO_FISICO := Color(1.0, 0.2, 0.86, 0.95)
const COLOR_RECTANGULO := Color(0.42, 0.86, 0.72, 0.75)
const COLOR_ENTRADA := Color(0.22, 1.0, 0.35, 1.0)
const COLOR_SALIDA := Color(1.0, 0.20, 0.18, 1.0)
const COLOR_FIGURA := Color(0.96, 0.96, 1.0, 1.0)
const COLOR_ORIENTACION := Color(0.76, 0.68, 1.0, 1.0)

var _dia: Node
var _mundo_id := 0
var _resumen := {
	"celdas": 0,
	"muros": 0,
	"contorno_fisico": 0,
	"salidas": 0,
	"figuras": 0,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func configurar(dia: Node) -> void:
	_dia = dia
	redibujar()


func _process(_delta: float) -> void:
	if _dia == null or not is_instance_valid(_dia):
		queue_free()
		return
	var mundo: Node = _dia.get("_mundo")
	var actual := mundo.get_instance_id() if mundo != null else 0
	if actual != _mundo_id:
		redibujar()


func redibujar() -> void:
	for hijo in get_children():
		hijo.queue_free()
	_resumen = {
		"celdas": 0,
		"muros": 0,
		"contorno_fisico": 0,
		"salidas": 0,
		"figuras": 0,
	}
	if _dia == null or not is_instance_valid(_dia):
		return
	var mundo: Node = _dia.get("_mundo")
	_mundo_id = mundo.get_instance_id() if mundo != null else 0
	var espacio = _dia.get("_espacio_actual")
	if not espacio is Dictionary or espacio.is_empty():
		return

	var lineas: Array = []
	if espacio.has("planta"):
		_dibujar_planta(lineas, espacio["planta"])
	elif espacio.has("suelo"):
		_dibujar_rectangulo(lineas, espacio)

	if espacio.has("contorno"):
		_dibujar_contorno_fisico(lineas, espacio["contorno"])

	_dibujar_cruz(lineas, espacio.get("entrada", Vector3.ZERO), COLOR_ENTRADA, 0.72)
	for salida in espacio.get("salidas", []):
		if salida is Dictionary:
			_dibujar_salida(lineas, salida)
			_resumen["salidas"] += 1
	for figura in espacio.get("figuras", []):
		if figura is Dictionary:
			_dibujar_figura(lineas, figura)
			_resumen["figuras"] += 1

	_materializar(lineas)


func resumen() -> Dictionary:
	return _resumen.duplicate(true)


func _dibujar_planta(lineas: Array, bloques: Array) -> void:
	var celdas := Planta.celdas(bloques)
	_resumen["celdas"] = celdas.size()
	for celda in celdas:
		var origen := Planta.esquina_en_metros(bloques, celda) + Vector3(0, ALTURA_CELDA, 0)
		var lado := Planta.CELDA
		var a := origen
		var b := origen + Vector3(lado, 0, 0)
		var c := origen + Vector3(lado, 0, lado)
		var d := origen + Vector3(0, 0, lado)
		_linea(lineas, a, b, COLOR_CELDA)
		_linea(lineas, b, c, COLOR_CELDA)
		_linea(lineas, c, d, COLOR_CELDA)
		_linea(lineas, d, a, COLOR_CELDA)

	var origen_planta := Planta.esquina_en_metros(bloques, Vector2i.ZERO)
	for tramo in Planta.contorno(bloques):
		var a: Vector3
		var b: Vector3
		var normal: Vector3
		if tramo["eje"] == "x":
			a = (
				origen_planta
				+ Vector3(
					float(tramo["desde"]) * Planta.CELDA,
					ALTURA_CONTORNO,
					float(tramo["linea"]) * Planta.CELDA
				)
			)
			b = (
				origen_planta
				+ Vector3(
					float(tramo["hasta"]) * Planta.CELDA,
					ALTURA_CONTORNO,
					float(tramo["linea"]) * Planta.CELDA
				)
			)
			normal = Vector3(0, 0, float(tramo["hacia"]))
		else:
			a = (
				origen_planta
				+ Vector3(
					float(tramo["linea"]) * Planta.CELDA,
					ALTURA_CONTORNO,
					float(tramo["desde"]) * Planta.CELDA
				)
			)
			b = (
				origen_planta
				+ Vector3(
					float(tramo["linea"]) * Planta.CELDA,
					ALTURA_CONTORNO,
					float(tramo["hasta"]) * Planta.CELDA
				)
			)
			normal = Vector3(float(tramo["hacia"]), 0, 0)
		_linea(lineas, a, b, COLOR_MURO)
		var medio := a.lerp(b, 0.5)
		_linea(lineas, medio, medio + normal * LARGO_NORMAL, COLOR_NORMAL)
		_resumen["muros"] += 1


func _dibujar_rectangulo(lineas: Array, espacio: Dictionary) -> void:
	var medidas: Vector2 = espacio.get("suelo", Vector2.ZERO)
	var centro: Vector2 = espacio.get("centro_suelo", Vector2.ZERO)
	var mitad := medidas / 2.0
	var y := ALTURA_CONTORNO
	var puntos := [
		Vector3(centro.x - mitad.x, y, centro.y - mitad.y),
		Vector3(centro.x + mitad.x, y, centro.y - mitad.y),
		Vector3(centro.x + mitad.x, y, centro.y + mitad.y),
		Vector3(centro.x - mitad.x, y, centro.y + mitad.y),
	]
	for i in puntos.size():
		_linea(lineas, puntos[i], puntos[(i + 1) % puntos.size()], COLOR_RECTANGULO)
	_resumen["muros"] = 4


func _dibujar_contorno_fisico(lineas: Array, contorno) -> void:
	if not contorno is PackedVector2Array or contorno.size() < 2:
		return
	for i in contorno.size():
		var a2: Vector2 = contorno[i]
		var b2: Vector2 = contorno[(i + 1) % contorno.size()]
		_linea(
			lineas,
			Vector3(a2.x, ALTURA_CONTORNO + 0.035, a2.y),
			Vector3(b2.x, ALTURA_CONTORNO + 0.035, b2.y),
			COLOR_CONTORNO_FISICO
		)
	_resumen["contorno_fisico"] = contorno.size()


func _dibujar_salida(lineas: Array, salida: Dictionary) -> void:
	var pos: Vector3 = salida.get("pos", Vector3.ZERO)
	var tam: Vector3 = salida.get("tam", Vector3(1.4, 2.2, 1.4))
	var base := Vector3(pos.x, ALTURA_MARCA, pos.z)
	_dibujar_cruz(lineas, base, COLOR_SALIDA, maxf(0.55, maxf(tam.x, tam.z) / 2.0))
	_linea(lineas, base, Vector3(base.x, maxf(pos.y + tam.y / 2.0, 1.0), base.z), COLOR_SALIDA)


func _dibujar_figura(lineas: Array, figura: Dictionary) -> void:
	var pos: Vector3 = figura.get("pos", Vector3.ZERO)
	var base := Vector3(pos.x, ALTURA_MARCA, pos.z)
	_dibujar_cruz(lineas, base, COLOR_FIGURA, 0.42)
	_linea(lineas, base, base + Vector3(0, 2.0, 0), COLOR_FIGURA)
	if figura.has("giro"):
		var giro := float(figura.get("giro", 0.0))
		var frente := Vector3(-sin(giro), 0, -cos(giro))
		_linea(lineas, base, base + frente * 1.1, COLOR_ORIENTACION)


func _dibujar_cruz(lineas: Array, centro: Vector3, color: Color, radio: float) -> void:
	var p := Vector3(centro.x, maxf(centro.y, ALTURA_MARCA), centro.z)
	_linea(lineas, p - Vector3(radio, 0, 0), p + Vector3(radio, 0, 0), color)
	_linea(lineas, p - Vector3(0, 0, radio), p + Vector3(0, 0, radio), color)


func _linea(lineas: Array, a: Vector3, b: Vector3, color: Color) -> void:
	lineas.append({"a": a, "b": b, "color": color})


func _materializar(lineas: Array) -> void:
	if lineas.is_empty():
		return
	var inmediata := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	inmediata.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for dato in lineas:
		inmediata.surface_set_color(dato["color"])
		inmediata.surface_add_vertex(dato["a"])
		inmediata.surface_set_color(dato["color"])
		inmediata.surface_add_vertex(dato["b"])
	inmediata.surface_end()

	var instancia := MeshInstance3D.new()
	instancia.name = NOMBRE_MALLA
	instancia.mesh = inmediata
	instancia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instancia)
