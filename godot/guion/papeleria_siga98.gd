## Biblioteca procedural de papelería burocrática SIGA-98 (#1472).
##
## Todo se construye con geometría simple y color: no hay texto, imágenes ni
## datos de expedientes. Las variantes se derivan de una semilla explícita para
## que la escena sea estable y no compita con la fuente de verdad documental.
class_name PapeleriaSiga98
extends RefCounted

const FAMILIAS := [
	"formulario_a4",
	"formulario_a5",
	"multicopia",
	"carpeta",
	"separadores",
	"sobre_interno",
	"sello_tampon",
	"consumibles",
	"bandejas",
	"lomos_expediente",
]

const COLOR_PAPEL := Color(0.83, 0.81, 0.73)
const COLOR_PAPEL_CALIDO := Color(0.86, 0.82, 0.70)
const COLOR_TINTA_FALSA := Color(0.34, 0.35, 0.33)
const COLOR_CARTULINA := [
	Color(0.47, 0.42, 0.31),
	Color(0.37, 0.43, 0.37),
	Color(0.46, 0.35, 0.31),
	Color(0.35, 0.38, 0.44),
]
const COLOR_COPIA := [
	Color(0.84, 0.80, 0.68),
	Color(0.78, 0.68, 0.66),
	Color(0.76, 0.79, 0.66),
]
const COLOR_BANDA := [
	Color(0.47, 0.50, 0.44),
	Color(0.50, 0.42, 0.37),
	Color(0.39, 0.45, 0.50),
]
const COLOR_METAL := Color(0.43, 0.44, 0.42)
const COLOR_GOMA := Color(0.20, 0.16, 0.13)
const COLOR_TAMPON := Color(0.24, 0.23, 0.22)
const COLOR_NOTA := [
	Color(0.72, 0.67, 0.40),
	Color(0.62, 0.68, 0.48),
	Color(0.69, 0.56, 0.45),
]


static func familias() -> PackedStringArray:
	return PackedStringArray(FAMILIAS)


## Viste únicamente la mesa de clasificación ya existente en EspaciosCatalogo.
## El conjunto es idempotente para que capturas/tests puedan llamar al dressing
## más de una vez sin apilar copias.
static func montar_mesa_clasificacion(raiz: Node3D, semilla: int = 98) -> Node3D:
	var existente := raiz.get_node_or_null("PapeleriaSiga98")
	if existente is Node3D:
		return existente

	var conjunto := Node3D.new()
	conjunto.name = "PapeleriaSiga98"
	conjunto.set_meta("familias_visuales", FAMILIAS.size())
	conjunto.set_meta("semilla_visual", semilla)
	raiz.add_child(conjunto)

	agregar_formulario_a4(conjunto, Vector3(3.10, 0.895, -0.28), semilla + 1)
	agregar_formulario_a5(conjunto, Vector3(3.31, 0.900, -0.31), semilla + 2)
	agregar_multicopia(conjunto, Vector3(3.56, 0.900, -0.29), semilla + 3)
	agregar_carpeta(conjunto, Vector3(3.84, 0.905, -0.27), semilla + 4)
	agregar_separadores(conjunto, Vector3(4.07, 0.905, -0.22), semilla + 5)
	agregar_sobre_interno(conjunto, Vector3(3.09, 0.900, 0.25), semilla + 6)
	agregar_sello_tampon(conjunto, Vector3(3.37, 0.900, 0.27), semilla + 7)
	agregar_consumibles(conjunto, Vector3(3.58, 0.900, 0.29), semilla + 8)
	agregar_bandejas(conjunto, semilla + 9)
	agregar_lomos_expediente(conjunto, Vector3(4.07, 0.905, 0.27), semilla + 10)
	return conjunto


static func agregar_formulario_a4(raiz: Node3D, pos: Vector3, semilla: int = 0) -> Node3D:
	return _agregar_formulario(raiz, "FormularioA4", pos, Vector2(0.19, 0.27), semilla)


static func agregar_formulario_a5(raiz: Node3D, pos: Vector3, semilla: int = 0) -> Node3D:
	return _agregar_formulario(raiz, "FormularioA5", pos, Vector2(0.14, 0.19), semilla)


static func agregar_multicopia(raiz: Node3D, pos: Vector3, semilla: int = 0) -> Node3D:
	var grupo := _grupo(raiz, "FormularioMulticopia", pos)
	for i in range(3):
		var color: Color = COLOR_COPIA[_indice(semilla, i, COLOR_COPIA.size())]
		_caja(
			grupo,
			"Copia%d" % (i + 1),
			Vector3(float(i) * 0.010, float(i) * 0.006, float(i) * 0.006),
			Vector3(0.18, 0.006, 0.24),
			color
		)
	_caja(\n		grupo,\n		"BandaMulticopia",\n		Vector3(0.0, 0.024, -0.075),\n		Vector3(0.16, 0.004, 0.018),\n		_tono(COLOR_BANDA, semilla, 2)\n	)
	return grupo


