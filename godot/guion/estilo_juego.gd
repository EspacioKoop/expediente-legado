## El aspecto de los menús del JUEGO: el menú general y el creador de personaje.
##
## No son programas de SIGA-98, así que no visten el gris de sistema del OS98:
## son la capa del jugador por encima de la ficción, y se leen como tal. Fondo
## grafito, texto claro y un único acento ámbar para el foco y la acción
## principal. La tipografía es la misma que la del OS98 (Atkinson, títulos en
## Bold): cambia el papel en que se escribe, no la letra.
##
## La regla que este tema existe para cumplir es la de todo el juego: ningún
## texto oscuro sobre fondo gris. Aquí el texto oscuro solo aparece sobre el
## ámbar del botón principal, y `pruebas_contraste_pantallas.gd` lo vigila en las
## pantallas reales, no solo en esta tabla.
class_name EstiloJuego
extends RefCounted

const FONDO := Color("121418")  ## detrás de todo, a pantalla completa
const PANEL := Color("1c1f25")  ## tarjetas y paneles
const BORDE := Color("3a404b")
const BOTON := Color("2a2e36")
const BOTON_HOVER := Color("353a44")
const BOTON_PULSADO := Color("20232a")
const CAMPO := Color("0e1013")  ## huecos donde se escribe o se elige
const SELECCION := Color("3d4a66")
const TEXTO := Color("ece8dc")
const TEXTO_SECUNDARIO := Color("b8b2a5")
const TEXTO_DESHABILITADO := Color("a39d91")
const ACENTO := Color("e3b34f")  ## foco, títulos de sección y la acción principal
const PRIMARIO := Color("c9962e")
const PRIMARIO_HOVER := Color("dcaa3f")
const TEXTO_PRIMARIO := Color("15171b")  ## sobre ámbar, nunca sobre gris
const VELO := Color(0.03, 0.035, 0.045, 0.86)  ## lo que tapa la partida al pausar

const RADIO := 3
const GROSOR_FOCO := 2
const LADO_CASILLA := 22
const ANCHO_INTERRUPTOR := 44
const ALTO_INTERRUPTOR := 22


static func caja(fondo: Color, borde: Color = BORDE, margen: float = 10.0) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(RADIO)
	estilo.content_margin_left = margen
	estilo.content_margin_right = margen
	estilo.content_margin_top = margen * 0.6
	estilo.content_margin_bottom = margen * 0.6
	return estilo


## Tarjeta que agrupa una sección: el panel del menú o una columna del creador.
static func tarjeta() -> StyleBoxFlat:
	var estilo := caja(PANEL, BORDE, 20.0)
	estilo.content_margin_top = 18.0
	estilo.content_margin_bottom = 18.0
	return estilo


static func caja_foco() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.draw_center = false
	estilo.border_color = ACENTO
	estilo.set_border_width_all(GROSOR_FOCO)
	estilo.set_corner_radius_all(RADIO)
	estilo.expand_margin_left = 2.0
	estilo.expand_margin_right = 2.0
	estilo.expand_margin_top = 2.0
	estilo.expand_margin_bottom = 2.0
	return estilo


## Marca [param boton] como la acción principal de su pantalla: ámbar con texto
## oscuro. Una por pantalla; si todo es principal, nada lo es.
static func hacer_primario(boton: Button) -> void:
	boton.add_theme_stylebox_override("normal", caja(PRIMARIO, PRIMARIO))
	boton.add_theme_stylebox_override("hover", caja(PRIMARIO_HOVER, PRIMARIO_HOVER))
	boton.add_theme_stylebox_override("pressed", caja(PRIMARIO.darkened(0.15), PRIMARIO))
	boton.add_theme_stylebox_override("focus", caja_foco())
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		boton.add_theme_color_override(estado, TEXTO_PRIMARIO)


## Rótulo de sección: título en Bold y en el color del acento.
static func titulo_seccion(etiqueta: Label, tamano: int = 18) -> void:
	etiqueta.add_theme_font_override("font", EstiloSiga.fuente_titulo())
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", ACENTO)


static func secundario(etiqueta: Control) -> void:
	etiqueta.add_theme_color_override("font_color", TEXTO_SECUNDARIO)


static func tema() -> Theme:
	var tema := Theme.new()
	tema.default_font = EstiloSiga.fuente_interfaz()
	tema.default_font_size = 16
	tema.set_font("title_font", "Label", EstiloSiga.fuente_titulo())
	tema.set_font("title_font", "Window", EstiloSiga.fuente_titulo())
	_configurar_paneles(tema)
	_configurar_texto(tema)
	_configurar_botones(tema)
	_configurar_campos(tema)
	_configurar_listas(tema)
	_configurar_rangos(tema)
	_configurar_casillas(tema)
	return tema


