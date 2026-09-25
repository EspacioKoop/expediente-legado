## Identidad histórica secundaria para avatares Rocketbox (#275).
##
## Mantiene intacta la cabeza, piel, cabello, ropa y texturas del avatar. Solo
## añade volúmenes/accesorios low-poly anclados al hueso Head para recuperar
## señales reconocibles que se perdieron al migrar desde persona.fbx.
##
## Cada pieza se coloca sobre los huesos faciales que trae Rocketbox —ojos,
## nariz, labio superior, cejas— leídos del rest del mismo esqueleto, y se
## dimensiona con la distancia entre los ojos. El origen de `Head` está en la
## base del cráneo, a la altura de la mandíbula: colocar a ojo desde ahí dejaba
## las gafas en las mejillas y el bigote bajo la barbilla.
extends RefCounted

const PERSONAJES := {
	"emperador": "Puyi",
	"aduanero_ny": "Herman Melville",
	"correspondencia": "Fernando Pessoa",
	"riegos": "Constantino Cavafis",
	"fielato": "Henri Rousseau",
}

## Distancia entre pupilas de referencia: la escala 1 de todas las medidas.
const INTEROCULAR := 0.064

## Rostro de un adulto Rocketbox en el espacio de `Head`, en metros. Se usa si
## a un avatar le falta algún hueso facial.
const ROSTRO_POR_DEFECTO := {
	"ojo_izq": Vector3(0.032, 0.120, 0.053),
	"ojo_der": Vector3(-0.032, 0.120, 0.053),
	"nariz": Vector3(0.0, 0.104, 0.108),
	"labio": Vector3(0.0, 0.067, 0.110),
	"ceja": Vector3(0.0, 0.140, 0.081),
}

const HUESOS_ROSTRO := {
	"ojo_izq": "LeftEye",
	"ojo_der": "RightEye",
	"nariz": "Bip01 MNose",
	"labio": "Bip01 MUpperLip",
	"ceja": "Bip01 MMiddleEyebrow",
}

const NEGRO := Color(0.04, 0.035, 0.03)
const CASTANO_OSCURO := Color(0.09, 0.07, 0.055)
const ENTRECANO := Color(0.17, 0.155, 0.14)
const CANAS := Color(0.47, 0.44, 0.40)
const GRIS_BARBA := Color(0.30, 0.28, 0.26)
const FIELTRO := Color(0.13, 0.12, 0.11)
const CINTA := Color(0.05, 0.045, 0.04)


static func aplicar(pieza: Node3D, retrato: String) -> void:
	var personaje := String(PERSONAJES.get(retrato, ""))
	if personaje.is_empty():
		return
	var esqueleto := _esqueleto(pieza)
	if esqueleto == null:
		return
	var cabeza := esqueleto.find_bone("Head")
	if cabeza < 0:
		return

	var r := rostro(esqueleto, cabeza)
	var enganche := BoneAttachment3D.new()
	enganche.name = "IdentidadHistorica275"
	enganche.bone_idx = cabeza
	esqueleto.add_child(enganche)
	esqueleto.set_meta("identidad_historica_275", retrato)

	match personaje:
		"Puyi":
			# Las gafas redondas de montura gruesa son todo el retrato.
			_gafas(enganche, r, "GafasPuyi", 0.0215, 0.0042, NEGRO)
		"Herman Melville":
			# 1885: barba entera y poblada, canosa, que tapa la boca.
			_barba(enganche, r, "BarbaMelville", CANAS, 1.35)
			_bigote(enganche, r, "BigoteMelville", CANAS, 1.25, 1.5)
		"Fernando Pessoa":
			_gafas(enganche, r, "GafasPessoa", 0.0185, 0.0022, NEGRO)
			_bigote(enganche, r, "BigotePessoa", CASTANO_OSCURO, 1.3, 0.62)
			_sombrero(enganche, r, "SombreroPessoa", FIELTRO)
		"Constantino Cavafis":
			# Afeitado en los retratos conocidos; lo reconocible son las gafas
			# y el pelo oscuro que le queda en sienes y nuca.
			_gafas(enganche, r, "GafasCavafis", 0.0200, 0.0030, NEGRO)
			_pelo(enganche, r, "PeloCavafis", ENTRECANO)
		"Henri Rousseau":
			# El autorretrato: barba recortada, bigote y boina de pintor.
			_barba(enganche, r, "BarbaRousseau", GRIS_BARBA, 1.0)
			_bigote(enganche, r, "BigoteRousseau", GRIS_BARBA, 1.2, 1.3)
			_boina(enganche, r, "BoinaRousseau", NEGRO)


