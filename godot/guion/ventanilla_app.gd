## La Ventanilla de Reclamaciones: la pantalla.
##
## #779 convierte el duelo en un careo documental: la elección de ronda sigue
## resolviéndose en `Combate`, pero una pista ya descubierta y vinculada al
## reclamante puede reforzar una lectura correcta. El reclamante se ve en 3D,
## las pruebas quedan selladas sobre el mostrador y una derrota puede apelarse
## mediante un Juicio por Combate 3D.
##
## El movimiento sigue tres reglas: la ronda se resuelve antes de animarla, la
## escritura puede saltarse y `reduccion_movimiento` conserva las reglas sin
## sacudidas, reacciones ni desplazamientos decorativos.
extends Control

## Cuando se abre desde la calle, la Ventanilla atiende con la MISMA partida del
## día: dos copias del estado guardando a la vez se pisarían la racha o la jornada.
signal cerrada

const SEGUNDOS_POR_CARACTER := 0.018
const SACUDIDA := 7.0
const SACUDIDA_SEGUNDOS := 0.28

var contenido := Contenido.new()
var partida := Partida.new()
var partida_externa: Partida = null
var historias := Historias.new()

var combate: Dictionary = {}
var racha := 0
var reduccion_movimiento := false

var _azar := RandomNumberGenerator.new()
var _rival: Dictionary = {}
var _escribiendo := ""
var _escrito := 0.0
var _sacudida := 0.0
var _tablero: Control
var _duelo_visual: HBoxContainer
var _previsualizador: PrevisualizadorReclamante3D
var _replica: RichTextLabel
var _cronica: Label
var _vida_jugador: ProgressBar
var _vida_rival: ProgressBar
var _nombre_rival: Label
var _marcador: Label
var _botones: HBoxContainer
var _habilidades: HBoxContainer
var _lista: ItemList
var _evidencias: ItemList
var _ficha: RichTextLabel
var _habilidad_elegida_eje := ""
var _juicio: JuicioCombate3D
var _pulso: CareoPulso
var _jugada_pendiente := ""
var _evidencia_pendiente := ""
var _habilidad_pendiente := ""
var _pulso_racha := 0


func _ready() -> void:
	theme = EstiloSiga.tema()
	contenido.cargar()
	historias.cargar()
	if partida_externa != null:
		partida = partida_externa
	else:
		partida.cargar()
	_sembrar_tiradas()
	_construir()
	_llenar_turno()


func _process(delta: float) -> void:
	if not _escribiendo.is_empty():
		_escrito += delta / SEGUNDOS_POR_CARACTER
		var hasta := mini(int(_escrito), _escribiendo.length())
		_replica.text = _escribiendo.substr(0, hasta)
		if hasta >= _escribiendo.length():
			_escribiendo = ""

	if _sacudida > 0.0:
		_sacudida = maxf(0.0, _sacudida - delta)
		var fuerza := SACUDIDA * (_sacudida / SACUDIDA_SEGUNDOS)
		_tablero.position = Vector2(
			_azar.randf_range(-fuerza, fuerza), _azar.randf_range(-fuerza, fuerza)
		)
		if is_zero_approx(_sacudida):
			_tablero.position = Vector2.ZERO


func _unhandled_input(evento: InputEvent) -> void:
	if _juicio != null:
		if evento.is_action_pressed("cancelar") or evento.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_juicio.abandonar()
		return
	if evento.is_action_pressed("cancelar") or evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_salir_ventanilla()
		return
	if evento.is_pressed() and not _escribiendo.is_empty():
		_escrito = float(_escribiendo.length())


func _salir_ventanilla() -> void:
	if partida_externa != null:
		cerrada.emit()
		return
	get_tree().change_scene_to_file("res://escenas/inicio.tscn")


func _draw() -> void:
	EstiloSiga.dibujar_bisel(self, Rect2(Vector2.ZERO, size), EstiloSiga.GRIS, true)


# --- Turno ------------------------------------------------------------------


