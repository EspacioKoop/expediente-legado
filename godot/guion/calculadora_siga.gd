## Calculadora interna del escritorio OS98 (#538, #791).
##
## Evalúa únicamente expresiones aritméticas con caracteres permitidos. No
## ejecuta comandos, funciones, rutas ni procesos del host.
class_name CalculadoraSiga
extends VBoxContainer

const CARACTERES_PERMITIDOS := "0123456789+-*/()., "

var _entrada: LineEdit
var _resultado: Label


func _ready() -> void:
	custom_minimum_size = Vector2(360, 330)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	_construir_interfaz()
	_entrada.grab_focus()


func resolver(texto: String) -> String:
	var expresion := texto.strip_edges().replace(",", ".")
	if expresion.is_empty():
		return ""
	if not _entrada_permitida(expresion):
		return tr("CALCULADORA_ENTRADA_NO_VALIDA")

	var calculo := Expression.new()
	if calculo.parse(expresion, []) != OK:
		return tr("CALCULADORA_EXPRESION_NO_VALIDA")
	var valor: Variant = calculo.execute([], null, false)
	if calculo.has_execute_failed():
		return tr("CALCULADORA_NO_SE_PUDO")
	if not (valor is int or valor is float):
		return tr("CALCULADORA_NO_NUMERICO")
	return str(valor)


func _construir_interfaz() -> void:
	var cabecera := Label.new()
	cabecera.name = "Cabecera"
	cabecera.text = tr("CALCULADORA_TITULO")
	cabecera.add_theme_font_size_override("font_size", 20)
	cabecera.add_theme_color_override("font_color", Color("#25313a"))
	add_child(cabecera)

	var ayuda := Label.new()
	ayuda.name = "Ayuda"
	ayuda.text = tr("CALCULADORA_AYUDA")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.add_theme_color_override("font_color", Color("#5d625c"))
	add_child(ayuda)

	var pantalla := PanelContainer.new()
	pantalla.name = "Pantalla"
	pantalla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pantalla.add_theme_stylebox_override(
		"panel", _caja(Color("#17271d"), Color("#68766c"), 2, 3)
	)
	add_child(pantalla)

	var contenido_pantalla := VBoxContainer.new()
	contenido_pantalla.add_theme_constant_override("separation", 4)
	pantalla.add_child(contenido_pantalla)

	_entrada = LineEdit.new()
	_entrada.name = "Entrada"
	_entrada.placeholder_text = tr("CALCULADORA_PLACEHOLDER")
	_entrada.text_submitted.connect(_al_enviar)
	_entrada.add_theme_color_override("font_color", Color("#d7f4c8"))
	_entrada.add_theme_color_override("font_placeholder_color", Color("#8ca786"))
	_entrada.add_theme_color_override("caret_color", Color("#d7f4c8"))
	_entrada.add_theme_stylebox_override(
		"normal", _caja(Color("#17271d"), Color("#17271d"), 0, 0)
	)
	_entrada.add_theme_stylebox_override(
		"focus", _caja(Color("#17271d"), Color("#a6c89a"), 1, 2)
	)
	contenido_pantalla.add_child(_entrada)

	_resultado = Label.new()
	_resultado.name = "Resultado"
	_resultado.text = tr("CALCULADORA_RESULTADO_VACIO")
	_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_resultado.add_theme_font_size_override("font_size", 18)
	_resultado.add_theme_color_override("font_color", Color("#d7f4c8"))
	contenido_pantalla.add_child(_resultado)

	var teclado := GridContainer.new()
	teclado.name = "Teclado"
	teclado.columns = 4
	teclado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teclado.add_theme_constant_override("h_separation", 6)
	teclado.add_theme_constant_override("v_separation", 6)
	add_child(teclado)

	var teclas: Array[Dictionary] = [
		{"texto": "7", "accion": "valor"},
		{"texto": "8", "accion": "valor"},
		{"texto": "9", "accion": "valor"},
		{"texto": "/", "accion": "valor"},
		{"texto": "4", "accion": "valor"},
		{"texto": "5", "accion": "valor"},
		{"texto": "6", "accion": "valor"},
		{"texto": "*", "accion": "valor"},
		{"texto": "1", "accion": "valor"},
		{"texto": "2", "accion": "valor"},
		{"texto": "3", "accion": "valor"},
		{"texto": "-", "accion": "valor"},
		{"texto": "0", "accion": "valor"},
		{"texto": ".", "accion": "valor"},
		{"texto": "(", "accion": "valor"},
		{"texto": ")", "accion": "valor"},
		{"texto": "+", "accion": "valor"},
		{"texto": "←", "accion": "retroceso"},
		{"texto": "C", "accion": "borrar"},
		{"texto": "=", "accion": "calcular"},
	]
	for config in teclas:
		_crear_tecla(teclado, String(config["texto"]), String(config["accion"]))

	var acciones := HBoxContainer.new()
	acciones.name = "Acciones"
	acciones.add_theme_constant_override("separation", 8)
	add_child(acciones)

	var calcular := Button.new()
	calcular.name = "Calcular"
	calcular.text = tr("CALCULADORA_CALCULAR")
	calcular.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calcular.pressed.connect(_calcular)
	_estilizar_tecla(calcular, true)
	acciones.add_child(calcular)

	var borrar := Button.new()
	borrar.name = "Borrar"
	borrar.text = tr("CALCULADORA_BORRAR")
	borrar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	borrar.pressed.connect(_borrar)
	_estilizar_tecla(borrar, false)
	acciones.add_child(borrar)


