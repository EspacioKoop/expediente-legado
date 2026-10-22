## Editor de niveles y cinemáticas de QA/debug (#2942).
extends Window

const CONTRATO := preload("res://debug/editor_niveles_cinematicas_contrato.gd")
const ESTILO_SIGA := preload("res://guion/estilo_siga.gd")
const ESPACIOS_CATALOGO := preload("res://guion/espacios_catalogo.gd")
const EDITOR_CATALOGO := preload("res://debug/editor_niveles_cinematicas_catalogo.gd")
const EDITOR_EFECTOS := preload("res://debug/editor_niveles_cinematicas_efectos.gd")

const TIPOS_DOC := ["nivel", "cinematica"]
const TIPOS_PLANO := ["3d", "2d"]
const DIRECTORIO := "user://editor_niveles_cinematicas"

var _tipo_doc: OptionButton
var _id: LineEdit
var _version: LineEdit
var _fase: OptionButton
var _lista: ItemList
var _detalle: VBoxContainer
var _diagnostico: Label
var _estado: Label
var _doc_actual: Dictionary = {}
var _editando_indice: int = -1
var _vista: SubViewportContainer
var _timeline: HBoxContainer

var _colocacion_tipo: OptionButton
var _colocacion_id: LineEdit
var _colocacion_recurso: LineEdit
var _colocacion_pos_x: SpinBox
var _colocacion_pos_y: SpinBox
var _colocacion_pos_z: SpinBox
var _colocacion_rot_x: SpinBox
var _colocacion_rot_y: SpinBox
var _colocacion_rot_z: SpinBox
var _colocacion_esc_x: SpinBox
var _colocacion_esc_y: SpinBox
var _colocacion_esc_z: SpinBox
var _colocacion_extra: TextEdit
var _biblioteca_mueble: OptionButton

var _plano_tipo: OptionButton
var _plano_segundos: SpinBox
var _plano_rotulo: LineEdit
var _plano_voz: LineEdit
var _plano_camara_x: SpinBox
var _plano_camara_y: SpinBox
var _plano_camara_z: SpinBox
var _plano_mira_x: SpinBox
var _plano_mira_y: SpinBox
var _plano_mira_z: SpinBox
var _plano_camara_desde_x: SpinBox
var _plano_camara_desde_y: SpinBox
var _plano_camara_desde_z: SpinBox
var _plano_mira_desde_x: SpinBox
var _plano_mira_desde_y: SpinBox
var _plano_mira_desde_z: SpinBox
var _plano_fov: SpinBox
var _plano_foco: SpinBox
var _plano_usa_camara_desde: CheckButton
var _plano_usa_mira_desde: CheckButton
var _plano_fundido_desde: SpinBox
var _plano_fundido_hasta: SpinBox
var _plano_sonido: LineEdit
var _plano_sonido_tono: SpinBox
var _efectos_plano: Dictionary = {}
var _plano_figura: TextEdit
var _plano_desde_x: SpinBox
var _plano_desde_y: SpinBox
var _plano_hasta_x: SpinBox
var _plano_hasta_y: SpinBox
var _plano_decorado: TextEdit


func _ready() -> void:
	title = "SIGA-98 · Editor de Niveles y Cinemáticas (QA)"
	size = Vector2i(1600, 950)
	min_size = Vector2i(1100, 700)
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_requested.connect(hide)
	_montar()
	_nuevo()
	popup_centered()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	if evento.keycode == KEY_F10 and evento.ctrl_pressed and evento.shift_pressed:
		if visible:
			hide()
		else:
			popup_centered()
			get_viewport().set_input_as_handled()


static func validar_nivel(datos: Dictionary) -> PackedStringArray:
	return CONTRATO.validar_nivel(datos)


static func validar_cinematica(datos: Dictionary) -> PackedStringArray:
	return CONTRATO.validar_cinematica(datos)


