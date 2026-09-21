## Tercer corte de #153: tarjeta de pronóstico previa a la primera lectura.
##
## Vive por encima del visor completo para que apostar no cambie ninguna regla
## de lectura, acusación, careo, anexos o marcadores. El contrato real sigue en
## Pronosticos; esta capa solo traduce controles en crear/abandonar y deriva si
## el expediente ya fue expuesto a partir de lecturas que el visor ya conserva.
extends "res://guion/visor_anexos_app.gd"

const TIPOS := [
	{"id": "habra_duelo", "texto": "VISOR_PRONOSTICO_DUELO"},
	{"id": "acusacion_precipitada", "texto": "VISOR_PRONOSTICO_PRECIPITADA"},
	{"id": "cierre_hoy", "texto": "VISOR_PRONOSTICO_CIERRE"},
	{"id": "arrastra_manana", "texto": "VISOR_PRONOSTICO_ARRASTRA"},
	{"id": "documento_clave", "texto": "VISOR_PRONOSTICO_DOCUMENTO"},
	{"id": "tarot", "texto": "VISOR_PRONOSTICO_TAROT"},
]

const TEXTO_DECISION_924 := {
	"responsabilidad_compartida": "VISOR_DECISION_924_RESPONSABILIDAD",
	"revision_procedimental": "VISOR_DECISION_924_REVISION",
	"conciliacion_interna": "VISOR_DECISION_924_CONCILIACION",
}

var _pronostico_tipo: OptionButton
var _pronostico_valor: OptionButton
var _pronostico_confirmar: Button
var _pronostico_abandonar: Button
var _pronostico_historial_boton: Button
var _pronostico_estado: Label
var _ventana_historial: Window
var _pronostico_historial_lista: ItemList
var _decision_924_bloque: VBoxContainer
var _decision_924_estado: Label
var _decision_924_opciones: VBoxContainer


func _ready() -> void:
	super._ready()
	_actualizar_pronostico()
	_actualizar_decision_924()


func _columna_indice() -> Control:
	var columna: Control = super._columna_indice()
	columna.add_child(HSeparator.new())

	# Los controles opcionales no deben caer directamente sobre el gris/sombra
	# del shell. Una superficie clara y opaca mantiene el contraste y separa la
	# apuesta secundaria de la lista de documentos, que es la acción principal.
	var panel := PanelContainer.new()
	panel.name = "PanelPronosticoAuditoria"
	panel.add_theme_stylebox_override("panel", EstiloSiga.caja_saliente(Color("e6e6e6")))
	columna.add_child(panel)

	var contenido_panel := VBoxContainer.new()
	contenido_panel.add_theme_constant_override("separation", 4)
	panel.add_child(contenido_panel)

	var titulo := Label.new()
	titulo.text = tr("VISOR_PRONOSTICO_TITULO")
	titulo.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	contenido_panel.add_child(titulo)

	_pronostico_estado = Label.new()
	_pronostico_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pronostico_estado.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	contenido_panel.add_child(_pronostico_estado)

	var opciones := HBoxContainer.new()
	opciones.add_theme_constant_override("separation", 4)
	_pronostico_tipo = OptionButton.new()
	_pronostico_tipo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for ficha in TIPOS:
		_pronostico_tipo.add_item(tr(String(ficha["texto"])))
		_pronostico_tipo.set_item_metadata(_pronostico_tipo.item_count - 1, String(ficha["id"]))
	_pronostico_tipo.item_selected.connect(_al_cambiar_tipo_pronostico)
	opciones.add_child(_pronostico_tipo)

	_pronostico_valor = OptionButton.new()
	_pronostico_valor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opciones.add_child(_pronostico_valor)
	contenido_panel.add_child(opciones)

	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 4)
	_pronostico_confirmar = Button.new()
	_pronostico_confirmar.text = tr("VISOR_PRONOSTICO_CONFIRMAR")
	_pronostico_confirmar.pressed.connect(_al_confirmar_pronostico)
	acciones.add_child(_pronostico_confirmar)
	_pronostico_abandonar = Button.new()
	_pronostico_abandonar.text = tr("VISOR_PRONOSTICO_ABANDONAR")
	_pronostico_abandonar.pressed.connect(_al_abandonar_pronostico)
	acciones.add_child(_pronostico_abandonar)
	_pronostico_historial_boton = Button.new()
	_pronostico_historial_boton.text = tr("VISOR_PRONOSTICO_HISTORIAL")
	_pronostico_historial_boton.pressed.connect(_abrir_historial_pronosticos)
	acciones.add_child(_pronostico_historial_boton)
	contenido_panel.add_child(acciones)

	_rellenar_valores_pronostico()
	_montar_decision_924(contenido_panel)
	return columna

