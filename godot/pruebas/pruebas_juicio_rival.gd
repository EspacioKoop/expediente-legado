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


static func _caso(comprobar: Callable, nombre: String, obtenido, esperado) -> void:
	comprobar.call(nombre, obtenido, esperado)
