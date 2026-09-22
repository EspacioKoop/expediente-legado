extends "res://arquetipos/arquetipo_base.gd"


func _init() -> void:
	super(
		"anima",
		"Anima/Animus",
		"Contraparte interior que guía y sana",
		{"curacion_aliados": 0.1, "resistencia_elemental": 0.15},
		150,
	)
