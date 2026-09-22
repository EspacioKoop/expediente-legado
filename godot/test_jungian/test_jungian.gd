extends Node


func _ready() -> void:
	print("Testing Jungian integration")
	var arquetipos = GestorArquetipos
	print("Insight:", arquetipos.insight_total)
	arquetipos.ganar_insight(200)
	print("Insight after gain:", arquetipos.insight_total)
	print("Arquetipos desbloqueados:")
	for id in ["sombra", "anima", "persona", "self"]:
		var arquetipo = arquetipos.obtener_arquetipo(id)
		if arquetipo != null:
			print("  %s: desbloqueado=%s" % [id, arquetipo.desbloqueado])
	var momentum = GestorMomentum
	print("Momentum inicial:", momentum.momentum_actual)
	momentum.registrar_golpe(true)
	print("Momentum después de golpe crítico:", momentum.momentum_actual)
