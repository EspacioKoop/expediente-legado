extends "res://arquetipos/arquetipo_base.gd"


func _init() -> void:
	configurar(
		"anima",
		"Anima/Animus",
		"Contraparte interior que guía y sana",
		{"curacion": 0.1, "resistencia_elemental": 0.15},
		150
	)
