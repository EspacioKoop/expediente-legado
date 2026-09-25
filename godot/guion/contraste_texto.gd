## Regla de todo el juego: ningún texto oscuro sobre fondo gris, y ningún texto
## por debajo de WCAG AA contra lo que tiene detrás.
##
## Nació de dos pantallas —el menú general y el creador de personaje— que
## heredaban el `Label` negro del tema OS98 sin darse un fondo, y quedaban en
## negro sobre el gris de serie de Godot. Ninguna prueba lo veía porque las de
## contraste comprobaban PAREJAS del tema, no lo que de verdad había detrás de
## cada texto. Este módulo mira la pantalla montada: para cada control con texto
## busca su fondo real —su propia caja, la de sus antepasados, un `ColorRect`, o
## lo que un control pintado a mano declare con `declarar_fondo`— y, si no hay
## ninguno, el color con que Godot limpia la ventana, que es justo el gris que se
## colaba.
##
## Lógica pura sobre el árbol de nodos: no pinta ni necesita GPU, así que corre
## en la suite headless igual que en una captura.
class_name ContrasteTexto
extends RefCounted

const MIN_AA := 4.5
## Un control deshabilitado no está obligado a AA, pero tiene que leerse.
const MIN_DESHABILITADO := 3.0
## Por debajo de esta luminancia relativa un texto cuenta como oscuro.
const TEXTO_OSCURO := 0.18
## Gris: casi sin croma y ni casi blanco ni casi negro. El papel del OS98 tiene
## croma cálida a propósito y queda fuera; un `#c0c0c0` o el `#4d4d4d` de serie,
## dentro.
const CROMA_GRIS := 0.05
const LUMINANCIA_GRIS_MIN := 0.03
const LUMINANCIA_GRIS_MAX := 0.85
const ALFA_OPACO := 0.5
const META_FONDO := &"contraste_fondo"


## Para controles que pintan su fondo en `_draw` (el bisel del OS98): sin esto
## la regla no puede saber qué hay detrás de sus textos.
static func declarar_fondo(control: Control, color: Color) -> void:
	control.set_meta(META_FONDO, color)


static func luminancia(color: Color) -> float:
	return 0.2126 * _lineal(color.r) + 0.7152 * _lineal(color.g) + 0.0722 * _lineal(color.b)


static func contraste(a: Color, b: Color) -> float:
	var la := luminancia(a)
	var lb := luminancia(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func es_gris(color: Color) -> bool:
	var croma := maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b))
	var lum := luminancia(color)
	return croma < CROMA_GRIS and lum > LUMINANCIA_GRIS_MIN and lum < LUMINANCIA_GRIS_MAX


static func es_oscuro(color: Color) -> bool:
	return luminancia(color) < TEXTO_OSCURO


## Cada infracción de [param raiz] y sus descendientes visibles, como
## `{ruta, texto, frente, fondo, ratio, motivo}`. Vacío si todo se lee.
static func auditar(raiz: Node, fondo_ventana: Color = Color(0.3, 0.3, 0.3)) -> Array:
	var fallos := []
	var pendientes: Array = [raiz]
	while not pendientes.is_empty():
		var nodo: Node = pendientes.pop_back()
		if nodo is CanvasItem and not (nodo as CanvasItem).is_visible_in_tree():
			continue
		if nodo is Control:
			var fallo := revisar(nodo, fondo_ventana)
			if not fallo.is_empty():
				fallos.append(fallo)
		for hijo in nodo.get_children():
			pendientes.append(hijo)
	return fallos