func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_actualizar_pronostico()
	_actualizar_decision_924()


func _al_elegir_documento(indice: int) -> void:
	super._al_elegir_documento(indice)
	_actualizar_pronostico()


func _mostrar_cierre(acusacion: Dictionary, duelo: Dictionary = {}) -> void:
	super._mostrar_cierre(acusacion, duelo)
	_actualizar_decision_924()


func _al_cambiar_tipo_pronostico(_indice: int) -> void:
	_rellenar_valores_pronostico()
	_actualizar_pronostico()


func _rellenar_valores_pronostico() -> void:
	if _pronostico_valor == null or _pronostico_tipo == null:
		return
	_pronostico_valor.clear()
	var tipo := _tipo_seleccionado()
	if tipo == "documento_clave":
		var tipos: Array[String] = []
		for registro in caso.get("registros", []):
			var nombre := String(registro.get("tipo", "")).strip_edges()
			if not nombre.is_empty() and not tipos.has(nombre):
				tipos.append(nombre)
		tipos.sort()
		for nombre in tipos:
			_pronostico_valor.add_item(nombre.capitalize())
			_pronostico_valor.set_item_metadata(_pronostico_valor.item_count - 1, nombre)
		return
	if tipo == "tarot":
		for carta in partida.estado.get("tarot", []):
			if carta.get("recogida", false):
				continue
			var carta_id := String(carta.get("id", "")).strip_edges()
			var nombre_carta := String(carta.get("nombre", "")).strip_edges()
			if carta_id.is_empty():
				continue
			_pronostico_valor.add_item(
				nombre_carta if not nombre_carta.is_empty() else carta_id.capitalize()
			)
			_pronostico_valor.set_item_metadata(_pronostico_valor.item_count - 1, carta_id)
		return

	_pronostico_valor.add_item(tr("VISOR_PRONOSTICO_SI"))
	_pronostico_valor.set_item_metadata(0, true)
	_pronostico_valor.add_item(tr("VISOR_PRONOSTICO_NO"))
	_pronostico_valor.set_item_metadata(1, false)


func _tipo_seleccionado() -> String:
	if _pronostico_tipo == null or _pronostico_tipo.item_count == 0:
		return ""
	return String(_pronostico_tipo.get_item_metadata(_pronostico_tipo.selected))


func _valor_seleccionado():
	if _pronostico_valor == null or _pronostico_valor.item_count == 0:
		return null
	return _pronostico_valor.get_item_metadata(_pronostico_valor.selected)


func _al_carta_desbloqueada(carta_id: String) -> void:
	PronosticosAuditoria.resolver_tarot(partida.estado, String(caso.get("id", "")), carta_id)
	_actualizar_pronostico()
	super._al_carta_desbloqueada(carta_id)


func _al_firmar(resultado: Dictionary, formulario: Control) -> void:
	PronosticosAuditoria.resolver_cierre(partida.estado, caso, resultado)
	_actualizar_pronostico()
	super._al_firmar(resultado, formulario)


func _al_confirmar_pronostico() -> void:
	if _hay_guardado_a_medias() or caso.is_empty() or _caso_expuesto():
		_actualizar_pronostico()
		return
	var tipo := _tipo_seleccionado()
	var valor = _valor_seleccionado()
	if tipo.is_empty() or valor == null:
		_actualizar_pronostico()
		return
	var estado: Dictionary = partida.estado["pronosticos"]
	if Pronosticos.crear(estado, String(caso["id"]), tipo, valor, false):
		Sonido.sonar(self, "pulsar")
		_guardar_o_avisar()
	_actualizar_pronostico()


func _al_abandonar_pronostico() -> void:
	if _hay_guardado_a_medias() or caso.is_empty():
		return
	var estado: Dictionary = partida.estado["pronosticos"]
	if Pronosticos.abandonar(estado, String(caso["id"])):
		Sonido.sonar(self, "pulsar")
		_guardar_o_avisar()
	_actualizar_pronostico()


