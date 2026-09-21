## Regresión headless del contrato de contraste OS98 (#792).
extends SceneTree

const MIN_AA := 4.5

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var tema := EstiloSiga.tema()

	_comprobar_par("label/gris", tema.get_color("font_color", "Label"), EstiloSiga.GRIS)
	_comprobar_par(
		"richtext/blanco", tema.get_color("default_color", "RichTextLabel"), EstiloSiga.BLANCO
	)
	_comprobar_par("itemlist/blanco", tema.get_color("font_color", "ItemList"), EstiloSiga.BLANCO)
	_comprobar_par(
		"itemlist seleccionado/azul",
		tema.get_color("font_selected_color", "ItemList"),
		EstiloSiga.AZUL_TITULO
	)
	_comprobar_par(
		"placeholder/blanco",
		tema.get_color("font_placeholder_color", "LineEdit"),
		EstiloSiga.BLANCO
	)
	_comprobar_par(
		"readonly/gris claro", tema.get_color("font_readonly_color", "TextEdit"), Color("e8e8e8")
	)
	_comprobar_par(
		"boton deshabilitado", tema.get_color("font_disabled_color", "Button"), Color("d0d0d0")
	)

	_comprobar(
		tema.get_stylebox("panel", "ItemList") != null,
		"ItemList conserva un fondo explícito en el tema común",
	)
	_comprobar(
		tema.get_stylebox("normal", "RichTextLabel") != null,
		"RichTextLabel conserva un fondo explícito en el tema común",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar_par(nombre: String, frente: Color, fondo: Color) -> void:
	var ratio := _contraste(frente, fondo)
	_comprobar(
		ratio >= MIN_AA,
		"%s queda en %.2f:1; mínimo %.1f:1" % [nombre, ratio, MIN_AA],
	)


func _contraste(a: Color, b: Color) -> float:
	var la := _luminancia(a)
	var lb := _luminancia(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _luminancia(color: Color) -> float:
	return (
		0.2126 * _canal_lineal(color.r)
		+ 0.7152 * _canal_lineal(color.g)
		+ 0.0722 * _canal_lineal(color.b)
	)


func _canal_lineal(canal: float) -> float:
	if canal <= 0.04045:
		return canal / 12.92
	return pow((canal + 0.055) / 1.055, 2.4)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
