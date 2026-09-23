class_name PruebasJuicioJugador
extends RefCounted


static func todo(comprobar: Callable) -> void:
	var base := JuicioCombateJugador.resolver_impacto(1, 0, false, false, {}, false, "", 0)
	_caso(comprobar, "jugador: impacto base conserva daño", base["dano"], 1)
	_caso(comprobar, "jugador: impacto base no interrumpe", base["interrumpir_rival"], false)

	var fuerte := (
		JuicioCombateJugador
		. resolver_impacto(
			2,
			1,
			true,
			true,
			{
				"dano_fuerte_bonus": 2,
				"interrumpe_telegrafo_fuerte": true,
				"dano_interrupcion_bonus": 1,
			},
			true,
			"",
			0,
		)
	)
	_caso(comprobar, "jugador: suma combo crítico y ritual", fuerte["dano"], 7)
	_caso(comprobar, "jugador: ritual fuerte interrumpe rival", fuerte["interrumpir_rival"], true)

	var asamblea := JuicioCombateJugador.resolver_impacto(
		1, 0, false, false, {}, true, "comunismo", 0
	)
	_caso(comprobar, "jugador: asamblea interrumpe ataque", asamblea["interrumpir_rival"], true)
	_caso(comprobar, "jugador: asamblea cierra doctrina", asamblea["cerrar_doctrina"], true)

	var contra := JuicioCombateJugador.resolver_impacto(1, 0, false, false, {}, false, "", 2)
	_caso(comprobar, "jugador: contraataque se suma al daño", contra["dano"], 3)
	_caso(
		comprobar,
		"jugador: contraataque se marca para consumo",
		contra["consumir_contraataque"],
		true,
	)

	var externalizado := JuicioCombateJugador.resolver_impacto(
		2, 0, false, false, {}, false, "neoliberal", 0
	)
	_caso(comprobar, "jugador: externalización duplica daño", externalizado["dano"], 4)
	_caso(
		comprobar,
		"jugador: externalización cierra doctrina",
		externalizado["cerrar_doctrina"],
		true,
	)

	var enredo := JuicioCombateJugador.resolver_impacto(
		1, 0, false, false, {"enredo_ligero_segundos": 0.75}, false, "", 0
	)
	_caso(
		comprobar,
		"jugador: ataque ligero conserva enredo ritual",
		is_equal_approx(float(enredo["enredo_segundos"]), 0.75),
		true,
	)
	var fuerte_sin_enredo := JuicioCombateJugador.resolver_impacto(
		1, 0, false, true, {"enredo_ligero_segundos": 0.75}, false, "", 0
	)
	_caso(
		comprobar,
		"jugador: ataque fuerte no aplica enredo ligero",
		fuerte_sin_enredo["enredo_segundos"],
		0.0,
	)

	_caso(
		comprobar,
		"jugador: bonus de evasión escala duración",
		is_equal_approx(JuicioCombateJugador.duracion_esquiva(0.5), 0.51),
		true,
	)

	var paso := JuicioCombateJugador.plan_movimiento(
		Vector3.ZERO, Vector2(1.0, 0.0), 4.8, false, 5.0, 0.5
	)
	_caso(
		comprobar,
		"jugador: avanza a su velocidad sin esquiva",
		(paso["posicion"] as Vector3).is_equal_approx(Vector3(2.4, 0.0, 0.0)),
		true,
	)
	_caso(
		comprobar,
		"jugador: se orienta hacia la entrada",
		is_equal_approx(float(paso["rotacion_y"]), PI / 2.0),
		true,
	)
	var diagonal := JuicioCombateJugador.plan_movimiento(
		Vector3.ZERO, Vector2(1.0, 1.0), 1.0, false, 5.0, 1.0
	)
	_caso(
		comprobar,
		"jugador: la diagonal no corre más que un eje",
		is_equal_approx((diagonal["posicion"] as Vector3).length(), 1.0),
		true,
	)
	var esquivando := JuicioCombateJugador.plan_movimiento(
		Vector3.ZERO, Vector2(0.0, 1.0), 1.0, true, 5.0, 1.0
	)
	_caso(
		comprobar,
		"jugador: la esquiva multiplica la velocidad",
		(esquivando["posicion"] as Vector3).is_equal_approx(Vector3(0.0, 0.0, 2.25)),
		true,
	)
	var borde := JuicioCombateJugador.plan_movimiento(
		Vector3(4.5, 0.0, 0.0), Vector2(1.0, 0.0), 4.8, false, 5.0, 1.0
	)
	_caso(
		comprobar,
		"jugador: el paso no sale de la arena",
		(borde["posicion"] as Vector3).is_equal_approx(Vector3(5.0, 0.0, 0.0)),
		true,
	)
	var quieto := JuicioCombateJugador.plan_movimiento(
		Vector3(1.0, 0.0, 1.0), Vector2(0.05, 0.0), 4.8, false, 5.0, 0.0
	)
	_caso(comprobar, "jugador: entrada residual no reorienta", quieto["orientar"], false)

	var sin_bono := JuicioCombateJugador.contraataque_tras_esquiva({}, 1)
	_caso(comprobar, "jugador: esquiva sin ritual no aplica bono", sin_bono["aplica"], false)
	_caso(
		comprobar, "jugador: esquiva sin ritual conserva contraataque", sin_bono["contraataque"], 1
	)
	var con_bono := JuicioCombateJugador.contraataque_tras_esquiva({"contraataque_esquiva": 1}, 0)
	_caso(comprobar, "jugador: esquiva ritual deja contraataque", con_bono["contraataque"], 1)
	var acumulado := JuicioCombateJugador.contraataque_tras_esquiva({"contraataque_esquiva": 1}, 3)
	_caso(comprobar, "jugador: el bono no se acumula", acumulado["contraataque"], 3)


static func _caso(comprobar: Callable, nombre: String, obtenido, esperado) -> void:
	comprobar.call(nombre, obtenido, esperado)
