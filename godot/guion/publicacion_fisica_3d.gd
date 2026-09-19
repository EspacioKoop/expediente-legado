## Representación física común de las publicaciones de #674.
##
## No posee inventario, economía ni lectura. Solo traduce una entrada del catálogo
## de Publicaciones98 a una gramática 3D estable, reutilizable antes y después de
## recoger el ejemplar. Portada/lomo son texto del mundo, no UI.
class_name PublicacionFisica3D
extends RefCounted

const IDENTIDAD := {
	"revista_umbral_98": {"cabecera": "UMBRAL", "edicion": "Nº 17 · 1998"},
	"libro_popol_wuj_98": {"cabecera": "CUADERNO CULTURAL", "edicion": "POPOL WUJ · 1998"},
	"periodico_tarde_98": {"cabecera": "LA TARDE LOCAL", "edicion": "EDICIÓN DE TARDE · 1998"},
	"byte_domestico_42": {"cabecera": "BYTE DOMÉSTICO", "edicion": "Nº 42 · 1998"},
	"marcador_98_deportes": {"cabecera": "MARCADOR 98", "edicion": "JORNADA 9"},
	"estratos_ciudad_06": {"cabecera": "ESTRATOS Y CIUDAD", "edicion": "CUADERNO 6"},
	"manual_casa_98": {"cabecera": "ARREGLOS DE CASA", "edicion": "EDICIÓN 98"},
}


static func montar(raiz: Node3D, item_id: String, con_colision: bool = false) -> Dictionary:
	var ficha := Publicaciones98.por_id(item_id)
	if ficha.is_empty():
		return {}
	var formato := formato_de(ficha)
	var paleta := paleta_de(item_id)
	var tam := Vector3(0.21, 0.026, 0.155)

	match formato:
		"periodico":
			tam = Vector3(0.27, 0.020, 0.20)
			_periodico(raiz, tam, paleta)
		"libro":
			tam = Vector3(0.18, 0.055, 0.14)
			_libro(raiz, tam, paleta)
		_:
			_revista(raiz, tam, paleta)

	_rotular(raiz, item_id, formato, tam, paleta)
	if con_colision:
		_colision(raiz, tam)
	raiz.set_meta("acabado_publicacion", "editorial_98")
	raiz.set_meta("cabecera_publicacion", cabecera_de(item_id))
	raiz.set_meta("edicion_publicacion", edicion_de(item_id))
	return {"id": item_id, "formato": formato, "tam": tam}


static func formato_de(ficha: Dictionary) -> String:
	match String(ficha.get("categoria", "")):
		"prensa_general":
			return "periodico"
		"guia_practica", "cultura_kiche":
			return "libro"
		_:
			return "revista"


static func cabecera_de(item_id: String) -> String:
	var identidad: Dictionary = IDENTIDAD.get(item_id, {})
	if not identidad.is_empty():
		return String(identidad.get("cabecera", ""))
	var ficha := Publicaciones98.por_id(item_id)
	return String(ficha.get("titulo", item_id)).to_upper()


static func edicion_de(item_id: String) -> String:
	var identidad: Dictionary = IDENTIDAD.get(item_id, {})
	return String(identidad.get("edicion", "1998"))


static func paleta_de(item_id: String) -> Array[Color]:
	match item_id:
		"revista_umbral_98":
			return [Color(0.25, 0.14, 0.18), Color(0.68, 0.50, 0.24), Color(0.12, 0.13, 0.16)]
		"libro_popol_wuj_98":
			return [Color(0.24, 0.20, 0.14), Color(0.69, 0.58, 0.35), Color(0.18, 0.30, 0.29)]
		"periodico_tarde_98":
			return [Color(0.68, 0.65, 0.56), Color(0.28, 0.32, 0.38), Color(0.48, 0.18, 0.16)]
		"byte_domestico_42":
			return [Color(0.18, 0.28, 0.38), Color(0.64, 0.62, 0.48), Color(0.20, 0.48, 0.45)]
		"marcador_98_deportes":
			return [Color(0.22, 0.42, 0.26), Color(0.75, 0.72, 0.54), Color(0.48, 0.18, 0.16)]
		"estratos_ciudad_06":
			return [Color(0.50, 0.38, 0.24), Color(0.25, 0.20, 0.17), Color(0.68, 0.58, 0.40)]
		"manual_casa_98":
			return [Color(0.50, 0.47, 0.32), Color(0.22, 0.30, 0.22), Color(0.72, 0.67, 0.48)]
		_:
			return [Color(0.42, 0.22, 0.18), Color(0.58, 0.53, 0.36), Color(0.28, 0.36, 0.46)]


