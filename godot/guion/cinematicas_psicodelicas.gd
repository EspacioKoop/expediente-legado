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
const JARDIN_COLGANTE_SIGA := "psico-jardin-colgante-siga"
const IDENTIDADES_SUPERPUESTAS := "psico-identidades-superpuestas"
const GRAN_RUPTURA_SIGA := "psico-gran-ruptura-siga"
const PROCESION_DE_LOS_ARCHIVADOS := "psico-procesion-archivados"

const IDS := [
	EXPEDIENTE_SUENA,
	COMITE_IMPOSIBLE,
	ARCHIVO_BAJO_LA_CIUDAD,
	JARDIN_COLGANTE_SIGA,
	IDENTIDADES_SUPERPUESTAS,
	GRAN_RUPTURA_SIGA,
	PROCESION_DE_LOS_ARCHIVADOS,
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
		JARDIN_COLGANTE_SIGA:
			return _jardin_colgante_siga()
		IDENTIDADES_SUPERPUESTAS:
			return _identidades_superpuestas()
		GRAN_RUPTURA_SIGA:
			return _gran_ruptura_siga()
		PROCESION_DE_LOS_ARCHIVADOS:
			return _procesion_de_los_archivados()
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


static func _pieza(pos: Vector3, tam: Vector3, color: Color, emisivo: bool = false) -> Dictionary:
	var pieza := {"pos": pos, "tam": tam, "color": color}
	if emisivo:
		pieza["emisivo"] = true
	return pieza


static func _figura(
	pos: Vector3,
	_ropa: Color,
	_piel: Color,
	escala: float = 1.0,
	modelo: String = "rocketbox/male_adult_13",
	retrato: String = "",
	gesto: String = "idle"
) -> Dictionary:
	return {
		"modelo": modelo,
		"retrato": retrato,
		"pos": pos,
		"rumbo": 180.0,
		"escala": escala,
		"gesto": gesto,
		"desfase": float(absi(hash("%s:%s" % [modelo, pos])) % 1000) / 1000.0,
	}


static func _decorado(
	piezas: Array, luz: Color, energia: float = 1.0, personas: Array = [], modelos: Array = []
) -> Dictionary:
	var decorado := (
		MesaCinematica
		. con(
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
	)
	decorado["personas"] = personas
	decorado["modelos"] = modelos
	return decorado


static func _modelo(
	modelo: String,
	pos: Vector3,
	escala: float = 1.0,
	rotacion: Vector3 = Vector3.ZERO,
	nombre: String = ""
) -> Dictionary:
	return {
		"modelo": modelo,
		"pos": pos,
		"escala": escala,
		"rotacion": rotacion,
		"nombre": nombre,
	}


static func _oficina(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.05, -1.2), Vector3(6.0, 0.1, 5.0), Color("68686f")),
		_pieza(Vector3(0, 3.0, -1.4), Vector3(6.0, 0.08, 0.18), Color("d8d4bc"), true),
	]
	var modelos := [
		_modelo("oficina_psx/desk1", Vector3(-1.35, 0.0, -0.55), 1.0),
		_modelo("oficina_psx/desk2", Vector3(1.35, 0.0, -0.55), 1.0),
		_modelo("oficina_psx/computer_monitor", Vector3(-1.25, 0.78, -0.72), 0.95),
		_modelo("oficina_psx/computer_monitor", Vector3(1.25, 0.78, -0.72), 0.95),
		_modelo("oficina_psx/desk_phone", Vector3(0.0, 0.78, -0.35), 0.95),
		_modelo("oficina_psx/office_chair_black", Vector3(-0.55, 0.0, 0.35), 0.95),
		_modelo("oficina_psx/office_chair_black", Vector3(0.55, 0.0, 0.35), 0.95),
	]
	return _decorado(piezas, Color("d6d0b7"), 0.95, figuras, modelos)


static func _archivo(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.05, -1.5), Vector3(5.0, 0.1, 7.0), Color("4d4e55")),
		_pieza(Vector3(0, 2.9, -3.2), Vector3(1.0, 0.08, 0.5), Color("b9b197"), true),
	]
	var modelos := [
		_modelo("oficina_psx/file_cabinet_large", Vector3(-1.7, 0.0, -2.0), 1.0),
		_modelo("oficina_psx/file_cabinet_large", Vector3(1.7, 0.0, -2.0), 1.0),
		_modelo("oficina_psx/file_cabinet_smaller", Vector3(-1.7, 0.0, 0.2), 1.0),
		_modelo("oficina_psx/file_cabinet_smaller", Vector3(1.7, 0.0, 0.2), 1.0),
		_modelo("cardboardBoxClosed", Vector3(0.0, 0.0, -2.8), 0.75),
	]
	return _decorado(piezas, Color("b9b197"), 0.7, figuras, modelos)


