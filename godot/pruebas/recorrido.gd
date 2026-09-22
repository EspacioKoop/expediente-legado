## Integración de escenas reales, solo bajo el verificador con datos aislados.
extends SceneTree

## La escena del día se carga una vez: los tres recorridos la instancian, y
## cargarla en cada uno es pedirle lo mismo tres veces al gestor de recursos.
const ESCENA_DIA := preload("res://escenas/dia.tscn")
const SCRIPT_VISOR := preload("res://guion/visor_pronosticos_app.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	if OS.get_environment("LEGADO_PRUEBAS_AISLADAS") != "1":
		printerr("Usa scripts/verificar_godot.py para no tocar partidas personales.")
		quit(1)
		return
	_recorrer.call_deferred()


func _recorrer() -> void:
	var dia = ESCENA_DIA.instantiate()
	root.add_child(dia)
	await process_frame
	dia.jornada["plantilla"] = 427
	dia.jornada["dia"] = 5
	dia.jornada["acciones"] = Jornada.ACCIONES_POR_DIA
	dia._abrir_expediente()
	await process_frame
	var visor = _visor_abierto(dia)
	_comprobar("el puesto conserva el visor al envolverlo", visor != null, true)
	if visor == null:
		quit(1)
		return
	_comprobar("el puesto abre en el mismo día", visor.jornada["dia"], 5)
	_comprobar("la plantilla no cambia al sentarse", visor.jornada["plantilla"], 427)
	_comprobar("el archivo ofrece los diez expedientes", visor._archivo.item_count, 10)
	for i in visor.contenido.casos.size():
		visor._al_elegir_caso(i)
		_comprobar(
			"seleccionar cambia el expediente", visor.caso["id"], visor.contenido.casos[i]["id"]
		)
		_comprobar(
			"cada expediente muestra sus documentos",
			visor._lista.item_count,
			visor.caso["registros"].size()
		)
	_comprobar("navegar no consume jornada", visor.jornada["acciones"], Jornada.ACCIONES_POR_DIA)
	_comprobar("navegar no abre un documento a escondidas", visor._documento.text, "")
	_comprobar(
		"el confidencial se identifica",
		visor._archivo.get_item_text(5).contains("CONFIDENCIAL"),
		true
	)
	visor._al_elegir_caso(0)
	visor._al_elegir_documento(0)
	dia._cerrar_expediente()
	await process_frame
	_comprobar("levantarse conserva la lectura", dia.jornada["leido_hoy"].size(), 1)
	_comprobar("levantarse no regala acciones", dia.jornada["acciones"], Jornada.ACCIONES_POR_DIA)

	# Reproducir la salida real del trayecto. Antes se guardaba la fase anterior.
	dia._entrar_en("trayecto")
	var salida := Area3D.new()
	salida.set_meta("frase", "")
	salida.set_meta("destino", "casa")
	dia._al_pisar_salida(dia._caminante, salida)
	salida.free()
	var releida := Partida.new()
	releida.cargar()
	_comprobar("el portal guarda la llegada a casa", releida.estado["jornada"]["fase"], "casa")
	_comprobar("el portal conserva el día", releida.estado["jornada"]["dia"], 5)
	_comprobar(
		"los contadores cargados son enteros", typeof(releida.estado["jornada"]["dia"]), TYPE_INT
	)
	dia.queue_free()
	await process_frame
	var vuelta = ESCENA_DIA.instantiate()
	root.add_child(vuelta)
	await process_frame
	_comprobar("reiniciar abre en casa", vuelta.jornada["fase"], "casa")
	_comprobar(
		"reiniciar conserva las acciones gastadas",
		vuelta.jornada["acciones"],
		Jornada.ACCIONES_POR_DIA
	)
	vuelta._abrir_expediente()
	await process_frame
	var archivo = _visor_abierto(vuelta)
	_comprobar("reabrir conserva el visor al envolverlo", archivo != null, true)
	if archivo == null:
		quit(1)
		return
	archivo.partida.estado["veredictos"][archivo.caso["id"]] = archivo.caso["sospechosos"][0]["id"]
	archivo._refrescar_estado()
	archivo._al_elegir_documento(1)
	_comprobar(
		"un expediente firmado sigue siendo legible", archivo._documento.text.is_empty(), false
	)
	_comprobar(
		"releer un expediente firmado es gratis",
		archivo.jornada["acciones"],
		Jornada.ACCIONES_POR_DIA
	)
	_comprobar("una firma firme desactiva imputar", archivo._imputar.disabled, true)
	_comprobar(
		"el expediente firmado cambia de fondo",
		archivo._archivo.get_item_custom_bg_color(0),
		EstiloSiga.GRIS
	)
	var antes: Array = archivo.descubiertas.duplicate()
	archivo._al_pulsar_marca("pista:" + archivo.caso["pistas"][0]["id"])
	_comprobar("no se modifica un expediente firmado", archivo.descubiertas, antes)
	PruebasLecturasYReloj.lecturas(archivo, Callable(self, "_comprobar"))
	vuelta.queue_free()
	await process_frame
	PruebasLecturasYReloj.reloj(Callable(self, "_comprobar"))

	await _vuelta_entera()
	await _reasignacion()
	await _remates_duelo()
	await PruebasHistoria.recorrer(self, Callable(self, "_comprobar"))
	# El mezclador libera las voces de las puertas en su propio hilo.
	await create_timer(0.25).timeout
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos else 0)


