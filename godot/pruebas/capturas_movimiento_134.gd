extends SceneTree

## Evidencia visual reproducible para #134.
##
## Monta la oficina real, conecta los mismos idles de compañeros que usa la
## jornada y captura el mismo encuadre en dos momentos distintos. El segundo
## momento adelanta la respiración/actividad y coloca un actor invisible delante
## de la única figura con atención selectiva.
##
## Uso:
## godot4 --path godot --script res://pruebas/capturas_movimiento_134.gd -- /ruta/salida

const TAM := Vector2i(1280, 720)
const POS_CAMARA := Vector3(-2.7, 1.55, 3.55)
const OBJETIVO_CAMARA := Vector3(3.6, 1.0, -0.6)
const FOV := 65.0
const PASO_MOMENTO := 1.0
const ANGULO_ACTOR := deg_to_rad(35.0)
const DISTANCIA_ACTOR := 2.0

var _viewport: SubViewport
var _mundo: Node3D
var _camara: Camera3D
var _actor: Node3D
var _idles: Array[CompaneroIdle3D] = []
var _idle_atencion: CompaneroIdle3D
var _salida := ""
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_salida = _resolver_salida()
	var error_dir := DirAccess.make_dir_recursive_absolute(_salida)
	if error_dir != OK:
		_fallar("no se puede crear %s: %s" % [_salida, error_dir])
		quit(1)
		return

	_montar_oficina()
	_montar_idles()
	_configurar_camara()

	for _i in range(8):
		await process_frame

	var momento_a := await _capturar("momento-a")
	var rotacion_antes := _rotacion_atencion()

	_colocar_actor_atencion()
	_avanzar_idles(PASO_MOMENTO)

	for _i in range(4):
		await process_frame

	var rotacion_despues := _rotacion_atencion()
	var giro := absf(wrapf(rotacion_despues - rotacion_antes, -PI, PI))
	if giro < deg_to_rad(5.0):
		_fallar("la figura de atención no produjo un giro visual suficiente")

	var momento_b := await _capturar("momento-b")
	if momento_a != null and momento_b != null and momento_a.get_data() == momento_b.get_data():
		_fallar("las dos capturas son idénticas")

	_guardar_manifest(giro)
	print("Gate visual #134: 2 capturas, %d fallos -> %s" % [_fallos, _salida])
	quit(1 if _fallos else 0)


func _resolver_salida() -> String:
	var argumentos := OS.get_cmdline_user_args()
	if not argumentos.is_empty():
		return String(argumentos[0])
	return ProjectSettings.globalize_path("user://capturas-movimiento-134")


func _montar_oficina() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "CapturaMovimiento134"
	_viewport.size = TAM
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	root.add_child(_viewport)

	_mundo = Node3D.new()
	_mundo.name = "OficinaMovimiento134"
	_viewport.add_child(_mundo)

	var entorno := WorldEnvironment.new()
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.05, 0.05, 0.06)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = EspaciosCatalogo.OFICINA.get("ambiente", Color(0.42, 0.43, 0.45))
	ambiente.ambient_light_energy = EspaciosCatalogo.OFICINA.get("ambiente_energia", 0.55)
	entorno.environment = ambiente
	_mundo.add_child(entorno)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_energy = EspaciosCatalogo.OFICINA.get("sol", 0.25)
	_mundo.add_child(sol)

	var espacio := EspaciosCatalogo.OFICINA.duplicate(true)
	espacio["figuras"] = _plantilla_visual()
	Espacio3D.construir(_mundo, espacio)

	var dressing_script := load("res://guion/dia_dressing_cc0_app.gd")
	var dressing = dressing_script.new()
	dressing.call("_vestir_archivo_cc0", _mundo)
	dressing.free()

	OficinaUtileria.montar(_mundo)
	OficinaAssetsCc0.montar(_mundo)
	PostersOficina.montar(_mundo)
	CuadrosOficina.montar(_mundo)

	_actor = Node3D.new()
	_actor.name = "ActorAtencionInvisible"
	_actor.position = Vector3(50.0, 0.0, 50.0)
	_mundo.add_child(_actor)


