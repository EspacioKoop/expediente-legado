## Presentación física de los objetos que viven en casa (#677).
##
## No posee estado ni decide inventario: consume exclusivamente `objetos_casa`
## del contrato de CasaEstadoAmbiental (#96), que a su vez deriva de
## Inventario.HOME_STORAGE (#97). La estantería de #133 actúa como superficie
## acotada: ocho anclas, orden estable por id y ninguna puntuación de colección.
class_name CasaAcumulacion3D
extends RefCounted

const NOMBRE_RAIZ := "AcumulacionCasa"
const NOMBRE_IMAN_CALENDARIO := "ImanCalendarioCorreo"
const ID_IMAN_CALENDARIO := "postal_iman_calendario"
const MAX_OBJETOS := 8
const ANCLAS := [
	Vector3(-0.30, 0.28, -0.03),
	Vector3(0.00, 0.28, -0.03),
	Vector3(0.30, 0.28, -0.03),
	Vector3(-0.30, 0.78, -0.03),
	Vector3(0.00, 0.78, -0.03),
	Vector3(0.30, 0.78, -0.03),
	Vector3(-0.20, 1.28, -0.03),
	Vector3(0.20, 1.28, -0.03),
]

const VAR_LAMPARA := "lampara"
const VAR_MARCO := "marco"
const VAR_PUBLICACION := "publicacion"
const VAR_CINTA := "cinta"
const VAR_PAQUETE := "paquete"
const VAR_PAPEL := "papel"
const VAR_RECUERDO := "recuerdo"
const VAR_UTIL := "util"


static func montar(raiz: Node3D, estado_ambiental: Dictionary) -> Node3D:
	var estanteria := raiz.get_node_or_null("EstanteriaComprasCasa") as Node3D
	if estanteria == null:
		return null

	var anterior := estanteria.get_node_or_null(NOMBRE_RAIZ)
	if anterior != null:
		estanteria.remove_child(anterior)
		anterior.queue_free()

	var nevera := raiz.find_child("NeveraCasa", true, false) as Node3D
	_limpiar_iman_calendario(nevera)

	var acumulacion := Node3D.new()
	acumulacion.name = NOMBRE_RAIZ
	estanteria.add_child(acumulacion)

	var objetos := _objetos_ordenados(estado_ambiental)
	var indice_estante := 0
	for objeto in objetos:
		if _es_iman_calendario(objeto) and nevera != null:
			_montar_iman_calendario(nevera, objeto)
			continue
		if indice_estante >= MAX_OBJETOS:
			break
		_montar_objeto(acumulacion, objeto, indice_estante)
		indice_estante += 1
	return acumulacion


static func firma(estado_ambiental: Dictionary) -> String:
	var ids: Array[String] = []
	for objeto in _objetos_ordenados(estado_ambiental):
		ids.append(String(objeto.get("id", "")))
	return "|".join(ids)


static func _objetos_ordenados(estado_ambiental: Dictionary) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var bruto = estado_ambiental.get("objetos_casa", [])
	if typeof(bruto) != TYPE_ARRAY:
		return salida
	for valor in bruto:
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		var objeto: Dictionary = valor
		if String(objeto.get("id", "")).is_empty():
			continue
		salida.append(objeto.duplicate(true))
	salida.sort_custom(func(a, b): return String(a["id"]) < String(b["id"]))
	return salida


static func _montar_objeto(padre: Node3D, objeto: Dictionary, indice: int) -> void:
	var variante := _variante(objeto)
	var nodo := _crear_nodo_objeto(objeto, variante)
	nodo.name = "ObjetoCasa%02d" % indice
	nodo.position = ANCLAS[indice]
	nodo.set_meta("objeto_id", String(objeto.get("id", "")))
	nodo.set_meta("origen", String(objeto.get("origen", "")))
	nodo.set_meta("variante", variante)
	padre.add_child(nodo)

	match variante:
		VAR_LAMPARA:
			_lampara(nodo)
		VAR_MARCO:
			_marco(nodo)
		VAR_PUBLICACION:
			_publicacion(nodo, objeto)
		VAR_CINTA:
			_cinta(nodo)
		VAR_PAQUETE:
			_paquete(nodo)
		VAR_PAPEL:
			_papel(nodo)
		VAR_RECUERDO:
			_recuerdo(nodo)
		_:
			_util(nodo)


