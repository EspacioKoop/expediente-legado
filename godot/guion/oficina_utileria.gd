## Utilería procedural para que los puestos del archivo parezcan usados antes de
## abrir ningún HUD (#400).
##
## No añade reglas: teclados, teléfonos, bandejas, tazas y cableado son dressing.
## Los CRT ya los aporta el primer corte #401; aquí se completa su contexto sin
## duplicarlos. La única interacción nueva es la máquina de café.
class_name OficinaUtileria
extends RefCounted

const COLOR_PERIFERICO := Color(0.64, 0.62, 0.56)
const COLOR_TELEFONO := Color(0.20, 0.20, 0.19)
const COLOR_BANDEJA := Color(0.31, 0.29, 0.25)
const COLOR_PAPEL := Color(0.82, 0.80, 0.72)
const COLOR_CAFE := Color(0.68, 0.66, 0.58)
const COLOR_CABLE := Color(0.08, 0.08, 0.08)
const COLOR_CARTON := Color(0.48, 0.36, 0.23)
const COLOR_AGENDA := Color(0.22, 0.27, 0.24)
const COLOR_LIBRETA := Color(0.74, 0.69, 0.56)
const COLOR_METAL := Color(0.42, 0.43, 0.40)
const COLOR_PLASTICO := Color(0.31, 0.30, 0.27)
const COLOR_VERDE := Color(0.23, 0.38, 0.20)
const COLOR_MACETA := Color(0.46, 0.28, 0.17)
const COLOR_TERMO := Color(0.49, 0.50, 0.47)

const PUESTOS := [
	Vector3(-4.0, 0.0, -2.0),
	Vector3(-4.0, 0.0, 1.0),
	Vector3(1.0, 0.0, -2.0),
	Vector3(1.0, 0.0, 1.0),
]

## Tres ranuras al fondo de la mesa: fuera del teclado, monitor y teléfono.
const RANURAS_PROPS := [
	Vector3(-0.54, 0.82, -0.30),
	Vector3(0.48, 0.82, -0.31),
	Vector3(-0.08, 0.82, -0.33),
]

## Los cinco históricos solo reciben objetos derivados de lo que ya documenta
## Companeros: archivo/editor, aduanas, correspondencia, riegos y pintura.
## No hay nombres, fotos familiares, ciudades ni texto que invente biografía.
const PERFILES_HISTORICOS := {
	"emperador": ["caja", "agenda", "portalapices"],
	"aduanero_ny": ["sello", "libreta", "llavero"],
	"correspondencia": ["sobre", "agenda", "portalapices"],
	"riegos": ["regla", "calculadora", "libreta"],
	"fielato": ["cuaderno_dibujo", "portalapices", "agenda"],
}

## El resto mantiene combinaciones ambientales neutras. El índice hace que un
## puesto se reconozca aun cuando no haya nadie sentado.
const PERFILES_NEUTROS := [
	["portalapices", "agenda", "planta"],
	["libreta", "calculadora", "funda_gafas"],
	["caja", "termo", "llavero"],
	["sobre", "regla", "planta"],
]


static func montar(raiz: Node3D, precio_cafe: int = 0) -> void:
	for i in PUESTOS.size():
		_montar_puesto(raiz, i, PUESTOS[i], _companero_del_puesto(raiz, PUESTOS[i]))
	# #1472: identidad burocrática visual en la mesa de clasificación; sin datos de caso.\n	PapeleriaSiga98.montar_mesa_clasificacion(raiz)\n	_montar_maquina_cafe(raiz, precio_cafe)


## Monta un único puesto en coordenadas arbitrarias, sin la planta de #400 ni
## la máquina de café. Lo usa el diorama del menú de inicio (#830), que solo
## necesita un escritorio reconocible y no la oficina entera.
static func montar_puesto_aislado(raiz: Node3D, base: Vector3, indice: int = 0) -> void:
	_montar_puesto(raiz, indice, base, "")


## Expone la taza procedural como pieza reutilizable para composiciones ligeras
## (p. ej. el diorama de inicio #830) sin duplicar geometría/materiales.
static func agregar_taza(raiz: Node3D, pos: Vector3) -> MeshInstance3D:
	return _agregar_taza(raiz, pos)


