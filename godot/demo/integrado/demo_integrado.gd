extends Node3D


func _ready() -> void:
	var arquetipos := get_node_or_null("/root/GestorArquetipos")
	var literatura := get_node_or_null("/root/GestorLiteratura")
	var momentum := get_node_or_null("/root/GestorMomentum")
	if arquetipos == null or literatura == null or momentum == null:
		push_warning("Demo integrada sin gestores jungianos disponibles")
		return

	print("Demo integrada iniciada")
	print("Insight inicial: ", arquetipos.get("insight_total"))
	print("Arquetipos desbloqueados:")
	for arquetipo_id in ["sombra", "anima", "persona", "self"]:
		var arquetipo = arquetipos.call("obtener_arquetipo", arquetipo_id)
		if arquetipo != null:
			print("  %s: %s" % [arquetipo_id, bool(arquetipo.get("desbloqueado"))])

	literatura.call("conocer_obra", "odisea")
	print("Después de leer Odisea:")
	print("  Insight: ", arquetipos.get("insight_total"))
	var sombra = arquetipos.call("obtener_arquetipo", "sombra")
	print("  Sombra desbloqueada: ", sombra != null and bool(sombra.get("desbloqueado")))

	momentum.call("registrar_golpe", true)
	momentum.call("registrar_golpe")
	momentum.call("registrar_golpe")
	print("Momentum tras 3 golpes: ", momentum.get("momentum_actual"))
