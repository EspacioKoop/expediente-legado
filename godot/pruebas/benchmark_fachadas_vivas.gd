extends SceneTree

const ANCHO := 1280
const ALTO := 720
const CALENTAMIENTO := 90
const MUESTRAS := 180
const POSICION_CAMARA := Vector3(0.0, 1.65, -7.4)
const OBJETIVO_CAMARA := Vector3(-5.25, 5.8, -12.2)
const FOV_CAMARA := 68.0
const DIA_CALLE := preload("res://guion/dia_calle_app.gd")
const DIA_ARBOLES := preload("res://guion/dia_arboles_cc0_app.gd")

var _modo := "baseline"
var _salida := ""


func _initialize() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--mode="):
			_modo = argumento.trim_prefix("--mode=")
		elif argumento.begins_with("--output="):
			_salida = argumento.trim_prefix("--output=")

	if _modo not in ["baseline", "full", "ambiental_baseline", "ambiental_full"]:
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
	escena.name = "BenchmarkFachadasVivas"
	ventana.add_child(escena)

	var mundo := Node3D.new()
	mundo.name = "TrayectoBenchmark"
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
	var fachadas: Node3D = null
	if _modo in ["full", "ambiental_baseline", "ambiental_full"]:
		fachadas = CalleFachadasVivas.montar(calle)
		if fachadas == null:
			_fallar("CalleFachadasVivas no pudo montarse")
			return
		componentes.append("fachadas_vivas")

	if _modo in ["ambiental_baseline", "ambiental_full"]:
		var arboles_modelo = DIA_ARBOLES.new()
		arboles_modelo.call("_montar_arbolado", mundo)
		arboles_modelo.free()
		componentes.append("arboles_cc0")

	var camara := Camera3D.new()
	camara.name = "CamaraBenchmarkFachadas"
	camara.fov = FOV_CAMARA
	camara.position = POSICION_CAMARA
	mundo.add_child(camara)
	camara.look_at(OBJETIVO_CAMARA, Vector3.UP)
	camara.current = true

	var ventanas_vivas: CalleVentanasVivas = null
	var viento: VientoAmbiental = null
	var animador: AnimadorAmbiental3D = null
	if _modo == "ambiental_full":
		animador = AnimadorAmbiental3D.new()
		animador.name = "AnimadorAmbientalBenchmark"
		escena.add_child(animador)
		animador.observar(camara)

		ventanas_vivas = CalleVentanasVivas.new()
		ventanas_vivas.name = "VentanasVivasBenchmark"
		escena.add_child(ventanas_vivas)
		ventanas_vivas.adoptar(calle, animador)

		viento = VientoAmbiental.new()
		viento.name = "VientoAmbientalBenchmark"
		escena.add_child(viento)
		viento.adoptar(mundo, animador)
		viento.fijar_clima("lluvia")
		componentes.append("animacion_ambiental")

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

	var conteo_fachadas := {
		"grupos": 0,
		"render_batches": 0,
		"batched_instances": 0,
	}
	if fachadas != null:
		var interiores := fachadas.get_node_or_null("Interiores") as Node3D
		if interiores != null:
			conteo_fachadas["grupos"] = interiores.get_child_count()
		for nodo in fachadas.find_children("*", "MultiMeshInstance3D", true, false):
			var lote := nodo as MultiMeshInstance3D
			if lote == null or lote.multimesh == null:
				continue
			conteo_fachadas["render_batches"] += 1
			conteo_fachadas["batched_instances"] += lote.multimesh.instance_count
	conteo_fachadas["animated_windows"] = (
		ventanas_vivas.ventanas_animadas() if ventanas_vivas != null else 0
	)
	conteo_fachadas["wind_materials"] = viento.materiales() if viento != null else 0
	conteo_fachadas["active_pieces"] = int(animador.estado()["activas"]) if animador != null else 0

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
			"target": [OBJETIVO_CAMARA.x, OBJETIVO_CAMARA.y, OBJETIVO_CAMARA.z],
			"fov": camara.fov,
		},
		"components": componentes,
		"feature_counts": conteo_fachadas,
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
	print("BENCHMARK_FACHADAS_OK mode=%s report=%s" % [_modo, json_path])
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
	ambiente.name = "EntornoBenchmarkFachadas"
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
	push_error("BENCHMARK_FACHADAS_ERROR: %s" % mensaje)
	quit(1)
