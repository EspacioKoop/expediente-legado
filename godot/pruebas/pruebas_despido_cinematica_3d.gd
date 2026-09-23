## Regresión headless del despido en 3D (#899, decisión de #395).
##
## No basta con que los planos digan `3d`: se reproducen en el reproductor
## común, que monta cada decorado en su plató, y se comprueba lo que queda
## montado —la carpeta, las tres personas, el gato real solo si seguía—.
extends SceneTree

const ESCENA_CINEMATICA := preload("res://escenas/cinematica.tscn")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	_probar_declaracion()
	_probar_gato_en_espacio()
	await _probar_reproduccion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_declaracion() -> void:
	var con_gato := DespidoCinematica.planos_de(true, 0, Cunado.clave_despido(1))
	var sin_gato := DespidoCinematica.planos_de(false)
	_comprobar(Cinematica.validar(con_gato).is_empty(), "el despido valida")
	_comprobar(con_gato.size() == 3, "el despido conserva sus tres momentos")
	for plano in con_gato:
		_comprobar(plano["tipo"] == "3d", "plano %s en 3d" % plano.get("nombre", "?"))
		_comprobar(
			plano.get("decorado", {}) is Dictionary and not plano["decorado"].is_empty(),
			"plano %s trae su decorado: el visor no tiene sala detrás" % plano.get("nombre", "?")
		)
		_comprobar(not plano.has("figura"), "sin figuras 2d")

	# La voz del cuñado solo rompe el silencio de la salida.
	_comprobar(not String(con_gato[1]["voz"]).is_empty(), "la salida lleva la voz del cuñado")
	_comprobar(String(con_gato[0]["voz"]).is_empty(), "el puesto no habla")
	_comprobar(String(con_gato[2]["voz"]).is_empty(), "la mañana no habla")

	_comprobar(con_gato[2]["decorado"].has("gatos"), "el gato presente cruza a la vida nueva")
	_comprobar(not sin_gato[2]["decorado"].has("gatos"), "un gato que se fue no se resucita")
	_comprobar(con_gato[1]["decorado"]["figuras"].size() == 3, "salen la persona y dos escoltas")

	# Repetir acorta, pero el remate no desaparece.
	var visto := DespidoCinematica.planos_de(true, 5)
	_comprobar(
		Cinematica.duracion(visto) < Cinematica.duracion(con_gato), "verlo otra vez lo acorta"
	)
	_comprobar(float(visto[2]["segundos"]) > 0.0, "el último plano sigue estando")

	# Copia profunda: estropear un rodaje no estropea el siguiente.
	con_gato[0]["decorado"]["bultos"].clear()
	_comprobar(
		not DespidoCinematica.planos_de(true)[0]["decorado"]["bultos"].is_empty(),
		"el decorado se entrega en copia"
	)

	# El cierre real sigue anexando el informe sellado detrás del despido.
	var sellado := {
		"evaluaciones_desempeno":
		[
			{
				"vuelta": 2,
				"motivo": "reasignacion",
				"veredictos_total": 3,
				"evaluacion": {"productividad": EvaluacionDesempeno.MEDIA},
			}
		]
	}
	var remate := DespidoCinematica.planos_con_remate(sellado, 0, "")
	_comprobar(
		remate.size() == 3 + EvaluacionDesempenoCinematica.planos_de(sellado).size(),
		"planos_con_remate añade la evaluación sellada"
	)
	_comprobar(remate.size() > 3, "y la evaluación tiene al menos un plano")
	_comprobar(remate[2].get("nombre", "") == "nuevo-dia", "el despido va primero")


func _probar_gato_en_espacio() -> void:
	var raiz := Node3D.new()
	root.add_child(raiz)
	Espacio3D.construir(raiz, {"suelo": Vector2(2, 2), "gatos": [{"pos": Vector3(0.3, 0.5, 0)}]})
	var gatos := raiz.find_children("*", "Gato", true, false)
	_comprobar(gatos.size() == 1, "un decorado con «gatos» monta el gato real")
	if gatos.size() == 1:
		var gato: Gato = gatos[0]
		_comprobar(gato.position.is_equal_approx(Vector3(0.3, 0.5, 0)), "donde se declara")
		_comprobar(gato.estado.get("estado", "") == "durmiendo", "quieto por defecto, dormido")
	raiz.free()

	var vacio := Node3D.new()
	root.add_child(vacio)
	Espacio3D.construir(vacio, {"suelo": Vector2(2, 2)})
	_comprobar(
		vacio.find_children("*", "Gato", true, false).is_empty(), "sin «gatos» no aparece ninguno"
	)
	vacio.free()

	# Las figuras pueden dar la espalda; sin `giro`, siguen como siempre.
	var pasillo := Node3D.new()
	root.add_child(pasillo)
	(
		Espacio3D
		. construir(
			pasillo,
			{
				"suelo": Vector2(2, 2),
				"figuras": [{"pos": Vector3(0.5, 0, 0), "giro": PI}, {"pos": Vector3(-0.5, 0, 0)}],
			}
		)
	)
	var giros := []
	for hijo in pasillo.get_children():
		if (
			hijo is Node3D
			and (
				hijo.position.is_equal_approx(Vector3(0.5, 0, 0))
				or hijo.position.is_equal_approx(Vector3(-0.5, 0, 0))
			)
		):
			giros.append(snappedf(hijo.rotation.y, 0.01))
	_comprobar(giros.size() == 2, "las dos figuras se montan")
	_comprobar(giros.has(snappedf(PI, 0.01)), "una figura con giro da la espalda")
	_comprobar(giros.has(0.0), "una figura sin giro no cambia")
	pasillo.free()


func _probar_reproduccion() -> void:
	var reproductor: Node = ESCENA_CINEMATICA.instantiate()
	root.add_child(reproductor)
	# Como en la partida real: el reproductor solo anota sobre un estado vivo.
	var estado := {"cinematicas_vistas": {}}
	var terminada := [false]
	reproductor.terminada.connect(func(): terminada[0] = true)
	reproductor.reproducir(DespidoCinematica.planos_de(true, 0, ""), DespidoCinematica.ID, estado)
	await process_frame

	_comprobar(reproductor._plato.visible, "el puesto rueda en el plató 3d")
	_comprobar(reproductor._camara.current, "con la cámara del plató")
	_comprobar(
		not reproductor._decorado.find_children("*", "Gato", true, false).size(),
		"en la oficina no hay gato"
	)

	# Salta al tercer plano consumiendo la duración de los dos primeros.
	reproductor._process(10.0)
	reproductor._process(10.0)
	await process_frame
	_comprobar(reproductor._plano == 2, "llega a la mañana siguiente")
	_comprobar(
		reproductor._decorado.find_children("*", "Gato", true, false).size() == 1,
		"el gato duerme en la mesa de casa"
	)

	reproductor.saltar()
	_comprobar(terminada[0], "se puede saltar")
	_comprobar(Cinematica.vistas_de(estado, DespidoCinematica.ID) == 1, "saltar cuenta como vista")
	reproductor.queue_free()
	await process_frame


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
