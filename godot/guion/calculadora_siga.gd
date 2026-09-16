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
	cabecera.text = tr("CALCULADORA_TITULO")
	add_child(cabecera)

	var ayuda := Label.new()
	ayuda.text = tr("CALCULADORA_AYUDA")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(ayuda)

	_entrada = LineEdit.new()
	_entrada.name = "Entrada"
	_entrada.placeholder_text = tr("CALCULADORA_PLACEHOLDER")
	_entrada.text_submitted.connect(_al_enviar)
	add_child(_entrada)

	var acciones := HBoxContainer.new()
	acciones.name = "Acciones"
	add_child(acciones)

	var calcular := Button.new()
	calcular.name = "Calcular"
	calcular.text = tr("CALCULADORA_CALCULAR")
	calcular.pressed.connect(_calcular)
	acciones.add_child(calcular)

	var borrar := Button.new()
	borrar.name = "Borrar"
	borrar.text = tr("CALCULADORA_BORRAR")
	borrar.pressed.connect(_borrar)
	acciones.add_child(borrar)

	_resultado = Label.new()
	_resultado.name = "Resultado"
	_resultado.text = tr("CALCULADORA_RESULTADO_VACIO")
	_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_resultado)


func _al_enviar(_texto: String) -> void:
	_calcular()


func _calcular() -> void:
	var valor := resolver(_entrada.text)
	_resultado.text = tr("CALCULADORA_RESULTADO") % valor


func _borrar() -> void:
	_entrada.clear()
	_resultado.text = tr("CALCULADORA_RESULTADO_VACIO")
	_entrada.grab_focus()


func _entrada_permitida(expresion: String) -> bool:
	for indice in range(expresion.length()):
		if not CARACTERES_PERMITIDOS.contains(expresion.substr(indice, 1)):
			return false
	return true
