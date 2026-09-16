## Ficha de creación del protagonista.
##
## No es un editor escultórico: ofrece diferencias grandes y legibles a baja
## resolución, coherentes con el estilo PSX, y mantiene separado el pasado del
## aspecto físico.
extends Control

const PIELES := [
	["Claro", "#e7c3a4"],
	["Medio claro", "#c9916b"],
	["Medio", "#a96f50"],
	["Oliva", "#9a7655"],
	["Oscuro", "#6f4936"],
	["Muy oscuro", "#452f26"],
]
const CABELLOS := [
	["Negro", "#1f1b19"],
	["Castaño oscuro", "#30251f"],
	["Castaño", "#5b4030"],
	["Rubio oscuro", "#8b7754"],
	["Canoso", "#77736f"],
]
const ROPAS := [
	["Gris oficina", "#59616b"],
	["Azul gastado", "#45566e"],
	["Marrón", "#665044"],
	["Verde apagado", "#4f5f52"],
	["Burdeos", "#69454c"],
]

var _perfil: Dictionary
var _cuerpo: OptionButton
var _altura: HSlider
var _hombros: HSlider
var _cintura: HSlider
var _piel: OptionButton
var _cabello: OptionButton
var _peinado: OptionButton
var _prenda: OptionButton
var _ropa: OptionButton
var _trasfondo: OptionButton
var _descripcion: Label
var _resumen: Label
var _estado: Label


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = EstiloSiga.tema()
	_perfil = PerfilJugador.cargar()
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
	titulo.text = "EXPEDIENTE PERSONAL · ALTA DE EMPLEADO"
	titulo.add_theme_font_size_override("font_size", 20)
	raiz.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "La apariencia no modifica colisiones ni estadísticas. El trasfondo describe tu vida anterior a SIGA."
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(subtitulo)

	var columnas := HBoxContainer.new()
	columnas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.add_theme_constant_override("separation", 24)
	raiz.add_child(columnas)

	var aspecto := VBoxContainer.new()
	aspecto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspecto.add_theme_constant_override("separation", 8)
	columnas.add_child(aspecto)
	_cabecera(aspecto, "APARIENCIA")

	_cuerpo = _opcion(
		aspecto, "Complexión", [["Delgado", "delgado"], ["Medio", "medio"], ["Robusto", "robusto"]]
	)
	_altura = _deslizador(aspecto, "Altura visual", 0.92, 1.08)
	_hombros = _deslizador(aspecto, "Hombros", 0.88, 1.12)
	_cintura = _deslizador(aspecto, "Cintura", 0.88, 1.12)
	_piel = _opcion(aspecto, "Tono de piel", PIELES)
	_cabello = _opcion(aspecto, "Color de pelo", CABELLOS)
	_peinado = _opcion(
		aspecto,
		"Peinado",
		[["Corto", "corto"], ["Medio", "medio"], ["Rapado", "rapado"], ["Recogido", "recogido"]]
	)
	_prenda = _opcion(
		aspecto, "Prenda", [["Camisa", "camisa"], ["Jersey", "jersey"], ["Chaqueta", "chaqueta"]]
	)
	_ropa = _opcion(aspecto, "Color de ropa", ROPAS)

	var pasado := VBoxContainer.new()
	pasado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pasado.add_theme_constant_override("separation", 8)
	columnas.add_child(pasado)
	_cabecera(pasado, "TRASFONDO")

	var etiqueta := Label.new()
	etiqueta.text = "Antes de SIGA"
	pasado.add_child(etiqueta)
	_trasfondo = OptionButton.new()
	_trasfondo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entrada in PerfilJugador.TRASFONDOS:
		_trasfondo.add_item(String(entrada["nombre"]))
		_trasfondo.set_item_metadata(_trasfondo.item_count - 1, entrada["id"])
	_trasfondo.item_selected.connect(func(_indice): _refrescar())
	pasado.add_child(_trasfondo)

	_descripcion = Label.new()
	_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_descripcion.custom_minimum_size.y = 110
	pasado.add_child(_descripcion)

	var nota := Label.new()
	nota.text = "El trasfondo podrá matizar diálogos, recuerdos, objetos y sueños; no concede una solución automática de expediente."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pasado.add_child(nota)

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
	volver.text = "Cancelar"
	volver.pressed.connect(_volver)
	botones.add_child(volver)
	var guardar := Button.new()
	guardar.text = "Guardar ficha"
	guardar.pressed.connect(_guardar)
	botones.add_child(guardar)


func _cabecera(caja: VBoxContainer, texto: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", 16)
	caja.add_child(etiqueta)
	caja.add_child(HSeparator.new())


func _opcion(caja: VBoxContainer, texto: String, opciones: Array) -> OptionButton:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.custom_minimum_size.x = 125
	fila.add_child(etiqueta)
	var control := OptionButton.new()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for opcion in opciones:
		control.add_item(String(opcion[0]))
		control.set_item_metadata(control.item_count - 1, opcion[1])
	control.item_selected.connect(func(_indice): _refrescar())
	fila.add_child(control)
	return control


func _deslizador(caja: VBoxContainer, texto: String, minimo: float, maximo: float) -> HSlider:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	var etiqueta := Label.new()
	etiqueta.text = texto
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
	var pasado := PerfilJugador.trasfondo_por_id(String(candidato["trasfondo"]))
	_descripcion.text = String(pasado.get("descripcion", ""))
	var etiquetas := Array(pasado.get("etiquetas", []))
	_resumen.text = (
		"Etiquetas narrativas: %s\nComplexión: %s · altura %.2f · hombros %.2f · cintura %.2f"
		% [
			", ".join(etiquetas),
			String(candidato["apariencia"]["cuerpo"]),
			float(candidato["apariencia"]["altura"]),
			float(candidato["apariencia"]["hombros"]),
			float(candidato["apariencia"]["cintura"]),
		]
	)


func _guardar() -> void:
	_perfil = _desde_controles()
	if PerfilJugador.guardar(_perfil):
		_estado.text = "Ficha guardada."
	else:
		_estado.text = "No se pudo guardar la ficha."


func _volver() -> void:
	get_tree().change_scene_to_file("res://escenas/inicio.tscn")
