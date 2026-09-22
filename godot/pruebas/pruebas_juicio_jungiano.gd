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

	var combo := JuicioCombateJungiano.aplicar_combo(
		1,
		5,
		0,
		0.1,
		{
			"dano_multiplier": 2.0,
			"dano": 2,
			"curacion": 2,
			"contragolpe": true,
			"evasion_temporal": true,
			"duracion": 1.2,
		},
		8,
	)
	_caso(comprobar, "jungiano: combo acumula daño pendiente", combo["dano_combo_pendiente"], 4)
	_caso(comprobar, "jungiano: combo cura sin superar máximo", combo["determinacion_jugador"], 7)
	_caso(comprobar, "jungiano: combo arma contragolpe", combo["contraataque"], 1)
	_caso(
		comprobar,
		"jungiano: combo amplía evasión temporal",
		is_equal_approx(float(combo["esquiva"]), 1.2),
		true,
	)

	var finisher := JuicioCombateJungiano.aplicar_finisher(
		5, 3, 0.2, {"dano": 2, "curacion_total": true, "invulnerabilidad": 1.1}, false, 8
	)
	_caso(comprobar, "jungiano: finisher aplica daño", finisher["determinacion_rival"], 3)
	_caso(comprobar, "jungiano: finisher cura al máximo", finisher["determinacion_jugador"], 8)
	_caso(
		comprobar,
		"jungiano: finisher conserva invulnerabilidad mayor",
		is_equal_approx(float(finisher["invulnerabilidad"]), 1.1),
		true,
	)
	_caso(
		comprobar,
		"jungiano: finisher normal fija sacudida",
		is_equal_approx(float(finisher["sacudida_camara"]), 0.24),
		true,
	)

	var curacion := JuicioCombateJungiano.aplicar_curacion_arquetipo(
		5, 0.75, {"curacion": 0.3}, 8
	)
	_caso(
		comprobar,
		"jungiano: curación acumulada suma un punto",
		curacion["determinacion_jugador"],
		6,
	)
	_caso(
		comprobar,
		"jungiano: curación conserva fracción restante",
		is_equal_approx(float(curacion["acumulada"]), 0.05),
		true,
	)


static func _caso(comprobar: Callable, nombre: String, obtenido, esperado) -> void:
	comprobar.call(nombre, obtenido, esperado)
