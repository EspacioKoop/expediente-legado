class_name PruebasJuicioRival
extends RefCounted


static func todo(comprobar: Callable) -> void:
	var paso := (
		JuicioCombateRival
		. plan_movimiento(
			Vector3(3.0, 0.0, 0.0),
			Vector3.ZERO,
			1.0,
			2.5,
			0.0,
			{},
			1.0,
		)
	)
	_caso(
		comprobar,
		"rival: avanza hacia el jugador fuera de alcance",
		paso["desplazamiento"],
		Vector3(2.5, 0.0, 0.0),
	)
	_caso(
		comprobar,
		"rival: no inicia ataque mientras avanza",
		paso["iniciar_ataque"],
		false,
	)

	var paso_sin_delta := (
		JuicioCombateRival
		. plan_movimiento(
			Vector3(3.0, 0.0, 0.0),
			Vector3.ZERO,
			1.0,
			2.5,
			0.0,
			{},
			0.0,
		)
	)
	_caso(
		comprobar,
		"rival: conserva intención de orientar con delta cero",
		paso_sin_delta["mover"],
		true,
	)

	var enredado := (
		JuicioCombateRival
		. plan_movimiento(
			Vector3(3.0, 0.0, 0.0),
			Vector3.ZERO,
			1.0,
			2.5,
			1.0,
			{"velocidad_enredado_mul": 0.5},
			1.0,
		)
	)
	_caso(
		comprobar,
		"rival: el ritual de enredo reduce desplazamiento",
		enredado["desplazamiento"],
		Vector3(1.25, 0.0, 0.0),
	)

	var listo := (
		JuicioCombateRival
		. plan_movimiento(
			Vector3(1.0, 0.0, 0.0),
			Vector3.ZERO,
			0.0,
			2.5,
			0.0,
			{},
			1.0,
		)
	)
	_caso(comprobar, "rival: dentro de alcance inicia ataque", listo["iniciar_ataque"], true)

	var telegrafo := JuicioCombateRival.iniciar_telegrafo(true, {"tags": ["telegraph"]})
	_caso(
		comprobar,
		"rival: Comisión amplía el telegrafiado",
		float(telegrafo["total"]) > JuicioCombateReglas.TELEGRAFO_RIVAL,
		true,
	)

	var avance := JuicioCombateRival.avanzar_telegrafo(0.45, 0.45, 0.20)
	_caso(
		comprobar,
		"rival: avanzar telegrafiado conserva tiempo restante",
		is_equal_approx(float(avance["restante"]), 0.25),
		true,
	)
	_caso(
		comprobar,
		"rival: telegrafiado parcial no resuelve",
		avance["resolver"],
		false,
	)
	var agotado := JuicioCombateRival.avanzar_telegrafo(0.10, 0.45, 0.20)
	_caso(comprobar, "rival: telegrafiado agotado resuelve", agotado["resolver"], true)

	var impacto := JuicioCombateRival.resolver_ataque(1.0, 0.0)
	_caso(comprobar, "rival: resolución conserva resultado", impacto["resultado"], "impacto")
	_caso(
		comprobar,
		"rival: resolución restaura recarga base",
		is_equal_approx(float(impacto["recarga"]), JuicioCombateReglas.RECARGA_RIVAL),
		true,
	)

	var cancelado := JuicioCombateRival.cancelar_telegrafo(0.0)
	_caso(
		comprobar,
		"rival: cancelar deja una recarga mínima",
		float(cancelado["recarga"]) > 0.0,
		true,
	)
	_caso(
		comprobar,
		"rival: cancelar restaura el total base",
		cancelado["total"],
		JuicioCombateReglas.TELEGRAFO_RIVAL,
	)

	_impactos_en_jugador(comprobar)
	_retornos(comprobar)
	_mesa(comprobar)


