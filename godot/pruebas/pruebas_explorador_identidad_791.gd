## Regresión visual mínima de identidad del Explorador OS98 (#791).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var explorador := ExploradorSiga.new()
	root.add_child(explorador)
	await process_frame

	var atras := explorador.find_child("Atras", true, false) as Button
	var ruta := explorador.find_child("Ruta", true, false) as LineEdit
	var medio := explorador.find_child("Medio", true, false) as OptionButton
	var entradas := explorador.find_child("Entradas", true, false) as ItemList
	var visor := explorador.find_child("VisorDocumento", true, false) as RichTextLabel
	var estado := explorador.find_child("Estado", true, false) as Label

	_comprobar(atras != null, "crea la barra de navegación")
	_comprobar(ruta != null, "crea el campo de ruta")
	_comprobar(medio != null, "crea el selector de medios")
	_comprobar(entradas != null, "crea la lista de entradas")
	_comprobar(visor != null, "crea el visor documental")
	_comprobar(estado != null, "crea la barra de estado")

	_comprobar(
		_fondo(atras, "normal").is_equal_approx(Color("#d9dee4")),
		"la toolbar usa su superficie fría propia",
	)
	_comprobar(
		_fondo(ruta, "normal").is_equal_approx(Color("#f8fbfc")),
		"la ruta se lee como campo editable separado",
	)
	_comprobar(
		_fondo(medio, "normal").is_equal_approx(Color("#d9dee4")),
		"los medios extraíbles comparten lenguaje de toolbar",
	)
	_comprobar(
		_fondo(entradas, "panel").is_equal_approx(Color("#eef4f7")),
		"la lista de archivos tiene fondo de explorador propio",
	)
	_comprobar(
		_fondo(visor, "normal").is_equal_approx(Color("#fffaf0")),
		"el documento abierto se separa visualmente como papel",
	)
	_comprobar(
		estado.get_theme_color("font_color").is_equal_approx(Color("#4e5c66")),
		"el estado queda jerárquicamente secundario",
	)
	_comprobar(
		ruta.get_theme_stylebox("focus") is StyleBoxFlat,
		"el campo de ruta conserva foco visible",
	)
	_comprobar(
		entradas.get_theme_stylebox("focus") is StyleBoxFlat,
		"la lista conserva foco visible para teclado y mando",
	)

	explorador.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _fondo(control: Control, nombre: String) -> Color:
	var caja := control.get_theme_stylebox(nombre)
	if caja is StyleBoxFlat:
		return (caja as StyleBoxFlat).bg_color
	return Color.TRANSPARENT


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
