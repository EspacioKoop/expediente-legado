## Ficha de creación del protagonista.
##
## No es un editor escultórico: ofrece diferencias grandes y legibles a baja
## resolución, coherentes con el estilo PSX, y mantiene separado el pasado del
## aspecto físico. La previsualización 3D consume el mismo perfil que se guarda,
## de modo que los controles nunca describen una silueta distinta a la jugable.
extends Control

## Cada opción es [clave de textos.csv, valor guardado en el perfil].
const CUERPOS := [
	["PERSONAJE_CUERPO_DELGADO", "delgado"],
	["PERSONAJE_CUERPO_MEDIO", "medio"],
	["PERSONAJE_CUERPO_ROBUSTO", "robusto"],
]
const PIELES := [
	["PERSONAJE_PIEL_CLARO", "#e7c3a4"],
	["PERSONAJE_PIEL_MEDIO_CLARO", "#c9916b"],
	["PERSONAJE_PIEL_MEDIO", "#a96f50"],
	["PERSONAJE_PIEL_OLIVA", "#9a7655"],
	["PERSONAJE_PIEL_OSCURO", "#6f4936"],
	["PERSONAJE_PIEL_MUY_OSCURO", "#452f26"],
]
const CABELLOS := [
	["PERSONAJE_CABELLO_NEGRO", "#1f1b19"],
	["PERSONAJE_CABELLO_CASTANO_OSCURO", "#30251f"],
	["PERSONAJE_CABELLO_CASTANO", "#5b4030"],
	["PERSONAJE_CABELLO_RUBIO_OSCURO", "#8b7754"],
	["PERSONAJE_CABELLO_CANOSO", "#77736f"],
]
const PEINADOS := [
	["PERSONAJE_PEINADO_CORTO", "corto"],
	["PERSONAJE_PEINADO_MEDIO", "medio"],
	["PERSONAJE_PEINADO_RAPADO", "rapado"],
	["PERSONAJE_PEINADO_RECOGIDO", "recogido"],
]
const PRENDAS := [
	["PERSONAJE_PRENDA_CAMISA", "camisa"],
	["PERSONAJE_PRENDA_JERSEY", "jersey"],
	["PERSONAJE_PRENDA_CHAQUETA", "chaqueta"],
]
const ROPAS := [
	["PERSONAJE_ROPA_GRIS", "#59616b"],
	["PERSONAJE_ROPA_AZUL", "#45566e"],
	["PERSONAJE_ROPA_MARRON", "#665044"],
	["PERSONAJE_ROPA_VERDE", "#4f5f52"],
	["PERSONAJE_ROPA_BURDEOS", "#69454c"],
]

var _partida := Partida.new()
var _perfil: Dictionary
var _alta_pendiente := false
var _cuerpo: OptionButton
var _altura: HSlider
var _hombros: HSlider
var _cintura: HSlider
var _piel: OptionButton
var _cabello: OptionButton
var _peinado: OptionButton
var _prenda: OptionButton
var _ropa: OptionButton
var _previsualizacion: PrevisualizadorPersonaje3D
var _trasfondo: OptionButton
var _descripcion: Label
var _auditorias: AuditoriasSiga
var _resumen: Label
var _estado: Label


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = EstiloSiga.tema()
	_partida.cargar()
	_perfil = PerfilJugador.completar(_partida.estado.get("perfil_jugador", {}))
	_alta_pendiente = not PerfilJugador.esta_configurado(_perfil)
	if _alta_pendiente:
		var historial_auditoria := Auditorias.historial(_partida.estado)
		_partida.estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva([], historial_auditoria, false)
	_construir()
	_cargar_controles()
	_refrescar()


