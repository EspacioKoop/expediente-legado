## Cinemáticas largas y psicodélicas construidas con el reproductor común.
##
## Cada secuencia cambia de decorado varias veces y reutiliza figuras humanas
## como ecos. No hay autoplay: la vertical que detecte un momento excepcional
## decide cuándo reproducirlas.
class_name CinematicasPsicodelicas
extends RefCounted

const EXPEDIENTE_SUENA := "psico-expediente-suena"
const COMITE_IMPOSIBLE := "psico-comite-imposible"
const ARCHIVO_BAJO_LA_CIUDAD := "psico-archivo-bajo-ciudad"

const IDS := [
	EXPEDIENTE_SUENA,
	COMITE_IMPOSIBLE,
	ARCHIVO_BAJO_LA_CIUDAD,
]


static func planos(id: String, datos: Dictionary = {}, vistas: int = 0) -> Array:
	var declarados := _declarados(id)
	assert(not declarados.is_empty(), "Cinemática psicodélica desconocida: %s" % id)
	var problemas := Cinematica.validar(declarados)
	assert(problemas.is_empty(), "Cinemática inválida %s: %s" % [id, problemas])
	return Cinematica.resolver(declarados, datos, vistas)


static func _declarados(id: String) -> Array:
	match id:
		EXPEDIENTE_SUENA:
			return _expediente_suena()
		COMITE_IMPOSIBLE:
			return _comite_imposible()
		ARCHIVO_BAJO_LA_CIUDAD:
			return _archivo_bajo_la_ciudad()
	return []


static func _plano(
	nombre: String,
	decorado: Dictionary,
	camara: Vector3,
	mira: Vector3,
	segundos: float,
	rotulo: String = "",
	voz: String = ""
) -> Dictionary:
	return {
		"tipo": "3d",
		"nombre": nombre,
		"decorado": decorado,
		"camara": camara,
		"mira": mira,
		"segundos": segundos,
		"rotulo": rotulo,
		"voz": voz,
	}


static func _pieza(
	pos: Vector3, tam: Vector3, color: Color, emisivo: bool = false
) -> Dictionary:
	var pieza := {"pos": pos, "tam": tam, "color": color}
	if emisivo:
		pieza["emisivo"] = true
	return pieza


static func _figura(pos: Vector3, ropa: Color, piel: Color, escala: float = 1.0) -> Array:
	return [
		_pieza(
			pos + Vector3(0, 0.95, 0) * escala,
			Vector3(0.46, 0.85, 0.28) * escala,
			ropa
		),
		_pieza(
			pos + Vector3(0, 1.55, 0) * escala,
			Vector3(0.34, 0.34, 0.30) * escala,
			piel
		),
		_pieza(
			pos + Vector3(-0.13, 0.38, 0) * escala,
			Vector3(0.14, 0.62, 0.18) * escala,
			ropa
		),
		_pieza(
			pos + Vector3(0.13, 0.38, 0) * escala,
			Vector3(0.14, 0.62, 0.18) * escala,
			ropa
		),
	]


static func _decorado(piezas: Array, luz: Color, energia: float = 1.0) -> Dictionary:
	return MesaCinematica.con(
		piezas,
		[
			{
				"pos": Vector3(0.0, 3.5, 1.0),
				"color": luz,
				"energia": energia,
				"alcance": 8.0,
				"carcasa": false,
			}
		]
	)


static func _oficina(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.05, -1.2), Vector3(6.0, 0.1, 5.0), Color("68686f")),
		_pieza(Vector3(0, 3.0, -1.4), Vector3(6.0, 0.08, 0.18), Color("d8d4bc"), true),
		_pieza(Vector3(-1.4, 0.65, -0.6), Vector3(1.5, 0.1, 0.8), Color("57575e")),
		_pieza(Vector3(1.4, 0.65, -0.6), Vector3(1.5, 0.1, 0.8), Color("57575e")),
		_pieza(Vector3(0, 1.25, -2.3), Vector3(1.0, 0.7, 0.08), Color("233528"), true),
	]
	for figura in figuras:
		piezas.append_array(figura)
	return _decorado(piezas, Color("d6d0b7"), 0.95)


