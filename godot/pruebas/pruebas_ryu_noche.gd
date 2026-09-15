## Smoke aislado del vertical nocturno Ryū (#440).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var ryu := SuenoRyu.new()
	ryu.reduccion_movimiento = true
	ryu.preparar()
	root.add_child(ryu)

	var arquitectura := ryu.get_node_or_null("ArquitecturaRyu")
	_comprobar(arquitectura != null, "arquitectura montada")
	if arquitectura == null:
		_finalizar(ryu, null)
		return

	_comprobar(
		arquitectura.get_node_or_null("DragonProcedural/Cabeza") != null,
		"dragón procedural reconocible",
	)
	var lluvia := arquitectura.get_node_or_null("LluviaSuspendida")
	_comprobar(lluvia != null, "lluvia montada")
	if lluvia != null:
		_comprobar(lluvia.get_child_count() == 8, "reducción de movimiento reduce lluvia")

	var cauce := arquitectura.get_node_or_null("CauceActivo")
	_comprobar(cauce != null, "cauce declarativo montado")
	if cauce != null:
		_comprobar(cauce.get_child_count() == 8, "cauce contiene ocho tramos")

	var actor := Node.new()
	actor.name = "ActorPrueba"
	root.add_child(actor)
	var compuerta_1 := arquitectura.get_node_or_null("CompuertaCauce1") as Interactuable3D
	var compuerta_2 := arquitectura.get_node_or_null("CompuertaCauce2") as Interactuable3D
	var compuerta_3 := arquitectura.get_node_or_null("CompuertaCauce3") as Interactuable3D
	_comprobar(
		compuerta_1 != null and compuerta_2 != null and compuerta_3 != null, "tres compuertas"
	)
	if compuerta_1 != null and compuerta_2 != null and compuerta_3 != null:
		# Las tres empiezan opuestas a sus guías. Una interacción deliberada por
		# compuerta basta para reconstruir el cauce objetivo [true, false, true].
		compuerta_1.interactuar(actor)
		compuerta_2.interactuar(actor)
		compuerta_3.interactuar(actor)
		_comprobar(ryu.estado_compuertas() == [true, false, true], "estado objetivo")
		_comprobar(ryu.resuelto(), "flujo resuelto")
		_comprobar(not compuerta_1.interactuar(actor), "compuertas bloqueadas tras resolver")

	_finalizar(ryu, actor)


func _finalizar(ryu: Node, actor: Node) -> void:
	if is_instance_valid(actor):
		actor.queue_free()
	if is_instance_valid(ryu):
		ryu.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO Ryū: " + nombre)