func _llenar_turno() -> void:
	combate = {}
	_habilidad_elegida_eje = ""
	_pulso_racha = 0
	_pulso.cancelar()
	_lista.clear()
	for reclamante in Ventanilla.disponibles(contenido, partida.estado["pistas_descubiertas"]):
		_lista.add_item(tr(reclamante["nombre"]))
		_lista.set_item_metadata(_lista.item_count - 1, reclamante)
	_lista.visible = true
	_duelo_visual.visible = false
	_botones.visible = false
	_habilidades.visible = false
	_cronica.text = tr("VENTANILLA_LLAME")
	_replica.text = ""
	_ficha.text = tr("VENTANILLA_NADIE")
	_actualizar_marcador()


func _al_llamar(indice: int) -> void:
	_rival = _lista.get_item_metadata(indice)
	var evidencias := CareoDocumental.evidencias_relevantes(
		_rival, contenido, partida.estado["pistas_descubiertas"]
	)
	combate = CareoDocumental.nuevo(_rival, historias.cargas(partida.estado), evidencias)
	_lista.visible = false
	_duelo_visual.visible = true
	_botones.visible = true
	_habilidades.visible = true
	_cronica.text = tr("VENTANILLA_SE_PRESENTA") % tr(_rival["nombre"])
	_replica.text = ""
	_previsualizador.reduccion_movimiento = reduccion_movimiento
	_previsualizador.mostrar(_rival)
	_pintar_ficha()
	_pintar_botones_jugada()
	_pintar_habilidades()
	_pintar_evidencias()
	_actualizar_marcador()


func _al_jugar(tipo: String) -> void:
	if combate.is_empty() or combate["terminado"] or _pulso.activo():
		return
	_jugada_pendiente = tipo
	_evidencia_pendiente = _evidencia_elegida()
	_habilidad_pendiente = _habilidad_elegida()
	for boton in _botones.get_children():
		boton.disabled = true
	for boton in _habilidades.get_children():
		boton.disabled = true
	_evidencias.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(
		_pulso
		. armar(
			tipo,
			int(combate["ronda"]),
			String(_rival.get("id", _rival.get("nombre", ""))),
			reduccion_movimiento,
			_pulso_racha,
		)
	)


func _al_pulso_confirmado(calidad: String) -> void:
	var ronda := CareoDocumental.jugar(
		combate, _jugada_pendiente, _evidencia_pendiente, _habilidad_pendiente, _tirada()
	)
	_habilidad_elegida_eje = ""
	_pulso_racha = CareoPulso.aplicar_iniciativa(combate, ronda, _pulso_racha, calidad, _tirada())
	if calidad == "perfecto":
		Sonido.sonar(self, "marcar" if not ronda["revelada"].is_empty() else "pulsar")
	_jugada_pendiente = ""
	_evidencia_pendiente = ""
	_habilidad_pendiente = ""
	_evidencias.mouse_filter = Control.MOUSE_FILTER_STOP
	_pintar_botones_jugada()
	_contar(ronda)


func _contar(ronda: Dictionary) -> void:
	var texto := (
		tr("COMBATE_CRONICA")
		% [
			Combate.etiqueta(ronda["tipo_jugador"]),
			tr(_rival["nombre"]),
			Combate.etiqueta(ronda["tipo_rival"]),
			_veredicto(ronda["veredicto"])
		]
	)
	if not ronda["revelada"].is_empty():
		texto += "\n" + tr("VENTANILLA_ADELANTA") % ronda["revelada"]
	var evidencia: Dictionary = ronda.get("evidencia", {})
	if not evidencia.is_empty():
		var resumen := String(evidencia.get("descripcion", evidencia.get("fraseGatillo", "")))
		if not resumen.is_empty():
			texto += "\n" + resumen
	_cronica.text = texto

	_decir(ronda["replica"])
	if ronda["dano_al_jugador"] > 0 and not reduccion_movimiento:
		_sacudida = SACUDIDA_SEGUNDOS
	_previsualizador.reaccion(ronda)

	_pintar_habilidades()
	_pintar_evidencias()
	_actualizar_marcador()

	if ronda["terminado"]:
		if ronda["ganador"] == "jugador":
			_cerrar(true)
		else:
			_ofrecer_juicio()