## Puntos del rostro en el espacio del hueso Head (rest), más `k`, la escala
## relativa a una distancia entre ojos de [constant INTEROCULAR].
static func rostro(esqueleto: Skeleton3D, cabeza: int) -> Dictionary:
	var base := esqueleto.get_bone_global_rest(cabeza).affine_inverse()
	var puntos := ROSTRO_POR_DEFECTO.duplicate()
	for clave in HUESOS_ROSTRO:
		var hueso := esqueleto.find_bone(HUESOS_ROSTRO[clave])
		if hueso >= 0:
			puntos[clave] = base * esqueleto.get_bone_global_rest(hueso).origin
	var ojos: float = (puntos["ojo_izq"] as Vector3).distance_to(puntos["ojo_der"])
	puntos["k"] = clampf(ojos / INTEROCULAR, 0.8, 1.25)
	puntos["ojos"] = ((puntos["ojo_izq"] as Vector3) + (puntos["ojo_der"] as Vector3)) * 0.5
	return puntos


static func _grupo(padre: Node3D, nombre: String) -> Node3D:
	var grupo := Node3D.new()
	grupo.name = nombre
	padre.add_child(grupo)
	return grupo


## Gafas redondas delante de los ojos: dos aros, puente y patillas hasta la
## oreja. [param radio] y [param grosor] son del aro, en metros.
static func _gafas(
	padre: Node3D, r: Dictionary, nombre: String, radio: float, grosor: float, color: Color
) -> void:
	var grupo := _grupo(padre, nombre)
	var k: float = r["k"]
	var ojos: Vector3 = r["ojos"]
	var z := ojos.z + 0.026 * k
	var radio_k := radio * k
	for ojo in [r["ojo_izq"], r["ojo_der"]]:
		var centro := Vector3((ojo as Vector3).x * 1.02, ojo.y, z)
		_aro(grupo, centro, radio_k, grosor * k, color)
	var interior: float = absf((r["ojo_izq"] as Vector3).x) * 1.02 - radio_k
	_caja(
		grupo,
		Vector3(0.0, ojos.y + radio_k * 0.25, z),
		Vector3(interior * 2.0 + grosor * k, grosor * k, grosor * k),
		color
	)
	# Las patillas van por fuera de las sienes (la cabeza mide ~14 cm de ancho a
	# la altura de los ojos) hasta la oreja; una bisagra las une al aro.
	var borde: float = absf((r["ojo_izq"] as Vector3).x) * 1.02 + radio_k
	var sien := 0.073 * k
	var largo := z + 0.030 * k
	var y := ojos.y + radio_k * 0.3
	for lado in [-1.0, 1.0]:
		_caja(
			grupo,
			Vector3(lado * (borde + sien) * 0.5, y, z),
			Vector3(sien - borde + grosor * k, grosor * k, grosor * k),
			color
		)
		_caja(
			grupo,
			Vector3(lado * sien, y, z - largo * 0.5),
			Vector3(grosor * k * 0.8, grosor * k * 0.8, largo),
			color
		)


## Bigote bajo la nariz: dos mechones que caen hacia las comisuras.
static func _bigote(
	padre: Node3D, r: Dictionary, nombre: String, color: Color, ancho: float, grueso: float
) -> void:
	var grupo := _grupo(padre, nombre)
	var k: float = r["k"]
	var nariz: Vector3 = r["nariz"]
	var labio: Vector3 = r["labio"]
	var y := lerpf(labio.y, nariz.y, 0.36)
	var z := maxf(labio.z, nariz.z) + 0.001 * k
	for lado in [-1.0, 1.0]:
		var mechon := _esfera(
			grupo,
			Vector3(lado * 0.0115 * k * ancho, y, z),
			Vector3(0.0135 * k * ancho, 0.0048 * k * grueso, 0.0065 * k),
			color
		)
		mechon.rotation.z = lado * -0.28


## Barba entera: dos masas que siguen la mandíbula, del carrillo al mentón, y
## una tercera en el mentón, solapadas para leerse como una sola. Van hundidas
## en la cara, así que solo asoma el borde. [param volumen] es cuánto asoma;
## por debajo de 1 es una barba recortada.
static func _barba(
	padre: Node3D, r: Dictionary, nombre: String, color: Color, volumen: float
) -> void:
	var grupo := _grupo(padre, nombre)
	var k: float = r["k"]
	var labio: Vector3 = r["labio"]
	for lado in [-1.0, 1.0]:
		var carrillo := _esfera(
			grupo,
			Vector3(lado * 0.047 * k, labio.y - 0.022 * k * volumen, 0.022 * k),
			Vector3(0.020 * volumen, 0.042 * volumen, 0.046) * k,
			color
		)
		carrillo.rotation = Vector3(0.62, lado * 0.30, 0.0)
		# La quijada entre carrillo y mentón, para que no quede un hueco.
		_esfera(
			grupo,
			Vector3(lado * 0.031 * k, labio.y - 0.040 * k * volumen, 0.058 * k),
			Vector3(0.022, 0.026 * volumen, 0.030) * k,
			color
		)
	_esfera(
		grupo,
		Vector3(0.0, labio.y - 0.046 * k * volumen, labio.z - 0.030 * k),
		Vector3(0.044, 0.040 * volumen, 0.034 * volumen) * k,
		color
	)
	# Bajo el labio, la mosca que une bigote y mentón.
	_esfera(
		grupo,
		Vector3(0.0, labio.y - 0.020 * k, labio.z - 0.007 * k),
		Vector3(0.018, 0.012, 0.008) * k,
		color
	)


