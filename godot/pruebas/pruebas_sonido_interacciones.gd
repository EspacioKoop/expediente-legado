extends SceneTree

var _pasadas := 0
var _fallos := 0


## Las voces espaciales exigen nodos dentro del árbol, y durante
## `_initialize` la raíz todavía no lo está: se prueba en el primer fotograma.
func _initialize() -> void:
	process_frame.connect(_ejecutar, CONNECT_ONE_SHOT)


func _ejecutar() -> void:
	_probar_familias()
	_probar_voz_por_verbo()
	_probar_verbos_mudos()
	_probar_sobrescritura()
	_probar_toggle_conserva_gesto()
	_probar_tv_distingue_potencia_y_navegacion()
	_probar_voz_sobrevive_al_objeto()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_familias() -> void:
	for nombre in Sonido.FAMILIAS:
		var familia := Sonido.stream(nombre) as AudioStreamRandomizer
		_comprobar(familia != null, "%s es una familia con variación" % nombre)
		if familia == null:
			continue
		_comprobar(
			familia.streams_count == Sonido.FAMILIAS[nombre].size(),
			"%s carga todas sus tomas" % nombre
		)
		for i in familia.streams_count:
			_comprobar(familia.get_stream(i) != null, "%s toma %d existe" % [nombre, i])
		_comprobar(Sonido.stream(nombre) == familia, "%s se reutiliza" % nombre)
	for nombre in Interactuable3D.SONIDO_POR_VERBO.values():
		_comprobar(Sonido.stream(nombre) != null, "el verbo pide un sonido real: %s" % nombre)


func _probar_voz_por_verbo() -> void:
	var escena := _escena()
	var objeto := _interactuable(escena, Interactuable3D.Verbo.ABRIR)
	objeto.position = Vector3(2.0, 1.0, -3.0)
	_comprobar(objeto.interactuar(null), "abrir se activa")
	var voces := _voces(escena)
	_comprobar(voces.size() == 1, "abrir deja una voz espacial")
	if voces.size() == 1:
		_comprobar(voces[0].stream == Sonido.stream("abrir"), "con la familia de abrir")
		_comprobar(
			voces[0].global_position.is_equal_approx(objeto.global_position),
			"y suena donde está el objeto"
		)
		_comprobar(voces[0].playing, "y está sonando")

	objeto.habilitado = false
	_comprobar(not objeto.interactuar(null), "deshabilitado no se activa")
	_comprobar(_voces(escena).size() == 1, "ni suena")
	escena.free()


func _probar_verbos_mudos() -> void:
	for verbo in [
		Interactuable3D.Verbo.EXAMINAR, Interactuable3D.Verbo.USAR, Interactuable3D.Verbo.GOLPEAR
	]:
		var escena := _escena()
		_interactuable(escena, verbo).interactuar(null)
		_comprobar(_voces(escena).is_empty(), "el verbo %d no suena por defecto" % verbo)
		escena.free()


func _probar_sobrescritura() -> void:
	var escena := _escena()
	var callado := _interactuable(escena, Interactuable3D.Verbo.ABRIR)
	callado.sonido = Interactuable3D.SIN_SONIDO
	callado.interactuar(null)
	_comprobar(_voces(escena).is_empty(), "SIN_SONIDO calla un verbo sonoro")

	var terminal := _interactuable(escena, Interactuable3D.Verbo.USAR)
	terminal.sonido = "pulsar"
	terminal.interactuar(null)
	var voces := _voces(escena)
	_comprobar(voces.size() == 1, "un verbo mudo puede declarar su sonido")
	if voces.size() == 1:
		_comprobar(voces[0].stream == Sonido.stream("pulsar"), "y suena el declarado")
	escena.free()


func _probar_toggle_conserva_gesto() -> void:
	var escena := _escena()
	var archivador := ArchivadorInteractivo3D.new()
	escena.add_child(archivador)
	archivador.configurar(Vector3(0.8, 1.2, 0.5))

	_comprobar(archivador.verbo == Interactuable3D.Verbo.ABRIR, "el archivador empieza cerrado")
	archivador.interactuar(null)
	var voces := _voces(escena)
	_comprobar(archivador.esta_abierto(), "el primer gesto abre el archivador")
	_comprobar(
		voces.size() == 1 and voces[0].stream == Sonido.stream("abrir"),
		"abrir suena a abrir aunque el callback deje el verbo en cerrar",
	)

	archivador.interactuar(null)
	voces = _voces(escena)
	_comprobar(not archivador.esta_abierto(), "el segundo gesto cierra el archivador")
	_comprobar(
		voces.size() == 2 and voces[1].stream == Sonido.stream("cerrar"),
		"cerrar suena a cerrar aunque el callback deje el verbo en abrir",
	)
	escena.free()


func _probar_tv_distingue_potencia_y_navegacion() -> void:
	var escena := _escena()
	var televisor := TelevisionInteractiva3D.new()
	televisor.name = "TelevisorPrueba"
	escena.add_child(televisor)
	televisor.configurar(Vector3(1.2, 0.8, 0.6))

	televisor.interactuar(null)
	var voces := _voces(escena)
	_comprobar(televisor.esta_encendida(), "el primer gesto enciende la TV")
	_comprobar(
		voces.size() == 1 and voces[0].stream == Sonido.stream("marcar"),
		"encender la TV usa el switch de potencia",
	)

	televisor.interactuar(null)
	voces = _voces(escena)
	_comprobar(televisor.esta_encendida(), "buscar canal no apaga la TV")
	_comprobar(
		voces.size() == 2 and voces[1].stream == Sonido.stream("pulsar"),
		"buscar canal usa clic y no repite el switch de potencia",
	)

	televisor.set("_documental_completado", true)
	televisor.interactuar(null)
	voces = _voces(escena)
	_comprobar(not televisor.esta_encendida(), "tras completar, el gesto apaga la TV")
	_comprobar(
		voces.size() == 3 and voces[2].stream == Sonido.stream("marcar"),
		"apagar la TV vuelve a usar el switch de potencia",
	)

	var mando := escena.get_node_or_null("MandoTelevision98") as MandoTelevision98
	_comprobar(mando != null, "la TV monta su mando real")
	if mando != null:
		mando.interactuar(null)
		voces = _voces(escena)
		_comprobar(televisor.esta_encendida(), "el mando alterna la potencia")
		_comprobar(
			voces.size() == 4 and voces[3].stream == Sonido.stream("pulsar"),
			"el botón del mando produce su clic físico",
		)
	escena.free()


func _probar_voz_sobrevive_al_objeto() -> void:
	var escena := _escena()
	var objeto := _interactuable(escena, Interactuable3D.Verbo.COGER)
	objeto.interactuar(null)
	objeto.free()
	_comprobar(_voces(escena).size() == 1, "coger sigue sonando aunque el objeto desaparezca")
	escena.free()


func _escena() -> Node3D:
	var escena := Node3D.new()
	root.add_child(escena)
	return escena


func _interactuable(escena: Node3D, verbo: int) -> Interactuable3D:
	var objeto := Interactuable3D.new()
	objeto.verbo = verbo
	escena.add_child(objeto)
	return objeto


func _voces(escena: Node) -> Array:
	return escena.find_children("*", "AudioStreamPlayer3D", false, false)


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)