func _ofrecer_juicio() -> void:
	_habilidades.visible = false
	_evidencias.visible = false
	_limpiar_hijos(_botones)
	_botones.visible = true

	# Reutiliza vocabulario ya presente: Objeción es la apelación extraordinaria
	# y Silencio acepta el resultado. El icono deja claro qué opción abre acción.
	var juicio := Button.new()
	var texto_juicio := "⚔ " + Combate.etiqueta("objecion")
	juicio.text = texto_juicio
	juicio.pressed.connect(_abrir_juicio)
	_botones.add_child(juicio)

	var aceptar := Button.new()
	var texto_aceptar := "✓ " + Combate.etiqueta("silencio")
	aceptar.text = texto_aceptar
	aceptar.pressed.connect(_cerrar.bind(false))
	_botones.add_child(aceptar)


func _abrir_juicio() -> void:
	if _juicio != null:
		return
	_tablero.visible = false
	_juicio = JuicioCombate3D.new()
	_juicio.configurar(_rival, CareoDocumental.bono_juicio(combate), reduccion_movimiento)
	_juicio.terminado.connect(_al_juicio_terminado)
	add_child(_juicio)


func _al_juicio_terminado(gano: bool) -> void:
	var juicio_actual := _juicio
	_juicio = null
	if juicio_actual != null:
		juicio_actual.queue_free()
	_tablero.visible = true
	_cerrar(gano)


func _cerrar(gano: bool) -> void:
	var cierre := Ventanilla.cerrar(partida.estado, racha, gano)
	racha = cierre["racha"]
	for id in cierre["logros"]:
		Prometeo.desbloquear_carta(partida.estado["tarot"], id)
	var se_guardo := partida.guardar()

	_botones.visible = false
	_habilidades.visible = false
	_evidencias.visible = false
	_cronica.text += (
		"\n\n%s" % (tr("VENTANILLA_ATENDIDA") % racha if gano else tr("VENTANILLA_NO_ATENDIDA"))
	)
	_actualizar_marcador()
	if not se_guardo:
		_cronica.text += "\n\n%s" % tr("ARCHIVO_ERROR_GUARDAR")

	var siguiente := Button.new()
	siguiente.text = tr("VENTANILLA_SIGUIENTE")
	siguiente.pressed.connect(
		func():
			if partida.guardado_pendiente:
				_cronica.text += (
					"\n\n%s"
					% (
						tr("ARCHIVO_GUARDADO_HECHO")
						if partida.guardar()
						else tr("ARCHIVO_ERROR_GUARDAR")
					)
				)
				if partida.guardado_pendiente:
					return
			siguiente.queue_free()
			_llenar_turno()
	)
	_botones.get_parent().add_child(siguiente)


func _pintar_ficha() -> void:
	var etiqueta := tr("FICHA_PERSONA") if _rival["tipo"] == "PERSONA" else tr("FICHA_COMITE")
	var cuerpo: String = tr(_rival.get("resumen", ""))
	_ficha.text = tr("FICHA_RECLAMANTE") % [tr(_rival["nombre"]), etiqueta, cuerpo]


func _decir(frase: String) -> void:
	if frase.is_empty():
		_replica.text = ""
		return
	if reduccion_movimiento:
		_replica.text = frase
		return
	_escribiendo = frase
	_escrito = 0.0
	_replica.text = ""


func _veredicto(cual: String) -> String:
	match cual:
		"gana_jugador":
			return tr("VEREDICTO_JUGADOR")
		"gana_rival":
			return tr("VEREDICTO_RIVAL")
		_:
			return tr("VEREDICTO_EMPATE")


func _sembrar_tiradas() -> void:
	var jornada: Dictionary = partida.estado.get("jornada", {})
	_azar.seed = Azar.derivar(
		int(partida.estado.get("semilla", 0)),
		"combate",
		[int(jornada.get("vuelta", 1)), int(jornada.get("dia", 1))]
	)


