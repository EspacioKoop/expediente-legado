extends "res://arquetipos/arquetipo_base.gd"


func _init() -> void:
	super(
		"persona",
		"Persona",
		"Máscara social que adapta al entorno",
		{"evasion": 0.1, "bonus_social": 0.2},
		100,
	)