## Sombrero de fieltro de ala corta: copa con cinta, calado a la altura de la
## frente y un poco echado hacia atrás.
static func _sombrero(padre: Node3D, r: Dictionary, nombre: String, color: Color) -> void:
	var grupo := _grupo(padre, nombre)
	var k: float = r["k"]
	var ceja: Vector3 = r["ceja"]
	var base_y := ceja.y + 0.016 * k
	grupo.position = Vector3(0.0, base_y, -0.012 * k)
	grupo.rotation.x = -0.10
	var ala := MeshInstance3D.new()
	var malla_ala := CylinderMesh.new()
	malla_ala.top_radius = 0.128 * k
	malla_ala.bottom_radius = 0.128 * k
	malla_ala.height = 0.007 * k
	malla_ala.radial_segments = 16
	ala.mesh = malla_ala
	ala.scale = Vector3(0.92, 1.0, 1.08)
	ala.material_override = _material(color)
	grupo.add_child(ala)

	var copa := MeshInstance3D.new()
	var malla_copa := CylinderMesh.new()
	malla_copa.top_radius = 0.072 * k
	malla_copa.bottom_radius = 0.090 * k
	malla_copa.height = 0.078 * k
	malla_copa.radial_segments = 12
	copa.mesh = malla_copa
	copa.position = Vector3(0.0, 0.039 * k, 0.0)
	copa.scale = Vector3(0.94, 1.0, 1.16)
	copa.material_override = _material(color)
	grupo.add_child(copa)

	var cinta := MeshInstance3D.new()
	var malla_cinta := CylinderMesh.new()
	malla_cinta.top_radius = 0.089 * k
	malla_cinta.bottom_radius = 0.091 * k
	malla_cinta.height = 0.018 * k
	malla_cinta.radial_segments = 12
	cinta.mesh = malla_cinta
	cinta.position = Vector3(0.0, 0.013 * k, 0.0)
	cinta.scale = Vector3(0.95, 1.0, 1.17)
	cinta.material_override = _material(CINTA)
	grupo.add_child(cinta)
	# La hendidura del fieltro: lo que separa un sombrero de fieltro de una
	# chistera o un bombín a esta resolución.
	var hendidura := _esfera(
		grupo, Vector3(0.0, 0.079 * k, 0.0), Vector3(0.030, 0.010, 0.060) * k, CINTA
	)
	hendidura.name = "Hendidura"


## Boina de pintor, ladeada sobre la coronilla.
static func _boina(padre: Node3D, r: Dictionary, nombre: String, color: Color) -> void:
	var grupo := _grupo(padre, nombre)
	var k: float = r["k"]
	var ceja: Vector3 = r["ceja"]
	grupo.position = Vector3(0.010 * k, ceja.y + 0.052 * k, -0.036 * k)
	grupo.rotation = Vector3(-0.32, 0.0, -0.24)
	_esfera(grupo, Vector3.ZERO, Vector3(0.104 * k, 0.026 * k, 0.114 * k), color)


## Pelo oscuro sobre un avatar calvo: lo que le queda a un hombre de entradas,
## en las sienes, sobre las orejas y por la nuca. Nada por delante de la oreja
## ni por encima de la coronilla, que es donde un casquete se lee como casco.
static func _pelo(padre: Node3D, r: Dictionary, nombre: String, color: Color) -> void:
	var grupo := _grupo(padre, nombre)
	var k: float = r["k"]
	var ojos: Vector3 = r["ojos"]
	for lado in [-1.0, 1.0]:
		_esfera(
			grupo,
			Vector3(lado * 0.060 * k, ojos.y + 0.004 * k, -0.044 * k),
			Vector3(0.015, 0.026, 0.040) * k,
			color
		)
	_esfera(
		grupo, Vector3(0.0, ojos.y - 0.004 * k, -0.070 * k), Vector3(0.056, 0.034, 0.024) * k, color
	)


static func _aro(
	padre: Node3D, posicion: Vector3, radio: float, grosor: float, color: Color
) -> void:
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = maxf(radio * 0.2, radio - grosor)
	toro.outer_radius = radio
	toro.rings = 14
	toro.ring_segments = 4
	aro.mesh = toro
	aro.position = posicion
	aro.rotation.x = PI / 2.0
	aro.material_override = _material(color)
	padre.add_child(aro)


static func _caja(padre: Node3D, posicion: Vector3, tamano: Vector3, color: Color) -> void:
	var pieza := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tamano
	pieza.mesh = caja
	pieza.position = posicion
	pieza.material_override = _material(color)
	padre.add_child(pieza)


static func _esfera(
	padre: Node3D, posicion: Vector3, escala: Vector3, color: Color
) -> MeshInstance3D:
	var rasgo := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 10
	esfera.rings = 6
	rasgo.mesh = esfera
	rasgo.position = posicion
	rasgo.scale = escala
	rasgo.material_override = _material(color)
	padre.add_child(rasgo)
	return rasgo


static func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.shader_del_sitio())
	material.set_shader_parameter("color_base", color)
	material.set_meta("identidad_historica_275", true)
	return material


static func _esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null