func _tirada() -> Callable:
	return func(): return _azar.randf()


# --- Evidencias y habilidades -----------------------------------------------


func _evidencia_elegida() -> String:
	var seleccion := _evidencias.get_selected_items()
	if seleccion.is_empty():
		return ""
	return String(_evidencias.get_item_metadata(seleccion[0]))


func _pintar_evidencias() -> void:
	_evidencias.clear()
	if combate.is_empty():
		_evidencias.visible = false
		return
	for evidencia in CareoDocumental.evidencias_disponibles(combate):
		var texto := String(evidencia.get("descripcion", evidencia.get("fraseGatillo", "")))
		_evidencias.add_item(texto)
		_evidencias.set_item_metadata(_evidencias.item_count - 1, evidencia.get("id", ""))
	_evidencias.visible = _evidencias.item_count > 0 and not combate["terminado"]


func _habilidad_elegida() -> String:
	return _habilidad_elegida_eje


func _pintar_habilidades() -> void:
	_limpiar_hijos(_habilidades)
	if combate.is_empty() or combate["terminado"]:
		return
	for eje in Combate.cargas_disponibles(combate):
		var habilidad: Dictionary = Historias.HABILIDADES[eje]
		var boton := Button.new()
		boton.text = tr("VENTANILLA_HABILIDAD") % [tr(habilidad["nombre"]), combate["cargas"][eje]]
		boton.tooltip_text = tr(habilidad["efecto"])
		boton.toggle_mode = true
		boton.pressed.connect(
			func():
				_habilidad_elegida_eje = eje if boton.button_pressed else ""
				for otro in _habilidades.get_children():
					if otro != boton:
						otro.button_pressed = false
		)
		_habilidades.add_child(boton)


func _pintar_botones_jugada() -> void:
	_limpiar_hijos(_botones)
	for tipo in Combate.TIPOS:
		var boton := Button.new()
		boton.text = Combate.etiqueta(tipo)
		boton.pressed.connect(_al_jugar.bind(tipo))
		_botones.add_child(boton)


func _actualizar_marcador() -> void:
	if combate.is_empty():
		_vida_jugador.value = 0
		_vida_rival.value = 0
		_nombre_rival.text = ""
	else:
		_vida_jugador.value = maxi(0, int(combate["vida_jugador"]))
		_vida_rival.value = maxi(0, int(combate["vida_rival"]))
		_nombre_rival.text = tr(_rival["nombre"])
	_marcador.text = (
		tr("VENTANILLA_MARCADOR") % [racha, partida.estado.get("coliseo_racha_mejor", 0)]
	)


# --- Cajas ------------------------------------------------------------------