## La infracción de un solo control, o vacío.
static func revisar(control: Control, fondo_ventana: Color) -> Dictionary:
	var texto := _texto_visible(control)
	if texto.is_empty():
		return {}
	var frente := color_texto(control)
	var fondo := fondo_de(control, fondo_ventana)
	var ratio := contraste(frente, fondo)
	var deshabilitado := control is BaseButton and (control as BaseButton).disabled
	var minimo := MIN_DESHABILITADO if deshabilitado else MIN_AA
	var motivo := ""
	if es_oscuro(frente) and es_gris(fondo):
		motivo = "texto oscuro sobre gris"
	elif ratio < minimo:
		motivo = "contraste %.2f:1 < %.1f:1" % [ratio, minimo]
	if motivo.is_empty():
		return {}
	return {
		"ruta": String(control.get_path()),
		"texto": texto.left(40),
		"frente": frente.to_html(false),
		"fondo": fondo.to_html(false),
		"ratio": ratio,
		"motivo": motivo,
	}


static func color_texto(control: Control) -> Color:
	if control is BaseButton:
		var boton := control as BaseButton
		if boton.disabled:
			return control.get_theme_color("font_disabled_color")
		return control.get_theme_color("font_color")
	if control is RichTextLabel:
		return control.get_theme_color("default_color")
	return control.get_theme_color("font_color")


## Lo que hay detrás del texto de [param control]: su caja propia si la pinta
## opaca, y si no la del antepasado más cercano que sí.
static func fondo_de(control: Control, fondo_ventana: Color) -> Color:
	var propio = _fondo_propio(control)
	if propio != null:
		return propio
	var nodo := control.get_parent()
	while nodo != null:
		if nodo is Control:
			var suyo = _fondo_contenedor(nodo as Control)
			if suyo != null:
				return suyo
		elif nodo is Window and nodo != control.get_tree().root:
			var panel = _caja_opaca((nodo as Window).get_theme_stylebox("panel"))
			if panel != null:
				return panel
		nodo = nodo.get_parent()
	return fondo_ventana


static func _texto_visible(control: Control) -> String:
	var texto := ""
	if control is Label:
		texto = (control as Label).text
	elif control is Button:
		texto = (control as Button).text
	elif control is LineEdit:
		var campo := control as LineEdit
		texto = campo.text if not campo.text.is_empty() else campo.placeholder_text
	elif control is RichTextLabel:
		texto = (control as RichTextLabel).get_parsed_text()
	return texto.strip_edges()


## La caja con que un control con texto se pinta a sí mismo.
static func _fondo_propio(control: Control) -> Variant:
	if control.has_meta(META_FONDO):
		return control.get_meta(META_FONDO)
	var estilo := ""
	if control is Button and (control as Button).flat:
		return null
	if control is BaseButton:
		estilo = "disabled" if (control as BaseButton).disabled else "normal"
	elif control is LineEdit:
		estilo = "read_only" if not (control as LineEdit).editable else "normal"
	elif control is RichTextLabel or control is Label:
		estilo = "normal"
	if estilo.is_empty() or not control.has_theme_stylebox(estilo):
		return null
	return _caja_opaca(control.get_theme_stylebox(estilo))


static func _fondo_contenedor(control: Control) -> Variant:
	if control.has_meta(META_FONDO):
		return control.get_meta(META_FONDO)
	if control is ColorRect:
		var color := (control as ColorRect).color
		return color if color.a >= ALFA_OPACO else null
	if control is PanelContainer or control is Panel:
		return _caja_opaca(control.get_theme_stylebox("panel"))
	if control is ItemList or control is Tree:
		return _caja_opaca(control.get_theme_stylebox("panel"))
	if control is TextEdit or control is LineEdit or control is BaseButton:
		return _fondo_propio(control)
	return null


static func _caja_opaca(estilo: StyleBox) -> Variant:
	if estilo is StyleBoxFlat:
		var plano := estilo as StyleBoxFlat
		if plano.draw_center and plano.bg_color.a >= ALFA_OPACO:
			return Color(plano.bg_color, 1.0)
	return null


static func _lineal(canal: float) -> float:
	if canal <= 0.04045:
		return canal / 12.92
	return pow((canal + 0.055) / 1.055, 2.4)