func _montar() -> void:
	var margen := MarginContainer.new()
	margen.theme = ESTILO_SIGA.tema()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 12)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_right", 12)
	margen.add_theme_constant_override("margin_bottom", 12)
	add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 8)
	margen.add_child(raiz)

	var ayuda := Label.new()
	ayuda.text = (
		"Herramienta QA. Guarda en user://editor_niveles_cinematicas. "
		+ "Ctrl+Shift+F10 muestra/oculta. Solo builds debug/qa."
	)
	raiz.add_child(ayuda)

	var cabecera := HBoxContainer.new()
	raiz.add_child(cabecera)

	cabecera.add_child(_etiqueta("Tipo:"))
	_tipo_doc = OptionButton.new()
	for t in TIPOS_DOC:
		_tipo_doc.add_item(t)
	_tipo_doc.item_selected.connect(_al_cambiar_tipo)
	cabecera.add_child(_tipo_doc)

	cabecera.add_child(_etiqueta("ID:"))
	_id = LineEdit.new()
	_id.placeholder_text = "mi-nivel-01"
	_id.text_changed.connect(_al_cambiar_metadatos)
	cabecera.add_child(_id)

	cabecera.add_child(_etiqueta("Versión:"))
	_version = LineEdit.new()
	_version.text = "1"
	_version.editable = false
	cabecera.add_child(_version)

	cabecera.add_child(_etiqueta("Fase (nivel):"))
	_fase = OptionButton.new()
	for f in CONTRATO.CATALOGO_ESPACIOS.POR_FASE.keys():
		_fase.add_item(f)
	_fase.item_selected.connect(_al_cambiar_metadatos)
	cabecera.add_child(_fase)

	# El viewport real ocupa la mitad izquierda; lista y propiedades quedan a la derecha.
	var division := HSplitContainer.new()
	division.size_flags_vertical = Control.SIZE_EXPAND_FILL
	division.split_offset = 820
	raiz.add_child(division)

	_vista = load("res://debug/editor_niveles_cinematicas_vista.gd").new()
	_vista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vista.custom_minimum_size = Vector2(640, 420)
	_vista.colocacion_seleccionada.connect(_al_seleccionar_vista)
	_vista.transformacion_cambiada.connect(_al_transformacion_cambiada_vista)
	division.add_child(_vista)

	var panel := VSplitContainer.new()
	panel.custom_minimum_size.x = 440
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	division.add_child(panel)

	var izq := VBoxContainer.new()
	izq.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(izq)
	izq.add_child(
		_etiqueta("Línea de tiempo / elementos (selecciona un plano para previsualizarlo):")
	)
	_timeline = load("res://debug/editor_niveles_cinematicas_timeline.gd").new()
	_timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_timeline.muestra_cambiada.connect(_al_cambiar_tiempo)
	izq.add_child(_timeline)
	_lista = ItemList.new()
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.item_selected.connect(_al_seleccionar)
	_lista.item_activated.connect(_al_activar_item)
	izq.add_child(_lista)

	var botones_lista := HBoxContainer.new()
	izq.add_child(botones_lista)
	_boton_accion(botones_lista, "Añadir", _anadir_elemento)
	_boton_accion(botones_lista, "Duplicar", _duplicar_elemento)
	_boton_accion(botones_lista, "Borrar", _borrar_elemento)
	_boton_accion(botones_lista, "Subir", _subir_elemento)
	_boton_accion(botones_lista, "Bajar", _bajar_elemento)

	var der := ScrollContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(der)
	_detalle = VBoxContainer.new()
	_detalle.add_theme_constant_override("separation", 6)
	der.add_child(_detalle)

	# Diagnóstico y estado
	_diagnostico = Label.new()
	_diagnostico.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(_diagnostico)

	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(_estado)

	# Acciones de archivo
	var acciones := HBoxContainer.new()
	raiz.add_child(acciones)
	_boton_accion(acciones, "Nuevo", _nuevo)
	_boton_accion(acciones, "Guardar JSON", _guardar)
	_boton_accion(acciones, "Cargar por ID", _cargar)
	_boton_accion(acciones, "Exportar registro", _exportar_registro)


func _al_cambiar_tipo(_idx: int) -> void:
	_nuevo()
	_refrescar_lista()
	_refrescar_detalle()


func _al_cambiar_metadatos(_valor: Variant) -> void:
	_refrescar_diagnostico()
	_actualizar_previsualizacion()


func _tipo_actual() -> String:
	return _tipo_doc.get_item_text(_tipo_doc.selected)


func _nuevo() -> void:
	_doc_actual = {
		"tipo": _tipo_actual(),
		"id": "",
		"version": "1",
		"fase": _fase.get_item_text(_fase.selected) if _tipo_actual() == "nivel" else "",
		"colocaciones": [] if _tipo_actual() == "nivel" else [],
		"planos": [] if _tipo_actual() == "cinematica" else [],
	}
	_editando_indice = -1
	_id.text = ""
	_fase.select(0)
	_refrescar_lista()
	_refrescar_detalle()
	_estado.text = "Documento nuevo (%s)" % _tipo_actual()


func _refrescar_lista() -> void:
	_lista.clear()
	var tipo := _tipo_actual()
	if tipo == "nivel":
		var colocaciones: Array = _doc_actual.get("colocaciones", [])
		for i in colocaciones.size():
			var c: Dictionary = colocaciones[i]
			var tid := String(c.get("id", "sin-id"))
			var ttipo := String(c.get("tipo", "?"))
			var trecurso := String(c.get("recurso", ""))
			_lista.add_item("%d: [%s] %s (%s)" % [i, ttipo, tid, trecurso])
	else:
		var planos: Array = _doc_actual.get("planos", [])
		for i in planos.size():
			var p: Dictionary = planos[i]
			var ttipo := String(p.get("tipo", "?"))
			var seg := float(p.get("segundos", 0.0))
			var rot := String(p.get("rotulo", ""))
			var txt := "%d: [%s] %.1fs" % [i, ttipo, seg]
			if not rot.is_empty():
				txt += " — %s" % rot
			_lista.add_item(txt)
	_timeline.configurar(
		_doc_actual.get("planos", []) if tipo == "cinematica" else [], tipo == "cinematica"
	)
	_actualizar_previsualizacion()


