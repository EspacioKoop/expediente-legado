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

const PeloCapas := preload("res://guion/pelo_capas.gd")

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
			# 1885: barba entera, poblada y canosa, que baja hasta el cuello y
			# se come la boca por arriba.
			_barba(
				esqueleto,
				r,
				"BarbaMelville",
				0.085,
				{
					"capas": 8,
					"largo": 0.019,
					"caida": 1.0,
					"densidad": 150.0,
					"raiz": Color(0.58, 0.56, 0.52),
					"punta": Color(0.80, 0.78, 0.74),
					"variacion": 0.18,
					"cobertura": 0.95,
				}
			)
			_bigote(
				esqueleto,
				r,
				"BigoteMelville",
				1.0,
				{
					"capas": 6,
					"largo": 0.013,
					"caida": 1.4,
					"densidad": 170.0,
					"raiz": Color(0.55, 0.53, 0.50),
					"punta": Color(0.78, 0.76, 0.72),
					"variacion": 0.15,
					"cobertura": 1.0,
				}
			)
		"Fernando Pessoa":
			_gafas(enganche, r, "GafasPessoa", 0.0185, 0.0022, NEGRO)
			_bigote(
				esqueleto,
				r,
				"BigotePessoa",
				0.8,
				{
					"capas": 7,
					"largo": 0.006,
					"caida": 0.9,
					"densidad": 120.0,
					"raiz": Color(0.10, 0.08, 0.065),
					"punta": Color(0.17, 0.14, 0.11),
					"variacion": 0.1,
					"cobertura": 1.0,
				}
			)
			_sombrero(enganche, r, "SombreroPessoa", FIELTRO)
		"Constantino Cavafis":
			# Afeitado en los retratos conocidos; lo reconocible son las gafas
			# redondas y el pelo oscuro peinado hacia atrás.
			_gafas(enganche, r, "GafasCavafis", 0.0200, 0.0030, NEGRO)
			_pelo(
				esqueleto,
				r,
				"PeloCavafis",
				{
					"capas": 9,
					"largo": 0.010,
					"caida": 0.5,
					"densidad": 190.0,
					"raiz": Color(0.13, 0.115, 0.10),
					"punta": Color(0.24, 0.21, 0.19),
					"variacion": 0.12,
					"cobertura": 1.0,
				}
			)
		"Henri Rousseau":
			# El autorretrato: barba recortada, bigote y boina de pintor.
			_barba(
				esqueleto,
				r,
				"BarbaRousseau",
				0.07,
				{
					"capas": 6,
					"largo": 0.009,
					"caida": 0.7,
					"densidad": 170.0,
					"raiz": Color(0.44, 0.42, 0.40),
					"punta": Color(0.64, 0.62, 0.58),
					"variacion": 0.18,
					"cobertura": 0.95,
				}
			)
			_bigote(
				esqueleto,
				r,
				"BigoteRousseau",
				1.0,
				{
					"capas": 5,
					"largo": 0.010,
					"caida": 1.2,
					"densidad": 180.0,
					"raiz": Color(0.40, 0.38, 0.36),
					"punta": Color(0.60, 0.58, 0.55),
					"variacion": 0.15,
					"cobertura": 1.0,
				}
			)
			_boina(enganche, r, "BoinaRousseau", Color(0.09, 0.09, 0.11))


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
	var z := ojos.z + 0.031 * k
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


## Barba entera por capas: desde la patilla, por los carrillos y bajo la
## línea del pómulo, hasta [param alcance] metros por debajo del labio. Deja
## libres los labios y el bigote, que va aparte.
static func _barba(
	esqueleto: Skeleton3D, r: Dictionary, nombre: String, alcance: float, opciones: Dictionary
) -> MeshInstance3D:
	return PeloCapas.crear(
		esqueleto, nombre, func(p: Vector3) -> float: return mascara_barba(p, r, alcance), opciones
	)


## Bigote por capas sobre el labio superior. [param ancho] 1 llega a las
## comisuras; por debajo, un bigote más corto.
static func _bigote(
	esqueleto: Skeleton3D, r: Dictionary, nombre: String, ancho: float, opciones: Dictionary
) -> MeshInstance3D:
	return PeloCapas.crear(
		esqueleto, nombre, func(p: Vector3) -> float: return mascara_bigote(p, r, ancho), opciones
	)


