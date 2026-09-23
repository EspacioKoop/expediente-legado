## Selector material de cartuchos para la Portátil Color 98 (#799).
##
## Es una capa de presentación sobre EmuladorPortatilAudioApp: no conoce SRAM,
## economía ni estado de campaña. Lee el mismo catálogo que la UI base, muestra
## hasta tres cartuchos reales en un SubViewport 3D y delega la carga al emulador.
class_name SelectorCartuchos3D
extends VBoxContainer

const RUTA_ETIQUETAS := "res://arte/consola98/cartuchos/"
const TAMANO_VIEWPORT := Vector2i(680, 400)
const DURACION_INSERCION := 0.14

var _app: Node
var _entradas: Array[Dictionary] = []
var _indice := 0
var _marco: SubViewportContainer
var _viewport: SubViewport
var _modelos: Node3D
var _cartucho_central: Node3D
var _nombre: Label
var _insertar: Button
var _reduccion_movimiento := false


static func instalar(app: Node) -> void:
	if app == null:
		return
	var lista_variante = app.get("_lista")
	if not (lista_variante is VBoxContainer):
		return
	var lista := lista_variante as VBoxContainer
	var entradas := _entradas_disponibles(app)
	if entradas.is_empty():
		return

	# Conserva el indicador de ranura que aporta EmuladorPortatilAudioApp; solo
	# sustituye los botones de texto que componían el selector antiguo.
	for hijo in lista.get_children():
		if hijo.name == "EstadoCartuchoPortatil":
			continue
		lista.remove_child(hijo)
		hijo.queue_free()

	var selector := SelectorCartuchos3D.new()
	selector.name = "SelectorCartuchos3D"
	lista.add_child(selector)
	selector.configurar(app, entradas)
	selector.enfocar.call_deferred()


static func _entradas_disponibles(app: Node) -> Array[Dictionary]:
	var entradas: Array[Dictionary] = []
	var compradas_variante = app.get("roms_compradas")
	var compradas: Array = compradas_variante if compradas_variante is Array else []
	var desbloqueadas_variante = app.get("roms_desbloqueadas")
	var desbloqueadas: Array = desbloqueadas_variante if desbloqueadas_variante is Array else []
	for rom in RomsPropias.en_consola(compradas, desbloqueadas):
		var titulo := String(rom.get("titulo", ""))
		var id_rom := String(rom.get("id", ""))
		var clave := "rom_propia"
		if not bool(rom.get("incluida", false)):
			clave = "rom_comprada" if compradas.has(id_rom) else "rom_desbloqueada"
		(
			entradas
			. append(
				{
					"id": String(rom.get("id", "")),
					"titulo": titulo,
					"nombre": String(app.call("_formatear", clave, [titulo])),
					"ruta": String(rom.get("rom", "")),
				}
			)
		)
	for local in CatalogoRomsUsuario.listar():
		var ruta := String(local.get("ruta", ""))
		(
			entradas
			. append(
				{
					"id": ruta.get_file().get_basename(),
					"titulo": String(local.get("nombre", "")),
					"nombre": String(local.get("nombre", "")),
					"ruta": ruta,
				}
			)
		)
	return entradas


func configurar(app: Node, entradas: Array[Dictionary]) -> void:
	_app = app
	_entradas = entradas.duplicate(true)
	_reduccion_movimiento = bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	process_mode = Node.PROCESS_MODE_ALWAYS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	_montar_escena()
	_montar_controles()
	_actualizar_selector()


func enfocar() -> void:
	if _insertar != null and is_instance_valid(_insertar):
		_insertar.grab_focus()