func _actualizar_previsualizacion() -> void:
	if not is_instance_valid(_vista):
		return
	if _tipo_actual() == "nivel":
		var fase := _fase.get_item_text(_fase.selected) if _fase.item_count > 0 else "archivo"
		_vista.mostrar_nivel(
			ESPACIOS_CATALOGO.POR_FASE.get(fase, {}), _doc_actual.get("colocaciones", [])
		)
		return
	var muestra: Dictionary = _timeline.muestra_actual()
	_al_cambiar_tiempo(int(muestra["indice"]), float(muestra["avance"]))


func _al_cambiar_tiempo(indice: int, avance: float) -> void:
	var planos: Array = _doc_actual.get("planos", [])
	if indice < 0 or indice >= planos.size():
		_vista.mostrar_decorado({})
		_vista.mostrar_plano_cinematica({})
		return
	var plano: Dictionary = planos[indice]
	_vista.mostrar_decorado(plano.get("decorado", {}))
	_vista.mostrar_plano_cinematica(plano, avance)


func _al_seleccionar_vista(indice: int) -> void:
	if _tipo_actual() != "nivel":
		_estado.text = "Objeto del decorado %d seleccionado; arrástralo para moverlo" % indice
		return
	_editando_indice = indice
	_lista.select(indice)
	_refrescar_detalle()


func _al_transformacion_cambiada_vista(indice: int, posicion: Vector3) -> void:
	var indice_plano := int(_timeline.muestra_actual().get("indice", -1))
	var resultado := CONTRATO.actualizar_posicion(
		_doc_actual, _tipo_actual(), indice, indice_plano, posicion
	)
	if resultado.is_empty():
		return
	if _tipo_actual() == "nivel":
		_refrescar_lista()
	else:
		if _editando_indice == indice_plano and is_instance_valid(_plano_decorado):
			_plano_decorado.text = JSON.stringify(resultado["decorado"], "  ")
	_refrescar_diagnostico()


func _al_seleccionar(idx: int) -> void:
	_editando_indice = idx
	_refrescar_detalle()
	if _tipo_actual() == "cinematica":
		_timeline.seleccionar_plano(idx)
	else:
		_actualizar_previsualizacion()


func _al_activar_item(idx: int) -> void:
	_al_seleccionar(idx)


func _refrescar_detalle() -> void:
	# Limpiar detalle previo
	for child in _detalle.get_children():
		child.queue_free()

	var tipo := _tipo_actual()
	if tipo == "nivel":
		_montar_detalle_nivel()
	else:
		_montar_detalle_cinematica()


func _montar_detalle_nivel() -> void:
	_detalle.add_child(_etiqueta("Biblioteca de assets del juego:"))
	var biblioteca := EDITOR_CATALOGO.biblioteca_nivel(_anadir_asset_al_nivel)
	_biblioteca_mueble = biblioteca["selector"]
	_detalle.add_child(biblioteca["fila"])

	var c: Dictionary = {}
	if _editando_indice >= 0:
		var arr: Array = _doc_actual.get("colocaciones", [])
		if _editando_indice < arr.size():
			c = arr[_editando_indice]

	# Tipo de recurso
	_colocacion_tipo = _opciones(_detalle, "Tipo recurso:", CONTRATO.TIPOS_RECURSO)
	if c.has("tipo"):
		_seleccionar_texto(_colocacion_tipo, String(c["tipo"]))
	_colocacion_tipo.item_selected.connect(_refrescar_detalle)

	# ID
	_colocacion_id = _campo(_detalle, "ID:", String(c.get("id", "")))

	# Recurso (modelo, malla, etc.)
	_colocacion_recurso = _campo(_detalle, "Recurso (modelo/ruta):", String(c.get("recurso", "")))

	# Transform
	_detalle.add_child(_etiqueta("Transform:"))
	var transform: Dictionary = c.get("transform", {})
	var pos: Vector3 = CONTRATO.vector3_desde(transform.get("posicion", Vector3.ZERO))
	var rot: Vector3 = CONTRATO.vector3_desde(transform.get("rotacion", Vector3.ZERO))
	var esc: Vector3 = CONTRATO.vector3_desde(transform.get("escala", Vector3.ONE), Vector3.ONE)

	var grid := GridContainer.new()
	grid.columns = 6
	_detalle.add_child(grid)

	_colocacion_pos_x = _spin(grid, "Pos X:", pos.x, -100, 100, 0.01)
	_colocacion_pos_y = _spin(grid, "Pos Y:", pos.y, -100, 100, 0.01)
	_colocacion_pos_z = _spin(grid, "Pos Z:", pos.z, -100, 100, 0.01)
	_colocacion_rot_x = _spin(grid, "Rot X:", rot.x, -360, 360, 1)
	_colocacion_rot_y = _spin(grid, "Rot Y:", rot.y, -360, 360, 1)
	_colocacion_rot_z = _spin(grid, "Rot Z:", rot.z, -360, 360, 1)
	_colocacion_esc_x = _spin(grid, "Esc X:", esc.x, 0.01, 50, 0.01)
	_colocacion_esc_y = _spin(grid, "Esc Y:", esc.y, 0.01, 50, 0.01)
	_colocacion_esc_z = _spin(grid, "Esc Z:", esc.z, 0.01, 50, 0.01)

	# Extra (JSON para campos específicos: color, texto, destino, etc.)
	_detalle.add_child(_etiqueta("Extra (JSON):"))
	_colocacion_extra = TextEdit.new()
	_colocacion_extra.custom_minimum_size.y = 120
	_colocacion_extra.placeholder_text = (
		'{"color": [0.5, 0.5, 0.5], ' + '"texto": "SALIDA", "destino": "casa"}'
	)
	var extra_json := JSON.stringify(c.get("extra", {}), "  ")
	_colocacion_extra.text = extra_json
	_detalle.add_child(_colocacion_extra)

	var btns := HBoxContainer.new()
	_detalle.add_child(btns)
	_boton_accion(btns, "Aplicar", _aplicar_colocacion)
	_boton_accion(btns, "Limpiar", _limpiar_detalle_nivel)