static func _montar_puesto(
	raiz: Node3D, indice: int, base: Vector3, companero_id: String = ""
) -> void:
	var puesto := Node3D.new()
	puesto.name = "PuestoUtileria%d" % (indice + 1)
	puesto.position = base
	raiz.add_child(puesto)

	# El teclado está delante del monitor y hace legible el escritorio como
	# puesto de trabajo incluso desde el pasillo central.
	_agregar_caja(
		puesto, "Teclado", Vector3(0.18, 0.79, 0.20), Vector3(0.58, 0.055, 0.22), COLOR_PERIFERICO
	)
	_agregar_caja(
		puesto,
		"CableTeclado",
		Vector3(0.18, 0.785, -0.02),
		Vector3(0.035, 0.025, 0.28),
		COLOR_CABLE
	)

	# El teléfono cambia de lado entre puestos para romper la repetición de la
	# planta sin fingir que cada mesa pertenece a un personaje concreto.
	var lado := -0.70 if indice % 2 == 0 else 0.70
	_agregar_caja(
		puesto, "TelefonoBase", Vector3(lado, 0.82, 0.12), Vector3(0.36, 0.10, 0.28), COLOR_TELEFONO
	)
	_agregar_caja(
		puesto, "Auricular", Vector3(lado, 0.91, 0.12), Vector3(0.42, 0.08, 0.10), COLOR_TELEFONO
	)

	# Alterna bandejas y taza: cuatro escritorios idénticos siguen pareciendo
	# un decorado aunque tengan muchos polígonos.
	if indice % 2 == 0:
		_agregar_bandeja(puesto, Vector3(-0.62, 0.81, -0.24))
	else:
		_agregar_taza(puesto, Vector3(-0.58, 0.86, -0.22))
	_montar_perfil_personal(puesto, indice, companero_id)


## Asocia cada mesa con el cuerpo que realmente está a su lado. El cuñado se
## ignora aquí: está de pie fuera de la alineación de tres puestos ocupados y no
## debe apropiarse por proximidad del puesto jugable.
static func _companero_del_puesto(raiz: Node3D, base: Vector3) -> String:
	var elegido := ""
	var mejor := 1.8
	var objetivo := raiz.to_global(base)
	for nodo in raiz.find_children("*", "Node3D", true, false):
		if not nodo.has_meta("companero_id"):
			continue
		var id := String(nodo.get_meta("companero_id", ""))
		if id.is_empty() or id == "cunado":
			continue
		var distancia := (nodo as Node3D).global_position.distance_to(objetivo)
		if distancia < mejor:
			mejor = distancia
			elegido = id
	return elegido


static func _montar_perfil_personal(puesto: Node3D, indice: int, companero_id: String) -> void:
	var perfil: Array = PERFILES_HISTORICOS.get(
		companero_id, PERFILES_NEUTROS[indice % PERFILES_NEUTROS.size()]
	)
	puesto.set_meta(
		"perfil_props", companero_id if not companero_id.is_empty() else "neutral_%d" % indice
	)
	for i in mini(perfil.size(), RANURAS_PROPS.size()):
		_agregar_prop(puesto, String(perfil[i]), RANURAS_PROPS[i])


static func _agregar_prop(raiz: Node3D, tipo: String, pos: Vector3) -> void:
	match tipo:
		"portalapices":
			agregar_portalapices(raiz, pos)
		"agenda":
			agregar_agenda(raiz, pos)
		"libreta":
			agregar_libreta(raiz, pos)
		"caja":
			agregar_caja_personal(raiz, pos)
		"calculadora":
			agregar_calculadora(raiz, pos)
		"funda_gafas":
			agregar_funda_gafas(raiz, pos)
		"planta":
			agregar_planta(raiz, pos)
		"llavero":
			agregar_llavero(raiz, pos)
		"termo":
			agregar_termo(raiz, pos)
		"sobre":
			agregar_sobre(raiz, pos)
		"sello":
			agregar_sello(raiz, pos)
		"regla":
			agregar_regla(raiz, pos)
		"cuaderno_dibujo":
			agregar_cuaderno_dibujo(raiz, pos)


