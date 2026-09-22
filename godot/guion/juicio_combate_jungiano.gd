## Adaptador entre el Juicio por Combate y los autoloads jungianos.
##
## Centraliza descubrimiento, ciclo de vida y señales. El orquestador conserva
## únicamente los efectos que alteran su propio estado de combate/presentación.
class_name JuicioCombateJungiano
extends RefCounted


static func gestor(anfitrion: Node, nombre: String) -> Node:
	return anfitrion.get_node_or_null("/root/" + nombre)


static func preparar(
	anfitrion: Node,
	al_arquetipo: Callable,
	al_momentum: Callable,
	al_combo: Callable,
	al_finisher: Callable,
) -> bool:
	var arquetipos := gestor(anfitrion, "GestorArquetipos")
	var momentum := gestor(anfitrion, "GestorMomentum")
	var combos := gestor(anfitrion, "GestorCombos")
	if arquetipos == null or momentum == null or combos == null:
		return false

	momentum.call("reiniciar")
	combos.call("reiniciar")
	var catalogo = arquetipos.get("arquetipos")
	if typeof(catalogo) == TYPE_DICTIONARY:
		for arquetipo_id in catalogo:
			var arquetipo = catalogo[arquetipo_id]
			if arquetipo != null and bool(arquetipo.get("desbloqueado")):
				momentum.call("aplicar_modificador_arquetipo", String(arquetipo_id))
	momentum.set("en_combate", true)

	_conectar(arquetipos, "arquetipo_desbloqueado", al_arquetipo)
	_conectar(momentum, "momentum_cambiado", al_momentum)
	_conectar(combos, "combo_ejecutado", al_combo)
	_conectar(combos, "finisher_ejecutado", al_finisher)
	return true


static func efectos_activos(anfitrion: Node) -> Dictionary:
	var arquetipos := gestor(anfitrion, "GestorArquetipos")
	if arquetipos == null:
		return {}
	var efectos = arquetipos.call("efectos_combinados")
	return efectos if typeof(efectos) == TYPE_DICTIONARY else {}


static func probabilidad_critico(efectos: Dictionary) -> float:
	return clampf(
		float(efectos.get("bonus_crit", 0.0)) + float(efectos.get("bonus_todo", 0.0)),
		0.0,
		0.75,
	)


static func bonus_evasion(efectos: Dictionary) -> float:
	return float(efectos.get("evasion", 0.0)) + float(efectos.get("bonus_todo", 0.0))


static func registrar_golpe(anfitrion: Node, es_critico: bool, fuerte: bool) -> void:
	var momentum := gestor(anfitrion, "GestorMomentum")
	if momentum != null:
		momentum.call("registrar_golpe", es_critico)
	var combos := gestor(anfitrion, "GestorCombos")
	if combos != null:
		combos.call("registrar_entrada", "ataque_pesado" if fuerte else "ataque_ligero")


static func registrar_esquiva(anfitrion: Node) -> void:
	var combos := gestor(anfitrion, "GestorCombos")
	if combos != null:
		combos.call("registrar_entrada", "esquivar")


static func registrar_dano_recibido(anfitrion: Node) -> void:
	var momentum := gestor(anfitrion, "GestorMomentum")
	if momentum != null:
		momentum.call("registrar_dano_recibido")


static func aplicar_arquetipo(anfitrion: Node, arquetipo_id: String) -> void:
	var momentum := gestor(anfitrion, "GestorMomentum")
	if momentum != null:
		momentum.call("aplicar_modificador_arquetipo", arquetipo_id)


static func ejecutar_finisher_disponible(anfitrion: Node) -> bool:
	var combos := gestor(anfitrion, "GestorCombos")
	if combos == null:
		return false
	var finisher_id := String(combos.call("finisher_disponible_actual"))
	if finisher_id.is_empty():
		return false
	return bool(combos.call("ejecutar_finisher", finisher_id))


static func estado_hud(anfitrion: Node) -> Dictionary:
	var momentum := gestor(anfitrion, "GestorMomentum")
	var combos := gestor(anfitrion, "GestorCombos")
	var estado := {
		"momentum_actual": 0.0,
		"momentum_max": 100.0,
		"finisher_id": "",
		"es_super": false,
		"disponible": false,
	}
	if momentum != null:
		estado["momentum_actual"] = float(momentum.get("momentum_actual"))
		estado["momentum_max"] = float(momentum.get("momentum_max"))
	if combos == null:
		return estado

	var finisher_id := String(combos.call("finisher_disponible_actual"))
	estado["finisher_id"] = finisher_id
	estado["disponible"] = not finisher_id.is_empty()
	if finisher_id.is_empty():
		return estado
	var catalogo = combos.get("finishers")
	if typeof(catalogo) == TYPE_DICTIONARY and catalogo.has(finisher_id):
		estado["es_super"] = bool(catalogo[finisher_id].get("es_super", false))
	return estado


static func salir_combate(anfitrion: Node) -> void:
	var momentum := gestor(anfitrion, "GestorMomentum")
	if momentum != null:
		momentum.call("salir_combate")
	var combos := gestor(anfitrion, "GestorCombos")
	if combos != null:
		combos.call("reiniciar")


static func _conectar(nodo: Node, senal: StringName, callback: Callable) -> void:
	if nodo.has_signal(senal) and not nodo.is_connected(senal, callback):
		nodo.connect(senal, callback)