func _abrir_historial_pronosticos() -> void:
	if _ventana_historial != null and is_instance_valid(_ventana_historial):
		_ventana_historial.popup_centered()
		if _pronostico_historial_lista != null:
			_pronostico_historial_lista.grab_focus()
		return

	var ventana := Window.new()
	ventana.title = tr("VISOR_PRONOSTICO_HISTORIAL_TITULO")
	ventana.size = Vector2i(760, 420)
	ventana.min_size = Vector2i(520, 300)
	ventana.transient = true
	ventana.exclusive = true
	ventana.close_requested.connect(_cerrar_historial_pronosticos)
	add_child(ventana)
	_ventana_historial = ventana

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margen.add_theme_constant_override(lado, 8)
	ventana.add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	margen.add_child(caja)

	var cabecera := Label.new()
	cabecera.text = tr("VISOR_PRONOSTICO_HISTORIAL_AYUDA")
	cabecera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(cabecera)

	_pronostico_historial_lista = ItemList.new()
	_pronostico_historial_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.add_child(_pronostico_historial_lista)

	var estado_pronosticos: Dictionary = partida.estado.get("pronosticos", {})
	var filas := Pronosticos.historial(estado_pronosticos)
	if filas.is_empty():
		_pronostico_historial_lista.add_item(tr("VISOR_PRONOSTICO_HISTORIAL_VACIO"))
		_pronostico_historial_lista.set_item_disabled(0, true)
	else:
		for fila in filas:
			var indice := _pronostico_historial_lista.item_count
			_pronostico_historial_lista.add_item(_texto_historial_pronostico(fila))
			_pronostico_historial_lista.set_item_metadata(indice, String(fila["expediente"]))

	ventana.popup_centered()
	_pronostico_historial_lista.grab_focus()


func _cerrar_historial_pronosticos() -> void:
	if _ventana_historial != null and is_instance_valid(_ventana_historial):
		_ventana_historial.queue_free()
	_ventana_historial = null
	_pronostico_historial_lista = null
	if _pronostico_historial_boton != null:
		_pronostico_historial_boton.grab_focus()


func _texto_historial_pronostico(fila: Dictionary) -> String:
	return (
		tr("VISOR_PRONOSTICO_HISTORIAL_FILA")
		% [
			_titulo_expediente(String(fila.get("expediente", ""))),
			_nombre_tipo(String(fila.get("tipo", ""))),
			_texto_valor(fila.get("valor")),
			_nombre_estado(String(fila.get("estado", ""))),
		]
	)


func _titulo_expediente(expediente_id: String) -> String:
	for ficha in contenido.casos:
		if String(ficha.get("id", "")) == expediente_id:
			return tr(String(ficha.get("titulo", expediente_id)))
	return expediente_id


func _actualizar_pronostico() -> void:
	if _pronostico_estado == null:
		return
	_rellenar_valores_pronostico()
	var actual := _pronostico_actual()
	var ocupado := not actual.is_empty()
	var expuesto := _caso_expuesto()
	var abierto := String(actual.get("estado", "")) == Pronosticos.ESTADO_ABIERTO

	_pronostico_tipo.disabled = ocupado or expuesto
	_pronostico_valor.disabled = ocupado or expuesto or _pronostico_valor.item_count == 0
	_pronostico_confirmar.disabled = ocupado or expuesto or _pronostico_valor.item_count == 0
	# Abandonar sigue permitido tras leer: la regla de #153 prohíbe cambiar la
	# apuesta, no renunciar a ella.
	_pronostico_abandonar.disabled = not abierto

	if ocupado:
		_pronostico_estado.text = (
			tr("VISOR_PRONOSTICO_RESUMEN")
			% [
				_nombre_tipo(String(actual.get("tipo", ""))),
				_texto_valor(actual.get("valor")),
				_nombre_estado(String(actual.get("estado", ""))),
			]
		)
	elif expuesto:
		_pronostico_estado.text = tr("VISOR_PRONOSTICO_BLOQUEADO")
	else:
		_pronostico_estado.text = tr("VISOR_PRONOSTICO_DISPONIBLE")


func _pronostico_actual() -> Dictionary:
	if caso.is_empty():
		return {}
	var estado: Dictionary = partida.estado.get("pronosticos", {})
	Pronosticos.completar(estado)
	var actual = estado["por_expediente"].get(String(caso["id"]), {})
	return actual if typeof(actual) == TYPE_DICTIONARY else {}


func _caso_expuesto() -> bool:
	if caso.is_empty() or Acusacion.esta_cerrado(partida.estado, String(caso.get("id", ""))):
		return true
	var leidos_total: Array = jornada.get("leidos_total", [])
	var leidos_hoy: Array = jornada.get("leido_hoy", [])
	for registro in caso.get("registros", []):
		if leidos_total.has(registro.get("id", "")) or leidos_hoy.has(registro.get("folio", "")):
			return true
	return false