## El día entero, por las salidas de verdad: archivo -> trayecto -> casa ->
## sueño -> archivo.
##
## Las piezas sueltas ya estaban probadas una a una, y aun así el ciclo no lo
## estaba: `Jornada` dice cuál es la fase siguiente, `EspaciosCatalogo` a dónde
## lleva cada puerta y `dia_app` las pega, y son tres sitios donde el orden del
## día puede dejar de coincidir sin que ninguna prueba unitaria se entere. Esto
## recorre la vuelta pisando los mismos disparadores que pisa el jugador.
func _vuelta_entera() -> void:
	var dia = ESCENA_DIA.instantiate()
	root.add_child(dia)
	await process_frame

	# Se aísla también el archivo: las lecturas gratuitas ya guardan la firma
	# del escenario anterior. Una partida sintética nueva evita que la prueba
	# de reasignación intente volver a firmar aquel expediente ya cerrado.
	dia.partida.estado = Partida.nueva()
	dia.jornada = dia.partida.estado["jornada"]
	dia._entrar_en("archivo")

	dia.jornada["cerrados_hoy"] = 2
	var dinero_antes: int = dia.jornada["dinero"]

	_pisar(dia, "trayecto")
	_comprobar("fichar la salida lleva al trayecto", dia.jornada["fase"], "trayecto")
	_comprobar(
		"y paga la base más los expedientes cerrados",
		dia.jornada["dinero"],
		dinero_antes + Jornada.BASE_DIARIA + 2 * Jornada.POR_EXPEDIENTE
	)

	_pisar(dia, "casa")
	_comprobar("el trayecto lleva a casa", dia.jornada["fase"], "casa")

	var en_el_bolsillo: int = dia.jornada["dinero"]
	_pisar(dia, "sueño")
	_comprobar("acostarse abre la preparación nocturna", dia.jornada["fase"], "casa")
	_comprobar("la preparación nocturna bloquea el paso", dia._pantalla != null, true)
	var preparacion = null
	if dia._pantalla != null and dia._pantalla.get_child_count() > 0:
		preparacion = dia._pantalla.get_child(0)
	_comprobar(
		"la preparación expone una confirmación real",
		preparacion != null and preparacion.has_signal("confirmada"),
		true,
	)
	if preparacion != null:
		preparacion.call("_emitir_confirmacion")
	_comprobar("confirmar la preparación lleva al sueño", dia.jornada["fase"], "sueño")
	_comprobar(
		"y vivir el día cuesta", dia.jornada["dinero"], en_el_bolsillo - Jornada.COSTE_DIARIO
	)
	_comprobar(
		"la noche trae sus escenas", dia.jornada["sueno_escenas"].size(), Sueno.ESCENAS_POR_NOCHE
	)

	# La noche se recorre escena a escena. La salida de la última lleva al
	# archivo y las demás a la siguiente: es el propio sueño quien lo dice,
	# así que la prueba pisa lo que el espacio ofrece en vez de adivinarlo.
	for queda in range(Sueno.ESCENAS_POR_NOCHE, 0, -1):
		_pisar(dia, "sueño" if queda > 1 else "archivo")
		if queda > 1:
			_comprobar("una escena más de noche no despierta", dia.jornada["fase"], "sueño")

	_comprobar("salir del sueño devuelve al archivo", dia.jornada["fase"], "archivo")
	_comprobar("y amanece el día dos", dia.jornada["dia"], 2)
	_comprobar(
		"con la jornada entera por delante", dia.jornada["acciones"], Jornada.ACCIONES_POR_DIA
	)
	_comprobar("y sin expedientes cerrados todavía", dia.jornada["cerrados_hoy"], 0)
	_comprobar("lo leído anoche ya no está", dia.jornada["leido_hoy"], [])

	# La vuelta completa tiene que haber quedado escrita, no solo vivida.
	var releida := Partida.new()
	releida.cargar()
	_comprobar("la vuelta entera se guarda", releida.estado["jornada"]["dia"], 2)
	_comprobar("y se guarda en el archivo", releida.estado["jornada"]["fase"], "archivo")

	dia.queue_free()
	await process_frame


