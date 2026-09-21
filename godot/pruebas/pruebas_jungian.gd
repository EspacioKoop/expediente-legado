extends RefCounted
class_name PruebasJungian


static func todo(comprobar: Callable) -> void:
	GestorArquetipos.reiniciar()
	GestorMomentum.reiniciar()
	GestorCombos.reiniciar()

	comprobar.call("hay cuatro arquetipos", GestorArquetipos.arquetipos.size(), 4)
	GestorArquetipos.ganar_insight(99)
	comprobar.call(
		"99 de insight no desbloquean Persona",
		GestorArquetipos.obtener_arquetipo("persona").desbloqueado,
		false
	)
	GestorArquetipos.ganar_insight(1)
	comprobar.call(
		"100 de insight desbloquean Persona",
		GestorArquetipos.obtener_arquetipo("persona").desbloqueado,
		true
	)
	comprobar.call("cada desbloqueo da un punto de habilidad", GestorArquetipos.puntos_habilidad, 1)

	GestorArquetipos.ganar_insight(50)
	comprobar.call(
		"150 desbloquea Sombra",
		GestorArquetipos.obtener_arquetipo("sombra").desbloqueado,
		true
	)
	comprobar.call(
		"150 desbloquea Anima",
		GestorArquetipos.obtener_arquetipo("anima").desbloqueado,
		true
	)
	comprobar.call("los tres desbloqueos acumulan puntos", GestorArquetipos.puntos_habilidad, 3)

	var efectos := GestorArquetipos.efectos_combinados()
	comprobar.call("Sombra expone crítico", efectos.get("bonus_crit", 0.0), 0.15)
	comprobar.call("Persona expone evasión", efectos.get("evasion", 0.0), 0.1)
	comprobar.call("Anima expone curación", efectos.get("curacion", 0.0), 0.1)

	GestorMomentum.aplicar_modificador_arquetipo("sombra")
	var ganancia := GestorMomentum.registrar_golpe()
	comprobar.call("Sombra mejora la ganancia de momentum", ganancia > 10.0, true)
	var antes_dano := GestorMomentum.momentum_actual
	GestorMomentum.registrar_dano_recibido()
	comprobar.call(
		"recibir daño reduce momentum",
		GestorMomentum.momentum_actual < antes_dano,
		true
	)

	GestorMomentum.reiniciar()
	GestorMomentum.agregar_momentum(30.0)
	var combos: Array[String] = []
	var capturar_combo := func(nombre: String, _efectos: Dictionary): combos.append(nombre)
	GestorCombos.combo_ejecutado.connect(capturar_combo)
	GestorCombos.registrar_entrada("ataque_ligero")
	GestorCombos.registrar_entrada("ataque_ligero")
	GestorCombos.registrar_entrada("ataque_pesado")
	comprobar.call("la secuencia ejecuta Golpe de la Sombra", combos, ["Golpe de la Sombra"])
	GestorCombos.combo_ejecutado.disconnect(capturar_combo)

	GestorMomentum.reiniciar()
	GestorMomentum.agregar_momentum(75.0)
	comprobar.call(
		"con Sombra y 75 hay finisher",
		GestorCombos.finisher_disponible_actual(),
		"sombra_desatada"
	)
	comprobar.call(
		"el finisher consume momentum",
		GestorCombos.ejecutar_finisher("sombra_desatada"),
		true
	)
	comprobar.call("el finisher deja el medidor a cero", GestorMomentum.momentum_actual, 0.0)

	GestorCombos.reiniciar()
	GestorMomentum.reiniciar()
	GestorArquetipos.reiniciar()