func _construir() -> void:
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 22)
	add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 12)
	margen.add_child(raiz)

	var titulo := Label.new()
	titulo.text = tr("PERSONAJE_TITULO")
	titulo.add_theme_font_size_override("font_size", 20)
	raiz.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = tr("PERSONAJE_SUBTITULO")
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(subtitulo)

	var columnas := HBoxContainer.new()
	columnas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.add_theme_constant_override("separation", 20)
	raiz.add_child(columnas)

	var aspecto := VBoxContainer.new()
	aspecto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspecto.add_theme_constant_override("separation", 8)
	columnas.add_child(aspecto)
	_cabecera(aspecto, "PERSONAJE_APARIENCIA")

	_cuerpo = _opcion(aspecto, "PERSONAJE_COMPLEXION", CUERPOS)
	_altura = _deslizador(aspecto, "PERSONAJE_ALTURA", 0.92, 1.08)
	_hombros = _deslizador(aspecto, "PERSONAJE_HOMBROS", 0.88, 1.12)
	_cintura = _deslizador(aspecto, "PERSONAJE_CINTURA", 0.88, 1.12)
	_piel = _opcion(aspecto, "PERSONAJE_PIEL", PIELES)
	_cabello = _opcion(aspecto, "PERSONAJE_CABELLO", CABELLOS)
	_peinado = _opcion(aspecto, "PERSONAJE_PEINADO", PEINADOS)
	_prenda = _opcion(aspecto, "PERSONAJE_PRENDA", PRENDAS)
	_ropa = _opcion(aspecto, "PERSONAJE_ROPA", ROPAS)

	var vista := VBoxContainer.new()
	vista.custom_minimum_size.x = 250.0
	vista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.add_child(vista)
	_previsualizacion = PrevisualizadorPersonaje3D.new()
	vista.add_child(_previsualizacion)

	var pasado := VBoxContainer.new()
	pasado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pasado.add_theme_constant_override("separation", 8)
	columnas.add_child(pasado)
	_cabecera(pasado, "PERSONAJE_TRASFONDO")

	var etiqueta := Label.new()
	etiqueta.text = tr("PERSONAJE_ANTES_DE_SIGA")
	pasado.add_child(etiqueta)
	_trasfondo = OptionButton.new()
	_trasfondo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entrada in PerfilJugador.TRASFONDOS:
		_trasfondo.add_item(tr(String(entrada["nombre"])))
		_trasfondo.set_item_metadata(_trasfondo.item_count - 1, entrada["id"])
	_trasfondo.item_selected.connect(func(_indice): _refrescar())
	pasado.add_child(_trasfondo)

	_descripcion = Label.new()
	_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_descripcion.custom_minimum_size.y = 110
	pasado.add_child(_descripcion)

	var nota := Label.new()
	nota.text = tr("PERSONAJE_NOTA_TRASFONDO")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pasado.add_child(nota)

	_auditorias = AuditoriasSiga.new()
	_auditorias.name = "AuditoriasIniciales"
	_auditorias.configurar_estado(_partida.estado, _alta_pendiente)
	pasado.add_child(_auditorias)

	_resumen = Label.new()
	_resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_resumen.custom_minimum_size.y = 54
	raiz.add_child(_resumen)

	_estado = Label.new()
	raiz.add_child(_estado)

	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_END
	botones.add_theme_constant_override("separation", 8)
	raiz.add_child(botones)
	var volver := Button.new()
	volver.text = tr("PERSONAJE_CANCELAR")
	volver.pressed.connect(_volver)
	botones.add_child(volver)
	var guardar := Button.new()
	guardar.text = tr("PERSONAJE_GUARDAR")
	guardar.pressed.connect(_guardar)
	botones.add_child(guardar)