func _construir() -> void:
	_tablero = VBoxContainer.new()
	_tablero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tablero.offset_left = 10
	_tablero.offset_top = 10
	_tablero.offset_right = -10
	_tablero.offset_bottom = -10
	_tablero.add_theme_constant_override("separation", 8)
	add_child(_tablero)

	_tablero.add_child(_titulo(tr("VENTANILLA_TITULO")))
	_marcador = _etiqueta("")
	_tablero.add_child(_marcador)

	_lista = ItemList.new()
	_lista.custom_minimum_size.y = 150
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.add_theme_stylebox_override("panel", _hundido(EstiloSiga.BLANCO))
	_lista.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	_lista.item_activated.connect(_al_llamar)
	_lista.item_selected.connect(_al_llamar)
	_tablero.add_child(_lista)

	_duelo_visual = HBoxContainer.new()
	_duelo_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_duelo_visual.add_theme_constant_override("separation", 10)
	_tablero.add_child(_duelo_visual)

	_previsualizador = PrevisualizadorReclamante3D.new()
	_previsualizador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_previsualizador.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_duelo_visual.add_child(_previsualizador)

	var informacion := VBoxContainer.new()
	informacion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	informacion.size_flags_vertical = Control.SIZE_EXPAND_FILL
	informacion.add_theme_constant_override("separation", 6)
	_duelo_visual.add_child(informacion)

	informacion.add_child(_construir_vidas())

	_replica = RichTextLabel.new()
	_replica.bbcode_enabled = false
	_replica.custom_minimum_size.y = 72
	_replica.add_theme_stylebox_override("normal", _hundido(EstiloSiga.BLANCO))
	_replica.add_theme_color_override("default_color", EstiloSiga.NEGRO)
	_replica.add_theme_font_override("normal_font", theme.get_font("mono_font", "RichTextLabel"))
	informacion.add_child(_replica)

	_cronica = _etiqueta("")
	_cronica.custom_minimum_size.y = 48
	_cronica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cronica.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	informacion.add_child(_cronica)

	_ficha = RichTextLabel.new()
	_ficha.bbcode_enabled = true
	_ficha.custom_minimum_size.y = 72
	_ficha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ficha.add_theme_stylebox_override("normal", _hundido(EstiloSiga.GRIS))
	_ficha.add_theme_color_override("default_color", EstiloSiga.NEGRO)
	informacion.add_child(_ficha)

	_evidencias = ItemList.new()
	_evidencias.custom_minimum_size.y = 86
	_evidencias.select_mode = ItemList.SELECT_SINGLE
	_evidencias.allow_reselect = true
	_evidencias.add_theme_stylebox_override("panel", _hundido(EstiloSiga.BLANCO))
	_evidencias.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	informacion.add_child(_evidencias)

	_pulso = CareoPulso.new()
	_pulso.confirmado.connect(_al_pulso_confirmado)
	_tablero.add_child(_pulso)

	_botones = HBoxContainer.new()
	_tablero.add_child(_botones)

	_habilidades = HBoxContainer.new()
	_tablero.add_child(_habilidades)

	var salir := Button.new()
	salir.name = "SalirVentanilla"
	salir.text = tr("VENTANILLA_SALIR")
	salir.pressed.connect(_salir_ventanilla)
	_tablero.add_child(salir)


func _construir_vidas() -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)

	_vida_jugador = ProgressBar.new()
	_vida_jugador.max_value = Combate.VIDA_INICIAL
	_vida_jugador.show_percentage = false
	_vida_jugador.custom_minimum_size = Vector2(110, 18)
	_vida_jugador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_vida_jugador)

	_nombre_rival = _etiqueta("")
	_nombre_rival.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre_rival.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_nombre_rival)

	_vida_rival = ProgressBar.new()
	_vida_rival.max_value = Combate.VIDA_INICIAL
	_vida_rival.show_percentage = false
	_vida_rival.custom_minimum_size = Vector2(110, 18)
	_vida_rival.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_vida_rival)
	return fila


func _limpiar_hijos(nodo: Node) -> void:
	for hijo in nodo.get_children():
		hijo.queue_free()


func _titulo(texto: String) -> Control:
	var barra := PanelContainer.new()
	var caja := StyleBoxFlat.new()
	caja.bg_color = EstiloSiga.AZUL_TITULO
	caja.set_corner_radius_all(0)
	caja.content_margin_left = 6
	caja.content_margin_top = 3
	caja.content_margin_bottom = 3
	barra.add_theme_stylebox_override("panel", caja)
	var etiqueta := _etiqueta(texto)
	etiqueta.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	etiqueta.add_theme_font_override("font", theme.get_font("title_font", "Label"))
	barra.add_child(etiqueta)
	return barra


func _etiqueta(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	etiqueta.add_theme_font_size_override("font_size", 14)
	return etiqueta


func _hundido(fondo: Color) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.set_corner_radius_all(0)
	caja.border_width_top = EstiloSiga.GROSOR
	caja.border_width_left = EstiloSiga.GROSOR
	caja.border_width_bottom = EstiloSiga.GROSOR
	caja.border_width_right = EstiloSiga.GROSOR
	caja.border_color = EstiloSiga.GRIS_OSCURO
	caja.content_margin_left = 8
	caja.content_margin_right = 8
	caja.content_margin_top = 6
	caja.content_margin_bottom = 6
	return caja