## Que te reasignen a media sesión: el día tiene que enterarse.
##
## `Acusacion` reinicia la vida laboral dentro del estado, pero el mundo montado
## es el de antes. Sin que el día vuelva a entrar, la segunda vuelta seguiría
## con los compañeros de la primera sentados en la planta.
func _reasignacion() -> void:
	var dia = ESCENA_DIA.instantiate()
	root.add_child(dia)
	await process_frame

	dia.jornada["dia"] = 9
	dia.jornada["dinero"] = 5
	dia.partida.estado["jornada"] = dia.jornada
	var plantilla_antes: int = dia.jornada["plantilla"]

	dia._abrir_expediente()
	await process_frame
	var visor = _visor_abierto(dia)
	_comprobar("reasignar conserva el visor al envolverlo", visor != null, true)
	if visor == null:
		return

	# Se acusa sin haber mirado nada y con una sola vida: precipitada, y la
	# última. Es el camino real al despido, no un reinicio a mano.
	visor.partida.estado["vida"] = 1
	visor.descubiertas = []
	var resultado := Acusacion.acusar(
		visor.partida.estado,
		visor.jornada,
		visor.caso,
		visor.caso["sospechosos"][0],
		visor.descubiertas
	)
	_comprobar("quedarse sin vidas conserva el cero", resultado["vida"], 0)
	_comprobar("quedarse sin vidas abre último recurso", resultado["despido_pendiente"], true)
	_comprobar("todavía no hay despido", resultado["despido"], false)
	visor._al_firmar(resultado, Control.new())
	await process_frame

	# #70: el expediente ya está firmado ANTES de que el sello termine. La
	# cinemática es presentación, no la autoridad del veredicto.
	_comprobar(
		"la firma existe antes de terminar el sello",
		Acusacion.esta_cerrado(visor.partida.estado, visor.caso["id"]),
		true
	)
	var reproductor: Node = null
	for hijo in visor.get_children():
		if hijo.has_method("saltar"):
			reproductor = hijo
			break
	_comprobar("el cierre pasa por la cinemática del sello", reproductor != null, true)
	if reproductor != null:
		reproductor.saltar()
		await process_frame
	_comprobar("el sello abre la decisión de último recurso", visor._ultimo_recurso != null, true)
	visor._al_aceptar_cese(resultado, {})
	await process_frame
	_comprobar("firmar el cese reasigna", visor._estado.text.contains(tr("VISOR_REASIGNADO")), true)

	# El id se guarda ANTES de cerrar: al cerrar se libera el visor, y
	# preguntárselo después es preguntarle a un nodo que ya no existe.
	var firmado: String = visor.caso["id"]

	dia._cerrar_expediente()
	await process_frame
	_comprobar("la vida laboral siguiente empieza por el día uno", dia.jornada["dia"], 1)
	_comprobar("es la vuelta dos", dia.jornada["vuelta"], 2)
	_comprobar("y se entra por el archivo", dia.jornada["fase"], "archivo")
	_comprobar("con otra gente en la planta", dia.jornada["plantilla"] != plantilla_antes, true)
	# El gato es lo único que cruza el despido: es tuyo, no del trabajo.
	_comprobar("el gato sigue ahí", dia.jornada["gato"]["presente"], true)
	# El archivo NO se reinicia: la firma de la vuelta anterior sigue firmada.
	_comprobar(
		"el expediente que firmó sigue cerrado",
		Acusacion.esta_cerrado(dia.partida.estado, firmado),
		true
	)

	dia.queue_free()
	await process_frame


