## Catálogo y reparto reproducible de fauna ambiental (#1396, #1411).
##
## No hay estado persistente ni IA global: qué animales aparecen y dónde es una
## función de fase, día, raíz y contexto ambiental. El gato sistémico vive en
## #787 y no forma parte de este catálogo.
class_name FaunaAmbiental
extends RefCounted

const FASE_CALLE := "trayecto"
const FASE_SUENO := "sueño"

const ESPECIES := {
	"paloma":
	{
		"movimiento": "suelo_ave",
		"escala": 1.0,
		"color": Color(0.42, 0.44, 0.48),
		"reaccion": "huir",
		"distancia_alerta": 2.6,
		"intensidad_reaccion": 1.10,
	},
	"gorrion":
	{
		"movimiento": "suelo_ave",
		"escala": 0.72,
		"color": Color(0.40, 0.31, 0.23),
		"reaccion": "huir",
		"distancia_alerta": 2.2,
		"intensidad_reaccion": 1.35,
	},
	"perro":
	{
		"movimiento": "deambular",
		"escala": 1.0,
		"color": Color(0.42, 0.28, 0.16),
		"reaccion": "observar",
		"distancia_alerta": 3.8,
		"intensidad_reaccion": 0.0,
	},
	"cuervo":
	{
		"movimiento": "vuelo",
		"escala": 1.18,
		"color": Color(0.035, 0.04, 0.055),
		"reaccion": "huir",
		"distancia_alerta": 3.4,
		"intensidad_reaccion": 0.75,
	},
	"polilla":
	{
		"movimiento": "orbita",
		"escala": 1.55,
		"color": Color(0.64, 0.58, 0.46),
		"reaccion": "subir",
		"distancia_alerta": 2.6,
		"intensidad_reaccion": 0.55,
	},
	"ciervo":
	{
		"movimiento": "deambular",
		"escala": 1.12,
		"color": Color(0.36, 0.25, 0.16),
		"reaccion": "vigilar",
		"distancia_alerta": 6.5,
		"intensidad_reaccion": 0.0,
	},
}

## Dos acabados por especie. Son parámetros, no modelos nuevos: la silueta y el
## coste geométrico de #1407 se mantienen y solo cambia la lectura del ejemplar.
const VARIANTES := {
	"paloma":
	[
		{"id": "ceniza", "color": Color(0.46, 0.48, 0.52), "escala": 0.97, "acabado": 0.02},
		{"id": "pizarra", "color": Color(0.31, 0.34, 0.40), "escala": 1.04, "acabado": -0.06},
	],
	"gorrion":
	[
		{"id": "calido", "color": Color(0.44, 0.32, 0.21), "escala": 0.96, "acabado": 0.02},
		{"id": "apagado", "color": Color(0.31, 0.28, 0.24), "escala": 1.03, "acabado": 0.05},
	],
	"perro":
	[
		{"id": "canela", "color": Color(0.46, 0.29, 0.15), "escala": 0.98, "acabado": 0.01},
		{"id": "oscuro", "color": Color(0.24, 0.20, 0.18), "escala": 1.06, "acabado": 0.04},
	],
	"cuervo":
	[
		{"id": "mate", "color": Color(0.028, 0.032, 0.043), "escala": 0.98, "acabado": 0.04},
		{"id": "azulado", "color": Color(0.035, 0.055, 0.080), "escala": 1.04, "acabado": -0.10},
	],
	"polilla":
	[
		{"id": "beige", "color": Color(0.66, 0.59, 0.46), "escala": 0.96, "acabado": 0.03},
		{"id": "ceniza_lunar", "color": Color(0.70, 0.72, 0.68), "escala": 1.08, "acabado": -0.12},
	],
	"ciervo":
	[
		{"id": "castano", "color": Color(0.37, 0.25, 0.16), "escala": 1.00, "acabado": 0.02},
		{
			"id": "palido_onirico",
			"color": Color(0.62, 0.60, 0.54),
			"escala": 1.05,
			"acabado": -0.08
		},
	],
}

