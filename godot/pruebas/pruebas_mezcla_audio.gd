extends SceneTree

const MezclaAudioScript := preload("res://guion/mezcla_audio.gd")

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var router := get_root().get_node_or_null("MezclaAudio")
	if router == null:
		router = MezclaAudioScript.new()
		router.name = "MezclaAudioPrueba"
		get_root().add_child(router)

	var efectos := AudioServer.get_bus_index("Efectos")
	var ambiente := AudioServer.get_bus_index("Ambiente")
	var musica := AudioServer.get_bus_index("Musica")
	comprobar("existe bus Efectos", efectos >= 0, true)
	comprobar("existe bus Ambiente", ambiente >= 0, true)
	comprobar("existe bus Musica", musica >= 0, true)
	comprobar("Efectos envía a Master", AudioServer.get_bus_send(efectos), &"Master")
	comprobar("Ambiente envía a Master", AudioServer.get_bus_send(ambiente), &"Master")
	comprobar("Musica envía a Master", AudioServer.get_bus_send(musica), &"Master")

	var efecto := AudioStreamPlayer.new()
	efecto.name = "EfectoPrueba"
	get_root().add_child(efecto)
	comprobar("reproductor genérico va a Efectos", efecto.bus, &"Efectos")

	var efecto_3d := AudioStreamPlayer3D.new()
	efecto_3d.name = "PisadaPrueba"
	get_root().add_child(efecto_3d)
	comprobar("reproductor 3D va a Efectos", efecto_3d.bus, &"Efectos")

	var efecto_2d := AudioStreamPlayer2D.new()
	efecto_2d.name = "InterfazPrueba"
	get_root().add_child(efecto_2d)
	comprobar("reproductor 2D va a Efectos", efecto_2d.bus, &"Efectos")

	var cama := AudioStreamPlayer.new()
	cama.name = "AmbienteContinuo"
	get_root().add_child(cama)
	comprobar("cama continua va a Ambiente", cama.bus, &"Ambiente")

	var tema := AudioStreamPlayer.new()
	tema.name = "MusicaPuntual"
	get_root().add_child(tema)
	comprobar("música puntual va a Musica", tema.bus, &"Musica")

	var explicito := AudioStreamPlayer.new()
	explicito.name = "BusExplicito"
	explicito.bus = &"Ambiente"
	get_root().add_child(explicito)
	comprobar("un bus explícito no se sobrescribe", explicito.bus, &"Ambiente")

	var preferencias := PreferenciasSiga.nuevas()
	preferencias["volumen"] = 0.8
	preferencias["volumen_efectos"] = 0.5
	preferencias["volumen_ambiente"] = 0.0
	preferencias["volumen_musica"] = 0.25
	router.aplicar_volumenes(preferencias)
	var master := AudioServer.get_bus_index("Master")
	comprobar(
		"Master respeta el nivel",
		is_equal_approx(AudioServer.get_bus_volume_db(master), linear_to_db(0.8)),
		true
	)
	comprobar("Master no se mutea con nivel positivo", AudioServer.is_bus_mute(master), false)
	comprobar(
		"Efectos respeta el nivel",
		is_equal_approx(AudioServer.get_bus_volume_db(efectos), linear_to_db(0.5)),
		true
	)
	comprobar("Efectos no se mutea con nivel positivo", AudioServer.is_bus_mute(efectos), false)
	comprobar("Ambiente a cero se mutea", AudioServer.is_bus_mute(ambiente), true)
	comprobar(
		"Musica respeta el nivel",
		is_equal_approx(AudioServer.get_bus_volume_db(musica), linear_to_db(0.25)),
		true
	)

	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])