static func agregar_carpeta(raiz: Node3D, pos: Vector3, semilla: int = 0) -> Node3D:
	var grupo := _grupo(raiz, "CarpetaCartulina", pos)
	var color := _tono(COLOR_CARTULINA, semilla, 0)
	_caja(grupo, "BaseCarpeta", Vector3.ZERO, Vector3(0.22, 0.012, 0.28), color)
	_caja(\n		grupo,\n		"SolapaCarpeta",\n		Vector3(0.07, 0.010, -0.135),\n		Vector3(0.075, 0.018, 0.035),\n		color.lightened(0.05)\n	)
	_caja(\n		grupo,\n		"EtiquetaSinTexto",\n		Vector3(-0.045, 0.010, -0.115),\n		Vector3(0.08, 0.004, 0.020),\n		COLOR_PAPEL_CALIDO\n	)
	return grupo


static func agregar_separadores(raiz: Node3D, pos: Vector3, semilla: int = 0) -> Node3D:
	var grupo := _grupo(raiz, "Separadores", pos)
	for i in range(4):
		var color := _tono(COLOR_BANDA, semilla, i)
		var z := float(i) * 0.025
		_caja(\n			grupo,\n			"Separador%d" % (i + 1),\n			Vector3(0.0, float(i) * 0.004, z),\n			Vector3(0.17, 0.006, 0.19),\n			COLOR_PAPEL\n		)
		_caja(\n			grupo,\n			"Pestana%d" % (i + 1),\n			Vector3(0.07, 0.006 + float(i) * 0.004, z - 0.075),\n			Vector3(0.055, 0.006, 0.025),\n			color\n		)
	return grupo


static func agregar_sobre_interno(raiz: Node3D, pos: Vector3, semilla: int = 0) -> Node3D:
	var grupo := _grupo(raiz, "SobreInternoDetallado", pos)
	var papel := COLOR_PAPEL_CALIDO.darkened(0.02 * float(_indice(semilla, 1, 3)))
	_caja(grupo, "CuerpoSobre", Vector3.ZERO, Vector3(0.21, 0.012, 0.13), papel)
	_caja(\n		grupo,\n		"SolapaSobre",\n		Vector3(0.0, 0.009, -0.037),\n		Vector3(0.16, 0.005, 0.045),\n		papel.darkened(0.05)\n	)
	_caja(\n		grupo,\n		"MarcaRutaSinTexto",\n		Vector3(0.052, 0.012, 0.030),\n		Vector3(0.065, 0.004, 0.012),\n		_tono(COLOR_BANDA, semilla, 4)\n	)
	return grupo


static func agregar_sello_tampon(raiz: Node3D, pos: Vector3, semilla: int = 0) -> Node3D:
	var grupo := _grupo(raiz, "SelloYTampon", pos)
	_caja(\n		grupo,\n		"TamponCerrado",\n		Vector3(-0.055, 0.018, 0.0),\n		Vector3(0.11, 0.036, 0.085),\n		COLOR_TAMPON\n	)
	_caja(grupo, "BaseSello", Vector3(0.065, 0.022, 0.0), Vector3(0.075, 0.042, 0.052), COLOR_GOMA)
	var mango := _cilindro(\n		grupo,\n		"MangoSello",\n		Vector3(0.065, 0.080, 0.0),\n		0.018,\n		0.090,\n		_tono(COLOR_CARTULINA, semilla, 2)\n	)
	mango.rotation_degrees.z = 5.0 * float(_indice(semilla, 3, 3) - 1)
	return grupo


static func agregar_consumibles(raiz: Node3D, pos: Vector3, semilla: int = 0) -> Node3D:
	var grupo := _grupo(raiz, "ClipsGrapasNotas", pos)
	var nota := _tono(COLOR_NOTA, semilla, 0)
	_caja(grupo, "NotaAdhesiva", Vector3(-0.045, 0.006, 0.0), Vector3(0.075, 0.008, 0.075), nota)
	for i in range(3):
		_caja(
			grupo,
			"Clip%d" % (i + 1),
			Vector3(0.035 + float(i) * 0.020, 0.008, -0.020 + float(i % 2) * 0.025),
			Vector3(0.032, 0.006, 0.008),
			COLOR_METAL
		)
	_caja(\n		grupo,\n		"Grapas",\n		Vector3(0.065, 0.010, 0.045),\n		Vector3(0.055, 0.012, 0.018),\n		COLOR_METAL.darkened(0.08)\n	)
	return grupo


