class_name PruebasJuicioJungiano
extends RefCounted


static func todo(comprobar: Callable) -> void:
	_caso(
		comprobar,
		"jungiano: crítico suma Sombra y bonus transversal",
		is_equal_approx(
			JuicioCombateJungiano.probabilidad_critico({"bonus_crit": 0.15, "bonus_todo": 0.10}),
			0.25,
		),
		true,
	)
	_caso(
		comprobar,
		"jungiano: crítico queda limitado",
		is_equal_approx(JuicioCombateJungiano.probabilidad_critico({"bonus_crit": 1.0}), 0.75),
		true,
	)
	_caso(
		comprobar,
		"jungiano: evasión suma Persona y bonus transversal",
		is_equal_approx(
			JuicioCombateJungiano.bonus_evasion({"evasion": 0.10, "bonus_todo": 0.05}),
			0.15,
		),
		true,
	)


static func _caso(comprobar: Callable, nombre: String, obtenido, esperado) -> void:
	comprobar.call(nombre, obtenido, esperado)
