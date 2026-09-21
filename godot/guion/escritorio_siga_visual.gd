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
const ICONOS_PROGRAMAS_32: Texture2D = preload("res://arte/os98/iconos_programas_32.svg")
const ICONOS_PROGRAMAS_16: Texture2D = preload("res://arte/os98/iconos_programas_16.svg")
const CURSORES_32: Texture2D = preload("res://arte/os98/cursores_32.svg")
const ORDEN_ICONOS := ["siga", "equipo", "documentos", "red", "papelera", "ayuda"]
const ORDEN_ICONOS_PROGRAMAS := [
	"explorador", "web98", "software", "correo", "bloc-notas", "calculadora", "catalogo-anomalias"
]
const ORDEN_CURSORES := ["normal", "ayuda", "ocupado", "seleccionar", "texto", "no-disponible"]
## Si el foco desaparece por cerrar/reparentar un Control, una de estas acciones
## es una señal inequívoca de que teclado/mando necesita un nuevo punto de partida.
const ACCIONES_RECUPERAR_FOCO := [
	"ui_up",
	"ui_down",
	"ui_left",
	"ui_right",
	"ui_accept",
	"ui_focus_next",
	"ui_focus_prev",
]

var _identidades_visuales: Dictionary = {}
var _boton_menu_visual: Button


func _ready() -> void:
	super._ready()
	_instalar_wallpaper()
	_instalar_marca()
	_decorar_boton_menu()
	_instalar_cursor()


func _exit_tree() -> void:
	# El cursor del OS98 pertenece al puesto de trabajo, no a todo el juego.
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)


func registrar_identidad_visual(id: String, clave: String) -> void:
	if id.is_empty() or (ORDEN_ICONOS.find(clave) < 0 and ORDEN_ICONOS_PROGRAMAS.find(clave) < 0):
		return
	_identidades_visuales[id] = clave
	_decorar_accesos(id)
	_decorar_ventana(id)


func registrar_aplicacion(
	id: String,
	titulo: String,
	creador: Callable,
	tamano_minimo: Vector2 = TAMANO_MINIMO_SERIE,
	tamano_preferido: Vector2 = TAMANO_PREFERIDO_SERIE,
	redimensionable: bool = false,
	multiples_instancias: bool = false
) -> void:
	super.registrar_aplicacion(
		id, titulo, creador, tamano_minimo, tamano_preferido, redimensionable, multiples_instancias
	)
	_decorar_accesos(id)


func minimizar(id: String) -> void:
	super.minimizar(id)
	_reparar_foco_si_oculto()


func cerrar(id: String) -> void:
	super.cerrar(id)
	call_deferred("_reparar_foco_si_oculto")


func _crear_ventana(
	id: String, titulo: String, contenido: Control, es_modal: bool = false, id_app: String = ""
) -> void:
	super._crear_ventana(id, titulo, contenido, es_modal, id_app)
	if not _ventanas.has(id):
		return

	# #782: ninguna app puede pintar fuera del marco aunque su mínimo interno
	# cambie después de registrarse. Además, si el contenido ya conoce un mínimo
	# mayor que el declarado (caso del visor SIGA-98), la ventana adopta ese mínimo
	# real hasta el tamaño disponible del escritorio en lugar de dejarlo desbordar.
	var datos: Dictionary = _ventanas[id]
	var panel: Control = datos["panel"]
	panel.clip_contents = true

	var minimo_declarado: Vector2 = datos.get("tamano_minimo", Vector2.ONE)
	var minimo_contenido := (
		contenido.get_combined_minimum_size() + Vector2(_esc(6.0), _alto_titulo + _esc(6.0))
	)
	var limite_ancho := maxf(_area_ventanas.size.x, minimo_declarado.x)
	var limite_alto := maxf(_area_ventanas.size.y, minimo_declarado.y)
	var minimo_real := Vector2(
		maxf(minimo_declarado.x, minf(minimo_contenido.x, limite_ancho)),
		maxf(minimo_declarado.y, minf(minimo_contenido.y, limite_alto))
	)
	datos["tamano_minimo"] = minimo_real
	panel.size.x = maxf(panel.size.x, minimo_real.x)
	panel.size.y = maxf(panel.size.y, minimo_real.y)
	_limitar_ventana(panel, minimo_real)

	_decorar_ventana(id)
	var foco := _primer_control_enfocable(contenido)
	if foco == null:
		foco = _primer_control_enfocable(panel)
	if foco != null:
		foco.grab_focus()


func _unhandled_key_input(evento: InputEvent) -> void:
	var menu_estaba_visible := _menu != null and _menu.visible
	super._unhandled_key_input(evento)
	if menu_estaba_visible and _menu != null and not _menu.visible:
		_reparar_foco_si_oculto()