## Los dos volúmenes base ya existen en EspaciosCatalogo. Aquí solo se añaden
## rebordes y códigos de color no textuales: se detallan sin duplicar las bases.
static func agregar_bandejas(raiz: Node3D, semilla: int = 0) -> Node3D:
	var grupo := _grupo(raiz, "BandejasEntradaSalida", Vector3.ZERO)
	var centros := [Vector3(3.32, 0.855, -0.12), Vector3(3.88, 0.865, 0.12)]
	for i in range(2):
		var centro: Vector3 = centros[i]
		var color := _tono(COLOR_BANDA, semilla, i)
		_caja(\n			grupo,\n			"BordeLargoA%d" % i,\n			centro + Vector3(-0.22, 0.0, 0.0),\n			Vector3(0.025, 0.055, 0.32),\n			color\n		)
		_caja(\n			grupo,\n			"BordeLargoB%d" % i,\n			centro + Vector3(0.22, 0.0, 0.0),\n			Vector3(0.025, 0.055, 0.32),\n			color\n		)
		_caja(\n			grupo,\n			"CodigoVisual%d" % i,\n			centro + Vector3(0.0, 0.032, -0.13),\n			Vector3(0.12, 0.006, 0.025),\n			color.lightened(0.08)\n		)
	return grupo


static func agregar_lomos_expediente(raiz: Node3D, pos: Vector3, semilla: int = 0) -> Node3D:
	var grupo := _grupo(raiz, "LomosExpediente", pos)
	for i in range(3):
		var color := _tono(COLOR_CARTULINA, semilla, i)
		var x := (float(i) - 1.0) * 0.055
		_caja(\n			grupo,\n			"Expediente%d" % (i + 1),\n			Vector3(x, float(i) * 0.010, 0.0),\n			Vector3(0.048, 0.035, 0.20),\n			color\n		)
		_caja(\n			grupo,\n			"BandaLomo%d" % (i + 1),\n			Vector3(x, 0.020 + float(i) * 0.010, -0.045),\n			Vector3(0.050, 0.006, 0.025),\n			_tono(COLOR_BANDA, semilla, i + 2)\n		)
	return grupo


static func _agregar_formulario(
	raiz: Node3D, nombre: String, pos: Vector3, tam: Vector2, semilla: int
) -> Node3D:
	var grupo := _grupo(raiz, nombre, pos)
	var papel := COLOR_PAPEL.lerp(COLOR_PAPEL_CALIDO, float(_indice(semilla, 0, 4)) * 0.08)
	_caja(grupo, "Hoja", Vector3.ZERO, Vector3(tam.x, 0.008, tam.y), papel)
	var banda := _tono(COLOR_BANDA, semilla, 1)
	_caja(\n		grupo,\n		"CabeceraGrafica",\n		Vector3(0.0, 0.007, -tam.y * 0.34),\n		Vector3(tam.x * 0.82, 0.004, tam.y * 0.055),\n		banda\n	)
	for i in range(3):
		var ancho := tam.x * (0.25 + 0.10 * float((i + semilla) % 3))
		var z := -tam.y * 0.13 + float(i) * tam.y * 0.16
		_caja(\n			grupo,\n			"BloqueGrafico%d" % i,\n			Vector3(-tam.x * 0.15, 0.007, z),\n			Vector3(ancho, 0.003, tam.y * 0.022),\n			COLOR_TINTA_FALSA\n		)
		_caja(\n			grupo,\n			"Casilla%d" % i,\n			Vector3(tam.x * 0.32, 0.007, z),\n			Vector3(tam.x * 0.065, 0.003, tam.x * 0.065),\n			COLOR_TINTA_FALSA\n		)
	return grupo


static func _grupo(raiz: Node3D, nombre: String, pos: Vector3) -> Node3D:
	var grupo := Node3D.new()
	grupo.name = nombre
	grupo.position = pos
	raiz.add_child(grupo)
	return grupo


static func _caja(
	raiz: Node3D, nombre: String, pos: Vector3, tam: Vector3, color: Color
) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	nodo.mesh = caja
	nodo.position = pos
	Modelos._pintar(nodo, color)
	raiz.add_child(nodo)
	return nodo


static func _cilindro(
	raiz: Node3D, nombre: String, pos: Vector3, radio: float, alto: float, color: Color
) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	cilindro.radial_segments = 8
	nodo.mesh = cilindro
	nodo.position = pos
	Modelos._pintar(nodo, color)
	raiz.add_child(nodo)
	return nodo


static func _tono(paleta: Array, semilla: int, salto: int) -> Color:
	return paleta[_indice(semilla, salto, paleta.size())]


static func _indice(semilla: int, salto: int, cantidad: int) -> int:
	return posmod(semilla * 31 + salto * 17, cantidad)