func _montar_detalle_cinematica() -> void:
	_detalle.add_child(_etiqueta("Plano / Beat de cinemática"))

	var p: Dictionary = {}
	if _editando_indice >= 0:
		var arr: Array = _doc_actual.get("planos", [])
		if _editando_indice < arr.size():
			p = arr[_editando_indice]

	# Tipo de plano
	_plano_tipo = _opciones(_detalle, "Tipo plano:", TIPOS_PLANO)
	if p.has("tipo"):
		_seleccionar_texto(_plano_tipo, String(p["tipo"]))
	_plano_tipo.item_selected.connect(_refrescar_detalle)

	# Duración
	_plano_segundos = _spin(_detalle, "Segundos:", float(p.get("segundos", 2.0)), 0.1, 120, 0.01)

	# Rótulo y voz
	_plano_rotulo = _campo(_detalle, "Rótulo (clave i18n):", String(p.get("rotulo", "")))
	_plano_voz = _campo(_detalle, "Voz (clave i18n):", String(p.get("voz", "")))

	# Campos 3D
	var es_3d := _plano_tipo.selected == 0  # "3d" es el primero

	if es_3d:
		_detalle.add_child(_etiqueta("--- 3D ---"))
		var cam: Vector3 = CONTRATO.vector3_desde(p.get("camara", Vector3.ZERO))
		var mira: Vector3 = CONTRATO.vector3_desde(p.get("mira", Vector3.FORWARD), Vector3.FORWARD)
		var cam_desde: Vector3 = CONTRATO.vector3_desde(p.get("camara_desde", cam), cam)
		var mira_desde: Vector3 = CONTRATO.vector3_desde(p.get("mira_desde", mira), mira)
		var grid3d := GridContainer.new()
		grid3d.columns = 6
		_detalle.add_child(grid3d)

		_plano_usa_camara_desde = CheckButton.new()
		_plano_usa_camara_desde.text = "Usar camara_desde"
		_plano_usa_camara_desde.button_pressed = p.has("camara_desde")
		_detalle.add_child(_plano_usa_camara_desde)
		_plano_usa_mira_desde = CheckButton.new()
		_plano_usa_mira_desde.text = "Usar mira_desde"
		_plano_usa_mira_desde.button_pressed = p.has("mira_desde")
		_detalle.add_child(_plano_usa_mira_desde)

		_plano_camara_x = _spin(grid3d, "Cam X:", cam.x, -200, 200, 0.01)
		_plano_camara_y = _spin(grid3d, "Cam Y:", cam.y, -50, 100, 0.01)
		_plano_camara_z = _spin(grid3d, "Cam Z:", cam.z, -200, 200, 0.01)
		_plano_mira_x = _spin(grid3d, "Mira X:", mira.x, -200, 200, 0.01)
		_plano_mira_y = _spin(grid3d, "Mira Y:", mira.y, -50, 100, 0.01)
		_plano_mira_z = _spin(grid3d, "Mira Z:", mira.z, -200, 200, 0.01)

		_plano_camara_desde_x = _spin(grid3d, "CamDesde X:", cam_desde.x, -200, 200, 0.01)
		_plano_camara_desde_y = _spin(grid3d, "CamDesde Y:", cam_desde.y, -50, 100, 0.01)
		_plano_camara_desde_z = _spin(grid3d, "CamDesde Z:", cam_desde.z, -200, 200, 0.01)
		_plano_mira_desde_x = _spin(grid3d, "MiraDesde X:", mira_desde.x, -200, 200, 0.01)
		_plano_mira_desde_y = _spin(grid3d, "MiraDesde Y:", mira_desde.y, -50, 100, 0.01)
		_plano_mira_desde_z = _spin(grid3d, "MiraDesde Z:", mira_desde.z, -200, 200, 0.01)

		# Óptica
		_plano_fov = _spin(_detalle, "FOV (grados, 0=auto):", float(p.get("fov", 0.0)), 0, 179, 1)
		_plano_foco = _spin(
			_detalle, "Foco (distancia, 0=auto):", float(p.get("foco", 0.0)), 0, 500, 0.1
		)

		# Fundido
		_detalle.add_child(_etiqueta("Fundido (0-1):"))
		var grid_fd := GridContainer.new()
		grid_fd.columns = 4
		_detalle.add_child(grid_fd)
		_plano_fundido_desde = _spin(
			grid_fd, "Desde:", float(p.get("fundido_desde", 0.0)), 0, 1, 0.01
		)
		_plano_fundido_hasta = _spin(
			grid_fd, "Hasta:", float(p.get("fundido_hasta", 0.0)), 0, 1, 0.01
		)

	# Campos 2D
	if not es_3d:
		_detalle.add_child(_etiqueta("--- 2D ---"))
		_plano_figura = TextEdit.new()
		_plano_figura.custom_minimum_size.y = 150
		var ph := '[{"rect": {"x": -1, "y": -1, "width": 2, "height": 2}, '
		ph += '"color": [1, 1, 1, 1]}]'
		_plano_figura.placeholder_text = ph
		var fig_json := JSON.stringify(p.get("figura", []), "  ")
		_plano_figura.text = fig_json
		_detalle.add_child(_plano_figura)

		var grid2d := GridContainer.new()
		grid2d.columns = 4
		_detalle.add_child(grid2d)
		var desde: Vector2 = CONTRATO.vector2_desde(p.get("desde", Vector2.ZERO))
		var hasta: Vector2 = CONTRATO.vector2_desde(p.get("hasta", Vector2.ZERO))
		_plano_desde_x = _spin(grid2d, "Desde X:", desde.x, -500, 500, 0.1)
		_plano_desde_y = _spin(grid2d, "Desde Y:", desde.y, -500, 500, 0.1)
		_plano_hasta_x = _spin(grid2d, "Hasta X:", hasta.x, -500, 500, 0.1)
		_plano_hasta_y = _spin(grid2d, "Hasta Y:", hasta.y, -500, 500, 0.1)

	# Sonido opcional
	_detalle.add_child(_etiqueta("Sonido (opcional):"))
	var grid_snd := GridContainer.new()
	grid_snd.columns = 4
	_detalle.add_child(grid_snd)
	_plano_sonido = _campo(grid_snd, "Nombre:", String(p.get("sonido", "")))
	_plano_sonido_tono = _spin(grid_snd, "Tono:", float(p.get("sonido_tono", 1.0)), 0.1, 4.0, 0.01)

	# Controles por plano para efectos ya soportados por CinematicaApp.
	_efectos_plano = EDITOR_EFECTOS.montar(_detalle, p, _editando_indice)

	# Decorado (para planos 3D con set propio)
	if es_3d:
		_detalle.add_child(_etiqueta("Decorado (JSON espacio, opcional):"))
		_plano_decorado = TextEdit.new()
		_plano_decorado.custom_minimum_size.y = 120
		_plano_decorado.placeholder_text = '{"suelo": [10,10], "bultos": [], "luces": []}'
		var dec_json := JSON.stringify(p.get("decorado", {}), "  ")
		_plano_decorado.text = dec_json
		_detalle.add_child(_plano_decorado)
		_detalle.add_child(_etiqueta("Escenario catalogado para el plano:"))
		var selector_escenario := EDITOR_CATALOGO.selector_escenario(_plano_decorado, _estado)
		_detalle.add_child(selector_escenario["fila"])
		_detalle.add_child(_etiqueta("Objetos del decorado:"))
		var biblioteca_decorado := EDITOR_CATALOGO.biblioteca_decorado(
			_plano_decorado, _estado, _plano_sonido
		)
		_biblioteca_mueble = biblioteca_decorado["selector"]
		_detalle.add_child(biblioteca_decorado["fila"])

	var btns := HBoxContainer.new()
	_detalle.add_child(btns)
	_boton_accion(btns, "Aplicar", _aplicar_plano)
	_boton_accion(btns, "Limpiar", _limpiar_detalle_cinematica)


