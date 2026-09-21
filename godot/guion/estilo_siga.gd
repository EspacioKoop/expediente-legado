## El aspecto de SIGA-98: un programa de escritorio de finales de los 90.
##
## Port de `legacy-theme.css`, donde el relieve eran `border-style: outset` e
## `inset`. Aquí se dibuja, porque un StyleBoxFlat solo admite UN color de
## borde y este bisel necesita dos: la luz arriba y a la izquierda, la sombra
## abajo y a la derecha. Invertir esos dos colores es toda la diferencia entre
## un botón que sobresale y un hueco donde va texto — el mismo vocabulario de
## relieve que usa la piel de los muros de la nave en el otro proyecto.
class_name EstiloSiga
extends RefCounted

const GRIS := Color("c0c0c0")  ## el gris de sistema de la época
const GRIS_CLARO := Color("dfdfdf")  ## la luz del bisel
const GRIS_OSCURO := Color("808080")  ## su sombra
const NEGRO := Color("000000")
const BLANCO := Color("ffffff")
const AZUL_TITULO := Color("000080")  ## la barra de título activa
const AZUL_ENLACE := Color("0000aa")
const AMARILLO_VISTO := Color("c8c800")  ## una frase gatillo ya leída
const GRIS_TEXTO := Color("595959")  ## texto secundario AA sobre blanco/gris claro
const GRIS_TEXTO_DESHABILITADO := Color("202020")  ## alto contraste incluso en controles disabled

const GROSOR := 2
const RUTA_FUENTE_DOCUMENTO := "res://assets/fonts/MFBOldstyle-Regular.otf"
const RUTA_FUENTE_INTERFAZ := "res://assets/fonts/AtkinsonHyperlegible-Regular.ttf"
const RUTA_FUENTE_TITULO := "res://assets/fonts/AtkinsonHyperlegible-Bold.ttf"
const RUTA_FUENTE_MONO := "res://assets/fonts/IBMPlexMono-Regular.ttf"
const RUTA_FUENTE_TERMINAL := "res://assets/fonts/Kubasta.ttf"


## Dibuja el bisel sobre un rectángulo. [param saliente] a false lo hunde.
static func dibujar_bisel(lienzo: CanvasItem, rect: Rect2, fondo: Color, saliente: bool) -> void:
	var luz := GRIS_CLARO if saliente else GRIS_OSCURO
	var sombra := GRIS_OSCURO if saliente else GRIS_CLARO
	lienzo.draw_rect(rect, fondo)
	for i in GROSOR:
		var d := float(i)
		# Arriba e izquierda.
		lienzo.draw_line(
			rect.position + Vector2(d, d), rect.position + Vector2(rect.size.x - d, d), luz
		)
		lienzo.draw_line(
			rect.position + Vector2(d, d), rect.position + Vector2(d, rect.size.y - d), luz
		)
		# Abajo y derecha.
		lienzo.draw_line(
			rect.position + Vector2(d, rect.size.y - 1.0 - d),
			rect.position + Vector2(rect.size.x - d, rect.size.y - 1.0 - d),
			sombra
		)
		lienzo.draw_line(
			rect.position + Vector2(rect.size.x - 1.0 - d, d),
			rect.position + Vector2(rect.size.x - 1.0 - d, rect.size.y - d),
			sombra
		)


## Equivalente reutilizable del bisel saliente para controles del Theme.
##
## StyleBoxFlat no deja asignar un color distinto a cada lado. Combinamos un
## borde claro con una sombra corta desplazada abajo/derecha: a tamaño real el
## resultado conserva las dos masas de luz del bisel clásico sin necesitar un
## recurso binario ni un shader por control.
static func caja_saliente(fondo: Color = GRIS) -> StyleBoxFlat:
	return _caja_retro(fondo, false)


## Variante hundida: borde oscuro y luz desplazada arriba/izquierda.
static func caja_hundida(fondo: Color = BLANCO) -> StyleBoxFlat:
	return _caja_retro(fondo, true)


## Anillo de foco deliberadamente independiente del relieve.
## Se dibuja en negro/azul oscuro para no depender solo del cambio de volumen.
static func caja_foco() -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color.TRANSPARENT
	caja.border_color = AZUL_TITULO
	caja.set_border_width_all(1)
	caja.set_corner_radius_all(0)
	return caja