static func _escuela(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.05, -1.2), Vector3(6.0, 0.1, 5.0), Color("776f65")),
		_pieza(Vector3(0, 1.65, -3.0), Vector3(4.5, 2.8, 0.12), Color("d0c6ae")),
		_pieza(Vector3(0, 1.8, -2.9), Vector3(2.8, 1.4, 0.04), Color("263d34")),
	]
	var modelos := [
		_modelo("styloo_school/principal_office_desk", Vector3(0.0, 0.0, -1.1), 1.0),
		_modelo("styloo_school/principal_office_chair", Vector3(0.0, 0.0, 0.15), 1.0),
		_modelo("styloo_school/principal_office_shelf", Vector3(-2.0, 0.0, -2.45), 0.9),
		_modelo("styloo_school/principal_office_telephone", Vector3(0.65, 0.78, -1.1), 0.9),
		_modelo("styloo_school/computer_pc_old", Vector3(-0.65, 0.78, -1.1), 0.85),
	]
	return _decorado(piezas, Color("d5c69f"), 1.0, figuras, modelos)


static func _desierto(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, -0.1, -2.0), Vector3(12.0, 0.15, 12.0), Color("b68d57")),
		_pieza(Vector3(-2.6, 0.8, -3.8), Vector3(1.1, 1.8, 1.1), Color("9c7048")),
		_pieza(Vector3(2.8, 1.3, -5.0), Vector3(0.7, 2.8, 0.7), Color("8b6548")),
		_pieza(Vector3(0, 4.5, -8.0), Vector3(7.0, 0.15, 2.0), Color("dfb47a"), true),
	]
	return _decorado(piezas, Color("e2a66d"), 1.4, figuras)


static func _castillo(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.0, -2.0), Vector3(7.0, 0.12, 7.0), Color("272931")),
		_pieza(Vector3(-2.2, 2.0, -4.0), Vector3(1.1, 4.0, 1.1), Color("393b45")),
		_pieza(Vector3(2.2, 2.0, -4.0), Vector3(1.1, 4.0, 1.1), Color("393b45")),
		_pieza(Vector3(0, 2.5, -4.3), Vector3(3.4, 4.8, 0.6), Color("32343c")),
		_pieza(Vector3(0, 2.8, -3.9), Vector3(0.3, 3.5, 0.1), Color("824f68"), true),
	]
	return _decorado(piezas, Color("726d93"), 0.9, figuras)


static func _vacio(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, -0.15, -1.0), Vector3(15.0, 0.08, 15.0), Color("090a0f")),
		_pieza(Vector3(0, 5.0, -8.0), Vector3(0.18, 10.0, 0.18), Color("9b88b6"), true),
		_pieza(Vector3(-3.0, 2.0, -6.0), Vector3(0.12, 4.0, 0.12), Color("5f8b9c"), true),
		_pieza(Vector3(3.5, 3.0, -7.0), Vector3(0.12, 6.0, 0.12), Color("a97474"), true),
	]
	return _decorado(piezas, Color("6e6384"), 0.65, figuras)


static func _expediente_suena() -> Array:
	var piel := Color("c7a58f")
	var gris := Color("555862")
	var rojo := Color("7c3845")
	var eco := _figura(Vector3(0, 0, -1.8), gris, piel, 1.0, "rocketbox/male_adult_14")
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


static func _jardin_colgante(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.0, -2.0), Vector3(9.0, 0.16, 9.0), Color("8c744f")),
		_pieza(Vector3(-2.8, 1.4, -4.2), Vector3(1.2, 2.8, 1.2), Color("726044")),
		_pieza(Vector3(2.8, 2.1, -4.8), Vector3(1.4, 4.2, 1.4), Color("726044")),
		_pieza(Vector3(0, 1.5, -5.5), Vector3(4.6, 0.18, 2.6), Color("6f8b61")),
		_pieza(Vector3(-1.2, 2.3, -5.5), Vector3(1.6, 0.18, 1.6), Color("739b67")),
		_pieza(Vector3(1.4, 2.8, -5.8), Vector3(1.8, 0.18, 1.5), Color("789e6a")),
		_pieza(Vector3(0, 3.9, -7.2), Vector3(5.5, 0.12, 0.5), Color("91b978"), true),
	]
	return _decorado(piezas, Color("c5a86d"), 1.25, figuras)


