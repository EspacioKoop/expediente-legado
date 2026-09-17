extends SceneTree

const ANCHO := 1280
const ALTO := 720
const FOV_CAMARA := 68.0
const FRAMES_ESTABILIZACION := 12
const DIA_CALLE := preload("res://guion/dia_calle_app.gd")
const ESTACIONES := [
	{
		"id": "cerca",
		"position": Vector3(0.0, 1.65, -12.0),
		"target": Vector3(-5.2, 5.8, -12.5),
	},
	{
		"id": "media",
		"position": Vector3(0.0, 1.65, 5.5),
		"target": Vector3(-5.2, 5.8, -12.5),
	},
	{
		"id": "lejos",
		"position": Vector3(0.0, 1.65, 14.5),
		"target": Vector3(-5.2, 5.8, -12.5),
	},
]

var _modo := "baseline"
var _salida := ""


func _initialize() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--mode="):
			_modo = argumento.trim_prefix("--mode=")
		elif argumento.begins_with("--output="):
			_salida = argumento.trim_prefix("--output=")

	if _modo not in ["baseline", "full"]:
		_fallar("modo inválido: %s" % _modo)
		return
	if _salida.is_empty():
		_fallar("falta --output=<directorio>")
		return
	DirAccess.make_dir_recursive_absolute(_salida)
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var ventana := get_root()
	ventana.size = Vector2i(ANCHO, ALTO)

	var escena := Node.new()
	escena.name = "CapturaRutaFachadasVivas"
	ventana.add_child(escena)

	var mundo := Node3D.new()
	mundo.name = "TrayectoCaptura"
	escena.add_child(mundo)

	var dia_modelo = DIA_CALLE.new()
	var espacio: Dictionary = dia_modelo.call("_espacio_de", "trayecto")
	dia_modelo.free()
	Espacio3D.construir(mundo, espacio)
	_montar_iluminacion(mundo, espacio)

	var calle := CalleIdentidad.montar(mundo)
	if calle == null:
		_fallar("CalleIdentidad no pudo montarse")
		return
	var componentes := ["trayecto", "calle_identidad"]
	if _modo == "full":
		var fachadas := CalleFachadasVivas.montar(calle)
		if fachadas == null:
			_fallar("CalleFachadasVivas no pudo montarse")
			return
		componentes.append("fachadas_vivas")

	var camara := Camera3D.new()
	camara.name = "CamaraRutaFachadas"
	camara.fov = FOV_CAMARA
	mundo.add_child(camara)
	camara.current = true

	var capturas := []
	for estacion in ESTACIONES:
		var id := String(estacion["id"])
		var posicion: Vector3 = estacion["position"]
		var objetivo: Vector3 = estacion["target"]
		camara.position = posicion
		camara.look_at(objetivo, Vector3.UP)
		for _i in FRAMES_ESTABILIZACION:
			await process_frame

		var nombre_png := "%s-ruta-%s.png" % [_modo, id]
		var png := _salida.path_join(nombre_png)
		var imagen := ventana.get_texture().get_image()
		var error_png := imagen.save_png(png)
		if error_png != OK:
			_fallar("no se pudo guardar %s (error %d)" % [png, error_png])
			return
		(
			capturas
			. append(
				{
					"id": id,
					"position": [posicion.x, posicion.y, posicion.z],
					"target": [objetivo.x, objetivo.y, objetivo.z],
					"distance_m": posicion.distance_to(objetivo),
					"screenshot": nombre_png,
				}
			)
		)

	var manifiesto := {
		"schema": 1,
		"mode": _modo,
		"resolution": [ANCHO, ALTO],
		"fov": FOV_CAMARA,
		"stabilization_frames": FRAMES_ESTABILIZACION,
		"components": componentes,
		"stations": capturas,
	}
	var json_path := _salida.path_join("%s-ruta.json" % _modo)
	var archivo := FileAccess.open(json_path, FileAccess.WRITE)
	if archivo == null:
		_fallar("no se pudo escribir %s" % json_path)
		return
	archivo.store_string(JSON.stringify(manifiesto, "  ") + "\n")
	archivo.close()
	print("CAPTURA_FACHADAS_RUTA_OK mode=%s report=%s" % [_modo, json_path])
	quit(0)


func _montar_iluminacion(mundo: Node3D, espacio: Dictionary) -> void:
	var ambiente := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.035, 0.055, 0.10)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = espacio.get("ambiente", Color(0.16, 0.17, 0.22))
	entorno.ambient_light_energy = float(espacio.get("ambiente_energia", 0.35))
	ambiente.environment = entorno
	ambiente.name = "EntornoCapturaFachadas"
	mundo.add_child(ambiente)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sol.light_energy = float(espacio.get("sol", 0.08))
	sol.shadow_enabled = false
	mundo.add_child(sol)

	for datos_luz in espacio.get("luces", []):
		var luz := OmniLight3D.new()
		luz.position = datos_luz.get("pos", Vector3.ZERO)
		luz.light_color = datos_luz.get("color", Color.WHITE)
		luz.light_energy = float(datos_luz.get("energia", 1.0))
		luz.omni_range = float(datos_luz.get("alcance", 8.0))
		luz.shadow_enabled = false
		mundo.add_child(luz)


func _fallar(mensaje: String) -> void:
	push_error("CAPTURA_FACHADAS_RUTA_ERROR: %s" % mensaje)
	quit(1)
