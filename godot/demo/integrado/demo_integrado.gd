extends Node3D


func _ready() -> void:
	print("Demo Integrado iniciado")
	print("Insight inicial:", GestorArquetipos.insight_total)
	print("Arquetipos desbloqueados:")
	for id in ["sombra", "anima", "persona", "self"]:
		var arquetipo = GestorArquetipos.obtener_arquetipo(id)
		if arquetipo != null:
			print("  %s: %s" % [id, arquetipo.desbloqueado])

	GestorLiteratura.conocer_obra("odisea")
	print("Despues de leer Odisea:")
	print("  Insight:", GestorArquetipos.insight_total)
	var sombra = GestorArquetipos.obtener_arquetipo("sombra")
	print("  Arquetipo sombra desbloqueado?", sombra != null and bool(sombra.desbloqueado))

	GestorMomentum.registrar_golpe(true)
	GestorMomentum.registrar_golpe()
	GestorMomentum.registrar_golpe()
	print("Momentum tras 3 golpes:", GestorMomentum.momentum_actual)