static func _faro(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, -0.05, -2.0), Vector3(10.0, 0.12, 10.0), Color("24313f")),
		_pieza(Vector3(0, 2.4, -5.5), Vector3(1.6, 4.8, 1.6), Color("c0b59b")),
		_pieza(Vector3(0, 5.1, -5.5), Vector3(2.0, 0.4, 2.0), Color("d3c5a2")),
		_pieza(Vector3(0, 5.4, -5.2), Vector3(0.6, 0.45, 0.6), Color("e4d48b"), true),
		_pieza(Vector3(2.7, 0.3, -4.6), Vector3(3.2, 0.45, 1.2), Color("394b5c")),
	]
	return _decorado(piezas, Color("8495a8"), 1.15, figuras)


static func _jardin_colgante_siga() -> Array:
	var piel := Color("c5a088")
	var verde := Color("536a55")
	var negro := Color("303138")
	var archivera := _figura(Vector3(0, 0, -1.8), verde, piel)
	var operador := _figura(Vector3(1.4, 0, -2.2), negro, piel)
	var operador_gigante := _figura(Vector3(0, 0, -6.0), negro, piel, 2.7)
	return [
		_plano(
			"terminal",
			_oficina([archivera]),
			Vector3(0, 1.6, 2.3),
			Vector3(0, 1.3, -1.6),
			3.0,
			"SIGA abre un expediente sin número."
		),
		_plano(
			"jardin",
			_jardin_colgante([archivera]),
			Vector3(-2.2, 2.0, 4.0),
			Vector3(0, 2.0, -4.8),
			4.0,
			"La pantalla muestra un jardín que no cabe en la oficina."
		),
		_plano(
			"terraza",
			_jardin_colgante([archivera, operador]),
			Vector3(2.0, 2.4, 3.5),
			Vector3(0, 1.8, -4.2),
			3.8,
			"Alguien ha fichado aquí hace dos mil años."
		),
		_plano(
			"faro",
			_faro([operador]),
			Vector3(-2.5, 2.2, 4.8),
			Vector3(0, 3.2, -5.2),
			4.2,
			"El faro responde a la consulta.",
			"Registro localizado."
		),
		_plano(
			"archivo",
			_archivo([archivera, operador]),
			Vector3(1.8, 1.8, 3.0),
			Vector3(0, 1.4, -2.1),
			3.3,
			"Las cajas tienen sellos de ciudades que aún no existen."
		),
		_plano(
			"gigante",
			_vacio([operador_gigante]),
			Vector3(0, 1.5, 5.0),
			Vector3(0, 3.4, -5.8),
			4.6,
			"El operador pronuncia tu contraseña antes de que la elijas."
		),
		_plano(
			"retorno-jardin",
			_jardin_colgante([]),
			Vector3(0, 2.0, 4.2),
			Vector3(0, 2.0, -5.3),
			3.8,
			"Las terrazas se pliegan como carpetas."
		),
		_plano(
			"retorno-terminal",
			_oficina([archivera]),
			Vector3(0, 1.7, 2.0),
			Vector3(0, 1.25, -1.7),
			3.1,
			"SIGA pregunta si deseas guardar los cambios."
		),
		_plano(
			"negro",
			_vacio([]),
			Vector3(0, 1.6, 3.0),
			Vector3(0, 1.6, -4.0),
			2.8,
			"CAMBIOS GUARDADOS"
		),
	]