func _anadir_asset_al_nivel(ruta: String = "") -> void:
	EDITOR_CATALOGO.anadir_a_nivel(self, ruta)


func _aplicar_colocacion() -> void:
	var tipo := _tipo_actual()
	if tipo != "nivel":
		return

	var c: Dictionary = {}
	c["tipo"] = _colocacion_tipo.get_item_text(_colocacion_tipo.selected)
	c["id"] = _colocacion_id.text.strip_edges()
	c["recurso"] = _colocacion_recurso.text.strip_edges()
	c["transform"] = {
		"posicion": [_colocacion_pos_x.value, _colocacion_pos_y.value, _colocacion_pos_z.value],
		"rotacion": [_colocacion_rot_x.value, _colocacion_rot_y.value, _colocacion_rot_z.value],
		"escala": [_colocacion_esc_x.value, _colocacion_esc_y.value, _colocacion_esc_z.value],
	}

	# Parsear extra JSON
	var extra_texto := _colocacion_extra.text.strip_edges()
	if not extra_texto.is_empty():
		var extra_var: Variant = JSON.parse_string(extra_texto)
		if extra_var is Dictionary:
			c["extra"] = extra_var
		else:
			_estado.text = "Extra: JSON inválido"
			return

	var arr: Array = _doc_actual["colocaciones"]
	if _editando_indice >= 0 and _editando_indice < arr.size():
		arr[_editando_indice] = c
	else:
		arr.append(c)

	_refrescar_lista()
	_refrescar_diagnostico()
	_estado.text = "Colocación aplicada"


