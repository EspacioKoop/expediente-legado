## Regresión del plan de navegación jugable de Crónicas (#2589).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	_probar_rutas_y_bloqueos()
	print("Crónicas capítulo 2589: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_rutas_y_bloqueos() -> void:
	var catalogo := CronicasCapituloRutas.catalogo()
	_comprobar(catalogo.size() == 10, "diez escenas originales en tres actos")
	_comprobar(
		catalogo[0]["escena"] == "res://escenas/cronicas/bastion_nombres_ausentes.tscn",
		"la vertical existente abre el episodio",
	)
	var ids := []
	for etapa in catalogo:
		var id := String(etapa.get("id", ""))
		_comprobar(not ids.has(id), "sin IDs de etapa repetidos")
		ids.append(id)
	catalogo.clear()
	_comprobar(CronicasCapituloRutas.catalogo().size() == 10, "catálogo inmutable por API")

	var sesion := CronicasCapituloRutas.nueva_sesion()
	var original := JSON.stringify(sesion)
	var inicio := CronicasCapituloRutas.etapa_actual(sesion)
	_comprobar(inicio.get("id") == "bastion", "inicio enlaza con Bastión original")
	_comprobar(
		inicio.get("estado") == CronicasCapituloRutas.ESTADO_JUGABLE,
		"el Bastión integrado es una escena cargable",
	)
	_comprobar(
		not bool(CronicasCapituloRutas.registrar_salida(sesion, "bastion", false)["registrado"]),
		"abrir escena sin completarla no adelanta progreso",
	)
	_comprobar(
		not bool(
			CronicasCapituloRutas.registrar_salida(sesion, "torre_tiempo", true)["registrado"]
		),
		"no permite saltar estancias",
	)
	var primera := CronicasCapituloRutas.registrar_salida(sesion, "bastion", true)
	_comprobar(bool(primera["registrado"]), "acepta salida real de Bastión")
	_comprobar(JSON.stringify(sesion) == original, "no muta sesión de entrada")
	var siguiente: Dictionary = primera["siguiente"]
	_comprobar(siguiente.get("id") == "patio_juramentos", "siguiente estancia prevista")
	_comprobar(
		(
			[
				CronicasCapituloRutas.ESTADO_PENDIENTE,
				CronicasCapituloRutas.ESTADO_JUGABLE,
			]
			. has(String(siguiente.get("estado", "")))
		),
		"nueva sala indica si está disponible sin saltársela",
	)
	var progreso: Dictionary = primera["sesion"]
	_comprobar(
		not bool(CronicasCapituloRutas.registrar_salida(progreso, "bastion", true)["registrado"]),
		"señal duplicada de Bastión no concede segundo avance",
	)
	_comprobar(
		CronicasCapituloRutas.etapa_actual(progreso) == siguiente,
		"reanudar la sesión produce el mismo punto exacto",
	)
	_comprobar(
		(
			CronicasCapituloRutas.etapa_actual({}).get("estado")
			== CronicasCapituloRutas.ESTADO_INVALIDO
		),
		"estado ausente falla cerrado",
	)
	_comprobar(
		(
			(
				CronicasCapituloRutas
				. etapa_actual(
					{"capitulo": CronicasCapituloRutas.CAPITULO, "completadas": ["torre_tiempo"]}
				)
				. get("estado")
			)
			== CronicasCapituloRutas.ESTADO_INVALIDO
		),
		"progreso adulterado y fuera de orden no concede atajos",
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("Crónicas capítulo: " + mensaje)