func _montar_decision_924(columna: Control) -> void:
	columna.add_child(HSeparator.new())
	_decision_924_bloque = VBoxContainer.new()
	_decision_924_bloque.name = "DecisionIdeologicaExpediente"
	_decision_924_bloque.add_theme_constant_override("separation", 4)
	columna.add_child(_decision_924_bloque)

	var titulo := Label.new()
	titulo.text = tr("VISOR_DECISION_924_TITULO")
	_decision_924_bloque.add_child(titulo)

	_decision_924_estado = Label.new()
	_decision_924_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_decision_924_bloque.add_child(_decision_924_estado)

	_decision_924_opciones = VBoxContainer.new()
	_decision_924_opciones.add_theme_constant_override("separation", 3)
	_decision_924_bloque.add_child(_decision_924_opciones)


func _actualizar_decision_924() -> void:
	if (
		_decision_924_bloque == null
		or _decision_924_estado == null
		or _decision_924_opciones == null
	):
		return
	var caso_id := String(caso.get("id", ""))
	var definicion := DecisionIdeologicaExpediente.definicion(caso_id)
	_decision_924_bloque.visible = not definicion.is_empty()
	_limpiar_opciones_decision_924()
	if definicion.is_empty():
		return

	var registrada := DecisionIdeologicaExpediente.opcion_registrada(partida.estado, caso_id)
	if not registrada.is_empty():
		_decision_924_estado.text = (
			tr("VISOR_DECISION_924_REGISTRADA") % _texto_opcion_decision_924(registrada)
		)
		return

	if not DecisionIdeologicaExpediente.disponible(partida.estado, caso_id):
		_decision_924_estado.text = tr("VISOR_DECISION_924_BLOQUEADA")
		return

	_decision_924_estado.text = tr("VISOR_DECISION_924_AYUDA")
	for opcion in DecisionIdeologicaExpediente.opciones(caso_id):
		var opcion_id := String(opcion.get("id", ""))
		if opcion_id.is_empty():
			continue
		var boton := Button.new()
		boton.text = _texto_opcion_decision_924(opcion_id)
		boton.pressed.connect(_resolver_decision_924.bind(opcion_id))
		_decision_924_opciones.add_child(boton)


func _limpiar_opciones_decision_924() -> void:
	for hijo in _decision_924_opciones.get_children():
		_decision_924_opciones.remove_child(hijo)
		hijo.queue_free()


func _resolver_decision_924(opcion_id: String) -> void:
	if _hay_guardado_a_medias():
		return
	var caso_id := String(caso.get("id", ""))
	var resultado := DecisionIdeologicaExpediente.resolver(partida.estado, caso_id, opcion_id)
	if String(resultado.get("resultado", "")) == "registrada":
		Sonido.sonar(self, "pulsar")
		_guardar_o_avisar()
	_actualizar_decision_924()


func _texto_opcion_decision_924(opcion_id: String) -> String:
	var clave := String(TEXTO_DECISION_924.get(opcion_id, ""))
	return tr(clave) if not clave.is_empty() else opcion_id


func _nombre_tipo(tipo: String) -> String:
	for ficha in TIPOS:
		if ficha["id"] == tipo:
			return tr(String(ficha["texto"]))
	return tipo


func _texto_valor(valor) -> String:
	if typeof(valor) == TYPE_BOOL:
		return tr("VISOR_PRONOSTICO_SI") if valor else tr("VISOR_PRONOSTICO_NO")
	var texto := String(valor)
	for carta in partida.estado.get("tarot", []):
		if String(carta.get("id", "")) == texto:
			return String(carta.get("nombre", texto.capitalize()))
	return texto.capitalize()


func _nombre_estado(estado: String) -> String:
	match estado:
		Pronosticos.ESTADO_ABIERTO:
			return tr("VISOR_PRONOSTICO_ESTADO_ABIERTO")
		Pronosticos.ESTADO_ABANDONADO:
			return tr("VISOR_PRONOSTICO_ESTADO_ABANDONADO")
		Pronosticos.ESTADO_ACERTADO:
			return tr("VISOR_PRONOSTICO_ESTADO_ACERTADO")
		Pronosticos.ESTADO_FALLADO:
			return tr("VISOR_PRONOSTICO_ESTADO_FALLADO")
		_:
			return tr("VISOR_PRONOSTICO_ESTADO_SIN_RESOLVER")