func _aplicar_plano() -> void:
	var tipo := _tipo_actual()
	if tipo != "cinematica":
		return

	var p: Dictionary = {}
	p["tipo"] = _plano_tipo.get_item_text(_plano_tipo.selected)
	p["segundos"] = _plano_segundos.value
	p["rotulo"] = _plano_rotulo.text.strip_edges()
	p["voz"] = _plano_voz.text.strip_edges()

	var es_3d := _plano_tipo.selected == 0

	if es_3d:
		p["camara"] = [_plano_camara_x.value, _plano_camara_y.value, _plano_camara_z.value]
		p["mira"] = [_plano_mira_x.value, _plano_mira_y.value, _plano_mira_z.value]
		if _plano_usa_camara_desde.button_pressed:
			p["camara_desde"] = [
				_plano_camara_desde_x.value,
				_plano_camara_desde_y.value,
				_plano_camara_desde_z.value
			]
		if _plano_usa_mira_desde.button_pressed:
			p["mira_desde"] = [
				_plano_mira_desde_x.value, _plano_mira_desde_y.value, _plano_mira_desde_z.value
			]
		if _plano_fov.value > 0:
			p["fov"] = _plano_fov.value
		if _plano_foco.value > 0:
			p["foco"] = _plano_foco.value
		if _plano_fundido_desde.value != 0.0 or _plano_fundido_hasta.value != 0.0:
			p["fundido_desde"] = _plano_fundido_desde.value
			p["fundido_hasta"] = _plano_fundido_hasta.value
	else:
		# Parsear figura JSON
		var fig_texto := _plano_figura.text.strip_edges()
		if fig_texto.is_empty():
			_estado.text = "Figura 2D requerida"
			return
		var fig_var: Variant = JSON.parse_string(fig_texto)
		if not (fig_var is Array):
			_estado.text = "Figura: debe ser un array JSON"
			return
		p["figura"] = fig_var
		p["desde"] = [_plano_desde_x.value, _plano_desde_y.value]
		p["hasta"] = [_plano_hasta_x.value, _plano_hasta_y.value]

	# Sonido
	if not _plano_sonido.text.strip_edges().is_empty():
		p["sonido"] = _plano_sonido.text.strip_edges()
		p["sonido_tono"] = _plano_sonido_tono.value

	EDITOR_EFECTOS.aplicar(p, _efectos_plano)

	# Decorado
	if es_3d:
		var dec_texto := _plano_decorado.text.strip_edges()
		if not dec_texto.is_empty():
			var dec_var: Variant = JSON.parse_string(dec_texto)
			if dec_var is Dictionary:
				p["decorado"] = dec_var
			else:
				_estado.text = "Decorado: JSON inválido"
				return

	var arr: Array = _doc_actual["planos"]
	if _editando_indice >= 0 and _editando_indice < arr.size():
		arr[_editando_indice] = p
	else:
		arr.append(p)

	_refrescar_lista()
	_refrescar_diagnostico()
	_estado.text = "Plano aplicado"


func _limpiar_detalle_nivel() -> void:
	_editando_indice = -1
	_refrescar_detalle()


func _limpiar_detalle_cinematica() -> void:
	_editando_indice = -1
	_refrescar_detalle()


func _anadir_elemento() -> void:
	_editando_indice = -1
	_refrescar_detalle()