func _crear_tecla(teclado: GridContainer, texto: String, accion: String) -> void:
	var tecla := Button.new()
	tecla.name = "Tecla_%02d" % teclado.get_child_count()
	tecla.text = texto
	tecla.custom_minimum_size = Vector2(0, 34)
	tecla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tecla.focus_mode = Control.FOCUS_ALL
	match accion:
		"valor":
			tecla.pressed.connect(_insertar_tecla.bind(texto))
		"retroceso":
			tecla.pressed.connect(_retroceso)
		"borrar":
			tecla.pressed.connect(_borrar)
		"calcular":
			tecla.pressed.connect(_calcular)
	_estilizar_tecla(tecla, texto in ["+", "-", "*", "/", "="])
	teclado.add_child(tecla)


func _estilizar_tecla(tecla: Button, operador: bool) -> void:
	var fondo := Color("#d7ddd0") if operador else Color("#eeece1")
	var fondo_hover := Color("#eef3e9") if operador else Color("#faf8ee")
	tecla.add_theme_color_override("font_color", Color("#20251f"))
	tecla.add_theme_color_override("font_focus_color", Color("#101510"))
	tecla.add_theme_stylebox_override("normal", _caja(fondo, Color("#676b61"), 1, 3))
	tecla.add_theme_stylebox_override("hover", _caja(fondo_hover, Color("#4e6754"), 1, 3))
	tecla.add_theme_stylebox_override("pressed", _caja(Color("#c5cbbf"), Color("#364a3b"), 2, 3))
	tecla.add_theme_stylebox_override("focus", _caja(fondo_hover, Color("#1f6b3f"), 2, 3))


func _caja(fondo: Color, borde: Color, ancho: int, radio: int) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.border_width_left = ancho
	caja.border_width_top = ancho
	caja.border_width_right = ancho
	caja.border_width_bottom = ancho
	caja.corner_radius_top_left = radio
	caja.corner_radius_top_right = radio
	caja.corner_radius_bottom_left = radio
	caja.corner_radius_bottom_right = radio
	caja.content_margin_left = 8.0
	caja.content_margin_top = 6.0
	caja.content_margin_right = 8.0
	caja.content_margin_bottom = 6.0
	return caja


func _insertar_tecla(valor: String) -> void:
	_entrada.text += valor
	_entrada.caret_column = _entrada.text.length()
	_entrada.grab_focus()


func _retroceso() -> void:
	if not _entrada.text.is_empty():
		_entrada.text = _entrada.text.left(_entrada.text.length() - 1)
	_entrada.caret_column = _entrada.text.length()
	_entrada.grab_focus()


func _al_enviar(_texto: String) -> void:
	_calcular()


func _calcular() -> void:
	var valor := resolver(_entrada.text)
	var texto_resultado := "%s %s" % [tr("CALCULADORA_RESULTADO_VACIO"), valor]
	_resultado.text = texto_resultado


func _borrar() -> void:
	_entrada.clear()
	_resultado.text = tr("CALCULADORA_RESULTADO_VACIO")
	_entrada.grab_focus()


func _entrada_permitida(expresion: String) -> bool:
	for indice in range(expresion.length()):
		if not CARACTERES_PERMITIDOS.contains(expresion.substr(indice, 1)):
			return false
	return true
