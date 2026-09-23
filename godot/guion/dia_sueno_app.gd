## Costura de #74 sobre el día existente.
##
## `dia_app.gd` sigue siendo la autoridad del ciclo diario. Esta capa solo
## intercepta el tránsito casa -> sueño para poner una continuidad visual una
## vez que Jornada ya ha calculado la noche y la primera sala ya está montada.
extends "res://guion/dia_app.gd"

const ESCENA_CINEMATICA := preload("res://escenas/cinematica.tscn")
const PREPARACION_SUENO := preload("res://guion/preparacion_sueno.gd")

## Un solo animador ambiental por día. Vive aquí, en el ancestro común de la
## cadena `dia_*`, porque el presupuesto de #1230 es global: si cada fase
## montara el suyo, la calle y el sueño podrían gastar el doble sin que nadie
## lo viera. Cada capa registra sus piezas y todas compiten por el mismo cupo.
const NOMBRE_ANIMADOR := "AnimadorAmbiental"

var _entrada_sueno: Node3D = null
var _animador_ambiental: AnimadorAmbiental3D = null
var _respiracion_sueno: SuenoRespiracion = null


## Las identidades fuertes reutilizan formas ya seleccionadas por la noche. La
## capa base construye primero el contenido autorizado de #87 y solo después se
## transforma la presentación de la forma concreta, sin tocar `Sueno.noche()`.
func _espacio_de(fase: String) -> Dictionary:
	var espacio: Dictionary = super._espacio_de(fase)
	if fase != "sueño" or jornada["sueno_escenas"].is_empty():
		return espacio
	var id := String(jornada["sueno_escenas"][0])
	# #786: cero lecturas tiene una identidad propia. No pasa por las identidades
	# temáticas ni por HorrorTexturas porque ambas introducirían señales ajenas al
	# día vacío; solo se deforma la estructura laboral que ya conoce el jugador.
	if jornada.get("leido_hoy", []).is_empty():
		return SuenoVacio.adaptar_espacio(espacio)
	if SuenoEscuela.es_forma(id):
		espacio = SuenoEscuela.adaptar_espacio(espacio, {"variante_aulas": 0})
	elif SuenoMontana.es_forma(id):
		espacio = SuenoMontana.adaptar_espacio(espacio, {"variante_cabana": 0})
	elif SuenoDesierto.es_forma(id):
		espacio = SuenoDesierto.adaptar_espacio(espacio, {"variante_horizonte": 0})

	# #231: primero sabemos QUÉ sueño es; después decidimos cuánto se degrada.
	# Así escuela/montaña/desierto/castillo reciben su perfil semántico real y
	# las salas posteriores de la misma noche pueden volverse más agresivas sin
	# reseleccionar escenas ni tocar progreso.
	var opciones := _opciones_sueno()
	var total_escenas := clampi(
		int(opciones.get("cantidad", Sueno.ESCENAS_POR_NOCHE)),
		1,
		SuenoFormas.ids().size(),
	)
	var nivel_horror := HorrorTexturas.nivel_para_noche(
		total_escenas, jornada["sueno_escenas"].size(), espacio
	)
	return HorrorTexturas.aplicar(espacio, id, nivel_horror)


## Las presentaciones específicas se montan DESPUÉS del espacio jugable. Así la
## geometría base sigue siendo la única autoridad de navegación/colisión y el
## arte puede vestirla sin duplicar reglas ni conocer el id de la sala aquí.
func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	# El mundo se rehace entero en cada fase: lo registrado apuntaría a nodos
	# muertos. Se suelta aquí, antes de que las capas descendientes monten lo
	# suyo sobre el mundo nuevo.
	soltar_animacion_ambiental()
	if fase != "sueño" or _mundo == null:
		return
	SuenoVacio3D.montar(_mundo, _espacio_actual)
	SuenoCastillo3D.montar(_mundo, _espacio_actual)
	SuenoMontana3D.montar(_mundo, _espacio_actual)
	SuenoDesierto3D.montar(_mundo, _espacio_actual)
	SuenoEscuela3D.montar(_mundo, _espacio_actual)
	_montar_respiracion_sueno()


## El animador ambiental vigente, listo para recibir piezas. Lo usan las capas
## descendientes de la cadena; aquí no se sabe qué se mueve en cada fase.
func animador_ambiental() -> AnimadorAmbiental3D:
	if _animador_ambiental == null or not is_instance_valid(_animador_ambiental):
		_animador_ambiental = AnimadorAmbiental3D.new()
		_animador_ambiental.name = NOMBRE_ANIMADOR
		add_child(_animador_ambiental)
	return _animador_ambiental


func soltar_animacion_ambiental() -> void:
	if _animador_ambiental != null and is_instance_valid(_animador_ambiental):
		_animador_ambiental.limpiar()
	if _respiracion_sueno != null and is_instance_valid(_respiracion_sueno):
		# Devolver la sala a su forma antes de soltarla: el material puede estar
		# cacheado y no puede heredar la respiración de la noche anterior.
		_respiracion_sueno.soltar()
		_respiracion_sueno.queue_free()
	_respiracion_sueno = null


