## Calculadora interna del escritorio OS98 (#538).
##
## Evalúa únicamente expresiones aritméticas con caracteres permitidos. No
## ejecuta comandos, funciones, rutas ni procesos del host.
class_name CalculadoraSiga
extends VBoxContainer

const CARACTERES_PERMITIDOS := "0123456789+-*/()., "

var _entrada: LineEdit
var _resultado: Label


func _ready() -> void:
	custom_minimum_size = Vector2(360, 220)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_construir_interfaz()
	_entrada.grab_focus()


func resolver(texto: String) -> String:
	var expresion := texto.strip_edges().replace(",", ".")
	if expresion.is_empty():
		return ""
	if not _entrada_permitida(expresion):
		return "Entrada no válida"

	var calculo := Expression.new()
	if calculo.parse(expresion, []) != OK:
		return "Expresión no válida"
	var valor: Variant = calculo.execute([], null, false)
	if calculo.has_execute_failed():
		return "No se pudo calcular"
	if not (valor is int or valor is float):
		return "Resultado no numérico"
	return str(valor)


func _construir_interfaz() -> void:
	var cabecera := Label.new()
	cabecera.text = "Calculadora"
	add_child(cabecera)

	var ayuda := Label.new()
	ayuda.text = "Operaciones disponibles: +, -, *, / y paréntesis. Pulse Intro para calcular."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(ayuda)

	_entrada = LineEdit.new()
	_entrada.name = "Entrada"
	_entrada.placeholder_text = "Ej.: (1250 + 340) / 2"
	_entrada.text_submitted.connect(_al_enviar)
	add_child(_entrada)

	var acciones := HBoxContainer.new()
	acciones.name = "Acciones"
	add_child(acciones)

	var calcular := Button.new()
	calcular.name = "Calcular"
	calcular.text = "Calcular"
	calcular.pressed.connect(_calcular)
	acciones.add_child(calcular)

	var borrar := Button.new()
	borrar.name = "Borrar"
	borrar.text = "Borrar"
	borrar.pressed.connect(_borrar)
	acciones.add_child(borrar)

	_resultado = Label.new()
	_resultado.name = "Resultado"
	_resultado.text = "Resultado:"
	_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_resultado)


func _al_enviar(_texto: String) -> void:
	_calcular()


func _calcular() -> void:
	var valor := resolver(_entrada.text)
	_resultado.text = "Resultado: %s" % valor


func _borrar() -> void:
	_entrada.clear()
	_resultado.text = "Resultado:"
	_entrada.grab_focus()


func _entrada_permitida(expresion: String) -> bool:
	for indice in range(expresion.length()):
		if not CARACTERES_PERMITIDOS.contains(expresion.substr(indice, 1)):
			return false
	return true
