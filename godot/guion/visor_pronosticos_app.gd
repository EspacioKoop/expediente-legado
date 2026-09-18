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
]

var _pronostico_tipo: OptionButton
var _pronostico_valor: OptionButton
var _pronostico_confirmar: Button
var _pronostico_abandonar: Button
var _pronostico_estado: Label


func _ready() -> void:
	super._ready()
	_actualizar_pronostico()


func _columna_indice() -> Control:
	var columna: Control = super._columna_indice()
	columna.add_child(HSeparator.new())

	var titulo := Label.new()
	titulo.text = tr("VISOR_PRONOSTICO_TITULO")
	columna.add_child(titulo)

	_pronostico_estado = Label.new()
	_pronostico_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_pronostico_estado)

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
	columna.add_child(opciones)

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
	columna.add_child(acciones)

	_rellenar_valores_pronostico()
	return columna


func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_actualizar_pronostico()


func _al_elegir_documento(indice: int) -> void:
	super._al_elegir_documento(indice)
	_actualizar_pronostico()


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


func _nombre_tipo(tipo: String) -> String:
	for ficha in TIPOS:
		if ficha["id"] == tipo:
			return tr(String(ficha["texto"]))
	return tipo


func _texto_valor(valor) -> String:
	if typeof(valor) == TYPE_BOOL:
		return tr("VISOR_PRONOSTICO_SI") if valor else tr("VISOR_PRONOSTICO_NO")
	return String(valor).capitalize()


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
