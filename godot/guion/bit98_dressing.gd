## Identidad visual física de Bit 98 (#676).
##
## Esta capa no conoce catálogo, precios ni economía. Solo viste la fachada y el
## interior ya creados por CalleLocalesComerciales3D y reutiliza las portadas que
## el proyecto ya usa para sus cartuchos propios.
class_name Bit98Dressing
extends RefCounted

const NOMBRE := "ArteBit98"
const ROTULO: Texture2D = preload("res://arte/bit98/rotulo_bit98.svg")
const CARTEL_JUEGA: Texture2D = preload("res://arte/bit98/cartel_juega.svg")
const CARTEL_SEGUNDA_MANO: Texture2D = preload("res://arte/bit98/cartel_segunda_mano.svg")
const CARTEL_NOVEDADES: Texture2D = preload("res://arte/bit98/cartel_novedades.svg")
const YGGDRASILS_EGG_ATREZZO: Texture2D = preload(
	"res://assets/texturas/yggdrasil_ai_98/yggdrasils_egg_atrezzo_98.webp"
)
const PORTADAS := [
	preload("res://arte/consola98/cartuchos/caza_pixeles_98.jpg"),
	preload("res://arte/consola98/cartuchos/paper_planes_98.jpg"),
	preload("res://arte/consola98/cartuchos/croc_riders_98.jpg"),
]


static func montar(calle: Node3D) -> Node3D:
	if calle == null:
		return null
	var existente := calle.get_node_or_null(NOMBRE) as Node3D
	if existente != null:
		return existente

	var raiz := Node3D.new()
	raiz.name = NOMBRE
	calle.add_child(raiz)

	var fachada := calle.get_node_or_null("TiendaVideojuegos") as Node3D
	if fachada != null:
		_montar_fachada(fachada)

	var locales := calle.get_node_or_null("LocalesComerciales") as Node3D
	if locales != null:
		var interior := locales.get_node_or_null("InteriorBit98") as Node3D
		if interior != null:
			_montar_interior(interior)
	return raiz


