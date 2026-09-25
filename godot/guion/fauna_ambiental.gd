## Catálogo y reparto reproducible de fauna ambiental (#1396).
##
## No hay estado persistente ni IA global: qué animales aparecen y dónde es una
## función de la fase, el día y la raíz de la partida. El gato sistémico vive en
## #787 y no forma parte de este catálogo.
class_name FaunaAmbiental
extends RefCounted

const FASE_CALLE := "trayecto"
const FASE_SUENO := "sueño"

const ESPECIES := {
	"paloma": {
		"movimiento": "suelo_ave",
		"escala": 1.0,
		"color": Color(0.42, 0.44, 0.48),
	},
	"gorrion": {
		"movimiento": "suelo_ave",
		"escala": 0.72,
		"color": Color(0.40, 0.31, 0.23),
	},
	"perro": {
		"movimiento": "deambular",
		"escala": 1.0,
		"color": Color(0.42, 0.28, 0.16),
	},
	"cuervo": {
		"movimiento": "vuelo",
		"escala": 1.18,
		"color": Color(0.035, 0.04, 0.055),
	},
	"polilla": {
		"movimiento": "orbita",
		"escala": 1.55,
		"color": Color(0.64, 0.58, 0.46),
	},
	"ciervo": {
		"movimiento": "deambular",
		"escala": 1.12,
		"color": Color(0.36, 0.25, 0.16),
	},
}

const CALLE_BASE := [
	{"especie": "paloma", "pos": Vector3(2.58, 0.10, -8.0)},
	{"especie": "paloma", "pos": Vector3(2.92, 0.10, -7.15)},
	{"especie": "paloma", "pos": Vector3(-2.72, 0.10, 5.75)},
	{"especie": "gorrion", "pos": Vector3(-3.02, 0.24, -1.6)},
	{"especie": "gorrion", "pos": Vector3(3.04, 0.24, 8.7)},
	{"especie": "perro", "pos": Vector3(-2.65, 0.28, 11.2)},
]

const SUENO_ESPECIES := ["cuervo", "cuervo", "polilla", "polilla", "polilla", "ciervo"]


static func ficha(especie: String) -> Dictionary:
	return Dictionary(ESPECIES.get(especie, {})).duplicate(true)


static func plan(
	fase: String,
	espacio: Dictionary,
	dia: int,
	raiz: int,
	contexto: String = "",
) -> Array[Dictionary]:
	if fase == FASE_CALLE:
		return _plan_calle(dia, raiz)
	if fase == FASE_SUENO:
		return _plan_sueno(espacio, dia, raiz, contexto)
	return []


static func _plan_calle(dia: int, raiz: int) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for i in CALLE_BASE.size():
		var base: Dictionary = CALLE_BASE[i]
		var especie := String(base["especie"])
		var semilla := Azar.derivar_texto(
			raiz, "presentacion", "fauna:calle:%s" % especie, [dia, i]
		)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var posicion: Vector3 = base["pos"]
		posicion.x += rng.randf_range(-0.14, 0.14)
		posicion.z += rng.randf_range(-0.55, 0.55)
		resultado.append(
			_dato(
				"fauna:calle:%s:%d" % [especie, i],
				especie,
				posicion,
				rng.randf_range(0.0, TAU),
			)
		)
	return resultado


static func _plan_sueno(
	espacio: Dictionary, dia: int, raiz: int, contexto: String
) -> Array[Dictionary]:
	var sitios := _sitios_sueno(espacio, SUENO_ESPECIES.size())
	var resultado: Array[Dictionary] = []
	for i in mini(sitios.size(), SUENO_ESPECIES.size()):
		var especie := String(SUENO_ESPECIES[i])
		var semilla := Azar.derivar_texto(
			raiz, "presentacion", "fauna:sueno:%s:%s" % [contexto, especie], [dia, i]
		)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var posicion: Vector3 = sitios[i]
		match especie:
			"cuervo":
				posicion.y += 1.55 + rng.randf_range(-0.12, 0.25)
			"polilla":
				posicion.y += 1.45 + rng.randf_range(-0.18, 0.30)
			"ciervo":
				posicion.y += 0.78
		resultado.append(
			_dato(
				"fauna:sueno:%s:%s:%d" % [contexto, especie, i],
				especie,
				posicion,
				rng.randf_range(0.0, TAU),
			)
		)
	return resultado


static func _dato(id: String, especie: String, posicion: Vector3, fase: float) -> Dictionary:
	var especie_ficha := ficha(especie)
	return {
		"id": id,
		"especie": especie,
		"pos": posicion,
		"fase": fase,
		"movimiento": String(especie_ficha.get("movimiento", "quieto")),
		"escala": float(especie_ficha.get("escala", 1.0)),
		"color": especie_ficha.get("color", Color.WHITE),
	}


## Coloca la fauna nocturna a lo largo del recorrido entrada -> salida. No añade
## navegación ni zonas físicas, así que incluso una sala poligonal conserva su
## autoridad geométrica intacta.
static func _sitios_sueno(espacio: Dictionary, cantidad: int) -> Array[Vector3]:
	var sitios: Array[Vector3] = []
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salida := entrada + Vector3(0.0, 0.0, -8.0)
	var salidas: Array = espacio.get("salidas", [])
	if not salidas.is_empty():
		salida = Dictionary(salidas[0]).get("pos", salida)
	if entrada.distance_to(salida) < 0.5:
		salida = entrada + Vector3(0.0, 0.0, -8.0)

	var direccion := salida - entrada
	var lateral := Vector3(-direccion.z, 0.0, direccion.x).normalized()
	for i in cantidad:
		var avance := float(i + 1) / float(cantidad + 1)
		var posicion := entrada.lerp(salida, avance)
		# Oscilación pequeña: separa siluetas sin fabricar rutas alternativas.
		if not lateral.is_zero_approx():
			posicion += lateral * (0.32 if i % 2 == 0 else -0.32)
		sitios.append(posicion)
	return sitios
