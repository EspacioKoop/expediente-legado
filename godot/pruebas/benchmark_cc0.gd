extends SceneTree

const ANCHO := 1280
const ALTO := 720
const CALENTAMIENTO := 90
const MUESTRAS := 180
const DIA_RAIZ := preload("res://guion/dia_clima_app.gd")
const DRESSING_CC0 := preload("res://guion/dia_dressing_cc0_app.gd")
const RETRO_URBAN := preload("res://guion/dia_retro_urban_app.gd")
const SKYLINE_CC0 := preload("res://guion/dia_skyline_cc0_app.gd")
const NATURALEZA_CC0 := preload("res://guion/dia_naturaleza_cc0_app.gd")
const CIELO_SIGA := preload("res://arte/cielo_siga.tres")
const MALLA_VAGON := preload("res://assets/cc0/quaternius_modular_train/CargoTrain_WagonEmpty.obj")
const MALLA_VIA := preload("res://assets/cc0/quaternius_modular_train/RailwayTrack_Straight.obj")


class DiaHarness:
	extends Node
	var jornada := {"fase": "trayecto"}
	var _mundo: Node3D


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
	escena.name = "BenchmarkCC0"
	ventana.add_child(escena)

	var mundo := Node3D.new()
	mundo.name = "TrayectoBenchmark"
	escena.add_child(mundo)

	var dia_modelo = DIA_RAIZ.new()
	var espacio: Dictionary = dia_modelo.call("_espacio_de", "trayecto")
	dia_modelo.free()
	Espacio3D.construir(mundo, espacio)
	_montar_iluminacion(mundo, espacio)

	var componentes := ["trayecto"]
	if _modo == "full":
		_montar_cielo(mundo)
		_montar_tren(mundo)
		componentes.append_array(["cielo_cc0", "tren_cc0"])
		var dia := DiaHarness.new()
		dia.name = "DiaHarness"
		dia._mundo = mundo
		escena.add_child(dia)
		for controlador_script in [DRESSING_CC0, RETRO_URBAN, SKYLINE_CC0, NATURALEZA_CC0]:
			var controlador = controlador_script.new()
			dia.add_child(controlador)
		componentes.append_array(["dressing_cc0", "retro_urban", "skyline_cc0", "naturaleza_cc0"])

	var camara := Camera3D.new()
	camara.name = "CamaraBenchmark"
	camara.fov = 68.0
	camara.position = Vector3(0.0, 2.0, -14.0)
	mundo.add_child(camara)
	camara.look_at(Vector3(0.0, 1.25, 5.0), Vector3.UP)
	camara.current = true

	for _i in CALENTAMIENTO:
		await process_frame

	var acumulado := {
		"draw_calls": 0.0,
		"objects": 0.0,
		"primitives": 0.0,
		"process_ms": 0.0,
		"static_memory_bytes": 0.0,
	}
	var maximos := acumulado.duplicate(true)
	for _i in MUESTRAS:
		await process_frame
		var muestra := _leer_metricas()
		for clave in acumulado:
			var valor := float(muestra[clave])
			acumulado[clave] += valor
			maximos[clave] = max(float(maximos[clave]), valor)

	var promedios := {}
	for clave in acumulado:
		promedios[clave] = float(acumulado[clave]) / float(MUESTRAS)

	var png := _salida.path_join("%s.png" % _modo)
	var imagen := ventana.get_texture().get_image()
	var error_png := imagen.save_png(png)
	if error_png != OK:
		_fallar("no se pudo guardar %s (error %d)" % [png, error_png])
		return

	var informe := {
		"schema": 1,
		"mode": _modo,
		"resolution": [ANCHO, ALTO],
		"warmup_frames": CALENTAMIENTO,
		"sample_frames": MUESTRAS,
		"rendering_method":
		ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"),
		"camera":
		{
			"position": [camara.position.x, camara.position.y, camara.position.z],
			"target": [0.0, 1.25, 5.0],
			"fov": camara.fov,
		},
		"components": componentes,
		"metrics_avg": promedios,
		"metrics_max": maximos,
		"gpu_frame_ms": null,
		"gpu_frame_ms_note":
		"N/D: Godot Performance no expone un tiempo GPU portable para este runner.",
		"screenshot": png.get_file(),
	}
	var json_path := _salida.path_join("%s.json" % _modo)
	var archivo := FileAccess.open(json_path, FileAccess.WRITE)
	if archivo == null:
		_fallar("no se pudo escribir %s" % json_path)
		return
	archivo.store_string(JSON.stringify(informe, "  ") + "\n")
	archivo.close()
	print("BENCHMARK_CC0_OK mode=%s report=%s" % [_modo, json_path])
	quit(0)


func _leer_metricas() -> Dictionary:
	return {
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
	}


func _montar_iluminacion(mundo: Node3D, espacio: Dictionary) -> void:
	var ambiente := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.035, 0.055, 0.10)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = espacio.get("ambiente", Color(0.16, 0.17, 0.22))
	entorno.ambient_light_energy = float(espacio.get("ambiente_energia", 0.35))
	ambiente.environment = entorno
	ambiente.name = "EntornoBenchmark"
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


func _montar_cielo(mundo: Node3D) -> void:
	var entorno_nodo := mundo.get_node_or_null("EntornoBenchmark") as WorldEnvironment
	if entorno_nodo == null or entorno_nodo.environment == null:
		return
	var cielo := Sky.new()
	cielo.process_mode = Sky.PROCESS_MODE_QUALITY
	cielo.radiance_size = Sky.RADIANCE_SIZE_64
	cielo.sky_material = CIELO_SIGA.duplicate()
	entorno_nodo.environment.background_mode = Environment.BG_SKY
	entorno_nodo.environment.sky = cielo


func _montar_tren(mundo: Node3D) -> void:
	var raiz := Node3D.new()
	raiz.name = "TrenFondoCC0"
	raiz.position = Vector3(7.2, 2.9, 0.0)
	raiz.rotation_degrees.y = 90.0
	mundo.add_child(raiz)

	var material_via := StandardMaterial3D.new()
	material_via.albedo_color = Color(0.16, 0.15, 0.14)
	material_via.roughness = 0.9
	var material_vagon := StandardMaterial3D.new()
	material_vagon.albedo_color = Color(0.20, 0.19, 0.17)
	material_vagon.roughness = 0.85

	for desplazamiento in [-9.0, 9.0]:
		var via := MeshInstance3D.new()
		via.mesh = MALLA_VIA
		via.position.x = desplazamiento
		via.material_override = material_via
		via.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(via)
	for desplazamiento in [-5.0, 4.2]:
		var vagon := MeshInstance3D.new()
		vagon.mesh = MALLA_VAGON
		vagon.position = Vector3(desplazamiento, 0.14, 0.0)
		vagon.material_override = material_vagon
		vagon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(vagon)


func _fallar(mensaje: String) -> void:
	push_error("BENCHMARK_CC0_ERROR: %s" % mensaje)
	quit(1)