static func _revista(raiz: Node3D, tam: Vector3, paleta: Array[Color]) -> void:
	_caja(raiz, "CuerpoPublicacion", Vector3.ZERO, tam, paleta[0])
	_caja(
		raiz,
		"LomoColor",
		Vector3(-tam.x * 0.47, 0, 0),
		Vector3(tam.x * 0.06, tam.y * 1.15, tam.z),
		paleta[1]
	)
	_caja(
		raiz,
		"BloquePortada",
		Vector3(tam.x * 0.12, tam.y * 0.62, -tam.z * 0.22),
		Vector3(tam.x * 0.64, 0.006, tam.z * 0.28),
		paleta[2]
	)


static func _periodico(raiz: Node3D, tam: Vector3, paleta: Array[Color]) -> void:
	_caja(raiz, "CuerpoPublicacion", Vector3.ZERO, tam, paleta[0])
	_caja(
		raiz,
		"CabeceraColor",
		Vector3(0, tam.y * 0.66, tam.z * 0.28),
		Vector3(tam.x * 0.90, 0.006, tam.z * 0.25),
		paleta[1]
	)
	_caja(
		raiz,
		"FotoPortada",
		Vector3(-tam.x * 0.20, tam.y * 0.70, -tam.z * 0.23),
		Vector3(tam.x * 0.36, 0.006, tam.z * 0.34),
		paleta[2]
	)
	for x in [-0.02, 0.045, 0.105]:
		_caja(
			raiz,
			"Columna%03d" % int((x + 0.2) * 1000.0),
			Vector3(x, tam.y * 0.70, -tam.z * 0.23),
			Vector3(0.006, 0.005, tam.z * 0.32),
			paleta[1]
		)


static func _libro(raiz: Node3D, tam: Vector3, paleta: Array[Color]) -> void:
	_caja(raiz, "CuerpoPublicacion", Vector3.ZERO, tam, paleta[0])
	_caja(
		raiz,
		"LomoColor",
		Vector3(-tam.x * 0.48, 0, 0),
		Vector3(tam.x * 0.08, tam.y * 1.08, tam.z),
		paleta[1]
	)
	_caja(
		raiz,
		"MarcoPortada",
		Vector3(tam.x * 0.07, tam.y * 0.58, 0),
		Vector3(tam.x * 0.72, 0.008, tam.z * 0.72),
		paleta[2]
	)


static func _rotular(
	raiz: Node3D, item_id: String, formato: String, tam: Vector3, paleta: Array[Color]
) -> void:
	var cabecera := _texto_mundo(cabecera_de(item_id), paleta[1], 32)
	cabecera.name = "TituloPortada"
	cabecera.position = Vector3(0, tam.y * 0.78, tam.z * 0.25)
	cabecera.rotation_degrees = Vector3(-90, 0, 0)
	cabecera.width = 280
	raiz.add_child(cabecera)

	var edicion := _texto_mundo(edicion_de(item_id), paleta[1], 22)
	edicion.name = "EdicionPortada"
	edicion.position = Vector3(0, tam.y * 0.80, -tam.z * 0.36)
	edicion.rotation_degrees = Vector3(-90, 0, 0)
	edicion.width = 260
	raiz.add_child(edicion)

	if formato == "periodico":
		return
	var lomo := _texto_mundo(cabecera_de(item_id), paleta[1], 24)
	lomo.name = "LomoPublicacion"
	lomo.position = Vector3(-tam.x * 0.505, 0, 0)
	lomo.rotation_degrees = Vector3(0, 90, 90)
	lomo.width = 220
	raiz.add_child(lomo)


static func _texto_mundo(texto: String, color: Color, tamano: int) -> Label3D:
	var etiqueta := Label3D.new()
	etiqueta.text = texto
	etiqueta.font = EstiloSiga.fuente_mono()
	etiqueta.font_size = tamano
	etiqueta.pixel_size = 0.0012
	etiqueta.modulate = color
	etiqueta.outline_size = 6
	etiqueta.outline_modulate = Color(0, 0, 0, 0.80)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.shaded = false
	etiqueta.fixed_size = false
	return etiqueta


static func _caja(raiz: Node3D, nombre: String, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)


static func _colision(raiz: Node3D, tam: Vector3) -> void:
	if not raiz is Interactuable3D:
		return
	var colision := CollisionShape3D.new()
	colision.name = "ColisionPublicacion"
	var forma := BoxShape3D.new()
	forma.size = tam + Vector3(0.04, 0.06, 0.04)
	colision.shape = forma
	raiz.add_child(colision)