const CALLE_BASE := [
	{"especie": "paloma", "pos": Vector3(2.58, 0.10, -8.0)},
	{"especie": "paloma", "pos": Vector3(2.92, 0.10, -7.15)},
	{"especie": "paloma", "pos": Vector3(-2.72, 0.10, 5.75)},
	{"especie": "gorrion", "pos": Vector3(-3.02, 0.24, -1.6)},
	{"especie": "gorrion", "pos": Vector3(3.04, 0.24, 8.7)},
	{"especie": "perro", "pos": Vector3(-4.72, 0.19, 11.2)},
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
	clima: String = "",
	franja: String = "",
) -> Array[Dictionary]:
	if fase == FASE_CALLE:
		return _plan_calle(dia, raiz, clima, franja)
	if fase == FASE_SUENO:
		return _plan_sueno(espacio, dia, raiz, contexto)
	return []


static func _plan_calle(dia: int, raiz: int, clima: String, franja: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for i in CALLE_BASE.size():
		var base: Dictionary = CALLE_BASE[i]
		var especie := String(base["especie"])
		if not _incluir_calle(especie, i, clima, franja):
			continue
		var semilla := Azar.derivar_texto(
			raiz, "presentacion", "fauna:calle:%s" % especie, [dia, i]
		)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var posicion: Vector3 = base["pos"]
		posicion.x += rng.randf_range(-0.14, 0.14)
		posicion.z += rng.randf_range(-0.55, 0.55)
		(
			resultado
			. append(
				_dato(
					"fauna:calle:%s:%d" % [especie, i],
					especie,
					posicion,
					rng.randf_range(0.0, TAU),
					rng,
					false,
					clima,
					franja,
				)
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
				posicion.y += 0.10
		(
			resultado
			. append(
				_dato(
					"fauna:sueno:%s:%s:%d" % [contexto, especie, i],
					especie,
					posicion,
					rng.randf_range(0.0, TAU),
					rng,
					true,
				)
			)
		)
	return resultado


static func _incluir_calle(especie: String, indice: int, clima: String, franja: String) -> bool:
	if especie == "gorrion":
		if clima == Clima.LLUVIA or clima == Clima.NIEVE or franja == "noche":
			return indice == 3
	if especie == "paloma" and franja == "noche" and indice == 2:
		return false
	return true


static func _dato(
	id: String,
	especie: String,
	posicion: Vector3,
	fase: float,
	rng: RandomNumberGenerator,
	onirico: bool = false,
	clima: String = "",
	franja: String = "",
) -> Dictionary:
	var especie_ficha := ficha(especie)
	var variante := _variante(especie, rng, onirico)
	var escala := float(especie_ficha.get("escala", 1.0)) * float(variante.get("escala", 1.0))
	return {
		"id": id,
		"especie": especie,
		"pos": posicion,
		"fase": fase,
		"movimiento": String(especie_ficha.get("movimiento", "quieto")),
		"escala": escala,
		"color": variante.get("color", especie_ficha.get("color", Color.WHITE)),
		"variante": String(variante.get("id", "base")),
		"acabado": float(variante.get("acabado", 0.0)),
		"ritmo": _ritmo_contextual(especie, clima, franja, onirico),
		"onirico": onirico,
		"reaccion": String(especie_ficha.get("reaccion", "ninguna")),
		"distancia_alerta": float(especie_ficha.get("distancia_alerta", 0.0)),
		"intensidad_reaccion": float(especie_ficha.get("intensidad_reaccion", 0.0)),
	}


static func _variante(especie: String, rng: RandomNumberGenerator, onirico: bool) -> Dictionary:
	var opciones: Array = VARIANTES.get(especie, [])
	if opciones.is_empty():
		return {}
	var indice := rng.randi_range(0, opciones.size() - 1)
	if onirico and especie == "ciervo":
		indice = mini(1, opciones.size() - 1)
	return Dictionary(opciones[indice]).duplicate(true)


static func _ritmo_contextual(
	especie: String, clima: String, franja: String, onirico: bool
) -> float:
	if onirico:
		match especie:
			"cuervo":
				return 0.92
			"polilla":
				return 1.12
			"ciervo":
				return 0.56
	if especie == "perro":
		if clima == Clima.LLUVIA:
			return 0.42
		if clima == Clima.NIEVE:
			return 0.55
		if franja == "noche":
			return 0.72
	if especie == "paloma" or especie == "gorrion":
		if clima == Clima.LLUVIA:
			return 0.72
		if clima == Clima.NIEVE:
			return 0.80
		if franja == "noche":
			return 0.82
	return 1.0


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
		if not lateral.is_zero_approx():
			posicion += lateral * (0.32 if i % 2 == 0 else -0.32)
		sitios.append(posicion)
	return sitios