static func _identidades_superpuestas() -> Array:
	var piel := Color("c7a088")
	var azul := Color("46566e")
	var rojo := Color("74414a")
	var gris := Color("64646b")
	var figura_azul := _figura(Vector3(0, 0, -1.8), azul, piel, 1.0, "rocketbox/male_adult_02")
	var figura_roja := _figura(Vector3(0, 0, -1.8), rojo, piel, 1.0, "rocketbox/female_adult_09")
	var figura_gris := _figura(Vector3(0, 0, -1.8), gris, piel, 1.0, "rocketbox/male_adult_14")
	var figura_blanca := _figura(Vector3(0, 0, -1.8), Color("c4c4c4"), Color("ededed"))
	return [
		_plano(
			"companero",
			_oficina([figura_azul]),
			Vector3(0, 1.6, 2.2),
			Vector3(0, 1.3, -1.8),
			3.2,
			"{nombre} te pregunta si recuerdas su cara."
		),
		_plano(
			"jefa",
			_oficina([figura_roja]),
			Vector3(0, 1.6, 2.2),
			Vector3(0, 1.3, -1.8),
			3.0,
			"En el siguiente parpadeo es tu superior."
		),
		_plano(
			"profesor",
			_escuela([figura_gris]),
			Vector3(0, 1.6, 2.2),
			Vector3(0, 1.3, -1.8),
			3.2,
			"Después es quien te enseñó a escribir tu nombre."
		),
		_plano(
			"archivero",
			_archivo([figura_blanca]),
			Vector3(0, 1.6, 2.2),
			Vector3(0, 1.3, -1.8),
			3.4,
			"Después no tiene rostro."
		),
		_plano(
			"castillo",
			_castillo([figura_roja]),
			Vector3(0, 1.8, 3.0),
			Vector3(0, 1.4, -2.0),
			3.6,
			"Pero conserva exactamente la misma postura."
		),
		_plano(
			"desierto",
			_desierto([figura_azul]),
			Vector3(0, 1.8, 3.2),
			Vector3(0, 1.4, -2.0),
			3.8,
			"El escenario cambia. Él no."
		),
		_plano(
			"vacio",
			_vacio([figura_blanca]),
			Vector3(0, 1.6, 3.0),
			Vector3(0, 1.3, -1.8),
			4.0,
			"Preguntas quién es.",
			"Responde con tu nombre."
		),
		_plano(
			"duplicacion",
			_oficina([figura_azul, _figura(Vector3(1.2, 0, -1.8), rojo, piel)]),
			Vector3(0.6, 1.7, 2.5),
			Vector3(0, 1.3, -1.8),
			3.5,
			"Ahora hay dos versiones."
		),
		_plano(
			"cierre-identidad",
			_archivo([figura_gris]),
			Vector3(0, 1.7, 2.1),
			Vector3(0, 1.3, -1.8),
			3.0,
			"La carpeta dice: IDENTIDAD PROVISIONAL."
		),
	]


static func _gato_os98(pos: Vector3, escala: float = 1.0) -> Array:
	return [
		_pieza(
			pos + Vector3(0, 0.35, 0) * escala, Vector3(0.55, 0.32, 0.28) * escala, Color("b9b2a2")
		),
		_pieza(
			pos + Vector3(0.28, 0.48, 0) * escala,
			Vector3(0.28, 0.28, 0.25) * escala,
			Color("c7c0ae")
		),
		_pieza(
			pos + Vector3(-0.34, 0.45, 0) * escala,
			Vector3(0.42, 0.08, 0.08) * escala,
			Color("b0a998")
		),
		_pieza(
			pos + Vector3(0.34, 0.53, 0.12) * escala,
			Vector3(0.06, 0.06, 0.04) * escala,
			Color("7fa08b"),
			true
		),
	]