func _cabecera(caja: VBoxContainer, clave: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = tr(clave)
	etiqueta.add_theme_font_size_override("font_size", 16)
	caja.add_child(etiqueta)
	caja.add_child(HSeparator.new())


func _opcion(caja: VBoxContainer, clave: String, opciones: Array) -> OptionButton:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	var etiqueta := Label.new()
	etiqueta.text = tr(clave)
	etiqueta.custom_minimum_size.x = 125
	fila.add_child(etiqueta)
	var control := OptionButton.new()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for opcion in opciones:
		control.add_item(tr(String(opcion[0])))
		control.set_item_metadata(control.item_count - 1, opcion[1])
	control.item_selected.connect(func(_indice): _refrescar())
	fila.add_child(control)
	return control


func _deslizador(caja: VBoxContainer, clave: String, minimo: float, maximo: float) -> HSlider:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	var etiqueta := Label.new()
	etiqueta.text = tr(clave)
	etiqueta.custom_minimum_size.x = 125
	fila.add_child(etiqueta)
	var control := HSlider.new()
	control.min_value = minimo
	control.max_value = maximo
	control.step = 0.01
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.value_changed.connect(func(_valor): _refrescar())
	fila.add_child(control)
	return control


func _cargar_controles() -> void:
	var apariencia: Dictionary = _perfil["apariencia"]
	_seleccionar(_cuerpo, apariencia["cuerpo"])
	_altura.value = float(apariencia["altura"])
	_hombros.value = float(apariencia["hombros"])
	_cintura.value = float(apariencia["cintura"])
	_seleccionar(_piel, apariencia["piel"])
	_seleccionar(_cabello, apariencia["cabello"])
	_seleccionar(_peinado, apariencia["peinado"])
	_seleccionar(_prenda, apariencia["prenda"])
	_seleccionar(_ropa, apariencia["ropa"])
	_seleccionar(_trasfondo, _perfil["trasfondo"])


func _seleccionar(control: OptionButton, valor) -> void:
	for i in range(control.item_count):
		if control.get_item_metadata(i) == valor:
			control.select(i)
			return


func _valor(control: OptionButton):
	if control.selected < 0:
		return null
	return control.get_item_metadata(control.selected)


func _desde_controles() -> Dictionary:
	return (
		PerfilJugador
		. completar(
			{
				"apariencia":
				{
					"cuerpo": _valor(_cuerpo),
					"altura": _altura.value,
					"hombros": _hombros.value,
					"cintura": _cintura.value,
					"piel": _valor(_piel),
					"cabello": _valor(_cabello),
					"peinado": _valor(_peinado),
					"prenda": _valor(_prenda),
					"ropa": _valor(_ropa),
				},
				"trasfondo": _valor(_trasfondo),
			}
		)
	)


func _refrescar() -> void:
	if _trasfondo == null:
		return
	var candidato := _desde_controles()
	if _previsualizacion != null:
		_previsualizacion.aplicar(candidato)
	var pasado := PerfilJugador.trasfondo_por_id(String(candidato["trasfondo"]))
	_descripcion.text = tr(String(pasado.get("descripcion", "")))
	var etiquetas := Array(pasado.get("etiquetas", []))
	_resumen.text = (
		tr("PERSONAJE_RESUMEN")
		% [
			", ".join(etiquetas),
			_cuerpo.get_item_text(maxi(_cuerpo.selected, 0)),
			float(candidato["apariencia"]["altura"]),
			float(candidato["apariencia"]["hombros"]),
			float(candidato["apariencia"]["cintura"]),
		]
	)


func _guardar() -> void:
	_perfil = _desde_controles()
	_perfil["configurado"] = true
	_partida.estado["perfil_jugador"] = _perfil
	var auditoria_previa: Dictionary = {}
	if _alta_pendiente and _auditorias != null:
		auditoria_previa = (
			Dictionary(_partida.estado.get(Auditorias.CLAVE_ESTADO, {})).duplicate(true)
		)
		if not Auditorias.resolver_seleccion(_partida.estado, _auditorias.seleccion()):
			_estado.text = tr("PERSONAJE_ERROR_GUARDAR")
			return
	if not _partida.guardar():
		if _alta_pendiente and not auditoria_previa.is_empty():
			_partida.estado[Auditorias.CLAVE_ESTADO] = auditoria_previa
		_estado.text = tr("PERSONAJE_ERROR_GUARDAR")
		return
	if _alta_pendiente:
		_alta_pendiente = false
		var error := get_tree().change_scene_to_file("res://escenas/dia.tscn")
		if error != OK:
			_estado.text = tr("PERSONAJE_ERROR_JORNADA")
		return
	_estado.text = tr("PERSONAJE_GUARDADA")


func _volver() -> void:
	get_tree().change_scene_to_file("res://escenas/inicio.tscn")