static func _configurar_paneles(tema: Theme) -> void:
	tema.set_stylebox("panel", "PanelContainer", tarjeta())
	tema.set_stylebox("panel", "Panel", caja(PANEL))
	tema.set_stylebox("panel", "PopupMenu", caja(PANEL, BORDE, 6.0))
	tema.set_stylebox("panel", "TooltipPanel", caja(PANEL, BORDE, 8.0))
	tema.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var linea := StyleBoxLine.new()
	linea.color = BORDE
	linea.thickness = 1
	tema.set_stylebox("separator", "HSeparator", linea)
	tema.set_constant("separation", "HSeparator", 10)


static func _configurar_texto(tema: Theme) -> void:
	tema.set_color("font_color", "Label", TEXTO)
	tema.set_color("font_color", "TooltipLabel", TEXTO)
	tema.set_color("default_color", "RichTextLabel", TEXTO)
	tema.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	tema.set_stylebox("focus", "RichTextLabel", caja_foco())
	tema.set_color("font_selected_color", "RichTextLabel", TEXTO)
	tema.set_color("selection_color", "RichTextLabel", SELECCION)


static func _configurar_botones(tema: Theme) -> void:
	for tipo in ["Button", "OptionButton", "MenuButton", "CheckBox", "CheckButton"]:
		var plano: bool = tipo == "CheckBox" or tipo == "CheckButton"
		var normal: StyleBox = StyleBoxEmpty.new() if plano else caja(BOTON)
		tema.set_stylebox("normal", tipo, normal)
		tema.set_stylebox("hover", tipo, caja(BOTON_HOVER))
		tema.set_stylebox("hover_pressed", tipo, caja(BOTON_HOVER))
		tema.set_stylebox("pressed", tipo, normal if plano else caja(BOTON_PULSADO, ACENTO))
		tema.set_stylebox("disabled", tipo, normal if plano else caja(BOTON.darkened(0.2)))
		tema.set_stylebox("focus", tipo, caja_foco())
		tema.set_color("font_color", tipo, TEXTO)
		tema.set_color("font_hover_color", tipo, TEXTO)
		tema.set_color("font_hover_pressed_color", tipo, TEXTO)
		tema.set_color("font_pressed_color", tipo, TEXTO)
		tema.set_color("font_focus_color", tipo, TEXTO)
		tema.set_color("font_disabled_color", tipo, TEXTO_DESHABILITADO)
		tema.set_color("icon_normal_color", tipo, TEXTO)
		tema.set_color("icon_hover_color", tipo, TEXTO)
		tema.set_color("icon_focus_color", tipo, ACENTO)
		tema.set_constant("outline_size", tipo, 0)
	tema.set_constant("h_separation", "Button", 10)


static func _configurar_campos(tema: Theme) -> void:
	for tipo in ["LineEdit", "TextEdit"]:
		tema.set_stylebox("normal", tipo, caja(CAMPO))
		tema.set_stylebox("focus", tipo, caja_foco())
		tema.set_stylebox("read_only", tipo, caja(PANEL))
		tema.set_color("font_color", tipo, TEXTO)
		tema.set_color("font_selected_color", tipo, TEXTO)
		tema.set_color("font_placeholder_color", tipo, TEXTO_SECUNDARIO)
		tema.set_color("caret_color", tipo, ACENTO)
		tema.set_color("selection_color", tipo, SELECCION)
	tema.set_color("font_uneditable_color", "LineEdit", TEXTO_SECUNDARIO)
	tema.set_color("font_readonly_color", "TextEdit", TEXTO_SECUNDARIO)


static func _configurar_listas(tema: Theme) -> void:
	var seleccion := caja(SELECCION, ACENTO, 6.0)
	tema.set_stylebox("hover", "PopupMenu", caja(BOTON_HOVER, BOTON_HOVER, 6.0))
	tema.set_color("font_color", "PopupMenu", TEXTO)
	tema.set_color("font_hover_color", "PopupMenu", TEXTO)
	tema.set_color("font_disabled_color", "PopupMenu", TEXTO_DESHABILITADO)
	tema.set_color("font_separator_color", "PopupMenu", TEXTO_SECUNDARIO)
	tema.set_stylebox("panel", "ItemList", caja(CAMPO))
	tema.set_stylebox("focus", "ItemList", caja_foco())
	tema.set_stylebox("hovered", "ItemList", caja(BOTON_HOVER, BOTON_HOVER, 6.0))
	for estado in ["selected", "selected_focus", "hovered_selected", "hovered_selected_focus"]:
		tema.set_stylebox(estado, "ItemList", seleccion)
	for estado in [
		"font_color", "font_hovered_color", "font_selected_color", "font_hovered_selected_color"
	]:
		tema.set_color(estado, "ItemList", TEXTO)
	tema.set_color("font_disabled_color", "ItemList", TEXTO_DESHABILITADO)