static func _caja_retro(fondo: Color, hundida: bool) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.set_corner_radius_all(0)
	caja.set_border_width_all(GROSOR)
	caja.content_margin_left = 7.0
	caja.content_margin_top = 4.0
	caja.content_margin_right = 7.0
	caja.content_margin_bottom = 4.0
	if hundida:
		caja.border_color = GRIS_OSCURO
		caja.shadow_color = GRIS_CLARO
		caja.shadow_size = 1
		caja.shadow_offset = Vector2(-1, -1)
	else:
		caja.border_color = GRIS_CLARO
		caja.shadow_color = GRIS_OSCURO
		caja.shadow_size = GROSOR
		caja.shadow_offset = Vector2(1, 1)
	return caja


static func _configurar_botones(tema: Theme) -> void:
	for tipo in ["Button", "OptionButton", "MenuButton"]:
		tema.set_stylebox("normal", tipo, caja_saliente())
		tema.set_stylebox("hover", tipo, caja_saliente(Color("d0d0d0")))
		tema.set_stylebox("pressed", tipo, caja_hundida(GRIS))
		tema.set_stylebox("disabled", tipo, caja_saliente(Color("d0d0d0")))
		tema.set_stylebox("focus", tipo, caja_foco())
		tema.set_color("font_color", tipo, NEGRO)
		tema.set_color("font_hover_color", tipo, NEGRO)
		tema.set_color("font_pressed_color", tipo, NEGRO)
		tema.set_color("font_focus_color", tipo, NEGRO)
		tema.set_color("font_disabled_color", tipo, GRIS_TEXTO_DESHABILITADO)
		tema.set_constant("outline_size", tipo, 0)


static func _configurar_campos(tema: Theme) -> void:
	for tipo in ["LineEdit", "TextEdit"]:
		tema.set_stylebox("normal", tipo, caja_hundida(BLANCO))
		tema.set_stylebox("focus", tipo, caja_foco())
		tema.set_stylebox("read_only", tipo, caja_hundida(Color("e8e8e8")))
		tema.set_color("font_color", tipo, NEGRO)
		tema.set_color("font_selected_color", tipo, BLANCO)
		tema.set_color("font_placeholder_color", tipo, GRIS_TEXTO)
		tema.set_color("caret_color", tipo, NEGRO)
		tema.set_color("selection_color", tipo, AZUL_TITULO)
	# Godot usa nombres distintos para el color no editable en ambos controles.
	tema.set_color("font_uneditable_color", "LineEdit", GRIS_TEXTO)
	tema.set_color("font_readonly_color", "TextEdit", GRIS_TEXTO)


static func caja_seleccion() -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = AZUL_TITULO
	caja.set_corner_radius_all(0)
	caja.content_margin_left = 4.0
	caja.content_margin_top = 2.0
	caja.content_margin_right = 4.0
	caja.content_margin_bottom = 2.0
	return caja


## Contraste base WCAG AA para texto normal del tema común (#792).
##
## Godot trae ItemList y RichTextLabel con grises/blancos pensados para temas
## oscuros. En OS98 esos defaults caían sobre GRIS y dejaban historial,
## favoritos, resultados y entradas bloqueadas casi ilegibles. Definimos aquí
## los pares de color y sus fondos para que todas las apps hereden el contrato.
static func _configurar_texto_y_listas(tema: Theme) -> void:
	tema.set_color("font_color", "Label", NEGRO)

	tema.set_stylebox("normal", "RichTextLabel", caja_hundida(BLANCO))
	tema.set_stylebox("focus", "RichTextLabel", caja_foco())
	tema.set_color("default_color", "RichTextLabel", NEGRO)
	tema.set_color("font_selected_color", "RichTextLabel", BLANCO)
	tema.set_color("selection_color", "RichTextLabel", AZUL_TITULO)

	var seleccion := caja_seleccion()
	tema.set_stylebox("panel", "ItemList", caja_hundida(BLANCO))
	tema.set_stylebox("focus", "ItemList", caja_foco())
	tema.set_stylebox("hovered", "ItemList", caja_saliente(Color("f0f0f0")))
	for estado in ["selected", "selected_focus", "hovered_selected", "hovered_selected_focus"]:
		tema.set_stylebox(estado, "ItemList", seleccion)
	tema.set_color("font_color", "ItemList", NEGRO)
	tema.set_color("font_hovered_color", "ItemList", NEGRO)
	tema.set_color("font_selected_color", "ItemList", BLANCO)
	tema.set_color("font_hovered_selected_color", "ItemList", BLANCO)
	tema.set_color("font_disabled_color", "ItemList", GRIS_TEXTO_DESHABILITADO)


