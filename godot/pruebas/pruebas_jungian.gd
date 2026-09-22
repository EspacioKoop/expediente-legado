class_name PruebasJungian
extends RefCounted


static func todo(comprobar: Callable, raiz: Node) -> void:
	var temporales: Array[Node] = []
	var arquetipos := _gestor(
		"GestorArquetipos", "res://arquetipos/gestor_arquetipos.gd", temporales, raiz
	)
	var momentum := _gestor("GestorMomentum", "res://combate/momentum.gd", temporales, raiz)
	var combos := _gestor("GestorCombos", "res://combate/combos.gd", temporales, raiz)
	comprobar.call("gestor de arquetipos disponible", arquetipos != null, true)
	comprobar.call("gestor de momentum disponible", momentum != null, true)
	comprobar.call("gestor de combos disponible", combos != null, true)
	if arquetipos == null or momentum == null or combos == null:
		return

	arquetipos.call("reiniciar")
	momentum.call("reiniciar")
	combos.call("reiniciar")

	var catalogo = arquetipos.get("arquetipos")
	comprobar.call("hay cuatro arquetipos", catalogo.size(), 4)
	arquetipos.call("ganar_insight", 99)
	comprobar.call(
		"99 de insight no desbloquean Persona",
		bool(arquetipos.call("obtener_arquetipo", "persona").get("desbloqueado")),
		false
	)
	arquetipos.call("ganar_insight", 1)
	comprobar.call(
		"100 de insight desbloquean Persona",
		bool(arquetipos.call("obtener_arquetipo", "persona").get("desbloqueado")),
		true
	)
	comprobar.call(
		"cada desbloqueo da un punto de habilidad", arquetipos.get("puntos_habilidad"), 1
	)

	arquetipos.call("ganar_insight", 50)
	comprobar.call(
		"150 desbloquea Sombra",
		bool(arquetipos.call("obtener_arquetipo", "sombra").get("desbloqueado")),
		true
	)
	comprobar.call(
		"150 desbloquea Anima",
		bool(arquetipos.call("obtener_arquetipo", "anima").get("desbloqueado")),
		true
	)
	comprobar.call("los tres desbloqueos acumulan puntos", arquetipos.get("puntos_habilidad"), 3)

	var efectos = arquetipos.call("efectos_combinados")
	(
		comprobar
		. call(
			"Sombra expone crítico",
			is_equal_approx(float(efectos.get("bonus_crit", 0.0)), 0.15),
			true,
		)
	)
	(
		comprobar
		. call(
			"Persona expone evasión",
			is_equal_approx(float(efectos.get("evasion", 0.0)), 0.1),
			true,
		)
	)
	(
		comprobar
		. call(
			"Anima expone curación",
			is_equal_approx(float(efectos.get("curacion", 0.0)), 0.1),
			true,
		)
	)

	momentum.call("aplicar_modificador_arquetipo", "sombra")
	var ganancia: float = momentum.call("registrar_golpe")
	comprobar.call("Sombra mejora la ganancia de momentum", ganancia > 10.0, true)
	var antes_dano := float(momentum.get("momentum_actual"))
	momentum.call("registrar_dano_recibido")
	comprobar.call(
		"recibir daño reduce momentum", float(momentum.get("momentum_actual")) < antes_dano, true
	)

	momentum.call("reiniciar")
	momentum.call("agregar_momentum", 30.0)
	var ejecutados: Array[String] = []
	var capturar_combo := func(nombre: String, _efectos: Dictionary): ejecutados.append(nombre)
	combos.connect("combo_ejecutado", capturar_combo)
	combos.call("registrar_entrada", "ataque_ligero")
	combos.call("registrar_entrada", "ataque_ligero")
	combos.call("registrar_entrada", "ataque_pesado")
	comprobar.call("la secuencia ejecuta Golpe de la Sombra", ejecutados, ["Golpe de la Sombra"])
	combos.disconnect("combo_ejecutado", capturar_combo)

	momentum.call("reiniciar")
	momentum.call("agregar_momentum", 75.0)
	comprobar.call(
		"con Sombra y 75 hay finisher", combos.call("finisher_disponible_actual"), "sombra_desatada"
	)
	comprobar.call(
		"el finisher consume momentum", combos.call("ejecutar_finisher", "sombra_desatada"), true
	)
	comprobar.call("el finisher deja el medidor a cero", momentum.get("momentum_actual"), 0.0)

	combos.call("reiniciar")
	momentum.call("reiniciar")
	arquetipos.call("reiniciar")
	for nodo in temporales:
		if is_instance_valid(nodo):
			nodo.free()


static func _gestor(nombre: String, ruta: String, temporales: Array[Node], raiz: Node) -> Node:
	var existente := raiz.get_node_or_null(nombre)
	if existente != null:
		return existente
	var script = load(ruta)
	if script == null:
		return null
	var instancia = script.new()
	if not (instancia is Node):
		return null
	instancia.name = nombre
	raiz.add_child(instancia)
	temporales.append(instancia)
	return instancia
