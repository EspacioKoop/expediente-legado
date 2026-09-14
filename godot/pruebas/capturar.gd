## Guarda una captura del visor, para poder MIRAR lo que dibuja en vez de
## deducirlo de las pruebas. Es herramienta, no juego: por eso vive aquí y el
## visor no sabe que existe.
##
##     xvfb-run -a godot4 --path godot --script pruebas/capturar.gd \
##         -- salida.png [documento] [descubrir]
##
## Apunta XDG_DATA_HOME, XDG_CONFIG_HOME y XDG_CACHE_HOME a un temporal, como
## hace `scripts/verificar_godot.py`: sin eso se captura TU partida, y basta con
## que tengas un expediente firmado para que la captura enseñe otra cosa.
##
## Con un destino que contenga "tarot", el segundo argumento es el folio que
## esconde la carta y el tercero el plano. Ojo: una carta se revela **una sola
## vez**, así que cada plano necesita su propio temporal; reutilizarlo hace que
## a partir del segundo no se abra ninguna cinemática.
##
## Con un destino que contenga "dia", el segundo argumento es la FASE, y para
## la fase "sueño" el tercero es la sala que se quiere mirar.
##
## [param documento] es el índice del documento a abrir y [param descubrir]
## a "1" descubre sus pistas antes de capturar, para poder comparar el antes y
## el después de notar una frase.
extends SceneTree