func _duplicar_elemento() -> void:
	if _editando_indice < 0:
		return
	var tipo := _tipo_actual()
	if tipo == "nivel":
		var arr: Array = _doc_actual["colocaciones"]
		if _editando_indice < arr.size():
			var nuevo: Dictionary = arr[_editando_indice].duplicate(true)
			nuevo["id"] = String(nuevo["id"]) + "_copia"
			arr.append(nuevo)
	else:
		var arr: Array = _doc_actual["planos"]
		if _editando_indice < arr.size():
			arr.append(arr[_editando_indice].duplicate(true))
	_refrescar_lista()
	_refrescar_diagnostico()


func _borrar_elemento() -> void:
	if _editando_indice < 0:
		return
	var tipo := _tipo_actual()
	if tipo == "nivel":
		var arr: Array = _doc_actual["colocaciones"]
		if _editando_indice < arr.size():
			arr.remove_at(_editando_indice)
	else:
		var arr: Array = _doc_actual["planos"]
		if _editando_indice < arr.size():
			arr.remove_at(_editando_indice)
	_editando_indice = -1
	_refrescar_lista()
	_refrescar_detalle()
	_refrescar_diagnostico()


func _subir_elemento() -> void:
	if _editando_indice <= 0:
		return
	var tipo := _tipo_actual()
	if tipo == "nivel":
		var arr: Array = _doc_actual["colocaciones"]
		var temp: Dictionary = arr[_editando_indice]
		arr[_editando_indice] = arr[_editando_indice - 1]
		arr[_editando_indice - 1] = temp
	else:
		var arr: Array = _doc_actual["planos"]
		var temp: Dictionary = arr[_editando_indice]
		arr[_editando_indice] = arr[_editando_indice - 1]
		arr[_editando_indice - 1] = temp
	_editando_indice -= 1
	_refrescar_lista()
	_refrescar_diagnostico()


func _bajar_elemento() -> void:
	var tipo := _tipo_actual()
	if tipo == "nivel":
		var arr: Array = _doc_actual["colocaciones"]
		if _editando_indice < 0 or _editando_indice >= arr.size() - 1:
			return
		var temp: Dictionary = arr[_editando_indice]
		arr[_editando_indice] = arr[_editando_indice + 1]
		arr[_editando_indice + 1] = temp
	else:
		var arr: Array = _doc_actual["planos"]
		if _editando_indice < 0 or _editando_indice >= arr.size() - 1:
			return
		var temp: Dictionary = arr[_editando_indice]
		arr[_editando_indice] = arr[_editando_indice + 1]
		arr[_editando_indice + 1] = temp
	_editando_indice += 1
	_refrescar_lista()
	_refrescar_diagnostico()


func _datos_desde_ui() -> Dictionary:
	var doc := _doc_actual.duplicate(true)
	doc["id"] = _id.text.strip_edges()
	doc["version"] = _version.text.strip_edges()
	if _tipo_actual() == "nivel":
		doc["fase"] = _fase.get_item_text(_fase.selected)
	return doc


func _aplicar_ui_desde_datos(datos: Dictionary) -> void:
	_id.text = String(datos.get("id", ""))
	_version.text = String(datos.get("version", "1"))
	if _tipo_actual() == "nivel":
		var fase := String(datos.get("fase", "archivo"))
		for i in _fase.item_count:
			if _fase.get_item_text(i) == fase:
				_fase.select(i)
				break
	_doc_actual = datos
	_editando_indice = -1
	_refrescar_lista()
	_refrescar_detalle()
	_refrescar_diagnostico()


func _refrescar_diagnostico() -> void:
	var datos := _datos_desde_ui()
	var errores := PackedStringArray()
	if _tipo_actual() == "nivel":
		errores = validar_nivel(datos)
	else:
		errores = validar_cinematica(datos)

	if errores.is_empty():
		_diagnostico.text = "Validación: OK"
		_diagnostico.add_theme_color_override("font_color", Color(0.0, 0.6, 0.0))
	else:
		_diagnostico.text = "Validación: %s" % "; ".join(errores)
		_diagnostico.add_theme_color_override("font_color", Color(0.8, 0.0, 0.0))


static func paquete_nivel(datos: Dictionary) -> Dictionary:
	return CONTRATO.paquete_nivel(datos)


static func paquete_cinematica(datos: Dictionary) -> Dictionary:
	return CONTRATO.paquete_cinematica(datos)


static func datos_desde_paquete(paquete: Variant) -> Dictionary:
	return CONTRATO.datos_desde_paquete(paquete)


func _guardar() -> void:
	var datos := _datos_desde_ui()
	var errores := PackedStringArray()
	if _tipo_actual() == "nivel":
		errores = validar_nivel(datos)
	else:
		errores = validar_cinematica(datos)

	if not errores.is_empty():
		_estado.text = "No se guardó: " + "; ".join(errores)
		return

	var error := DirAccess.make_dir_recursive_absolute(DIRECTORIO)
	if error != OK:
		_estado.text = "No se pudo crear %s (error %d)" % [DIRECTORIO, error]
		return

	var ruta := _ruta(String(datos["id"]), _tipo_actual())
	var paquete := paquete_nivel(datos) if _tipo_actual() == "nivel" else paquete_cinematica(datos)
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		_estado.text = "No se pudo abrir %s para escritura" % ruta
		return
	archivo.store_string(JSON.stringify(paquete, "  "))
	_estado.text = "Guardado: %s" % ruta