## Vocabulario público y reutilizable de utilería. Son piezas pequeñas,
## geométricas y sin texto; no añaden colisión ni interacción.
static func agregar_portalapices(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "Portalapices", pos)
	_agregar_cilindro(prop, "VasoLapices", Vector3(0, 0.055, 0), 0.055, 0.11, COLOR_PLASTICO)
	for x in [-0.025, 0.0, 0.025]:
		_agregar_cilindro(prop, "Lapiz", Vector3(x, 0.145, 0), 0.006, 0.16, COLOR_CARTON)
	return prop


static func agregar_agenda(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "AgendaCerrada", pos)
	_agregar_caja(
		prop, "CuerpoAgenda", Vector3(0, 0.025, 0), Vector3(0.22, 0.05, 0.16), COLOR_AGENDA
	)
	_agregar_caja(
		prop, "LomoAgenda", Vector3(-0.105, 0.052, 0), Vector3(0.012, 0.018, 0.15), COLOR_METAL
	)
	return prop


static func agregar_libreta(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "Libreta", pos)
	_agregar_caja(
		prop, "HojasLibreta", Vector3(0, 0.018, 0), Vector3(0.20, 0.035, 0.14), COLOR_LIBRETA
	)
	_agregar_caja(
		prop, "EspiralLibreta", Vector3(-0.096, 0.043, 0), Vector3(0.012, 0.018, 0.13), COLOR_METAL
	)
	return prop


static func agregar_caja_personal(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "CajaPersonal", pos)
	_agregar_caja(prop, "CajaCarton", Vector3(0, 0.06, 0), Vector3(0.23, 0.12, 0.17), COLOR_CARTON)
	_agregar_caja(
		prop,
		"TapaCaja",
		Vector3(0, 0.125, 0),
		Vector3(0.24, 0.018, 0.18),
		COLOR_CARTON.lightened(0.06)
	)
	return prop


static func agregar_calculadora(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "Calculadora", pos)
	_agregar_caja(
		prop, "CuerpoCalculadora", Vector3(0, 0.025, 0), Vector3(0.17, 0.05, 0.12), COLOR_PLASTICO
	)
	_agregar_caja(
		prop,
		"PantallaCalculadora",
		Vector3(0, 0.055, -0.035),
		Vector3(0.11, 0.012, 0.025),
		Color(0.18, 0.24, 0.18)
	)
	return prop


static func agregar_funda_gafas(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "FundaGafas", pos)
	_agregar_caja(
		prop,
		"EstucheGafas",
		Vector3(0, 0.03, 0),
		Vector3(0.18, 0.06, 0.075),
		Color(0.20, 0.18, 0.16)
	)
	return prop


static func agregar_planta(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "PlantaPequena", pos)
	_agregar_cilindro(prop, "Maceta", Vector3(0, 0.05, 0), 0.065, 0.10, COLOR_MACETA)
	_agregar_cilindro(prop, "Tallo", Vector3(0, 0.145, 0), 0.012, 0.10, COLOR_VERDE.darkened(0.12))
	_agregar_esfera(prop, "Hojas", Vector3(-0.03, 0.21, 0), 0.06, COLOR_VERDE)
	_agregar_esfera(prop, "Hojas", Vector3(0.035, 0.205, 0.01), 0.055, COLOR_VERDE.lightened(0.05))
	return prop


static func agregar_llavero(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "Llavero", pos)
	_agregar_caja(
		prop, "CabezaLlave", Vector3(-0.045, 0.012, 0), Vector3(0.055, 0.02, 0.05), COLOR_METAL
	)
	_agregar_caja(
		prop, "VastagoLlave", Vector3(0.025, 0.012, 0), Vector3(0.10, 0.014, 0.018), COLOR_METAL
	)
	return prop


static func agregar_termo(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "Termo", pos)
	_agregar_cilindro(prop, "CuerpoTermo", Vector3(0, 0.11, 0), 0.055, 0.22, COLOR_TERMO)
	_agregar_cilindro(prop, "TapaTermo", Vector3(0, 0.235, 0), 0.05, 0.035, COLOR_PLASTICO)
	return prop