static func _archivo(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.05, -1.5), Vector3(5.0, 0.1, 7.0), Color("4d4e55")),
		_pieza(Vector3(-1.7, 1.7, -1.8), Vector3(0.5, 3.3, 4.5), Color("555861")),
		_pieza(Vector3(1.7, 1.7, -1.8), Vector3(0.5, 3.3, 4.5), Color("555861")),
		_pieza(Vector3(0, 2.9, -3.2), Vector3(1.0, 0.08, 0.5), Color("b9b197"), true),
	]
	for figura in figuras:
		piezas.append_array(figura)
	return _decorado(piezas, Color("b9b197"), 0.7)


static func _escuela(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.05, -1.2), Vector3(6.0, 0.1, 5.0), Color("776f65")),
		_pieza(Vector3(0, 1.65, -3.0), Vector3(4.5, 2.8, 0.12), Color("d0c6ae")),
		_pieza(Vector3(0, 1.8, -2.9), Vector3(2.8, 1.4, 0.04), Color("263d34")),
		_pieza(Vector3(-1.5, 0.55, -0.7), Vector3(1.2, 0.08, 0.6), Color("705946")),
		_pieza(Vector3(0, 0.55, -0.7), Vector3(1.2, 0.08, 0.6), Color("705946")),
		_pieza(Vector3(1.5, 0.55, -0.7), Vector3(1.2, 0.08, 0.6), Color("705946")),
	]
	for figura in figuras:
		piezas.append_array(figura)
	return _decorado(piezas, Color("d5c69f"), 1.0)


static func _desierto(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, -0.1, -2.0), Vector3(12.0, 0.15, 12.0), Color("b68d57")),
		_pieza(Vector3(-2.6, 0.8, -3.8), Vector3(1.1, 1.8, 1.1), Color("9c7048")),
		_pieza(Vector3(2.8, 1.3, -5.0), Vector3(0.7, 2.8, 0.7), Color("8b6548")),
		_pieza(Vector3(0, 4.5, -8.0), Vector3(7.0, 0.15, 2.0), Color("dfb47a"), true),
	]
	for figura in figuras:
		piezas.append_array(figura)
	return _decorado(piezas, Color("e2a66d"), 1.4)


static func _castillo(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.0, -2.0), Vector3(7.0, 0.12, 7.0), Color("272931")),
		_pieza(Vector3(-2.2, 2.0, -4.0), Vector3(1.1, 4.0, 1.1), Color("393b45")),
		_pieza(Vector3(2.2, 2.0, -4.0), Vector3(1.1, 4.0, 1.1), Color("393b45")),
		_pieza(Vector3(0, 2.5, -4.3), Vector3(3.4, 4.8, 0.6), Color("32343c")),
		_pieza(Vector3(0, 2.8, -3.9), Vector3(0.3, 3.5, 0.1), Color("824f68"), true),
	]
	for figura in figuras:
		piezas.append_array(figura)
	return _decorado(piezas, Color("726d93"), 0.9)


static func _vacio(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, -0.15, -1.0), Vector3(15.0, 0.08, 15.0), Color("090a0f")),
		_pieza(Vector3(0, 5.0, -8.0), Vector3(0.18, 10.0, 0.18), Color("9b88b6"), true),
		_pieza(Vector3(-3.0, 2.0, -6.0), Vector3(0.12, 4.0, 0.12), Color("5f8b9c"), true),
		_pieza(Vector3(3.5, 3.0, -7.0), Vector3(0.12, 6.0, 0.12), Color("a97474"), true),
	]
	for figura in figuras:
		piezas.append_array(figura)
	return _decorado(piezas, Color("6e6384"), 0.65)