func _input(event: InputEvent) -> void:
	if not _puede_interactuar():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT:
			_mover(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_RIGHT:
			_mover(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_insertar_actual()
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_DPAD_LEFT:
			_mover(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
			_mover(1)
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_A:
			_insertar_actual()
			get_viewport().set_input_as_handled()


func _puede_interactuar() -> bool:
	if _app == null or not is_instance_valid(_app) or _entradas.is_empty():
		return false
	if bool(_app.get("_jugando")) or bool(_app.get("_encendiendo")):
		return false
	return not bool(_app.get("_cambiando_cartucho"))


func _al_input_carrusel(event: InputEvent) -> void:
	if not _puede_interactuar():
		return
	if not (event is InputEventMouseButton) or not event.pressed:
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_mover(-1)
		accept_event()
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_mover(1)
		accept_event()
		return
	if event.button_index != MOUSE_BUTTON_LEFT or _marco == null:
		return

	var ancho := maxf(_marco.size.x, 1.0)
	var fraccion: float = event.position.x / ancho
	if fraccion < 0.34:
		_mover(-1)
	elif fraccion > 0.66:
		_mover(1)
	else:
		_insertar_actual()
	accept_event()


func _montar_escena() -> void:
	_marco = SubViewportContainer.new()
	_marco.name = "CarruselCartuchos3D"
	_marco.custom_minimum_size = Vector2(340, 200)
	_marco.stretch = true
	_marco.mouse_filter = Control.MOUSE_FILTER_STOP
	_marco.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_marco.gui_input.connect(_al_input_carrusel)
	add_child(_marco)

	_viewport = SubViewport.new()
	_viewport.size = TAMANO_VIEWPORT
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_marco.add_child(_viewport)

	var entorno := WorldEnvironment.new()
	entorno.environment = Environment.new()
	entorno.environment.background_mode = Environment.BG_COLOR
	entorno.environment.background_color = Color(0.025, 0.032, 0.034)
	entorno.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.environment.ambient_light_color = Color(0.46, 0.52, 0.54)
	entorno.environment.ambient_light_energy = 0.72
	_viewport.add_child(entorno)

	var camara := Camera3D.new()
	camara.position = Vector3(0.0, -0.05, 3.1)
	camara.fov = 36.0
	camara.current = true
	_viewport.add_child(camara)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-28.0, -24.0, 0.0)
	luz.light_energy = 1.35
	luz.shadow_enabled = true
	_viewport.add_child(luz)

	_modelos = Node3D.new()
	_modelos.name = "Cartuchos"
	_viewport.add_child(_modelos)
	_montar_ranura()


func _montar_ranura() -> void:
	var base := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(1.04, 0.16, 0.30)
	base.mesh = caja
	base.position = Vector3(0.0, -0.76, -0.02)
	base.material_override = _material(Color(0.08, 0.10, 0.105), 0.90)
	_viewport.add_child(base)

	var ranura := MeshInstance3D.new()
	var hueco := BoxMesh.new()
	hueco.size = Vector3(0.80, 0.045, 0.19)
	ranura.mesh = hueco
	ranura.position = Vector3(0.0, -0.655, 0.025)
	ranura.material_override = _material(Color(0.012, 0.015, 0.016), 0.98)
	_viewport.add_child(ranura)


func _montar_controles() -> void:
	_nombre = Label.new()
	_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nombre.custom_minimum_size = Vector2(0, 42)
	add_child(_nombre)

	var navegacion := HBoxContainer.new()
	navegacion.alignment = BoxContainer.ALIGNMENT_CENTER
	navegacion.add_theme_constant_override("separation", 8)
	add_child(navegacion)

	var anterior := Button.new()
	anterior.text = "<"
	anterior.tooltip_text = String(_app.call("_texto", "selector_anterior"))
	anterior.focus_mode = Control.FOCUS_NONE
	anterior.pressed.connect(_mover.bind(-1))
	navegacion.add_child(anterior)

	_insertar = Button.new()
	_insertar.custom_minimum_size = Vector2(220, 38)
	_insertar.pressed.connect(_insertar_actual)
	navegacion.add_child(_insertar)

	var siguiente := Button.new()
	siguiente.text = ">"
	siguiente.tooltip_text = String(_app.call("_texto", "selector_siguiente"))
	siguiente.focus_mode = Control.FOCUS_NONE
	siguiente.pressed.connect(_mover.bind(1))
	navegacion.add_child(siguiente)


func _mover(delta: int) -> void:
	if _entradas.is_empty():
		return
	_indice = posmod(_indice + delta, _entradas.size())
	_actualizar_selector()
	if _app != null and is_instance_valid(_app):
		_app.call("_reproducir_sonido_fisico", &"boton")


func _actualizar_selector() -> void:
	if _entradas.is_empty():
		return
	var entrada := _entradas[_indice]
	var titulo := _titulo(entrada)
	_nombre.text = "%d/%d · %s" % [_indice + 1, _entradas.size(), String(entrada["nombre"])]
	_insertar.text = String(_app.call("_formatear", "selector_insertar", [titulo]))
	_reconstruir_carrusel()


func _reconstruir_carrusel() -> void:
	if _modelos == null:
		return
	for hijo in _modelos.get_children():
		_modelos.remove_child(hijo)
		hijo.queue_free()
	_cartucho_central = null

	var usados: Dictionary = {}
	for desplazamiento in [-1, 0, 1]:
		var indice := posmod(_indice + desplazamiento, _entradas.size())
		if usados.has(indice):
			continue
		usados[indice] = true
		var cartucho := _crear_cartucho(_entradas[indice])
		var lateral := float(desplazamiento)
		cartucho.position = Vector3(lateral * 0.92, 0.10, -absf(lateral) * 0.20)
		cartucho.rotation_degrees.y = lateral * -18.0
		if desplazamiento != 0:
			cartucho.scale = Vector3.ONE * 0.72
		_modelos.add_child(cartucho)
		if desplazamiento == 0:
			_cartucho_central = cartucho


func _crear_cartucho(entrada: Dictionary) -> Node3D:
	var cartucho := Node3D.new()

	var cuerpo := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.72, 0.86, 0.12)
	cuerpo.mesh = caja
	cuerpo.material_override = _material(Color(0.16, 0.17, 0.18), 0.76)
	cartucho.add_child(cuerpo)

	var hombro := MeshInstance3D.new()
	var caja_hombro := BoxMesh.new()
	caja_hombro.size = Vector3(0.60, 0.08, 0.14)
	hombro.mesh = caja_hombro
	hombro.position = Vector3(0.0, 0.42, 0.0)
	hombro.material_override = _material(Color(0.12, 0.13, 0.14), 0.82)
	cartucho.add_child(hombro)

	var contactos := MeshInstance3D.new()
	var caja_contactos := BoxMesh.new()
	caja_contactos.size = Vector3(0.54, 0.055, 0.135)
	contactos.mesh = caja_contactos
	contactos.position = Vector3(0.0, -0.43, 0.0)
	contactos.material_override = _material(Color(0.67, 0.53, 0.20), 0.56)
	cartucho.add_child(contactos)

	var etiqueta := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.58, 0.50)
	etiqueta.mesh = quad
	etiqueta.position = Vector3(0.0, 0.045, 0.064)
	var material_etiqueta := StandardMaterial3D.new()
	material_etiqueta.roughness = 0.84
	material_etiqueta.cull_mode = BaseMaterial3D.CULL_DISABLED
	var ruta_etiqueta := _ruta_etiqueta(entrada)
	var tiene_arte := false
	if not ruta_etiqueta.is_empty():
		var textura := load(ruta_etiqueta)
		if textura is Texture2D:
			material_etiqueta.albedo_texture = textura
			tiene_arte = true
	if not tiene_arte:
		material_etiqueta.albedo_color = Color(0.20, 0.34, 0.32)
	etiqueta.material_override = material_etiqueta
	cartucho.add_child(etiqueta)

	if not tiene_arte:
		var rotulo := Label3D.new()
		var texto := _titulo(entrada)
		rotulo.text = texto.substr(0, mini(texto.length(), 18))
		rotulo.font_size = 28
		rotulo.pixel_size = 0.0035
		rotulo.position = Vector3(0.0, 0.045, 0.068)
		cartucho.add_child(rotulo)
	return cartucho


func _ruta_etiqueta(entrada: Dictionary) -> String:
	var id := String(entrada.get("id", ""))
	if id.is_empty():
		return ""
	var ruta := RUTA_ETIQUETAS.path_join("%s.jpg" % id)
	return ruta if ResourceLoader.exists(ruta) else ""


func _titulo(entrada: Dictionary) -> String:
	var titulo := String(entrada.get("titulo", ""))
	return titulo if not titulo.is_empty() else String(entrada.get("nombre", ""))


func _insertar_actual() -> void:
	if not _puede_interactuar():
		return
	var ruta := String(_entradas[_indice].get("ruta", ""))
	if ruta.is_empty():
		return
	_animar_insercion()
	_app.call("_cargar_rom", ruta)


func _animar_insercion() -> void:
	if _cartucho_central == null or not is_instance_valid(_cartucho_central):
		return
	if _app == null or not bool(_app.get("_efectos_presentacion")):
		return
	if _reduccion_movimiento:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	(
		tween
		. tween_property(
			_cartucho_central,
			"position",
			Vector3(0.0, -0.43, 0.08),
			DURACION_INSERCION,
		)
	)
	tween.tween_callback(_reconstruir_carrusel)


func _material(color: Color, rugosidad: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rugosidad
	return material
