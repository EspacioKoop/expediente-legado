extends SceneTree

var pasadas := 0
var fallos := 0

const DIALOGO := "biblioteca_calderon_apariencia"


func _initialize() -> void:
	_probar_catalogo_y_dos_ramas()
	_probar_insight_con_procedencia()
	_probar_reentrada_idempotente()
	_probar_dos_consumidores()
	_probar_exposicion_no_es_identidad()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_catalogo_y_dos_ramas() -> void:
	var dialogo := LiteraturaDialogo.obtener(DIALOGO)
	_comprobar(not dialogo.is_empty(), "carga el primer dialogo literario")
	var ramas: Array = dialogo.get("ramas", [])
	_comprobar(ramas.size() == 2, "el primer dialogo ofrece dos ramas")
	if ramas.size() < 2:
		return
	_comprobar(
		String(ramas[0].get("insight_id", "")) == String(ramas[1].get("insight_id", "")),
		"las dos lecturas convergen en un insight contextual comun",
	)
	_comprobar(
		not String(ramas[0].get("consecuencia_visible", "")).is_empty(),
		"la primera rama declara una consecuencia visible",
	)
	_comprobar(
		not String(ramas[1].get("consecuencia_visible", "")).is_empty(),
		"la segunda rama declara una consecuencia visible",
	)


func _probar_insight_con_procedencia() -> void:
	var registro := LiteraturaEventos.nuevo()
	var resultado := LiteraturaDialogo.conversar(
		registro,
		DIALOGO,
		"eleccion",
		"npc:biblioteca:mediadora_98",
		4,
	)
	_comprobar(bool(resultado["valida"]), "la rama valida se resuelve")
	_comprobar(bool(resultado["insight_nuevo"]), "la primera conversacion registra insight")
	_comprobar(
		not String(resultado["consecuencia_visible"]).is_empty(),
		"la conversacion devuelve consecuencia visible",
	)

	var insights := LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_INSIGHT)
	_comprobar(insights.size() == 1, "solo se registra un insight")
	if insights.is_empty():
		return
	var insight: Dictionary = insights[0]
	var metadatos: Dictionary = insight.get("metadatos", {})
	_comprobar(
		String(insight.get("fuente", "")) == "npc:biblioteca:mediadora_98",
		"el insight conserva la procedencia del NPC",
	)
	_comprobar(int(insight.get("jornada", 0)) == 4, "el insight conserva la jornada")
	_comprobar(
		String(metadatos.get("rama_id", "")) == "eleccion",
		"el insight conserva la rama observada",
	)
	_comprobar(
		String(metadatos.get("movimiento_id", "")) == "barroco",
		"el movimiento queda como contexto del evento",
	)


func _probar_reentrada_idempotente() -> void:
	var registro := LiteraturaEventos.nuevo()
	var primera := LiteraturaDialogo.conversar(
		registro,
		DIALOGO,
		"eleccion",
		"npc:biblioteca:mediadora_98",
		2,
	)
	var repetida := LiteraturaDialogo.conversar(
		registro,
		DIALOGO,
		"eleccion",
		"npc:biblioteca:mediadora_98",
		3,
	)
	var otra_rama := LiteraturaDialogo.conversar(
		registro,
		DIALOGO,
		"representacion",
		"npc:biblioteca:mediadora_98",
		3,
	)
	_comprobar(bool(primera["insight_nuevo"]), "la primera entrada crea el hecho")
	_comprobar(not bool(repetida["insight_nuevo"]), "repetir la rama no duplica")
	_comprobar(not bool(otra_rama["insight_nuevo"]), "la otra rama no duplica el mismo insight")
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_INSIGHT).size() == 1,
		"la reentrada mantiene un solo evento",
	)


func _probar_dos_consumidores() -> void:
	var registro := LiteraturaEventos.nuevo()
	LiteraturaDialogo.conversar(
		registro,
		DIALOGO,
		"representacion",
		"npc:biblioteca:mediadora_98",
		5,
	)
	var reentrada := LiteraturaDialogoReentrada.resolver(registro, DIALOGO)
	var contexto := LiteraturaMovimientoContexto.resolver(registro, DIALOGO)
	_comprobar(bool(reentrada["disponible"]), "el NPC consume el insight en reentrada")
	_comprobar(bool(contexto["disponible"]), "la ficha contextual consume el mismo insight")
	_comprobar(
		String(reentrada["consumidor"]) != String(contexto["consumidor"]),
		"son consumidores distintos",
	)
	_comprobar(
		String(reentrada["insight_id"]) == String(contexto["insight_id"]),
		"ambos consumen el mismo insight",
	)
	_comprobar(
		String(reentrada["fuente"]) == String(contexto["fuente"]),
		"ambos conservan la misma procedencia",
	)
	_comprobar(not String(reentrada["texto"]).is_empty(), "la reentrada produce variante de dialogo")
	_comprobar(not String(contexto["texto"]).is_empty(), "el movimiento produce contexto utilizable")


func _probar_exposicion_no_es_identidad() -> void:
	var registro := LiteraturaEventos.nuevo()
	LiteraturaDialogo.conversar(
		registro,
		DIALOGO,
		"eleccion",
		"npc:biblioteca:mediadora_98",
		1,
	)
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_CONOCIMIENTO).is_empty(),
		"hablar no finge haber completado la obra",
	)
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_POSESION).is_empty(),
		"hablar no concede posesion",
	)
	_comprobar(
		LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_RITUAL).is_empty(),
		"hablar no activa ritual",
	)
	var serializado := JSON.stringify(registro).to_lower()
	for palabra in ["alineamiento", "afiliacion", "reputacion", "arquetipo"]:
		_comprobar(not serializado.contains(palabra), "el registro no crea %s" % palabra)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO #1180: %s" % nombre)