func _plantilla_visual() -> Array:
	var figuras := []
	var quienes := Companeros.plantilla(134)
	var sitios: Array = EspaciosCatalogo.OFICINA.get("sitios_companeros", [])
	for i in mini(quienes.size(), sitios.size()):
		var quien: Dictionary = quienes[i]
		figuras.append(
			{
				"pos": sitios[i],
				"color": quien.get("color", Color(0.3, 0.3, 0.3)),
				"modelo": Companeros.cuerpo_de(quien),
				"retrato": quien.get("retrato", ""),
				"rotulo": "",
				"frase": "",
			}
		)
	return figuras


func _montar_idles() -> void:
	var sitios: Array = EspaciosCatalogo.OFICINA.get("sitios_companeros", [])
	for indice in sitios.size():
		var cuerpo := _cuerpo_en(sitios[indice])
		if cuerpo == null:
			continue
		var idle := CompaneroIdle3D.new()
		idle.name = "IdleCompanero%d" % (indice + 1)
		_mundo.add_child(idle)

		var semilla := hash("companero-%d" % indice)
		var telefono := indice == 0
		var trabajo := indice > 0 and indice % 2 == 1
		var brazos := indice > 0 and not trabajo
		var en_silla := trabajo
		var atencion := indice > 0 and indice == sitios.size() - 1
		idle.configurar(
			cuerpo, semilla, telefono, false, trabajo, brazos, en_silla, atencion, _actor
		)
		idle.set_process(false)
		_idles.append(idle)
		if atencion:
			_idle_atencion = idle

	if _idles.is_empty():
		_fallar("no se encontraron compañeros animables")
	if not is_instance_valid(_idle_atencion):
		_fallar("no se encontró la figura de atención selectiva")


func _cuerpo_en(posicion: Vector3) -> Node3D:
	for hijo in _mundo.get_children():
		if not hijo is Node3D:
			continue
		var nodo := hijo as Node3D
		if nodo.position.distance_to(posicion) < 0.02 and Modelos._esqueleto(nodo) != null:
			return nodo
	return null


func _configurar_camara() -> void:
	_camara = Camera3D.new()
	_camara.name = "CamaraMovimiento134"
	_camara.current = true
	_camara.near = 0.05
	_camara.far = 40.0
	_camara.fov = FOV
	_camara.position = POS_CAMARA
	_mundo.add_child(_camara)
	_camara.look_at(OBJETIVO_CAMARA, Vector3.UP)


func _colocar_actor_atencion() -> void:
	if not is_instance_valid(_idle_atencion) or not is_instance_valid(_idle_atencion.objetivo):
		return
	var cuerpo := _idle_atencion.objetivo
	var angulo := cuerpo.rotation.y + ANGULO_ACTOR
	var direccion := Vector3(-sin(angulo), 0.0, -cos(angulo))
	_actor.position = cuerpo.position + direccion * DISTANCIA_ACTOR


func _avanzar_idles(delta: float) -> void:
	for idle in _idles:
		if is_instance_valid(idle):
			idle._process(delta)


func _rotacion_atencion() -> float:
	if not is_instance_valid(_idle_atencion) or not is_instance_valid(_idle_atencion.objetivo):
		return 0.0
	return _idle_atencion.objetivo.rotation.y


func _capturar(nombre: String) -> Image:
	await RenderingServer.frame_post_draw
	var imagen := _viewport.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		_fallar("viewport vacío para %s" % nombre)
		return null

	var ruta := _salida.path_join("%s.png" % nombre)
	var error_png := imagen.save_png(ruta)
	if error_png != OK:
		_fallar("no se pudo guardar %s: %s" % [ruta, error_png])
	return imagen


func _guardar_manifest(giro: float) -> void:
	var ruta := _salida.path_join("README.md")
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		_fallar("no se pudo escribir %s" % ruta)
		return
	archivo.store_string(
		"""# Gate visual de movimiento #134

Dos capturas del mismo encuadre de la oficina real:

- momento-a.png: estado inicial de los compañeros.
- momento-b.png: un segundo lógico después, con respiración/actividad avanzada
  y el actor invisible dentro del cono de atención de una única figura.

El gate falla si ambas imágenes son byte a byte idénticas o si la figura
seleccionada no gira al menos 5 grados. Giro observado: %.2f grados.

La revisión humana debe confirmar que el movimiento se lee como presencia
ambiental y no como vigilancia colectiva, y que el gesto del teléfono sigue
siendo distinguible.
"""
		% rad_to_deg(giro)
	)
	archivo.close()


func _fallar(mensaje: String) -> void:
	_fallos += 1
	push_error("Gate visual #134: %s" % mensaje)