func _cargar() -> void:
	var id := _id.text.strip_edges()
	if id.is_empty() or not CONTRATO.id_ruta_valido(id):
		_estado.text = "Escribe un ID válido para cargar"
		return
	var ruta := _ruta(id, _tipo_actual())
	if not FileAccess.file_exists(ruta):
		_estado.text = "No existe: %s" % ruta
		return
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		_estado.text = "No se pudo leer: %s" % ruta
		return
	var paquete_var: Variant = JSON.parse_string(archivo.get_as_text())
	var datos := datos_desde_paquete(paquete_var)
	if datos.is_empty():
		_estado.text = "Formato no compatible o JSON inválido"
		return
	var tipo := String(datos["tipo"])
	var errores := validar_nivel(datos) if tipo == "nivel" else validar_cinematica(datos)
	if not errores.is_empty():
		_estado.text = "No se cargó: " + "; ".join(errores)
		return
	for i in _tipo_doc.item_count:
		if _tipo_doc.get_item_text(i) == tipo:
			_tipo_doc.select(i)
			break
	_aplicar_ui_desde_datos(datos)
	_estado.text = "Cargado: %s" % ruta


func _exportar_registro() -> void:
	var datos := _datos_desde_ui()
	var errores := PackedStringArray()
	if _tipo_actual() == "nivel":
		errores = validar_nivel(datos)
	else:
		errores = validar_cinematica(datos)
	if not errores.is_empty():
		_estado.text = "No se exportó: " + "; ".join(errores)
		return

	var tipo := _tipo_actual()
	var registro := {}
	if tipo == "nivel":
		registro = {
			"id": datos["id"],
			"tipo": "NIVEL",
			"version": datos["version"],
			"fase": datos["fase"],
			"colocaciones": datos["colocaciones"],
		}
	else:
		registro = {
			"id": datos["id"],
			"tipo": "CINEMATICA",
			"version": datos["version"],
			"planos": datos["planos"],
		}

	var error := DirAccess.make_dir_recursive_absolute(DIRECTORIO)
	if error != OK:
		_estado.text = "No se pudo crear directorio"
		return
	var ruta := "%s/%s_%s_registro.json" % [DIRECTORIO, datos["id"], tipo]
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		_estado.text = "No se pudo escribir registro"
		return
	archivo.store_string(
		JSON.stringify(
			{
				"formato":
				CONTRATO.FORMATO_NIVEL if tipo == "nivel" else CONTRATO.FORMATO_CINEMATICA,
				"registro": registro
			},
			"  "
		)
	)
	_estado.text = "Registro exportado: %s" % ruta


func _ruta(id: String, tipo: String) -> String:
	return "%s/%s_%s.json" % [DIRECTORIO, id, tipo]


func _campo(padre: Control, rotulo: String, placeholder: String) -> LineEdit:
	var cont := HBoxContainer.new()
	padre.add_child(cont)
	var etiqueta := Label.new()
	etiqueta.text = rotulo
	etiqueta.custom_minimum_size.x = 140
	cont.add_child(etiqueta)
	var campo := LineEdit.new()
	campo.placeholder_text = placeholder
	campo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.add_child(campo)
	return campo


func _spin(
	padre: Control, rotulo: String, valor: float, minimo: float, maximo: float, paso: float
) -> SpinBox:
	var cont := HBoxContainer.new()
	padre.add_child(cont)
	var etiqueta := Label.new()
	etiqueta.text = rotulo
	etiqueta.custom_minimum_size.x = 120
	cont.add_child(etiqueta)
	var spin := SpinBox.new()
	spin.min_value = minimo
	spin.max_value = maximo
	spin.step = paso
	spin.value = valor
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.add_child(spin)
	return spin


func _opciones(padre: Control, rotulo: String, valores: Array) -> OptionButton:
	var cont := HBoxContainer.new()
	padre.add_child(cont)
	var etiqueta := Label.new()
	etiqueta.text = rotulo
	etiqueta.custom_minimum_size.x = 140
	cont.add_child(etiqueta)
	var opcion := OptionButton.new()
	for v in valores:
		opcion.add_item(String(v))
	opcion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.add_child(opcion)
	return opcion


func _boton_accion(padre: HBoxContainer, rotulo: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = rotulo
	boton.pressed.connect(accion)
	padre.add_child(boton)


func _etiqueta(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", ESTILO_SIGA.AZUL_TITULO)
	return etiqueta


func _seleccionar_texto(opcion: OptionButton, texto: String) -> void:
	for i in opcion.item_count:
		if opcion.get_item_text(i) == texto:
			opcion.select(i)
			return
	opcion.select(0)
