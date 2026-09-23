extends SceneTree

## Gate visual reproducible para #126.
##
## Construye la oficina con el catálogo y las mismas capas de dressing que usa
## el día, sin CanvasLayer/HUD. Genera dos encuadres fijos para revisar la
## lectura espacial tras cambios de mobiliario, materiales o assets.
##
## Uso:
## godot4 --path godot --script res://pruebas/capturas_oficina_126.gd -- /ruta/salida

const TAM := Vector2i(1280, 720)
const VISTAS := [
	{
		"nombre": "puestos-archivo",
		"pos": Vector3(-2.7, 1.55, 3.55),
		"objetivo": Vector3(3.6, 1.0, -0.6),
		"fov": 65.0,
	},
	{
		"nombre": "acceso-ventanas",
		# Desde el pasillo central, suficientemente lejos de los compañeros para
		# que ninguna cabeza tape el acceso, el café o las ventanas.
		"pos": Vector3(0.0, 1.60, -3.80),
		"objetivo": Vector3(-2.8, 1.30, 4.20),
		"fov": 76.0,
	},
]

var _viewport: SubViewport
var _mundo: Node3D
var _camara: Camera3D
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
	for _i in range(8):
		await process_frame

	for vista in VISTAS:
		await _capturar(vista as Dictionary)

	_guardar_manifest()
	print("Gate visual #126: %d capturas, %d fallos -> %s" % [VISTAS.size(), _fallos, _salida])
	quit(1 if _fallos else 0)


func _resolver_salida() -> String:
	var argumentos := OS.get_cmdline_user_args()
	if not argumentos.is_empty():
		return String(argumentos[0])
	return ProjectSettings.globalize_path("user://capturas-oficina-126")


func _montar_oficina() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "CapturaOficina126"
	_viewport.size = TAM
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	root.add_child(_viewport)

	_mundo = Node3D.new()
	_mundo.name = "OficinaGate126"
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

	_camara = Camera3D.new()
	_camara.name = "CamaraGate126"
	_camara.current = true
	_camara.near = 0.05
	_camara.far = 40.0
	_mundo.add_child(_camara)


func _plantilla_visual() -> Array:
	var figuras := []
	var quienes := Companeros.plantilla(126)
	var sitios: Array = EspaciosCatalogo.OFICINA.get("sitios_companeros", [])
	for i in mini(quienes.size(), sitios.size()):
		var quien: Dictionary = quienes[i]
		(
			figuras
			. append(
				{
					"pos": sitios[i],
					"color": quien.get("color", Color(0.3, 0.3, 0.3)),
					"modelo": Companeros.cuerpo_de(quien),
					"retrato": quien.get("retrato", ""),
					"rotulo": "",
					"frase": "",
				}
			)
		)
	return figuras


func _capturar(vista: Dictionary) -> void:
	_camara.fov = float(vista["fov"])
	_camara.position = vista["pos"]
	_camara.look_at(vista["objetivo"], Vector3.UP)

	for _i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw

	var imagen := _viewport.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		_fallar("viewport vacío para %s" % String(vista["nombre"]))
		return

	var nombre := "%s.png" % String(vista["nombre"])
	var ruta := _salida.path_join(nombre)
	var error_png := imagen.save_png(ruta)
	if error_png != OK:
		_fallar("no se pudo guardar %s: %s" % [ruta, error_png])


func _guardar_manifest() -> void:
	var ruta := _salida.path_join("README.md")
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		_fallar("no se pudo escribir %s" % ruta)
		return
	var commit_sha := OS.get_environment("GITHUB_SHA").strip_edges()
	if commit_sha.is_empty():
		commit_sha = "no-disponible"
	var styloo_activo := _mundo.has_meta("oficina_styloo_cc0")
	var renderer := RenderingServer.get_current_rendering_method()
	(
		archivo
		. store_string(
			("""# Gate visual de oficina #126

Capturas deterministas del espacio real sin HUD.

- commit SHA: `%s`
- Styloo administrativo activo: **%s**
- renderer: `%s`
- `puestos-archivo.png`: puestos, mesa de clasificación y batería de archivo.
- `acceso-ventanas.png`: acceso, café y ventanas nocturnas.

La revisión humana debe comprobar que el lugar se reconoce como oficina/archivo
habitado y funcional sin depender de rótulos. El playtest final debe usar una
build cuyo SHA coincida con el commit de este artifact.
"""
				% [commit_sha, "sí" if styloo_activo else "no", renderer]
			)
		)
	)
	archivo.close()

func _fallar(mensaje: String) -> void:
	_fallos += 1
	push_error("Gate visual #126: %s" % mensaje)