## Deslizadores con carril visible sobre grafito: el de serie de Godot es gris
## oscuro y desaparece contra el panel.
static func _configurar_rangos(tema: Theme) -> void:
	var carril := caja(CAMPO, BORDE, 0.0)
	carril.content_margin_top = 3.0
	carril.content_margin_bottom = 3.0
	var lleno := caja(ACENTO.darkened(0.25), ACENTO.darkened(0.25), 0.0)
	lleno.content_margin_top = 3.0
	lleno.content_margin_bottom = 3.0
	for tipo in ["HSlider", "VSlider"]:
		tema.set_stylebox("slider", tipo, carril)
		tema.set_stylebox("grabber_area", tipo, lleno)
		tema.set_stylebox("grabber_area_highlight", tipo, lleno)
		tema.set_stylebox("focus", tipo, caja_foco())


## Casillas e interruptores dibujados aquí: los iconos de serie de Godot son gris
## oscuro sobre transparente y, sobre grafito, una casilla sin marcar no se veía.
## Se generan en código, sin binarios, y a un tamaño que se lee a 1080p.
static func _configurar_casillas(tema: Theme) -> void:
	var libre := _icono_casilla(false, false)
	var marcada := _icono_casilla(true, false)
	tema.set_icon("unchecked", "CheckBox", libre)
	tema.set_icon("checked", "CheckBox", marcada)
	tema.set_icon("unchecked_disabled", "CheckBox", _icono_casilla(false, true))
	tema.set_icon("checked_disabled", "CheckBox", _icono_casilla(true, true))
	tema.set_icon("radio_unchecked", "CheckBox", libre)
	tema.set_icon("radio_checked", "CheckBox", marcada)
	var apagado := _icono_interruptor(false, false)
	var encendido := _icono_interruptor(true, false)
	for sufijo in ["", "_mirrored"]:
		tema.set_icon("unchecked" + sufijo, "CheckButton", apagado)
		tema.set_icon("checked" + sufijo, "CheckButton", encendido)
		tema.set_icon("unchecked_disabled" + sufijo, "CheckButton", _icono_interruptor(false, true))
		tema.set_icon("checked_disabled" + sufijo, "CheckButton", _icono_interruptor(true, true))


static func _icono_casilla(marcada: bool, deshabilitada: bool) -> ImageTexture:
	var borde := TEXTO_DESHABILITADO if deshabilitada else TEXTO_SECUNDARIO
	var imagen := Image.create(LADO_CASILLA, LADO_CASILLA, false, Image.FORMAT_RGBA8)
	imagen.fill(Color.TRANSPARENT)
	imagen.fill_rect(Rect2i(0, 0, LADO_CASILLA, LADO_CASILLA), borde)
	var relleno := ACENTO if marcada and not deshabilitada else CAMPO
	if marcada and deshabilitada:
		relleno = BOTON
	imagen.fill_rect(Rect2i(2, 2, LADO_CASILLA - 4, LADO_CASILLA - 4), relleno)
	if marcada:
		var trazo := TEXTO_PRIMARIO if not deshabilitada else TEXTO_DESHABILITADO
		_trazar(imagen, Vector2i(5, 11), Vector2i(9, 15), trazo)
		_trazar(imagen, Vector2i(9, 15), Vector2i(16, 6), trazo)
	return ImageTexture.create_from_image(imagen)


static func _icono_interruptor(activo: bool, deshabilitado: bool) -> ImageTexture:
	var imagen := Image.create(ANCHO_INTERRUPTOR, ALTO_INTERRUPTOR, false, Image.FORMAT_RGBA8)
	imagen.fill(Color.TRANSPARENT)
	var borde := TEXTO_DESHABILITADO if deshabilitado else TEXTO_SECUNDARIO
	var carril := ACENTO.darkened(0.25) if activo and not deshabilitado else CAMPO
	imagen.fill_rect(Rect2i(0, 0, ANCHO_INTERRUPTOR, ALTO_INTERRUPTOR), borde)
	imagen.fill_rect(Rect2i(2, 2, ANCHO_INTERRUPTOR - 4, ALTO_INTERRUPTOR - 4), carril)
	var lado := ALTO_INTERRUPTOR - 8
	var x := ANCHO_INTERRUPTOR - lado - 4 if activo else 4
	var boton := TEXTO if not deshabilitado else TEXTO_DESHABILITADO
	imagen.fill_rect(Rect2i(x, 4, lado, lado), boton)
	return ImageTexture.create_from_image(imagen)


## Segmento de dos píxeles de grosor, para la marca de la casilla.
static func _trazar(imagen: Image, desde: Vector2i, hasta: Vector2i, color: Color) -> void:
	var pasos := maxi(absi(hasta.x - desde.x), absi(hasta.y - desde.y))
	for i in pasos + 1:
		var punto := Vector2(desde).lerp(Vector2(hasta), float(i) / float(maxi(pasos, 1)))
		var p := Vector2i(roundi(punto.x), roundi(punto.y))
		for dx in 2:
			for dy in 2:
				var q := p + Vector2i(dx, dy)
				if q.x >= 0 and q.y >= 0 and q.x < imagen.get_width() and q.y < imagen.get_height():
					imagen.set_pixel(q.x, q.y, color)