static func _expediente_suena() -> Array:
	var piel := Color("c7a58f")
	var gris := Color("555862")
	var rojo := Color("7c3845")
	var eco := _figura(Vector3(0, 0, -1.8), gris, piel)
	var doble := _figura(Vector3(1.2, 0, -2.0), rojo, piel)
	var gigante := _figura(Vector3(0, 0, -5.4), rojo, piel, 3.2)
	var planos := [
		_plano(
			"oficina",
			_oficina([eco]),
			Vector3(0, 1.7, 2.5),
			Vector3(0, 1.2, -1.2),
			3.2,
			"Al final del turno, {nombre} sigue sentado frente a ti."
		),
		_plano(
			"archivo",
			_archivo([eco]),
			Vector3(-0.8, 1.5, 2.2),
			Vector3(0, 1.3, -1.8),
			3.0,
			"En el archivo ocupa exactamente la misma silla."
		),
		_plano(
			"aula",
			_escuela([eco, doble]),
			Vector3(1.5, 1.7, 2.4),
			Vector3(0, 1.4, -1.4),
			3.4,
			"Ahora hay dos."
		),
		_plano(
			"desierto",
			_desierto([doble]),
			Vector3(-2.2, 1.5, 3.4),
			Vector3(1.2, 1.2, -2.0),
			3.6,
			"Uno espera donde termina la carretera.",
			"No mires su sombra."
		),
		_plano(
			"castillo",
			_castillo([eco, doble]),
			Vector3(0, 2.0, 3.6),
			Vector3(0, 1.6, -3.0),
			3.6,
			"El otro ya estaba dentro."
		),
		_plano(
			"gigante",
			_vacio([gigante]),
			Vector3(0, 1.4, 4.0),
			Vector3(0, 3.8, -5.4),
			4.0,
			"Tu expediente se abre detrás de sus ojos."
		),
		_plano(
			"regreso",
			_oficina([eco, doble]),
			Vector3(0.6, 1.5, 1.8),
			Vector3(0, 1.25, -1.6),
			3.2,
			"Los dos sellan el mismo documento."
		),
		_plano(
			"remate",
			_archivo([]),
			Vector3(0, 1.5, 1.6),
			Vector3(0, 1.5, -3.0),
			2.6,
			"El documento lleva tu firma."
		),
	]
	planos[0]["camara_desde"] = Vector3(2.2, 1.7, 3.0)
	planos[5]["fundido_desde"] = 0.0
	planos[5]["fundido_hasta"] = 0.35
	return planos


static func _comite_imposible() -> Array:
	var piel := Color("c6a38c")
	var azul := Color("394d65")
	var marron := Color("665347")
	var blanco := Color("b9b6ad")
	var jefa := _figura(Vector3(-1.1, 0, -1.4), azul, piel)
	var colega := _figura(Vector3(1.1, 0, -1.4), marron, piel)
	var vacio := _figura(Vector3(0, 0, -2.4), blanco, Color("d7d7d7"))
	var aula := _escuela([jefa, colega, vacio])
	var castillo := _castillo([jefa, colega, vacio])
	var desierto := _desierto([jefa, colega, vacio])
	var nada := _vacio(
		[
			_figura(Vector3(-2.0, 0, -4.0), azul, piel, 1.5),
			_figura(Vector3(0, 0, -5.0), blanco, Color("d7d7d7"), 2.1),
			_figura(Vector3(2.2, 0, -4.3), marron, piel, 1.4),
		]
	)
	return [
		_plano(
			"reunion",
			_oficina([jefa, colega, vacio]),
			Vector3(0, 1.65, 2.8),
			Vector3(0, 1.3, -1.5),
			3.5,
			"El comité extraordinario empieza a las {hora}."
		),
		_plano(
			"aula",
			aula,
			Vector3(-1.8, 1.7, 2.6),
			Vector3(0, 1.35, -1.5),
			3.2,
			"Nadie comenta que la sala ya no es la sala."
		),
		_plano(
			"examen",
			aula,
			Vector3(1.6, 1.4, 1.8),
			Vector3(0, 1.4, -2.0),
			3.0,
			"La evaluación está escrita en la pizarra.",
			"APTO. APTO. APTO. AUSENTE."
		),
		_plano(
			"fortaleza",
			castillo,
			Vector3(0, 2.1, 4.0),
			Vector3(0, 1.6, -3.2),
			3.8,
			"La puerta del fondo conduce a Recursos Humanos."
		),
		_plano(
			"arena",
			desierto,
			Vector3(-2.4, 1.6, 3.5),
			Vector3(0, 1.2, -2.1),
			3.7,
			"Votan levantando la mano."
		),
		_plano(
			"votacion",
			nada,
			Vector3(0, 2.0, 5.2),
			Vector3(0, 2.0, -4.7),
			4.5,
			"Todas las manos son tuyas."
		),
		_plano(
			"acta",
			_archivo([vacio]),
			Vector3(0.8, 1.6, 2.0),
			Vector3(0, 1.3, -2.4),
			3.4,
			"El acta se archivó en 1963."
		),
		_plano(
			"cierre",
			_oficina([]),
			Vector3(0, 1.7, 2.2),
			Vector3(0, 1.25, -1.2),
			2.8,
			"La reunión todavía no ha empezado."
		),
	]


