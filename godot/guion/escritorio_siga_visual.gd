## Piel visual del escritorio corporativo de 1998 (#534).
##
## Mantiene los assets y su asignación fuera de EscritorioSiga: el gestor base
## sigue ocupándose solo del ciclo de vida de ventanas. Los atlas incluyen los
## iconos que necesitarán las siguientes aplicaciones, pero solo se muestran
## cuando una aplicación real registra su identidad visual.
class_name EscritorioSigaVisual
extends EscritorioSiga

const WALLPAPER: Texture2D = preload("res://arte/os98/wallpaper.svg")
const SYSTEM_MARK: Texture2D = preload("res://arte/os98/system_mark.svg")
const ICONOS_32: Texture2D = preload("res://arte/os98/iconos_32.svg")
const ICONOS_16: Texture2D = preload("res://arte/os98/iconos_16.svg")
const ORDEN_ICONOS := ["siga", "equipo", "documentos", "red", "papelera", "ayuda"]

var _identidades_visuales: Dictionary = {}


func _ready() -> void:
	super._ready()
	_instalar_wallpaper()
	_instalar_marca()
	_decorar_boton_menu()


func registrar_identidad_visual(id: String, clave: String) -> void:
	if id.is_empty() or ORDEN_ICONOS.find(clave) < 0:
		return
	_identidades_visuales[id] = clave
	_decorar_accesos(id)
	_decorar_ventana(id)


func registrar_aplicacion(id: String, titulo: String, creador: Callable) -> void:
	super.registrar_aplicacion(id, titulo, creador)
	_decorar_accesos(id)


func _crear_ventana(id: String, titulo: String, contenido: Control) -> void:
	super._crear_ventana(id, titulo, contenido)
	_decorar_ventana(id)


func _instalar_wallpaper() -> void:
	var wallpaper := TextureRect.new()
	wallpaper.name = "WallpaperCorporativo"
	wallpaper.texture = WALLPAPER
	wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(wallpaper)
	move_child(wallpaper, _fondo.get_index() + 1)


func _instalar_marca() -> void:
	var marca := TextureRect.new()
	marca.name = "MarcaSistema"
	marca.texture = SYSTEM_MARK
	marca.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marca.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marca.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	marca.offset_left = -54.0
	marca.offset_top = 12.0
	marca.offset_right = -34.0
	marca.offset_bottom = 32.0
	add_child(marca)
	_marca.offset_right = -60.0
	_marca.offset_left = -374.0


func _decorar_boton_menu() -> void:
	var candidato := _barra.find_child("BotonMenu", true, false)
	if candidato is Button:
		var boton := candidato as Button
		boton.icon = SYSTEM_MARK
		boton.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _decorar_accesos(id: String) -> void:
	var clave := String(_identidades_visuales.get(id, ""))
	if clave.is_empty():
		return
	var lanzador := _iconos.get_node_or_null("Lanzador_%s" % id)
	if lanzador is Button:
		var boton_lanzador := lanzador as Button
		boton_lanzador.icon = _icono(clave, 32)
		boton_lanzador.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var entrada := _programas_menu.get_node_or_null("Programa_%s" % id)
	if entrada is Button:
		var boton_entrada := entrada as Button
		boton_entrada.icon = _icono(clave, 16)
		boton_entrada.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _decorar_ventana(id: String) -> void:
	if not _ventanas.has(id):
		return
	var clave := String(_identidades_visuales.get(id, ""))
	if clave.is_empty():
		return
	var datos: Dictionary = _ventanas[id]
	var tarea: Button = datos["tarea"]
	tarea.icon = _icono(clave, 16)
	tarea.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var barra: PanelContainer = datos["titulo_barra"]
	if barra.get_child_count() == 0:
		return
	var fila := barra.get_child(0)
	if not fila is HBoxContainer or fila.get_node_or_null("IconoAplicacion") != null:
		return
	var icono := TextureRect.new()
	icono.name = "IconoAplicacion"
	icono.texture = _icono(clave, 16)
	icono.custom_minimum_size = Vector2(18, 18)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icono.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	(fila as HBoxContainer).add_child(icono)
	(fila as HBoxContainer).move_child(icono, 0)


func _icono(clave: String, tamano: int) -> Texture2D:
	var indice := ORDEN_ICONOS.find(clave)
	if indice < 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = ICONOS_32 if tamano == 32 else ICONOS_16
	atlas.region = Rect2(float(indice * tamano), 0.0, float(tamano), float(tamano))
	return atlas