func _init() -> void:
	var destino := "captura.png"
	var argumentos := OS.get_cmdline_user_args()
	if argumentos.size() > 0:
		destino = argumentos[0]

	# Qué escena capturar: por defecto el visor.
	var ruta := "res://escenas/visor.tscn"
	if destino.contains("entrada"):
		# La entrada (#68) se pone encima del día, así que la escena es la misma:
		# lo que cambia es que aquí se adelanta plano a plano en vez de esperar a
		# que termine.
		ruta = "res://escenas/dia.tscn"
	elif destino.contains("ventanilla"):
		ruta = "res://escenas/ventanilla.tscn"
	elif destino.contains("dia"):
		ruta = "res://escenas/dia.tscn"
	elif destino.contains("careo"):
		ruta = "res://escenas/careo.tscn"
	# La cinemática del tarot (#71) ocurre DENTRO del visor: la escena es la
	# misma y lo que cambia es que aquí se pulsa la marca de la carta.
	var escena: Node = load(ruta).instantiate()
	if ruta.contains("careo"):
		# El acusado se le pasa ANTES de añadirlo: la escena lo lee en _ready.
		var contenido := Contenido.new()
		contenido.cargar()
		for c in contenido.casos:
			for s in c["sospechosos"]:
				if not s.get("ataques", []).is_empty():
					escena.acusado = s
					escena.folio = "ACTA-1958-001"
					break
	root.add_child(escena)
	await process_frame

	if ruta.contains("careo"):
		# El plano a capturar llega como argumento: la cinemática son cuatro y
		# hay que mirarlos por separado.
		var plano := int(argumentos[1]) if argumentos.size() > 1 else 1
		for i in 3:
			await process_frame
		if plano < 0:
			escena._reproductor.saltar()
		else:
			# Se adelanta la cinemática plano a plano por el reproductor común,
			# que es quien la lleva desde #67.
			for i in plano:
				escena._reproductor._siguiente()
		for i in 6:
			await process_frame
		var imagen_c := root.get_texture().get_image()
		imagen_c.save_png(destino)
		print("captura en %s" % destino)
		quit(0)
		return

	if destino.contains("entrada"):
		# La entrada son cuatro planos y hay que mirarlos por separado, igual que
		# los del careo: se adelanta por el reproductor común, que es quien la
		# lleva. Con un plano negativo se salta, para comprobar que saltarla deja
		# la oficina a la vista y no una pantalla a medias.
		var plano_e := int(argumentos[1]) if argumentos.size() > 1 else 0
		for i in 3:
			await process_frame
		if plano_e < 0:
			escena._entrada.saltar()
		else:
			for i in plano_e:
				escena._entrada._siguiente()
		for i in 6:
			await process_frame
		var imagen_e := root.get_texture().get_image()
		imagen_e.save_png(destino)
		print("captura en %s" % destino)
		quit(0)
		return

	if ruta.contains("dia"):
		# La entrada de la vida laboral (#68) se pone ENCIMA del día, así que sin
		# saltarla todas las capturas de fase salían tapadas por ella y se
		# estaba mirando la cinemática creyendo mirar la oficina o la casa. Para
		# mirar la entrada a propósito está el destino "entrada".
		if escena._entrada != null:
			escena._entrada.saltar()
			await process_frame

		# La fase a capturar llega como argumento: el día entero no cabe en una
		# imagen y cada sitio hay que mirarlo por separado.
		if argumentos.size() > 1:
			# El sueño son tres escenas por noche y cuáles depende de lo leído
			# ese día (#86), así que para MIRAR una sala concreta hay que
			# poder pedirla por su nombre: si no, solo se ven las tres que
			# toquen. La forma va como tercer argumento.
			if argumentos[1] == "sueño" and argumentos.size() > 2:
				# Las tres, la misma: el reparto del contenido es de la NOCHE
				# entera (#87), así que con una sola escena se estaría mirando
				# el trozo que le toca a la tercera y no el de la primera.
				escena.jornada["sueno_escenas"] = [argumentos[2], argumentos[2], argumentos[2]]
				# Y su noche: sin reloj, el sueño se acaba en el primer
				# fotograma y lo que se captura es el archivo del día siguiente.
				escena.jornada["sueno_resto"] = Sueno.segundos_de_noche(
					escena.jornada["sueno_escenas"]
				)
				# Un sueño sin nada leído sale VACÍO a propósito (#87), así que
				# para mirar lo que dibuja hay que darle un día de trabajo: se
				# le da el primer expediente entero y sus pistas descubiertas.
				var caso: Dictionary = escena.contenido.casos[0]
				escena.jornada["leido_hoy"] = caso["registros"].map(func(r): return r["folio"])
				escena.partida.estado["pistas_descubiertas"] = caso["pistas"].map(
					func(p): return p["id"]
				)
				escena.partida.estado["veredictos"] = {caso["id"]: caso["sospechosos"][0]["id"]}
			escena._entrar_en(argumentos[1])

		# Con "borrar" en el destino se pulsa UNA vez el botón de empezar de
		# cero, para mirar el aviso. Pulsarlo dos veces borraría de verdad, y
		# una captura no está para cambiar nada.
		if destino.contains("borrar"):
			escena._al_pulsar_borrar()
		# Unos cuantos fotogramas para que la física asiente al caminante en el
		# suelo: capturar antes lo pilla cayendo.
		for i in 12:
			await process_frame
		var imagen_d := root.get_texture().get_image()
		imagen_d.save_png(destino)
		print("captura en %s" % destino)
		quit(0)
		return

	if ruta.contains("ventanilla"):
		# Llamar al primer turno y jugar una ronda, para que la captura enseñe
		# un combate en marcha y no una cola vacía.
		escena.reduccion_movimiento = true
		escena._al_llamar(int(argumentos[1]) if argumentos.size() > 1 else 0)
		await process_frame
		escena._al_jugar("objecion")
		await process_frame
		var imagen_v := root.get_texture().get_image()
		imagen_v.save_png(destino)
		print("captura en %s" % destino)
		# quit() no interrumpe la función: sin este return se sigue ejecutando
		# el camino del visor y revienta al buscar un `caso` que aquí no hay.
		quit(0)
		return

	if destino.contains("tarot"):
		quit(await _capturar_tarot(escena, destino, argumentos))
		return

	var indice := int(argumentos[1]) if argumentos.size() > 1 else 0
	if argumentos.size() > 2 and argumentos[2] == "1":
		# Por el mismo camino que un clic, no tocando el estado por detrás: si
		# esto escribiera en `descubiertas` directamente, la captura enseñaría
		# una pista descubierta que nunca llegó a guardarse.
		for pista in escena.contenido.pistas_de_registro(
			escena.caso, escena.caso["registros"][indice]["id"]
		):
			if pista.get("fraseGatillo") != null:
				escena._al_pulsar_marca("pista:%s" % pista["id"])
	# Por el selector, no llamando al pintor: abrir un documento gasta una
	# acción de la jornada, y saltárselo enseñaría un estado que no se alcanza
	# jugando. Es el mismo atajo que ya falseó una captura antes.
	escena._lista.select(indice)
	escena._al_elegir_documento(indice)
	if argumentos.size() > 2 and argumentos[2] == "formulario":
		escena._abrir_formulario()

	# Dos fotogramas: uno para que los contenedores repartan el espacio y otro
	# para que se dibuje con el reparto ya hecho.
	await process_frame
	await process_frame
	await process_frame

	var imagen := root.get_texture().get_image()
	var error := imagen.save_png(destino)
	if error != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error])
	else:
		print("captura en %s (%dx%d)" % [destino, imagen.get_width(), imagen.get_height()])
	quit(0 if error == OK else 1)


