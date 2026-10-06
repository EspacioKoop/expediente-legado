## Catálogo de cinemáticas diegéticas cortas para momentos de umbral.
##
## No se reproducen automáticamente: una vertical decide cuándo ganárselas y
## pasa el resultado a cinematica_app.gd. Así evitamos otra avalancha al inicio.
class_name CinematicasUmbral
extends RefCounted

const EXPEDIENTE_IMPOSIBLE := "umbral-expediente-imposible"
const SIGA_FANTASMA := "umbral-siga-fantasma"
const ENTRADA_SUENO := "umbral-entrada-sueno"
const REGRESO_OFICINA := "umbral-regreso-oficina"

const IDS := [
	EXPEDIENTE_IMPOSIBLE,
	SIGA_FANTASMA,
	ENTRADA_SUENO,
	REGRESO_OFICINA,
]

static func planos(id: String, datos: Dictionary = {}, vistas: int = 0) -> Array:
	var declarados := _declarados(id)
	assert(not declarados.is_empty(), "Cinemática de umbral desconocida: %s" % id)
	var problemas := Cinematica.validar(declarados)
	assert(problemas.is_empty(), "Cinemática inválida %s: %s" % [id, problemas])
	return Cinematica.resolver(declarados, datos, vistas)

static func _declarados(id: String) -> Array:
	match id:
		EXPEDIENTE_IMPOSIBLE:
			return _expediente_imposible()
		SIGA_FANTASMA:
			return _siga_fantasma()
		ENTRADA_SUENO:
			return _entrada_sueno()
		REGRESO_OFICINA:
			return _regreso_oficina()
	return []

static func _mesa(piezas: Array, luz: Color) -> Dictionary:
	return MesaCinematica.con(
		piezas,
		[
			{
				"pos": Vector3(0.0, 2.2, 0.8),
				"color": luz,
				"energia": 1.1,
				"alcance": 4.5,
				"carcasa": false,
			}
		]
	)

static func _expediente_imposible() -> Array:
	var papel := Color("d7d2bc")
	var tinta := Color("25252a")
	var decorado := _mesa(
		[
			{"pos": Vector3(0, 1.02, 0), "tam": Vector3(0.72, 0.02, 0.95), "color": papel},
			{"pos": Vector3(0, 1.035, 0.12), "tam": Vector3(0.52, 0.008, 0.04), "color": tinta},
			{"pos": Vector3(0, 1.035, -0.02), "tam": Vector3(0.58, 0.008, 0.025), "color": tinta},
			{"pos": Vector3(0.18, 1.04, -0.28), "tam": Vector3(0.18, 0.012, 0.18), "color": Color("6f2020")},
		],
		Color("e8dfba")
	)
	return [
		{
			"tipo": "3d", "nombre": "folio",
			"camara_desde": Vector3(0.0, 2.0, 2.2), "camara": Vector3(0.0, 1.65, 1.35),
			"mira": Vector3(0.0, 1.0, 0.0), "segundos": 1.25, "decorado": decorado,
			"rotulo": "El expediente figura como archivado en {fecha}.", "voz": ""
		},
		{
			"tipo": "3d", "nombre": "sello",
			"camara": Vector3(0.55, 1.38, 0.85), "mira": Vector3(0.18, 1.02, -0.28),
			"segundos": 1.15, "decorado": decorado,
			"rotulo": "La fecha del sello todavía no ha ocurrido.", "voz": ""
		},
		{
			"tipo": "3d", "nombre": "remate",
			"camara": Vector3(-0.25, 1.75, 1.7), "mira": Vector3(0.0, 1.0, 0.0),
			"segundos": 0.85, "decorado": decorado,
			"rotulo": "EXPEDIENTE {expediente}", "voz": ""
		},
	]