static func _crear_nodo_objeto(objeto: Dictionary, variante: String) -> Node3D:
	if variante != VAR_PUBLICACION:
		return Node3D.new()

	var lectura := Interactuable3D.new()
	lectura.verbo = Interactuable3D.Verbo.LEER
	var item_id := String(objeto.get("id", ""))
	var ficha := Publicaciones98.por_id(item_id)
	lectura.nombre_objeto = String(
		ficha.get("titulo", objeto.get("nombre", item_id.replace("_", " ")))
	)
	lectura.set_meta("publicacion_id", item_id)
	lectura.set_meta("titulo_publicacion", lectura.nombre_objeto)
	lectura.set_meta("categoria_publicacion", String(ficha.get("categoria", "publicacion")))
	lectura.set_meta("portada_titulo", _titulo_portada(ficha))
	lectura.set_meta("formato_publicacion", _formato_publicacion(ficha))
	return lectura


static func _titulo_portada(ficha: Dictionary) -> String:
	var piezas = ficha.get("piezas", [])
	if typeof(piezas) != TYPE_ARRAY:
		return ""
	for pieza in piezas:
		if typeof(pieza) != TYPE_DICTIONARY:
			continue
		if String(pieza.get("tipo", "")) == "portada":
			return String(pieza.get("titulo", ""))
	if not piezas.is_empty() and typeof(piezas[0]) == TYPE_DICTIONARY:
		return String(piezas[0].get("titulo", ""))
	return ""


static func _formato_publicacion(ficha: Dictionary) -> String:
	return PublicacionFisica3D.formato_de(ficha)


static func _es_iman_calendario(objeto: Dictionary) -> bool:
	return String(objeto.get("id", "")) == ID_IMAN_CALENDARIO


static func _limpiar_iman_calendario(nevera: Node3D) -> void:
	if nevera == null:
		return
	var anterior := nevera.get_node_or_null(NOMBRE_IMAN_CALENDARIO)
	if anterior != null:
		nevera.remove_child(anterior)
		anterior.queue_free()


static func _montar_iman_calendario(nevera: Node3D, objeto: Dictionary) -> void:
	var iman := Node3D.new()
	iman.name = NOMBRE_IMAN_CALENDARIO
	# La puerta visible de NeveraCasa está en x=-0.36. El papel queda claramente
	# por delante para evitar z-fighting y separado de las asas situadas hacia z negativo.
	iman.position = Vector3(-0.392, 1.26, 0.12)
	iman.set_meta("objeto_id", String(objeto.get("id", "")))
	iman.set_meta("origen", String(objeto.get("origen", "")))
	iman.set_meta("variante", "iman_calendario")
	nevera.add_child(iman)

	# Cuerpo del calendario: deliberadamente mayor y más contrastado que la primera
	# versión. Desde la cámara jugable debe leerse como papel sujeto a la puerta,
	# no como otra variación del metal gris de la nevera.
	_caja(iman, Vector3.ZERO, Vector3(0.018, 0.40, 0.30), Color(0.88, 0.84, 0.69))
	_caja(iman, Vector3(-0.014, 0.145, 0), Vector3(0.014, 0.075, 0.27), Color(0.58, 0.16, 0.12))
	for y in [-0.090, -0.035, 0.020, 0.075]:
		_caja(iman, Vector3(-0.014, y, 0), Vector3(0.014, 0.010, 0.25), Color(0.20, 0.18, 0.16))
	for z in [-0.080, 0.0, 0.080]:
		_caja(
			iman, Vector3(-0.014, -0.030, z), Vector3(0.014, 0.22, 0.008), Color(0.20, 0.18, 0.16)
		)
	for z in [-0.105, 0.105]:
		_cilindro(
			iman,
			Vector3(-0.024, 0.155, z),
			0.024,
			0.016,
			Color(0.10, 0.18, 0.28),
			Vector3(0, 0, 90)
		)


static func _variante(objeto: Dictionary) -> String:
	var id := String(objeto.get("id", "")).to_lower()
	var categoria := String(objeto.get("categoria", "")).to_lower()
	if "lampara" in id:
		return VAR_LAMPARA
	if "marco" in id or "foto" in id:
		return VAR_MARCO
	if categoria in ["publicacion", "libro", "revista", "prensa"]:
		return VAR_PUBLICACION
	if "cassette" in id or "cinta" in id or categoria in ["audio", "cassette"]:
		return VAR_CINTA
	if "paquete" in id or "caja" in id or categoria in ["paquete", "correo"]:
		return VAR_PAQUETE
	if "ticket" in id or "carta" in id or categoria in ["documento", "papel"]:
		return VAR_PAPEL
	if "figur" in id or categoria in ["recuerdo", "regalo"]:
		return VAR_RECUERDO
	return VAR_UTIL