## La cinemática de encontrar una carta (#71), plano a plano.
##
## Se entra por donde se entra jugando: se abre el documento que esconde la
## carta y se pulsa su marca. Tocar el estado por detrás enseñaría una
## cinemática que no se alcanza jugando, que es el fallo que estas capturas
## existen para no cometer.
func _capturar_tarot(escena: Node, destino: String, argumentos: PackedStringArray) -> int:
	var folio_carta := String(argumentos[1]) if argumentos.size() > 1 else "ACTA-1999-014"
	var oculta := CartasOcultas.en_folio(folio_carta)
	if oculta.is_empty():
		printerr("El folio %s no esconde ninguna carta" % folio_carta)
		return 1

	var registros: Array = escena.caso["registros"]
	var cual := -1
	for i in registros.size():
		if registros[i]["folio"] == folio_carta:
			cual = i
			break
	if cual < 0:
		printerr("El folio %s no está en el expediente abierto" % folio_carta)
		return 1

	escena._lista.select(cual)
	escena._al_elegir_documento(cual)
	await process_frame
	escena._al_pulsar_marca("carta:%s" % oculta["carta"])
	await process_frame

	# El reproductor lo crea el visor y no lo guarda en ningún campo: aquí se
	# busca entre sus hijos, que es lo único que este capturador puede saber sin
	# obligar al visor a exponerlo solo para las capturas.
	var reproductor: Node = null
	for hijo in escena.get_children():
		if hijo.has_method("reproducir"):
			reproductor = hijo
	if reproductor == null:
		printerr("La marca no abrió ninguna cinemática: ¿el expediente ya está cerrado?")
		return 1

	# Los planos se miran de uno en uno, como los del careo y los de la entrada:
	# los cuatro juntos en una imagen no son mirables.
	var plano := int(argumentos[2]) if argumentos.size() > 2 else 0
	for i in 3:
		await process_frame
	if plano < 0:
		reproductor.saltar()
	else:
		for i in plano:
			reproductor._siguiente()
	# Solo dos fotogramas, y no seis como en el careo: el canto dura 0,22 s y
	# con xvfb un fotograma puede costar más que eso, así que esperar de más
	# capturaba el plano SIGUIENTE. El síntoma era que el canto no aparecía
	# nunca y las capturas del giro salían idénticas a la del frontal.
	for i in 2:
		await process_frame

	root.get_texture().get_image().save_png(destino)
	print("captura en %s" % destino)
	return 0
