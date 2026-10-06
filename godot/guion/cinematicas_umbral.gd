## Catálogo de cinemáticas diegéticas cortas para momentos de umbral.
##
## No se reproducen automáticamente: una vertical decide cuándo ganárselas y
## pasa el resultado a cinematica_app.gd. Así evitamos otra avalancha al inicio.
class_name CinematicasUmbral
extends RefCounted

const EXPEDIENTE_IMPOSIBLE := "umbral-expediente-imposible"
const SIGA_FANTASMA := "umbral-siga-fantasma"
const LLAMADA_SIN_LINEA := "umbral-llamada-sin-linea"
const ARCHIVO_SE_REORDENA := "umbral-archivo-se-reordena"
const REGRESO_OFICINA := "umbral-regreso-oficina"

const IDS := [
	EXPEDIENTE_IMPOSIBLE,
	SIGA_FANTASMA,
	LLAMADA_SIN_LINEA,
	ARCHIVO_SE_REORDENA,
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
		LLAMADA_SIN_LINEA:
			return _llamada_sin_linea()
		ARCHIVO_SE_REORDENA:
			return _archivo_se_reordena()
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


static func _pieza(
	pos: Vector3, tam: Vector3, color: Color, emisivo: bool = false
) -> Dictionary:
	var pieza := {"pos": pos, "tam": tam, "color": color}
	if emisivo:
		pieza["emisivo"] = true
	return pieza


static func _plano(
	nombre: String,
	camara: Vector3,
	mira: Vector3,
	segundos: float,
	decorado: Dictionary,
	rotulo: String = "",
	voz: String = ""
) -> Dictionary:
	return {
		"tipo": "3d",
		"nombre": nombre,
		"camara": camara,
		"mira": mira,
		"segundos": segundos,
		"decorado": decorado,
		"rotulo": rotulo,
		"voz": voz,
	}


static func _expediente_imposible() -> Array:
	var papel := Color("d7d2bc")
	var tinta := Color("25252a")
	var decorado := _mesa(
		[
			_pieza(Vector3(0, 1.02, 0), Vector3(0.72, 0.02, 0.95), papel),
			_pieza(Vector3(0, 1.035, 0.12), Vector3(0.52, 0.008, 0.04), tinta),
			_pieza(Vector3(0, 1.035, -0.02), Vector3(0.58, 0.008, 0.025), tinta),
			_pieza(
				Vector3(0.18, 1.04, -0.28),
				Vector3(0.18, 0.012, 0.18),
				Color("6f2020")
			),
		],
		Color("e8dfba")
	)
	var entrada := _plano(
		"folio",
		Vector3(0.0, 1.65, 1.35),
		Vector3(0.0, 1.0, 0.0),
		1.25,
		decorado,
		"El expediente figura como archivado en {fecha}."
	)
	entrada["camara_desde"] = Vector3(0.0, 2.0, 2.2)
	return [
		entrada,
		_plano(
			"sello",
			Vector3(0.55, 1.38, 0.85),
			Vector3(0.18, 1.02, -0.28),
			1.15,
			decorado,
			"La fecha del sello todavía no ha ocurrido."
		),
		_plano(
			"remate",
			Vector3(-0.25, 1.75, 1.7),
			Vector3(0.0, 1.0, 0.0),
			0.85,
			decorado,
			"EXPEDIENTE {expediente}"
		),
	]


static func _siga_fantasma() -> Array:
	var verde := Color("79b88d")
	var decorado := _mesa(
		[
			_pieza(Vector3(0, 1.35, 0), Vector3(1.15, 0.72, 0.06), Color("24272b")),
			_pieza(
				Vector3(0, 1.35, 0.035),
				Vector3(0.92, 0.52, 0.01),
				Color("14251b"),
				true
			),
			_pieza(Vector3(0, 1.43, 0.045), Vector3(0.72, 0.025, 0.008), verde, true),
			_pieza(
				Vector3(-0.12, 1.31, 0.045),
				Vector3(0.54, 0.02, 0.008),
				verde,
				true
			),
		],
		Color("739984")
	)
	var acercamiento := _plano(
		"acercamiento",
		Vector3(0.0, 1.42, 1.0),
		Vector3(0.0, 1.38, 0.0),
		1.2,
		decorado,
		"USUARIO: {usuario}",
		"Hay una sesión abierta desde antes de tu alta."
	)
	acercamiento["camara_desde"] = Vector3(0.0, 1.5, 1.7)
	var negro := _plano(
		"negro",
		Vector3(0.0, 1.42, 1.0),
		Vector3(0.0, 1.38, 0.0),
		0.7,
		decorado,
		"CONEXIÓN RESTABLECIDA"
	)
	negro["fundido_desde"] = 0.0
	negro["fundido_hasta"] = 1.0
	return [
		_plano(
			"terminal",
			Vector3(0.0, 1.5, 1.7),
			Vector3(0.0, 1.35, 0.0),
			1.0,
			decorado,
			"SIGA procesa una consulta que no has escrito."
		),
		acercamiento,
		negro,
	]


static func _llamada_sin_linea() -> Array:
	var rojo := Color("8a2f36")
	var decorado := _mesa(
		[
			_pieza(Vector3(0, 1.02, 0), Vector3(0.9, 0.09, 0.55), Color("3a3a40")),
			_pieza(Vector3(-0.22, 1.14, 0), Vector3(0.18, 0.14, 0.38), Color("25252a")),
			_pieza(Vector3(0.25, 1.13, 0.04), Vector3(0.26, 0.05, 0.2), rojo, true),
			_pieza(Vector3(0.0, 1.08, -0.18), Vector3(0.52, 0.025, 0.04), Color("5a5a61")),
		],
		Color("c7b7a0")
	)
	var acercamiento := _plano(
		"telefono",
		Vector3(0.0, 1.45, 1.35),
		Vector3(0.0, 1.08, 0.0),
		1.0,
		decorado,
		"El teléfono suena sin estar conectado."
	)
	acercamiento["camara_desde"] = Vector3(0.7, 1.65, 1.8)
	return [
		acercamiento,
		_plano(
			"auricular",
			Vector3(-0.35, 1.32, 0.8),
			Vector3(-0.22, 1.14, 0.0),
			1.15,
			decorado,
			"EXTENSIÓN {extension}",
			"Una voz repite tu número de expediente."
		),
		_plano(
			"corte",
			Vector3(0.2, 1.35, 0.9),
			Vector3(0.25, 1.13, 0.04),
			0.7,
			decorado,
			"LLAMADA FINALIZADA"
		),
	]


static func _archivo_se_reordena() -> Array:
	var gris := Color("555860")
	var papel := Color("b8b29e")
	var decorado := _mesa(
		[
			_pieza(Vector3(-0.5, 1.2, -0.2), Vector3(0.18, 1.4, 0.55), gris),
			_pieza(Vector3(0.0, 1.2, -0.2), Vector3(0.18, 1.4, 0.55), gris),
			_pieza(Vector3(0.5, 1.2, -0.2), Vector3(0.18, 1.4, 0.55), gris),
			_pieza(Vector3(-0.48, 1.55, 0.1), Vector3(0.12, 0.28, 0.38), papel),
			_pieza(Vector3(0.48, 0.95, 0.1), Vector3(0.12, 0.28, 0.38), papel),
		],
		Color("b8b1a2")
	)
	var giro := _plano(
		"pasillo",
		Vector3(0.0, 1.55, 1.7),
		Vector3(0.0, 1.2, -0.2),
		1.0,
		decorado,
		"El archivo estaba ordenado por número."
	)
	giro["camara_desde"] = Vector3(-0.9, 1.55, 1.7)
	return [
		giro,
		_plano(
			"cambio",
			Vector3(0.55, 1.45, 1.0),
			Vector3(0.48, 0.95, 0.1),
			1.1,
			decorado,
			"Ahora está ordenado por fecha de defunción."
		),
		_plano(
			"remate",
			Vector3(-0.55, 1.42, 1.0),
			Vector3(-0.48, 1.55, 0.1),
			0.85,
			decorado,
			"Tu carpeta está en la primera balda."
		),
	]

static func _regreso_oficina() -> Array:
	var fluorescente := Color("d9d7c5")
	var decorado := _mesa(
		[
			_pieza(
				Vector3(0, 2.4, -0.3), Vector3(1.8, 0.06, 0.22), fluorescente, true
			),
			_pieza(Vector3(0, 0.55, -0.7), Vector3(3.8, 0.08, 3.8), Color("626269")),
			_pieza(
				Vector3(0.7, 1.05, -0.55), Vector3(0.7, 0.9, 0.7), Color("4b4c52")
			),
		],
		Color("e3e0c8")
	)
	var flash := _plano(
		"flash",
		Vector3(0.0, 1.55, 1.0),
		Vector3(0.0, 1.5, -0.3),
		0.35,
		decorado
	)
	flash["fundido_desde"] = 1.0
	flash["fundido_hasta"] = 0.0
	return [
		flash,
		_plano(
			"fluorescente",
			Vector3(0.0, 1.4, 0.7),
			Vector3(0.0, 2.35, -0.3),
			0.8,
			decorado,
			"El fluorescente lleva zumbando todo el tiempo."
		),
		_plano(
			"puesto",
			Vector3(-0.35, 1.55, 1.45),
			Vector3(0.45, 1.05, -0.55),
			1.0,
			decorado,
			"Son las {hora}.",
			"En el registro no consta ninguna ausencia."
		),
	]