static func _siga_fantasma() -> Array:
	var verde := Color("79b88d")
	var decorado := _mesa(
		[
			{"pos": Vector3(0, 1.35, 0), "tam": Vector3(1.15, 0.72, 0.06), "color": Color("24272b")},
			{"pos": Vector3(0, 1.35, 0.035), "tam": Vector3(0.92, 0.52, 0.01), "color": Color("14251b"), "emisivo": true},
			{"pos": Vector3(0, 1.43, 0.045), "tam": Vector3(0.72, 0.025, 0.008), "color": verde, "emisivo": true},
			{"pos": Vector3(-0.12, 1.31, 0.045), "tam": Vector3(0.54, 0.02, 0.008), "color": verde, "emisivo": true},
		],
		Color("739984")
	)
	return [
		{
			"tipo": "3d", "nombre": "terminal",
			"camara": Vector3(0.0, 1.5, 1.7), "mira": Vector3(0.0, 1.35, 0.0),
			"segundos": 1.0, "decorado": decorado,
			"rotulo": "SIGA procesa una consulta que no has escrito.", "voz": ""
		},
		{
			"tipo": "3d", "nombre": "acercamiento",
			"camara_desde": Vector3(0.0, 1.5, 1.7), "camara": Vector3(0.0, 1.42, 1.0),
			"mira": Vector3(0.0, 1.38, 0.0), "segundos": 1.2, "decorado": decorado,
			"rotulo": "USUARIO: {usuario}", "voz": "Hay una sesión abierta desde antes de tu alta."
		},
		{
			"tipo": "3d", "nombre": "negro",
			"camara": Vector3(0.0, 1.42, 1.0), "mira": Vector3(0.0, 1.38, 0.0),
			"segundos": 0.7, "decorado": decorado, "fundido_desde": 0.0, "fundido_hasta": 1.0,
			"rotulo": "CONEXIÓN RESTABLECIDA", "voz": ""
		},
	]

static func _entrada_sueno() -> Array:
	var azul := Color("75819b")
	var decorado := _mesa(
		[
			{"pos": Vector3(0, 0.45, -0.6), "tam": Vector3(4.6, 0.08, 4.6), "color": Color("32343b")},
			{"pos": Vector3(0, 1.3, -0.9), "tam": Vector3(0.12, 2.3, 0.12), "color": azul, "emisivo": true},
			{"pos": Vector3(-0.7, 1.0, -0.7), "tam": Vector3(0.08, 1.4, 0.08), "color": azul, "emisivo": true},
			{"pos": Vector3(0.8, 1.6, -1.0), "tam": Vector3(0.08, 2.6, 0.08), "color": azul, "emisivo": true},
		],
		Color("65758d")
	)
	return [
		{
			"tipo": "3d", "nombre": "oficina-se-despega",
			"camara_desde": Vector3(0.0, 1.65, 2.0), "camara": Vector3(0.0, 1.8, 1.25),
			"mira_desde": Vector3(0.0, 1.2, -0.4), "mira": Vector3(0.0, 1.5, -0.9),
			"segundos": 1.35, "decorado": decorado,
			"rotulo": "El techo queda demasiado lejos.", "voz": ""
		},
		{
			"tipo": "3d", "nombre": "umbral",
			"camara": Vector3(0.0, 1.7, 0.7), "mira": Vector3(0.0, 1.3, -0.9),
			"segundos": 1.25, "decorado": decorado,
			"rotulo": "{sueno}", "voz": "No recuerdas haberte dormido."
		},
		{
			"tipo": "3d", "nombre": "entrada",
			"camara": Vector3(0.0, 1.65, 0.3), "mira": Vector3(0.0, 1.4, -1.0),
			"segundos": 0.85, "decorado": decorado, "fundido_desde": 0.0, "fundido_hasta": 1.0,
			"rotulo": "", "voz": ""
		},
	]

static func _regreso_oficina() -> Array:
	var fluorescente := Color("d9d7c5")
	var decorado := _mesa(
		[
			{"pos": Vector3(0, 2.4, -0.3), "tam": Vector3(1.8, 0.06, 0.22), "color": fluorescente, "emisivo": true},
			{"pos": Vector3(0, 0.55, -0.7), "tam": Vector3(3.8, 0.08, 3.8), "color": Color("626269")},
			{"pos": Vector3(0.7, 1.05, -0.55), "tam": Vector3(0.7, 0.9, 0.7), "color": Color("4b4c52")},
		],
		Color("e3e0c8")
	)
	return [
		{
			"tipo": "3d", "nombre": "flash",
			"camara": Vector3(0.0, 1.55, 1.0), "mira": Vector3(0.0, 1.5, -0.3),
			"segundos": 0.35, "decorado": decorado, "fundido_desde": 1.0, "fundido_hasta": 0.0,
			"rotulo": "", "voz": ""
		},
		{
			"tipo": "3d", "nombre": "fluorescente",
			"camara": Vector3(0.0, 1.4, 0.7), "mira": Vector3(0.0, 2.35, -0.3),
			"segundos": 0.8, "decorado": decorado,
			"rotulo": "El fluorescente lleva zumbando todo el tiempo.", "voz": ""
		},
		{
			"tipo": "3d", "nombre": "puesto",
			"camara": Vector3(-0.35, 1.55, 1.45), "mira": Vector3(0.45, 1.05, -0.55),
			"segundos": 1.0, "decorado": decorado,
			"rotulo": "Son las {hora}.", "voz": "En el registro no consta ninguna ausencia."
		},
	]