## #72: el resultado del careo se aplica antes de la cinemática y solo una vez.
## Los dos remates comparten el expediente, no escriben "victoria" ni cambian
## el veredicto, y terminar o saltar desemboca en el mismo cierre.
func _remates_duelo() -> void:
	var victoria := DueloRemateCinematica.planos_de(true)
	var derrota := DueloRemateCinematica.planos_de(false)
	_comprobar("el remate de victoria es válido", Cinematica.validar(victoria), [])
	_comprobar("el remate de derrota es válido", Cinematica.validar(derrota), [])
	var ids_distintos := DueloRemateCinematica.id_de(true) != DueloRemateCinematica.id_de(false)
	_comprobar("victoria y derrota tienen id distinto", ids_distintos, true)
	_comprobar(
		"ambos terminan en el mismo expediente", victoria[-1]["figura"], derrota[-1]["figura"]
	)
	var victoria_estatica := victoria.all(
		func(p): return p.get("desde", Vector2.ZERO) == p.get("hasta", Vector2.ZERO)
	)
	var derrota_estatica := derrota.all(
		func(p): return p.get("desde", Vector2.ZERO) == p.get("hasta", Vector2.ZERO)
	)
	_comprobar("el remate de victoria es estático", victoria_estatica, true)
	_comprobar("el remate de derrota es estático", derrota_estatica, true)
	_comprobar("los dos remates se distinguen", victoria[0]["figura"] != derrota[0]["figura"], true)

	var visor = load("res://escenas/visor.tscn").instantiate()
	root.add_child(visor)
	await process_frame
	visor.partida.estado = Partida.nueva()
	visor.jornada = visor.partida.estado["jornada"]
	visor.partida.estado["vida"] = 3
	var acusacion := {"desenlace": "CIERRE-PRUEBA", "precipitada": false, "despido": false}
	var vida_antes: int = visor.partida.estado["vida"]
	var careo := Node3D.new()
	visor.add_child(careo)
	visor._duelo_resuelto = false
	visor._al_terminar_careo(false, careo, acusacion)
	_comprobar("perder el duelo quita una vida", visor.partida.estado["vida"], vida_antes - 1)
	visor._al_terminar_careo(false, careo, acusacion)
	_comprobar(
		"una señal repetida no quita otra vida", visor.partida.estado["vida"], vida_antes - 1
	)
	await process_frame
	var reproductor: Node = null
	for hijo in visor.get_children():
		if hijo.has_method("saltar"):
			reproductor = hijo
			break
	_comprobar("la derrota abre su remate", reproductor != null, true)
	_comprobar("el cierre espera al remate", visor._aviso_partida.contains("CIERRE-PRUEBA"), false)
	if reproductor != null:
		reproductor.saltar()
		await process_frame
	_comprobar(
		"saltar el remate llega al cierre", visor._aviso_partida.contains("CIERRE-PRUEBA"), true
	)

	visor.queue_free()
	await process_frame


## Encuentra el visor por su script, no por su posición en el árbol. Desde #534
## el shell lo adopta dentro de una ventana y deja de ser hijo directo de la capa.
func _visor_abierto(dia):
	if dia._pantalla == null:
		return null
	for nodo in dia._pantalla.find_children("*", "", true, false):
		if nodo.get_script() == SCRIPT_VISOR:
			return nodo
	return null


## Pisa la salida que lleva a [param destino], como haría el jugador al cruzarla.
func _pisar(dia, destino: String) -> void:
	var salida := Area3D.new()
	salida.set_meta("frase", "")
	salida.set_meta("destino", destino)
	dia._al_pisar_salida(dia._caminante, salida)
	salida.free()


func _comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s: %s != %s" % [nombre, obtenido, esperado])