static func _montar_fachada(fachada: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "IdentidadBit98"
	fachada.add_child(grupo)

	_lamina(
		grupo,
		"RotuloBit98Exterior",
		ROTULO,
		Vector3(5.34, 2.70, -6.50),
		Vector2(3.45, 0.86),
		-90.0,
	)
	_texto_cartel(
		grupo,
		"TextoRotuloBit98Exterior",
		"BIT 98",
		Vector3(5.28, 2.76, -6.68),
		-90.0,
		Color(0.95, 0.92, 0.84),
		64,
		0.0062,
	)
	_texto_cartel(
		grupo,
		"SubtituloBit98Exterior",
		"VIDEOJUEGOS · CONSOLAS · PC",
		Vector3(5.28, 2.47, -6.68),
		-90.0,
		Color(0.86, 0.76, 0.48),
		28,
		0.0026,
	)
	_lamina(
		grupo,
		"CartelNovedadesExterior",
		CARTEL_NOVEDADES,
		Vector3(5.33, 1.58, -7.98),
		Vector2(0.62, 0.80),
		-90.0,
	)
	_texto_cartel(
		grupo,
		"TextoNovedadesExterior",
		"NOVEDADES",
		Vector3(5.27, 1.62, -7.98),
		-90.0,
		Color(0.94, 0.91, 0.84),
		28,
		0.0019,
	)
	_lamina(
		grupo,
		"CartelSegundaManoExterior",
		CARTEL_SEGUNDA_MANO,
		Vector3(5.33, 1.56, -6.32),
		Vector2(0.82, 0.61),
		-90.0,
	)
	_texto_cartel(
		grupo,
		"TextoSegundaManoExterior",
		"2ª MANO",
		Vector3(5.27, 1.58, -6.32),
		-90.0,
		Color(0.18, 0.16, 0.13),
		30,
		0.0022,
	)


static func _montar_interior(interior: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "IdentidadBit98"
	interior.add_child(grupo)

	_lamina(
		grupo,
		"RotuloBit98Interior",
		ROTULO,
		Vector3(0.0, 2.45, -3.93),
		Vector2(3.55, 0.88),
		0.0,
	)
	_texto_cartel(
		grupo,
		"TextoRotuloBit98Interior",
		"BIT 98",
		Vector3(0.0, 2.51, -3.87),
		0.0,
		Color(0.95, 0.92, 0.84),
		70,
		0.0062,
	)
	_lamina(
		grupo,
		"CartelJuegaInterior",
		CARTEL_JUEGA,
		Vector3(-2.20, 1.48, -3.92),
		Vector2(0.88, 1.17),
		0.0,
	)
	_texto_cartel(
		grupo,
		"TextoJuegaInterior",
		"JUEGA\nEXPLORA\nCOLECCIONA",
		Vector3(-2.20, 1.48, -3.86),
		0.0,
		Color(0.94, 0.91, 0.84),
		36,
		0.0040,
	)
	_lamina(
		grupo,
		"CartelSegundaManoInterior",
		CARTEL_SEGUNDA_MANO,
		Vector3(2.15, 1.56, -3.92),
		Vector2(1.12, 0.83),
		0.0,
	)
	_texto_cartel(
		grupo,
		"TextoSegundaManoInterior",
		"SEGUNDA\nMANO",
		Vector3(2.15, 1.56, -3.86),
		0.0,
		Color(0.18, 0.16, 0.13),
		36,
		0.0040,
	)

	_texto_cartel(
		grupo,
		"TextoNovedadesInterior",
		"NOVEDADES",
		Vector3(0.0, 1.94, -3.86),
		0.0,
		Color(0.86, 0.76, 0.48),
		34,
		0.0030,
	)
	for indice in PORTADAS.size():
		_lamina_alto(
			grupo,
			"PortadaDestacada_%d" % indice,
			PORTADAS[indice],
			Vector3(-1.08 + float(indice) * 1.08, 1.47, -3.84),
			0.72,
			0.0,
		)

	var expositor := Node3D.new()
	expositor.name = "ExpositorPortadasPropias"
	grupo.add_child(expositor)
	for lado in 2:
		var x := -3.10 if lado == 0 else 3.10
		var giro := 90.0 if lado == 0 else -90.0
		for indice in PORTADAS.size():
			var z := -1.35 + float(indice) * 1.35
			_lamina_alto(
				expositor,
				"PortadaPropia_%d_%d" % [lado, indice],
				PORTADAS[indice],
				Vector3(x, 1.52, z),
				0.72,
				giro,
			)

	# Producto ficticio de 1998, solo atrezzo: no entra en RomsPropias ni en
	# TiendaVideojuegos y, por tanto, no tiene precio, stock ni ROM asociada.
	var huevo := _lamina_alto(
		grupo,
		"YggdrasilsEggAtrezzo98",
		YGGDRASILS_EGG_ATREZZO,
		Vector3(1.55, 1.45, -2.22),
		0.66,
		-18.0,
	)
	var material_huevo := huevo.material_override as StandardMaterial3D
	if material_huevo != null:
		material_huevo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


static func _texto_cartel(
	padre: Node3D,
	nombre: String,
	texto: String,
	pos: Vector3,
	giro_y: float,
	color: Color,
	tamano: int,
	pixel: float,
) -> Label3D:
	var etiqueta := Label3D.new()
	etiqueta.name = nombre
	etiqueta.text = texto
	etiqueta.position = pos
	etiqueta.rotation_degrees.y = giro_y
	etiqueta.font = EstiloSiga.fuente_mono()
	etiqueta.font_size = tamano
	etiqueta.pixel_size = pixel
	etiqueta.modulate = color
	etiqueta.outline_size = 6
	etiqueta.outline_modulate = Color(0.03, 0.03, 0.04)
	etiqueta.shaded = false
	etiqueta.double_sided = true
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	padre.add_child(etiqueta)
	return etiqueta


static func _lamina_alto(
	padre: Node3D,
	nombre: String,
	textura: Texture2D,
	pos: Vector3,
	alto: float,
	giro_y: float,
) -> MeshInstance3D:
	var ancho := alto
	if textura != null and textura.get_height() > 0:
		ancho = alto * float(textura.get_width()) / float(textura.get_height())
	return _lamina(padre, nombre, textura, pos, Vector2(ancho, alto), giro_y)


static func _lamina(
	padre: Node3D,
	nombre: String,
	textura: Texture2D,
	pos: Vector3,
	tam: Vector2,
	giro_y: float,
) -> MeshInstance3D:
	var lamina := MeshInstance3D.new()
	lamina.name = nombre
	lamina.position = pos
	lamina.rotation_degrees.y = giro_y
	lamina.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var plano := QuadMesh.new()
	plano.size = tam
	lamina.mesh = plano

	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	lamina.material_override = material
	padre.add_child(lamina)
	return lamina
