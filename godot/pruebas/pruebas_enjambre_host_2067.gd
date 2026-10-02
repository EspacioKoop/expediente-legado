## Regresion runtime del ENJAMBRE real (#2067/#2120).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const PASO := 1.0 / 60.0
const RAIZ := 2067

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	await _probar_montaje()
	await _probar_presupuesto_e_impacto()
	await _probar_cuerpos_debiles_y_resolucion_unica()
	await _probar_reduccion_movimiento()
	print("enjambre_host_2067: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_montaje() -> void:
	var juicio := await _nuevo(false)
	var actores: Array = juicio._enjambre_1771.get("actores", [])
	_comprobar(actores.size(), 3, "monta tres cuerpos")
	_comprobar(juicio._determinacion_rival, 3, "la determinacion agregada son tres unidades")
	_comprobar(juicio._rival.visible, false, "el rival unico sale de la ruta visual")
	for actor in actores:
		_comprobar(bool(actor.get("vivo", false)), true, "cada cuerpo empieza vivo")
		_comprobar((actor.get("cuerpo") as CharacterBody3D).visible, true, "cada cuerpo es visible")
	juicio.free()
	await process_frame


func _probar_presupuesto_e_impacto() -> void:
	var juicio := await _nuevo(true)
	var actores: Array = juicio._enjambre_1771["actores"]
	var unidades: Array = juicio._enjambre_1771["unidades"]
	juicio._jugador.position = Vector3.ZERO
	(actores[0]["cuerpo"] as CharacterBody3D).position = Vector3(0.0, 0.0, -1.15)
	(actores[1]["cuerpo"] as CharacterBody3D).position = Vector3(1.0, 0.0, -0.55)
	(actores[2]["cuerpo"] as CharacterBody3D).position = Vector3(-3.0, 0.0, -2.0)
	for unidad in unidades:
		unidad["cooldown"] = 0.0

	juicio._avanzar_arquetipo(PASO)
	unidades = juicio._enjambre_1771["unidades"]
	_comprobar(_contar_atacantes(unidades), 2, "solo dos ocupan presupuesto compartido")
	_comprobar(_avisos_visibles(actores), 2, "solo dos telegraphs aparecen")

	var antes := juicio._determinacion_jugador
	juicio._avanzar_arquetipo(0.40)
	_comprobar(
		juicio._determinacion_jugador,
		antes - 2,
		"dos ataques cortos cercanos usan la autoridad comun de impacto",
	)
	var tras_ataques := juicio._determinacion_jugador
	juicio._avanzar_arquetipo(0.01)
	_comprobar(
		juicio._determinacion_jugador,
		tras_ataques,
		"permanecer en ATACAR no repite el impacto por frame",
	)
	juicio.free()
	await process_frame


func _probar_cuerpos_debiles_y_resolucion_unica() -> void:
	var juicio := await _nuevo(true)
	var finales := [0]
	juicio.terminado.connect(func(_gano: bool): finales[0] += 1)
	for restantes_esperados in [2, 1, 0]:
		var objetivo := _primer_vivo(juicio)
		var cuerpo := objetivo["cuerpo"] as CharacterBody3D
		juicio._jugador.position = cuerpo.position + Vector3(0.0, 0.0, 0.9)
		juicio._recarga_jugador = 0.0
		(
			juicio
			. _atacar(
				1,
				JuicioCombate3D.ALCANCE_LIGERO,
				JuicioCombate3D.RECARGA_LIGERA,
				false,
			)
		)
		_comprobar(
			juicio._determinacion_rival,
			restantes_esperados,
			"cada golpe elimina una unidad de determinacion uno",
		)
		_comprobar(cuerpo.visible, false, "la unidad derrotada desaparece sin respawn")
	_comprobar(juicio._acabado, true, "la ultima unidad fija el desenlace una sola vez")
	await create_timer(JuicioCombate3D.PAUSA_FINAL_MAX + 0.2).timeout
	_comprobar(finales[0], 1, "el encuentro emite una unica resolucion")
	juicio._terminar(true, true)
	await process_frame
	_comprobar(finales[0], 1, "un segundo cierre no duplica terminado")
	juicio.free()
	await process_frame


func _probar_reduccion_movimiento() -> void:
	var animado := await _nuevo(false)
	var reducido := await _nuevo(true)
	for juicio in [animado, reducido]:
		for unidad in juicio._enjambre_1771["unidades"]:
			unidad["cooldown"] = 0.0
	var iguales := true
	for _i in range(45):
		animado._avanzar_arquetipo(PASO)
		reducido._avanzar_arquetipo(PASO)
		if _estados(animado) != _estados(reducido):
			iguales = false
			break
	_comprobar(iguales, true, "reduccion de movimiento conserva estados y timings")
	animado.free()
	reducido.free()
	await process_frame


func _primer_vivo(juicio: JuicioCombate3D) -> Dictionary:
	var actores: Array = juicio._enjambre_1771["actores"]
	var unidades: Array = juicio._enjambre_1771["unidades"]
	for indice in range(actores.size()):
		if bool(actores[indice].get("vivo", false)) and int(unidades[indice]["determinacion"]) > 0:
			return actores[indice]
	return {}


func _estados(juicio: JuicioCombate3D) -> Array:
	var estados := []
	for unidad in juicio._enjambre_1771["unidades"]:
		estados.append(String(unidad.get("estado", "")))
	return estados


func _contar_atacantes(unidades: Array) -> int:
	var total := 0
	for unidad in unidades:
		if String(unidad.get("estado", "")) in HOST.ESTADOS_ATACANTE:
			total += 1
	return total


func _avisos_visibles(actores: Array) -> int:
	var total := 0
	for actor in actores:
		var aviso := actor.get("aviso") as MeshInstance3D
		if aviso != null and aviso.visible:
			total += 1
	return total


func _nuevo(reducir: bool) -> JuicioCombate3D:
	var juicio := JuicioCombate3D.new()
	juicio.configurar({"id": "enjambre-2067", "nombre": "ENJAMBRE"}, 0, reducir, RAIZ)
	juicio.arquetipo_onirico = ARQUETIPOS.ENJAMBRE
	get_root().add_child(juicio)
	juicio.set_process(false)
	await process_frame
	return juicio


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #2067 enjambre: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