static func _archivo_bajo_la_ciudad() -> Array:
	var piel := Color("c49d88")
	var negro := Color("2f3036")
	var operador := _figura(Vector3(0, 0, -1.7), negro, piel)
	var operador_lejos := _figura(Vector3(0, 0, -4.8), negro, piel, 1.8)
	var planos := [
		_plano(
			"ascensor",
			_archivo([operador]),
			Vector3(0, 1.5, 2.0),
			Vector3(0, 1.25, -1.6),
			3.0,
			"El ascensor baja después de la planta -1."
		),
		_plano(
			"anden",
			_vacio([operador]),
			Vector3(-2.0, 1.6, 3.8),
			Vector3(0, 1.4, -2.0),
			3.4,
			"Hay un andén donde debería estar el archivo."
		),
		_plano(
			"escuela",
			_escuela([operador]),
			Vector3(1.8, 1.5, 2.6),
			Vector3(0, 1.35, -1.8),
			3.2,
			"El siguiente pasillo termina en tu antigua aula."
		),
		_plano(
			"desierto",
			_desierto([operador_lejos]),
			Vector3(0, 1.7, 4.5),
			Vector3(0, 1.9, -4.8),
			4.0,
			"El conserje sigue caminando aunque ya no hay edificio."
		),
		_plano(
			"castillo",
			_castillo([operador]),
			Vector3(-1.5, 2.0, 3.4),
			Vector3(0, 1.4, -2.8),
			3.6,
			"Tras la muralla vuelve a oírse el ascensor."
		),
		_plano(
			"subsuelo",
			_vacio([operador_lejos]),
			Vector3(2.0, 2.4, 5.4),
			Vector3(0, 2.6, -4.6),
			4.6,
			"Debajo de la ciudad hay otra ciudad.",
			"Debajo de esa, otra oficina."
		),
		_plano(
			"oficina-profunda",
			_oficina([operador]),
			Vector3(0, 1.5, 2.3),
			Vector3(0, 1.3, -1.7),
			3.4,
			"En tu puesto hay alguien terminando tu jornada."
		),
		_plano(
			"archivo-final",
			_archivo([operador]),
			Vector3(0, 1.7, 2.0),
			Vector3(0, 1.4, -2.3),
			3.2,
			"Te entrega una carpeta marcada: SUPERFICIE."
		),
	]
	planos[0]["camara_desde"] = Vector3(0, 3.0, 2.3)
	planos[5]["fundido_desde"] = 0.1
	planos[5]["fundido_hasta"] = 0.5
	return planos