## Texto de documento. MFB Oldstyle ya estaba empaquetada y registrada como
## CC0; ahora es un rol explícito en vez de la fuente global accidental de todo
## el proyecto. La carga es diferida a propósito: en un checkout limpio Godot
## parsea este script antes de importar el OTF y `preload()` falla al no existir
## todavía un ResourceLoader para esa extensión.
static func fuente_documento() -> Font:
	return load(RUTA_FUENTE_DOCUMENTO) as Font


## Títulos de programa y barras activas: la variante Bold de Atkinson mantiene
## la legibilidad de la interfaz general, pero añade jerarquía sin depender de
## otra familia ni de una fuente instalada en el sistema.
static func fuente_titulo() -> Font:
	return load(RUTA_FUENTE_TITULO) as Font


## Monoespaciada para terminales, volcados y rótulos técnicos: IBM Plex Mono,
## empaquetada con licencia OFL-1.1 (ver `procedencia.json`). Reemplaza el
## fallback de sistema: #298 sigue cubriendo la identidad propia de terminales,
## pero la interfaz general ya no depende de qué monoespaciada tenga instalada
## cada máquina. Carga diferida por el mismo motivo que `fuente_documento()`.
static func fuente_mono() -> Font:
	return load(RUTA_FUENTE_MONO) as Font


## Rol específico de terminal (#298). Kubasta se usa únicamente cuando el
## recurso materializado está disponible; IBM Plex Mono sigue siendo fallback
## reproducible para checkouts sin el objeto LFS o antes de la importación.
## Mantener este rol separado evita que la identidad de terminal altere rótulos
## técnicos, publicaciones o texto 3D que usan la monoespaciada genérica.
static func fuente_terminal() -> Font:
	if ResourceLoader.exists(RUTA_FUENTE_TERMINAL):
		var kubasta := load(RUTA_FUENTE_TERMINAL) as Font
		if kubasta != null:
			return kubasta
	return fuente_mono()


## Interfaz general: Atkinson Hyperlegible, diseñada por el Braille Institute
## para legibilidad a tamaño pequeño y con licencia OFL-1.1 empaquetada en el
## juego. Sustituye la tipografía de respaldo del motor: esa ya era consistente
## entre plataformas, pero no estaba pensada para leerse bien a 14px ni tenía
## identidad propia. Carga diferida por el mismo motivo que `fuente_documento()`.
static func fuente_interfaz() -> Font:
	return load(RUTA_FUENTE_INTERFAZ) as Font


## El Theme define relieve, color, tamaño y ahora también la fuente general:
## una familia empaquetada y con licencia libre en vez del respaldo genérico
## del motor. Los roles especializados (título, documento, mono) se registran
## aparte para sus consumidores.
static func tema() -> Theme:
	var documento := fuente_documento()
	var titulo := fuente_titulo()
	var mono := fuente_mono()
	var terminal := fuente_terminal()
	var tema := Theme.new()
	tema.default_font = fuente_interfaz()
	tema.default_font_size = 14
	# `title_font` es un rol manual en Label y, a la vez, el nombre nativo que
	# Godot consulta para las barras de título de Window. Así los diálogos y
	# lectores OS98 heredan la misma jerarquía sin repetir overrides por programa.
	tema.set_font("title_font", "Label", titulo)
	tema.set_font("title_font", "Window", titulo)
	tema.set_font("document_font", "RichTextLabel", documento)
	tema.set_font("mono_font", "RichTextLabel", mono)
	# Rol manual para superficies terminal/diagnóstico. Se registra para los dos
	# controles de texto que más lo necesitan sin convertirlo en fuente global.
	# Label se registra para cabeceras/estado técnico que lo solicitan explícitamente.
	tema.set_font("terminal_font", "Label", terminal)
	tema.set_font("terminal_font", "RichTextLabel", terminal)
	tema.set_font("terminal_font", "LineEdit", terminal)
	_configurar_botones(tema)
	_configurar_campos(tema)
	_configurar_texto_y_listas(tema)
	return tema
