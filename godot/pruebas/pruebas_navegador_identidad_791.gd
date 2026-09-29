## Regresión visual mínima de identidad del Navegador Web98 (#791).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var navegador := NavegadorSiga.new()
	navegador.configurar_contexto({"dia": 1, "conocimiento": [], "urls_caidas": []})
	root.add_child(navegador)
	await process_frame

	var atras := navegador.find_child("Atras", true, false) as Button
	var direccion := navegador.find_child("Direccion", true, false) as LineEdit
	var busqueda := navegador.find_child("Busqueda", true, false) as LineEdit
	var pagina := navegador.find_child("Pagina", true, false) as RichTextLabel
	var enlaces := navegador.find_child("Enlaces", true, false) as ItemList
	var historial := navegador.find_child("Historial", true, false) as ItemList
	var favoritos := navegador.find_child("Favoritos", true, false) as ItemList

	_comprobar(atras != null, "crea controles de navegación identificables")
	_comprobar(direccion != null, "crea el campo de dirección")
	_comprobar(busqueda != null, "crea la búsqueda Web98")
	_comprobar(pagina != null, "crea la superficie de página")
	_comprobar(enlaces != null, "crea la lista de enlaces")
	_comprobar(historial != null, "crea el lateral de historial")
	_comprobar(favoritos != null, "crea el lateral de favoritos")

	_comprobar(
		_fondo(atras, "normal").is_equal_approx(NavegadorSiga.FONDO_CROMO),
		"la toolbar usa cromo Web98 propio",
	)
	_comprobar(
		_fondo(direccion, "normal").is_equal_approx(NavegadorSiga.FONDO_DIRECCION),
		"la dirección se separa como campo marfil",
	)
	_comprobar(
		_fondo(busqueda, "normal").is_equal_approx(NavegadorSiga.FONDO_DIRECCION),
		"la búsqueda comparte el lenguaje de entrada del navegador",
	)
	_comprobar(
		_fondo(pagina, "normal").is_equal_approx(NavegadorSiga.FONDO_PAGINA),
		"la página tiene superficie de lectura propia",
	)
	_comprobar(
		_fondo(enlaces, "panel").is_equal_approx(NavegadorSiga.FONDO_PAGINA),
		"los enlaces permanecen ligados a la página",
	)
	_comprobar(
		_fondo(historial, "panel").is_equal_approx(NavegadorSiga.FONDO_LATERAL),
		"historial usa un lateral frío diferenciado",
	)
	_comprobar(
		_fondo(favoritos, "panel").is_equal_approx(NavegadorSiga.FONDO_LATERAL),
		"favoritos comparte la identidad lateral",
	)
	_comprobar(
		direccion.get_theme_stylebox("focus") is StyleBoxFlat, "dirección conserva foco visible"
	)
	_comprobar(
		enlaces.get_theme_stylebox("focus") is StyleBoxFlat, "enlaces conservan foco visible"
	)
	_comprobar(
		navegador.url_actual() == NavegadorSiga.URL_INICIO,
		"la identidad visual no cambia la navegación inicial",
	)

	navegador.queue_free()
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
