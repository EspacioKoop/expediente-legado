extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	await _probar_cuatro_presentaciones()
	await _probar_idempotencia_y_reduccion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _espacio(id: String, reducir := false) -> Dictionary:
	var base := Sueno.espacio("crucero", 1, {})
	return MutadoresSueno.aplicar(base, {"id": id}, reducir)


func _probar_cuatro_presentaciones() -> void:
	for id in MutadoresSueno.IDS:
		var mundo := Node3D.new()
		root.add_child(mundo)
		var capa := SuenoMutadorPresentacion3D.montar(mundo, _espacio(id))
		_comprobar(capa != null, "%s monta una capa" % id)
		_comprobar(
			capa != null and String(capa.get_meta("mutador_id", "")) == id,
			"%s conserva su id" % id,
		)
		_comprobar(
			capa != null and not bool(capa.get_meta("afecta_navegacion", true)),
			"%s declara navegacion intacta" % id,
		)
		_comprobar(
			capa != null and not bool(capa.get_meta("afecta_objetivo", true)),
			"%s declara objetivo intacto" % id,
		)
		_comprobar(
			mundo.find_children("*", "CollisionShape3D", true, false).is_empty(),
			"%s no crea colisiones" % id,
		)
		_comprobar(
			mundo.find_children("*", "StaticBody3D", true, false).is_empty(),
			"%s no crea cuerpos solidos" % id,
		)
		match id:
			MutadoresSueno.HUMEDAD:
				_comprobar(
					capa.find_children("Charco*", "MeshInstance3D", true, false).size() == 3,
					"humedad crea charcos"
				)
			MutadoresSueno.APAGONES:
				_comprobar(
					capa.find_children("FuenteLocal*", "OmniLight3D", true, false).size() == 2,
					"apagones conserva luz local"
				)
			MutadoresSueno.REPETICION:
				var ecos := capa.find_children("EcoIdentidad*", "MeshInstance3D", true, false)
				_comprobar(ecos.size() == 2, "repeticion duplica un elemento secundario")
				_comprobar(
					(
						ecos.size() == 2
						and (
							ecos[0].get_meta("identidad_repetida", "")
							== ecos[1].get_meta("identidad_repetida", "")
						)
					),
					"las copias comparten identidad",
				)
			MutadoresSueno.DESFASE:
				_comprobar(
					capa.get_node_or_null("PulsoOriginal") is AudioStreamPlayer3D,
					"desfase crea sonido original"
				)
				_comprobar(
					capa.get_node_or_null("PulsoDesfasado") is AudioStreamPlayer3D,
					"desfase crea eco sonoro"
				)
		mundo.queue_free()
		await process_frame


func _probar_idempotencia_y_reduccion() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var primera := SuenoMutadorPresentacion3D.montar(mundo, _espacio(MutadoresSueno.APAGONES, true))
	var segunda := SuenoMutadorPresentacion3D.montar(mundo, _espacio(MutadoresSueno.APAGONES, true))
	_comprobar(primera == segunda, "remontar el mismo mutador no duplica capa")
	_comprobar(mundo.get_child_count() == 1, "solo existe una capa por mundo")
	_comprobar(not primera.is_processing(), "reduccion de movimiento apaga ciclo de luces")
	for luz in primera.find_children("FuenteLocal*", "OmniLight3D", true, false):
		_comprobar(float(luz.light_energy) > 0.0, "la ruta conserva fuentes locales estaticas")
	mundo.queue_free()
	await process_frame


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