## Con foco válido, Godot resuelve navegación normal y no intervenimos. Este
## fallback solo actúa cuando un cierre/reparentado deja `gui_get_focus_owner()`
## vacío o fuera de la superficie que manda (modal/menú/escritorio). Así el
## siguiente gesto de teclado o mando siempre vuelve a tener desde dónde navegar.
func _unhandled_input(evento: InputEvent) -> void:
	if recuperar_foco(evento):
		get_viewport().set_input_as_handled()


func recuperar_foco(evento: InputEvent) -> bool:
	if not _evento_recupera_foco(evento) or _foco_valido_en_escritorio():
		return false
	var objetivo := _objetivo_recuperacion_foco()
	if objetivo == null:
		return false
	objetivo.grab_focus()
	return true


func _evento_recupera_foco(evento: InputEvent) -> bool:
	for accion in ACCIONES_RECUPERAR_FOCO:
		if evento.is_action_pressed(accion):
			return true
	return false


func _foco_valido_en_escritorio() -> bool:
	var foco := get_viewport().gui_get_focus_owner()
	if not is_instance_valid(foco) or not foco.is_visible_in_tree():
		return false
	if not _modal_id.is_empty() and _ventanas.has(_modal_id):
		var panel_modal: Control = _ventanas[_modal_id]["panel"]
		return foco == panel_modal or panel_modal.is_ancestor_of(foco)
	if _menu != null and _menu.visible:
		return foco == _menu or _menu.is_ancestor_of(foco)
	return foco == self or is_ancestor_of(foco)


func _objetivo_recuperacion_foco() -> Control:
	if not _modal_id.is_empty() and _ventanas.has(_modal_id):
		var panel_modal: Control = _ventanas[_modal_id]["panel"]
		var foco_modal := _primer_control_enfocable(panel_modal)
		if foco_modal != null:
			return foco_modal
	if _menu != null and _menu.visible:
		var foco_menu := _primer_control_enfocable(_menu)
		if foco_menu != null:
			return foco_menu
	var foco_ventana := _foco_ventana_superior()
	if foco_ventana != null:
		return foco_ventana
	if is_instance_valid(_boton_menu_visual) and _boton_menu_visual.is_visible_in_tree():
		return _boton_menu_visual
	return null


func _foco_ventana_superior() -> Control:
	var mayor := -1
	var elegida: Control = null
	for id in _ventanas:
		var datos: Dictionary = _ventanas[id]
		if bool(datos.get("minimizada", false)):
			continue
		var panel: Control = datos["panel"]
		if not is_instance_valid(panel) or not panel.is_visible_in_tree() or panel.z_index <= mayor:
			continue
		var contenido := panel.find_child("Contenido", true, false)
		var candidato: Control = null
		if contenido != null:
			candidato = _primer_control_enfocable(contenido)
		if candidato == null:
			candidato = _primer_control_enfocable(panel)
		if candidato != null:
			mayor = panel.z_index
			elegida = candidato
	return elegida


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
		_boton_menu_visual = boton
		boton.icon = SYSTEM_MARK
		boton.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		boton.pressed.connect(_al_cambiar_visibilidad_menu)


func _al_cambiar_visibilidad_menu() -> void:
	# El handler base alterna primero la visibilidad. Si acaba de cerrarse,
	# el foco vuelve al botón del sistema en vez de quedarse en una entrada oculta.
	if _menu != null and not _menu.visible:
		_enfocar_boton_menu()


func _reparar_foco_si_oculto() -> void:
	if _foco_valido_en_escritorio():
		return
	var objetivo := _objetivo_recuperacion_foco()
	if objetivo != null:
		objetivo.grab_focus()


func _enfocar_boton_menu() -> void:
	if is_instance_valid(_boton_menu_visual) and _boton_menu_visual.is_visible_in_tree():
		_boton_menu_visual.grab_focus()


func _instalar_cursor() -> void:
	Input.set_custom_mouse_cursor(_cursor("normal"), Input.CURSOR_ARROW, Vector2(1, 1))


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
	# Una instancia adicional ("explorador#2") comparte la identidad visual de
	# su aplicación base: el "#" nunca es parte de un id registrado.
	var id_base := id.split("#")[0]
	var clave := String(_identidades_visuales.get(id, _identidades_visuales.get(id_base, "")))
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
	var fuente_atlas: Texture2D = ICONOS_32 if tamano == 32 else ICONOS_16
	if indice < 0:
		indice = ORDEN_ICONOS_PROGRAMAS.find(clave)
		if indice < 0:
			return null
		fuente_atlas = ICONOS_PROGRAMAS_32 if tamano == 32 else ICONOS_PROGRAMAS_16
	var atlas := AtlasTexture.new()
	atlas.atlas = fuente_atlas
	atlas.region = Rect2(float(indice * tamano), 0.0, float(tamano), float(tamano))
	return atlas


func _cursor(clave: String) -> Texture2D:
	var indice := ORDEN_CURSORES.find(clave)
	if indice < 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = CURSORES_32
	atlas.region = Rect2(float(indice * 32), 0.0, 32.0, 32.0)
	return atlas