func _montar_respiracion_sueno() -> void:
	var animador := animador_ambiental()
	animador.semilla = int(jornada.get("dia", 1))
	_respiracion_sueno = SuenoRespiracion.new()
	_respiracion_sueno.name = "RespiracionSueno"
	add_child(_respiracion_sueno)
	_respiracion_sueno.adoptar(_mundo, animador)


## Mientras se ve la bisagra no corre el reloj onírico. La noche ya existe,
## pero no empieza a gastarse hasta que el jugador recupera el control.
func _process(delta: float) -> void:
	if _entrada_sueno != null:
		return
	super._process(delta)


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	var destino := String(salida.get_meta("destino", ""))
	var frase := String(salida.get_meta("frase", ""))
	var evento := String(salida.get_meta("evento", ""))
	if (
		jornada.get("fase", "") == "sueño"
		and cuerpo == _caminante
		and _pantalla == null
		and evento == "codice_castillo"
		and not frase.is_empty()
		and not bool(salida.get_meta("reaccion_castillo", false))
	):
		salida.set_meta("reaccion_castillo", true)
		SuenoCastillo3D.reaccionar_a_lectura(_mundo)
	if (
		jornada.get("fase", "") == "casa"
		and cuerpo == _caminante
		and _pantalla == null
		and not partida.guardado_pendiente
		and frase.is_empty()
		and destino == "sueño"
	):
		_abrir_preparacion_sueno()
		return
	super._al_pisar_salida(cuerpo, salida)


## Antes de dormir, #162 deja elegir qué lecturas se lleva la memoria. La capa
## no modifica la jornada todavía: abrir/cancelar es una UI reversible y solo
## confirmar llama al contrato persistente de SeleccionNocturna.
func _abrir_preparacion_sueno() -> void:
	if _pantalla != null:
		return
	_caminante.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.visible = false
	_mostrar_prioridades(false)

	_pantalla = CanvasLayer.new()
	_pantalla.layer = 30
	add_child(_pantalla)
	var panel := PREPARACION_SUENO.new()
	(
		panel
		. configurar(
			jornada.get("leido_hoy", []),
			jornada.get("seleccion_nocturna", []),
		)
	)
	_pantalla.add_child(panel)
	panel.confirmada.connect(_confirmar_preparacion_sueno)
	panel.cancelada.connect(_cancelar_preparacion_sueno)


func _confirmar_preparacion_sueno(seleccion: Array) -> void:
	if not Jornada.preparar_sueno(jornada, seleccion):
		return
	_cerrar_preparacion_sueno(false)
	_dormir_con_entrada()


func _cancelar_preparacion_sueno() -> void:
	_cerrar_preparacion_sueno(true)


func _cerrar_preparacion_sueno(restaurar_control: bool) -> void:
	if _pantalla != null:
		_pantalla.queue_free()
		_pantalla = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not restaurar_control:
		return
	_caminante.set_physics_process(true)
	_hud.visible = true
	_mostrar_prioridades(true)


## La regla ocurre primero: pagar el día, actualizar el gato, seleccionar la
## noche, montar la primera sala y recordar su mapa. Solo después se reproduce
## la transición, de modo que saltarla o cerrarla no decide nada.
func _dormir_con_entrada() -> void:
	var noche := Jornada.dormir(jornada)
	_aplicar_politica_sueno()
	_hablando = false
	_nomina.text = (
		tr("DIA_VIVIR")
		% [
			noche["coste"],
			noche["dinero"],
			(tr("DIA_SIN_GATO_AVISO") if noche["gato_se_fue"] else "") + _aviso_imprevisto(noche)
		]
	)

	# El sueño queda detrás de la cinemática ya construido. Así no existe un
	# fotograma negro entre ambas capas y el mapa está actualizado antes de que
	# empiece la presentación.
	_entrar_en("sueño")
	_guardar_o_avisar("")

	_caminante.set_physics_process(false)
	# La secuencia rueda dentro de la sala: sin HUD encima, igual que la cama.
	_hud.visible = false
	_mostrar_prioridades(false)
	_mundo.process_mode = Node.PROCESS_MODE_DISABLED
	_entrada_sueno = ESCENA_CINEMATICA.instantiate()
	add_child(_entrada_sueno)
	_entrada_sueno.terminada.connect(_cerrar_entrada_sueno)
	_entrada_sueno.reproducir(
		EntradaSuenoCinematica.planos_de(
			jornada["leido_hoy"],
			Cinematica.vistas_de(partida.estado, EntradaSuenoCinematica.ID),
			_espacio_actual
		),
		EntradaSuenoCinematica.ID,
		partida.estado
	)


func _cerrar_entrada_sueno() -> void:
	if _entrada_sueno == null:
		return
	_entrada_sueno.queue_free()
	_entrada_sueno = null
	_mundo.process_mode = Node.PROCESS_MODE_INHERIT
	_caminante.set_physics_process(true)
	_hud.visible = true
	_mostrar_prioridades(true)
	# Conserva también la cuenta de vistas de la cinemática. El resto del sueño
	# ya se había guardado antes de empezar a verla.
	_guardar_o_avisar("")


func _mostrar_prioridades(mostrar: bool) -> void:
	var prioridades := get_node_or_null("HUDPrioridades")
	if prioridades != null:
		prioridades.set("visible", mostrar)