static func agregar_sobre(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "SobreInterno", pos)
	_agregar_caja(prop, "PapelSobre", Vector3(0, 0.012, 0), Vector3(0.22, 0.024, 0.13), COLOR_PAPEL)
	_agregar_caja(
		prop,
		"SolapaSobre",
		Vector3(0, 0.027, -0.035),
		Vector3(0.17, 0.006, 0.045),
		COLOR_PAPEL.darkened(0.05)
	)
	return prop


static func agregar_sello(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "SelloCaucho", pos)
	_agregar_caja(
		prop, "BaseSello", Vector3(0, 0.018, 0), Vector3(0.10, 0.035, 0.06), Color(0.18, 0.15, 0.12)
	)
	_agregar_cilindro(prop, "MangoSello", Vector3(0, 0.085, 0), 0.022, 0.10, COLOR_CARTON)
	return prop


static func agregar_regla(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "Regla", pos)
	_agregar_caja(
		prop,
		"ReglaSinTexto",
		Vector3(0, 0.009, 0),
		Vector3(0.25, 0.018, 0.025),
		Color(0.66, 0.57, 0.35)
	)
	return prop


static func agregar_cuaderno_dibujo(raiz: Node3D, pos: Vector3) -> Node3D:
	var prop := _grupo_prop(raiz, "CuadernoDibujoCerrado", pos)
	_agregar_caja(
		prop, "Cuaderno", Vector3(0, 0.025, 0), Vector3(0.21, 0.05, 0.15), Color(0.50, 0.48, 0.41)
	)
	_agregar_caja(
		prop, "LapizDibujo", Vector3(0, 0.058, 0.07), Vector3(0.20, 0.012, 0.012), COLOR_CARTON
	)
	return prop


static func _grupo_prop(raiz: Node3D, nombre: String, pos: Vector3) -> Node3D:
	var grupo := Node3D.new()
	grupo.name = nombre
	grupo.position = pos
	raiz.add_child(grupo)
	return grupo


static func _agregar_bandeja(raiz: Node3D, pos: Vector3) -> void:
	var bandeja := Node3D.new()
	bandeja.name = "BandejaEntrada"
	bandeja.position = pos
	raiz.add_child(bandeja)
	_agregar_caja(bandeja, "BaseBandeja", Vector3.ZERO, Vector3(0.44, 0.045, 0.32), COLOR_BANDEJA)
	_agregar_caja(
		bandeja, "PapelBandeja", Vector3(0, 0.035, 0), Vector3(0.36, 0.025, 0.25), COLOR_PAPEL
	)


static func _agregar_taza(raiz: Node3D, pos: Vector3) -> MeshInstance3D:
	var taza := MeshInstance3D.new()
	taza.name = "TazaPuesto"
	var malla := CylinderMesh.new()
	malla.top_radius = 0.085
	malla.bottom_radius = 0.075
	malla.height = 0.18
	taza.mesh = malla
	taza.position = pos
	_aplicar_material(taza, COLOR_CAFE)
	raiz.add_child(taza)
	return taza


static func _montar_maquina_cafe(raiz: Node3D, precio_cafe: int) -> void:
	var maquina := MaquinaCafeInteractiva3D.new()
	maquina.name = "MaquinaCafeInteractuable"
	# Coincide con el bulto de la máquina ya declarado en EspaciosCatalogo.
	maquina.position = Vector3(-6.0, 0.75, 4.2)
	raiz.add_child(maquina)
	maquina.configurar(precio_cafe)


static func _agregar_caja(
	raiz: Node3D, nombre: String, pos: Vector3, tam: Vector3, color: Color
) -> void:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	_aplicar_material(malla, color)
	raiz.add_child(malla)


static func _agregar_cilindro(
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
	_aplicar_material(nodo, color)
	raiz.add_child(nodo)
	return nodo


static func _agregar_esfera(
	raiz: Node3D, nombre: String, pos: Vector3, radio: float, color: Color
) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var esfera := SphereMesh.new()
	esfera.radius = radio
	esfera.height = radio * 2.0
	esfera.radial_segments = 8
	esfera.rings = 4
	nodo.mesh = esfera
	nodo.position = pos
	_aplicar_material(nodo, color)
	raiz.add_child(nodo)
	return nodo


static func _aplicar_material(malla: MeshInstance3D, color: Color) -> void:
	Modelos._pintar(malla, color)