static func _gran_ruptura_siga() -> Array:
	var piel := Color("c6a18b")
	var traje_puyi := Color("4d5666")
	var traje_pessoa := Color("66534a")
	var uniforme := Color("565861")
	var puyi := _figura(
		Vector3(-1.1, 0, -1.9),
		traje_puyi,
		piel,
		1.0,
		"rocketbox/business_male_02",
		"emperador",
		"work"
	)
	var pessoa := _figura(
		Vector3(1.1, 0, -1.9),
		traje_pessoa,
		piel,
		1.0,
		"rocketbox/business_male_03",
		"correspondencia",
		"work"
	)
	var funcionario := _figura(
		Vector3(0, 0, -2.2), uniforme, piel, 1.0, "rocketbox/business_female_02", "", "work"
	)
	var gato := _gato_os98(Vector3(0.9, 0, -1.0))
	var gato_gigante := _gato_os98(Vector3(0, 0, -6.0), 3.0)
	var nino := _figura(Vector3(0, 0, -1.8), Color("73809a"), piel, 0.7)
	var adulto := _figura(Vector3(0, 0, -1.8), Color("59606f"), piel, 1.0)
	var anciano := _figura(Vector3(0, 0, -1.8), Color("454850"), Color("b8a89c"), 0.95)
	var planos := [
		_plano(
			"oficina-1998",
			_oficina([funcionario, gato]),
			Vector3(0, 1.7, 2.6),
			Vector3(0, 1.25, -1.6),
			4.0,
			"1998. El turno continúa aunque todas las pantallas marcan una fecha distinta."
		),
		_plano(
			"archivo-puyi",
			_archivo([puyi]),
			Vector3(-1.8, 1.7, 3.0),
			Vector3(-1.0, 1.4, -1.9),
			4.2,
			"Puyi ordena expedientes que todavía no han sido escritos."
		),
		_plano(
			"correspondencia-pessoa",
			_escuela([pessoa]),
			Vector3(1.7, 1.6, 2.7),
			Vector3(1.0, 1.3, -1.9),
			4.0,
			"Pessoa copia una carta dirigida a alguien que usa tu nombre."
		),
		_plano(
			"jardin-archivo",
			_jardin_colgante([puyi, pessoa]),
			Vector3(-2.4, 2.3, 4.5),
			Vector3(0, 2.0, -4.8),
			4.8,
			"Las terrazas de Babilonia se convierten en archivadores."
		),
		_plano(
			"faro-terminal",
			_faro([funcionario]),
			Vector3(2.5, 2.5, 5.0),
			Vector3(0, 3.4, -5.2),
			4.8,
			"El faro de Alejandría emite la luz verde de SIGA.",
			"Sincronización completada."
		),
		_plano(
			"edad-nino",
			_oficina([nino, gato]),
			Vector3(0, 1.4, 2.1),
			Vector3(0, 1.1, -1.8),
			3.8,
			"En tu silla hay un niño."
		),
		_plano(
			"edad-adulto",
			_oficina([adulto, gato]),
			Vector3(0, 1.55, 2.1),
			Vector3(0, 1.2, -1.8),
			3.6,
			"Parpadeas. Ahora tiene tu edad."
		),
		_plano(
			"edad-anciano",
			_oficina([anciano, gato]),
			Vector3(0, 1.55, 2.1),
			Vector3(0, 1.2, -1.8),
			4.0,
			"Parpadeas otra vez. Sigue esperando tu jubilación."
		),
		_plano(
			"desierto-gato",
			_desierto([gato_gigante]),
			Vector3(-2.2, 1.8, 5.0),
			Vector3(0, 2.0, -5.8),
			4.6,
			"El gato de OS98 cruza el horizonte como si conociera el camino."
		),
		_plano(
			"castillo-comite",
			_castillo([puyi, pessoa, funcionario]),
			Vector3(0, 2.2, 4.4),
			Vector3(0, 1.7, -3.2),
			4.6,
			"El comité lleva siglos esperando tu expediente."
		),
		_plano(
			"vacio-duplicado",
			_vacio(
				[
					_figura(Vector3(-1.7, 0, -4.5), traje_puyi, piel, 1.5),
					_figura(Vector3(1.7, 0, -4.5), traje_pessoa, piel, 1.5),
					_gato_os98(Vector3(0, 0, -5.2), 1.8),
				]
			),
			Vector3(0, 2.1, 5.5),
			Vector3(0, 2.2, -4.8),
			5.0,
			"Todos miran hacia una puerta que no existe."
		),
		_plano(
			"retorno-archivo",
			_archivo([funcionario, gato]),
			Vector3(0.8, 1.7, 2.5),
			Vector3(0, 1.3, -2.1),
			4.2,
			"Al volver, tu expediente pesa más."
		),
		_plano(
			"retorno-terminal",
			_oficina([]),
			Vector3(0, 1.7, 2.2),
			Vector3(0, 1.25, -1.8),
			3.8,
			"SIGA registra la incidencia como: SIN NOVEDAD."
		),
		_plano(
			"negro-final",
			_vacio([]),
			Vector3(0, 1.6, 3.0),
			Vector3(0, 1.6, -4.0),
			3.0,
			"FECHA DEL SISTEMA: {fecha}"
		),
	]
	planos[0]["camara_desde"] = Vector3(2.4, 1.7, 3.0)
	planos[4]["fundido_desde"] = 0.0
	planos[4]["fundido_hasta"] = 0.25
	planos[10]["fundido_desde"] = 0.15
	planos[10]["fundido_hasta"] = 0.5
	planos[13]["fundido_desde"] = 0.0
	planos[13]["fundido_hasta"] = 1.0
	return planos


