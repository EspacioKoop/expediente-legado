## Smoke aislado de la integración nocturna de la Hidra (#439).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var jornada := {"dia": 4}
	_comprobar(
		SemillasOniricas.activar_semilla_onirica(jornada, "hidra", "rom:hydra_loop_98", 2),
		"semilla Hidra válida",
	)

	var encuentro := SuenoHidraInteraccion3D.new()
	root.add_child(encuentro)
	_comprobar(
		encuentro.configurar(SemillasOniricas.obtener_semillas(jornada), true, 3),
		"encuentro habilitado por semilla",
	)

	var hidra := encuentro.get_node_or_null("HidraProcedural") as SuenoHidra
	var sintoma := encuentro.get_node_or_null("SintomaHidra") as Interactuable3D
	var conexiones := encuentro.get_node_or_null("ConexionesHidra") as Interactuable3D
	var nodo := encuentro.get_node_or_null("NodoComunHidra") as Interactuable3D
	_comprobar(hidra != null, "vertical procedural montado")
	_comprobar(
		sintoma != null and conexiones != null and nodo != null,
		"tres intenciones jugables montadas",
	)

	var actor := Node.new()
	actor.name = "ActorPrueba"
	root.add_child(actor)

	if hidra != null:
		_comprobar(hidra.modo_aparicion() == "fundido_discreto", "reducción de movimiento")

	if sintoma != null and conexiones != null and nodo != null:
		_comprobar(not nodo.interactuar(actor), "nodo bloqueado antes de deducir la raíz")
		_comprobar(sintoma.interactuar(actor), "primer síntoma interactuable")
		_comprobar(sintoma.interactuar(actor), "segundo síntoma interactuable")
		var estado := encuentro.estado_actual()
		_comprobar(
			int(estado.get("cabezas", 0)) > SuenoHidra.CABEZAS_INICIALES, "proliferación visible"
		)
		_comprobar(int(estado.get("regeneraciones", 0)) == 1, "regeneración arquitectónica")
		_comprobar(estado.get("nodo_legible", false) == true, "raíz deducible tras insistir")
		if hidra != null:
			var conexiones_visuales := hidra.get_node_or_null("ConexionesRaiz")
			_comprobar(
				conexiones_visuales != null
				and conexiones_visuales.get_child_count() == int(estado.get("cabezas", 0)),
				"cada cabeza mantiene conexión visual con la raíz",
			)
		_comprobar(nodo.habilitado, "nodo común habilitado al ser legible")
		_comprobar(nodo.interactuar(actor), "intervención explícita sobre el nodo")
		_comprobar(encuentro.resuelta(), "Hidra resuelta por causa común")
		if hidra != null:
			var semilla_final := hidra.get_node_or_null("ResolucionHidra/SemillaHydraLoopFinal")
			var conexiones_finales := hidra.get_node_or_null("ConexionesRaiz")
			_comprobar(semilla_final != null, "la Hidra colapsa al cartucho que sembró el sueño")
			_comprobar(
				conexiones_finales != null and conexiones_finales.get_child_count() == 0,
				"las conexiones desaparecen al resolver la causa",
			)
		_comprobar(not sintoma.interactuar(actor), "síntomas bloqueados tras resolver")
		_comprobar(not conexiones.interactuar(actor), "observación bloqueada tras resolver")

	_finalizar(encuentro, actor)


func _finalizar(encuentro: Node, actor: Node) -> void:
	if is_instance_valid(actor):
		actor.queue_free()
	if is_instance_valid(encuentro):
		encuentro.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO Hidra: " + nombre)