static func _impactos_en_jugador(comprobar: Callable) -> void:
	var golpe := JuicioCombateRival.resolver_impacto_en_jugador("impacto", 8, 0.0, "")
	_caso(comprobar, "rival: un impacto resta uno", golpe["determinacion_jugador"], 7)
	_caso(comprobar, "rival: un impacto no cierra doctrina", golpe["cerrar_comision"], false)

	var externalizado := JuicioCombateRival.resolver_impacto_en_jugador(
		"impacto", 8, 0.0, "neoliberal"
	)
	_caso(comprobar, "rival: Externalizar duplica el golpe", externalizado["dano"], 2)
	_caso(
		comprobar,
		"rival: Externalizar se consume con el golpe",
		externalizado["cerrar_externalizar"],
		true,
	)

	var negado := JuicioCombateRival.resolver_impacto_en_jugador("impacto", 1, 0.4, "neoliberal")
	_caso(comprobar, "rival: la invulnerabilidad niega el golpe", negado["desenlace"], "negado")
	_caso(comprobar, "rival: un golpe negado no resta", negado["determinacion_jugador"], 1)
	_caso(comprobar, "rival: un golpe negado no derrota", negado["derrota"], false)
	_caso(
		comprobar,
		"rival: un golpe negado no gasta Externalizar",
		negado["cerrar_externalizar"],
		false,
	)

	var esquivado := JuicioCombateRival.resolver_impacto_en_jugador(
		"esquiva", 1, 0.0, "socialdemocrata"
	)
	_caso(comprobar, "rival: la esquiva no resta", esquivado["determinacion_jugador"], 1)
	_caso(
		comprobar,
		"rival: Comisión termina aunque el golpe se esquive",
		esquivado["cerrar_comision"],
		true,
	)
	var fallado := JuicioCombateRival.resolver_impacto_en_jugador("falla", 1, 0.0, "")
	_caso(comprobar, "rival: fuera de alcance falla", fallado["desenlace"], "falla")

	var ultimo := JuicioCombateRival.resolver_impacto_en_jugador("impacto", 1, 0.0, "")
	_caso(comprobar, "rival: el último punto derrota", ultimo["derrota"], true)
	var suelo := JuicioCombateRival.resolver_impacto_en_jugador("impacto", 1, 0.0, "neoliberal")
	_caso(comprobar, "rival: la determinación no baja de cero", suelo["determinacion_jugador"], 0)


static func _retornos(comprobar: Callable) -> void:
	var ritual := {"retornos_rival": 1, "determinacion_retorno": 3}
	var primero := JuicioCombateRival.retorno(ritual, 0)
	_caso(comprobar, "rival: el ritual concede un retorno", primero["acepta"], true)
	_caso(comprobar, "rival: el retorno repone determinación", primero["determinacion"], 3)
	_caso(comprobar, "rival: el retorno se cuenta", primero["retornos"], 1)
	_caso(
		comprobar,
		"rival: el retorno deja media recarga",
		is_equal_approx(float(primero["recarga"]), JuicioCombateReglas.RECARGA_RIVAL * 0.5),
		true,
	)
	var agotado := JuicioCombateRival.retorno(ritual, 1)
	_caso(comprobar, "rival: sin retornos restantes termina", agotado["acepta"], false)
	_caso(comprobar, "rival: un retorno rechazado no se cuenta", agotado["retornos"], 1)
	_caso(
		comprobar,
		"rival: sin ritual no hay retorno",
		JuicioCombateRival.retorno({}, 0)["acepta"],
		false
	)


static func _mesa(comprobar: Callable) -> void:
	var apartado := JuicioCombateRival.posicion_mesa(
		Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.6, 0.5), 3.0
	)
	_caso(
		comprobar,
		"rival: Mesa aparta en el plano a la distancia pedida",
		apartado.is_equal_approx(Vector3(1.0, 0.0, 3.0)),
		true,
	)
	var encima := JuicioCombateRival.posicion_mesa(
		Vector3(2.0, 0.0, 2.0), Vector3(2.0, 1.0, 2.0), 3.0
	)
	_caso(
		comprobar,
		"rival: Mesa usa una dirección fija si se solapan",
		encima.is_equal_approx(Vector3(2.0, 0.0, -1.0)),
		true,
	)


static func _caso(comprobar: Callable, nombre: String, obtenido, esperado) -> void:
	comprobar.call(nombre, obtenido, esperado)