static func _procesion_de_los_archivados() -> Array:
	var piel := Color("c6a18b")
	var azul := Color("3f526d")
	var rojo := Color("70434b")
	var gris := Color("555861")
	var dorado := Color("807057")
	var fila := [
		_figura(Vector3(-2.0, 0, -2.2), azul, piel),
		_figura(Vector3(-0.7, 0, -2.2), rojo, piel),
		_figura(Vector3(0.7, 0, -2.2), gris, piel),
		_figura(Vector3(2.0, 0, -2.2), dorado, piel),
	]
	var fila_lejana := [
		_figura(Vector3(-2.5, 0, -5.0), azul, piel, 1.2),
		_figura(Vector3(-0.8, 0, -5.2), rojo, piel, 1.2),
		_figura(Vector3(0.9, 0, -5.1), gris, piel, 1.2),
		_figura(Vector3(2.6, 0, -5.3), dorado, piel, 1.2),
	]
	var fila_gigante := [
		_figura(Vector3(-2.8, 0, -7.0), azul, piel, 2.2),
		_figura(Vector3(0.0, 0, -7.2), rojo, piel, 2.4),
		_figura(Vector3(2.9, 0, -7.0), gris, piel, 2.2),
	]
	var planos := [
		_plano(
			"fila-oficina",
			_oficina(fila),
			Vector3(0, 1.8, 3.3),
			Vector3(0, 1.4, -2.0),
			4.0,
			"Cuatro personas esperan frente a una ventanilla que no existe."
		),
		_plano(
			"fila-archivo",
			_archivo(fila),
			Vector3(-1.8, 1.8, 3.1),
			Vector3(0, 1.4, -2.1),
			4.0,
			"El archivo conserva exactamente la misma cola."
		),
		_plano(
			"fila-aula",
			_escuela(fila),
			Vector3(1.8, 1.7, 3.0),
			Vector3(0, 1.4, -2.0),
			4.0,
			"En el aula siguen esperando."
		),
		_plano(
			"fila-jardin",
			_jardin_colgante(fila_lejana),
			Vector3(-2.4, 2.4, 5.2),
			Vector3(0, 2.0, -5.1),
			4.8,
			"En Babilonia, la cola llega hasta la terraza superior."
		),
		_plano(
			"fila-faro",
			_faro(fila_lejana),
			Vector3(2.4, 2.4, 5.3),
			Vector3(0, 2.4, -5.1),
			4.8,
			"En Alejandría esperan a que el faro abra turno."
		),
		_plano(
			"fila-desierto",
			_desierto(fila_lejana),
			Vector3(0, 1.9, 5.2),
			Vector3(0, 1.7, -5.0),
			4.6,
			"En el desierto nadie abandona su sitio."
		),
		_plano(
			"fila-castillo",
			_castillo(fila),
			Vector3(0, 2.1, 4.2),
			Vector3(0, 1.6, -3.0),
			4.4,
			"Tras la muralla, la cola gira otra vez."
		),
		_plano(
			"fila-vacio",
			_vacio(fila_gigante),
			Vector3(0, 2.2, 6.0),
			Vector3(0, 2.8, -6.5),
			5.2,
			"Cuando ya no queda mundo, siguen esperando."
		),
		_plano(
			"ventanilla-gato",
			_oficina(
				[
					_figura(Vector3(-1.2, 0, -1.8), azul, piel),
					_figura(Vector3(1.2, 0, -1.8), rojo, piel),
					_gato_os98(Vector3(0, 0, -0.9), 1.4),
				]
			),
			Vector3(0, 1.7, 2.8),
			Vector3(0, 1.2, -1.4),
			4.2,
			"El gato OS98 ocupa ahora la ventanilla."
		),
		_plano(
			"turno",
			_archivo([]),
			Vector3(0, 1.7, 2.4),
			Vector3(0, 1.5, -2.5),
			3.8,
			"En la pantalla aparece tu número."
		),
		_plano(
			"cierre-procesion",
			_vacio([]),
			Vector3(0, 1.7, 3.2),
			Vector3(0, 1.7, -4.5),
			3.2,
			"TURNO ACTUAL: {expediente}"
		),
	]
	planos[0]["camara_desde"] = Vector3(3.0, 1.8, 3.8)
	planos[7]["fundido_desde"] = 0.0
	planos[7]["fundido_hasta"] = 0.35
	planos[10]["fundido_desde"] = 0.0
	planos[10]["fundido_hasta"] = 1.0
	return planos