## Pelo corto por capas en coronilla, sienes y nuca, con la línea del
## nacimiento en la frente y sin tapar las orejas.
static func _pelo(
	esqueleto: Skeleton3D, r: Dictionary, nombre: String, opciones: Dictionary
) -> MeshInstance3D:
	return PeloCapas.crear(
		esqueleto, nombre, func(p: Vector3) -> float: return mascara_pelo(p, r), opciones
	)


static func mascara_barba(p: Vector3, r: Dictionary, alcance: float) -> float:
	var k: float = r["k"]
	var ojos: Vector3 = r["ojos"]
	var labio: Vector3 = r["labio"]
	var x := absf(p.x) / k
	# Línea superior: de la comisura sube por el carrillo hasta la patilla.
	var tope := lerpf(
		labio.y + 0.004 * k, ojos.y - 0.042 * k, clampf((x - 0.020) / 0.042, 0.0, 1.0)
	)
	# La patilla: una franja estrecha delante de la oreja.
	if x > 0.060 and p.z > -0.024 * k and p.z < 0.004 * k:
		tope = ojos.y + 0.004 * k
	var arriba := _escalon(tope + 0.005 * k, tope - 0.005 * k, p.y)
	# Por detrás de la oreja no hay barba.
	var delante := _escalon(-0.030 * k, -0.016 * k, p.z)
	# Por debajo, hasta el cuello.
	var fondo := _escalon(labio.y - alcance - 0.010 * k, labio.y - alcance + 0.010 * k, p.y)
	# Los labios quedan libres.
	var boca := 1.0
	if p.z > labio.z - 0.030 * k:
		var d := pow(p.x / (0.026 * k), 2.0) + pow((p.y - labio.y + 0.009 * k) / (0.013 * k), 2.0)
		boca = _escalon(0.75, 1.35, d)
	# El bigote es otra máscara.
	var bigote := 1.0 - _escalon(0.0, 1.0, mascara_bigote(p, r, 1.0) * 4.0)
	return arriba * delante * fondo * boca * bigote


static func mascara_bigote(p: Vector3, r: Dictionary, ancho: float) -> float:
	var k: float = r["k"]
	var labio: Vector3 = r["labio"]
	var x := absf(p.x) / k
	if p.z < labio.z - 0.028 * k:
		return 0.0
	var lateral := _escalon(0.030 * ancho + 0.004, 0.030 * ancho - 0.004, x)
	# Pegado al labio, y en las puntas cae hacia la comisura.
	var suelo := labio.y + lerpf(-0.006, -0.011, clampf((x - 0.014) / 0.02, 0.0, 1.0)) * k
	var techo := labio.y + 0.002 * k
	# La franja es estrecha: sin reforzar, la máscara casi nunca llega a 1 y el
	# bigote sale deshilachado entero.
	var valor := (
		lateral
		* _escalon(suelo - 0.002 * k, suelo + 0.002 * k, p.y)
		* _escalon(techo + 0.003 * k, techo - 0.003 * k, p.y)
	)
	return clampf(valor * 4.0, 0.0, 1.0)


static func mascara_pelo(p: Vector3, r: Dictionary) -> float:
	var k: float = r["k"]
	var ojos: Vector3 = r["ojos"]
	var ceja: Vector3 = r["ceja"]
	var labio: Vector3 = r["labio"]
	# El nacimiento baja de la frente a la nuca según se va hacia atrás.
	var atras := clampf((0.030 * k - p.z) / (0.110 * k), 0.0, 1.0)
	var linea := lerpf(ceja.y + 0.036 * k, labio.y - 0.004 * k, atras)
	var pelo := _escalon(linea - 0.006 * k, linea + 0.006 * k, p.y)
	# Las orejas, libres.
	if absf(p.x) > 0.058 * k and p.y < ojos.y + 0.016 * k and p.z > -0.050 * k:
		pelo *= 1.0 - _escalon(-0.050 * k, -0.036 * k, p.z)
	return clampf(pelo * 1.6, 0.0, 1.0)


static func _escalon(desde: float, hasta: float, x: float) -> float:
	return smoothstep(desde, hasta, x) if desde < hasta else 1.0 - smoothstep(hasta, desde, x)


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