static func _lampara(raiz: Node3D) -> void:
	_cilindro(raiz, Vector3(0, -0.09, 0), 0.09, 0.04, Color(0.16, 0.28, 0.18))
	_cilindro(raiz, Vector3(0, 0.02, 0), 0.018, 0.20, Color(0.30, 0.31, 0.27))
	_cilindro_truncado(raiz, Vector3(0, 0.14, 0), 0.07, 0.12, 0.12, Color(0.24, 0.42, 0.27))


static func _marco(raiz: Node3D) -> void:
	_caja(raiz, Vector3.ZERO, Vector3(0.22, 0.28, 0.035), Color(0.48, 0.36, 0.16))
	_caja(raiz, Vector3(0, 0, -0.022), Vector3(0.16, 0.21, 0.012), Color(0.15, 0.13, 0.11))


static func _publicacion(raiz: Node3D, objeto: Dictionary) -> void:
	PublicacionFisica3D.montar(raiz, String(objeto.get("id", "")), true)


static func _cinta(raiz: Node3D) -> void:
	_caja(raiz, Vector3.ZERO, Vector3(0.22, 0.14, 0.045), Color(0.18, 0.18, 0.17))
	_cilindro(
		raiz, Vector3(-0.055, 0, -0.03), 0.032, 0.018, Color(0.60, 0.58, 0.50), Vector3(90, 0, 0)
	)
	_cilindro(
		raiz, Vector3(0.055, 0, -0.03), 0.032, 0.018, Color(0.60, 0.58, 0.50), Vector3(90, 0, 0)
	)


static func _paquete(raiz: Node3D) -> void:
	_caja(raiz, Vector3.ZERO, Vector3(0.24, 0.18, 0.18), Color(0.48, 0.36, 0.24))
	_caja(raiz, Vector3(0, 0.095, 0), Vector3(0.045, 0.012, 0.19), Color(0.28, 0.22, 0.17))
	_caja(raiz, Vector3(0, 0.095, 0), Vector3(0.25, 0.012, 0.04), Color(0.28, 0.22, 0.17))


static func _papel(raiz: Node3D) -> void:
	_caja(raiz, Vector3(-0.02, -0.08, 0), Vector3(0.22, 0.018, 0.16), Color(0.68, 0.64, 0.52))
	_caja(raiz, Vector3(0.025, -0.055, -0.01), Vector3(0.18, 0.016, 0.13), Color(0.57, 0.55, 0.47))


static func _recuerdo(raiz: Node3D) -> void:
	_cilindro(raiz, Vector3(0, -0.09, 0), 0.075, 0.035, Color(0.30, 0.26, 0.22))
	_cilindro_truncado(raiz, Vector3(0, 0.00, 0), 0.035, 0.055, 0.14, Color(0.34, 0.45, 0.53))
	_caja(raiz, Vector3(0, 0.09, 0), Vector3(0.10, 0.07, 0.08), Color(0.42, 0.52, 0.58))


static func _util(raiz: Node3D) -> void:
	_caja(raiz, Vector3.ZERO, Vector3(0.20, 0.16, 0.16), Color(0.34, 0.34, 0.31))
	_cilindro(
		raiz, Vector3(0.06, 0.02, -0.09), 0.026, 0.025, Color(0.64, 0.58, 0.38), Vector3(90, 0, 0)
	)


static func _caja(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)


static func _cilindro(
	raiz: Node3D,
	pos: Vector3,
	radio: float,
	alto: float,
	color: Color,
	rotacion: Vector3 = Vector3.ZERO
) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	malla.mesh = cilindro
	malla.position = pos
	malla.rotation_degrees = rotacion
	Modelos._pintar(malla, color)
	raiz.add_child(malla)


static func _cilindro_truncado(
	raiz: Node3D,
	pos: Vector3,
	radio_superior: float,
	radio_inferior: float,
	alto: float,
	color: Color
) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio_superior
	cilindro.bottom_radius = radio_inferior
	cilindro.height = alto
	malla.mesh = cilindro
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)
