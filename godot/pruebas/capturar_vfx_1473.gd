## Evidencia reproducible de los gates visual y de rendimiento de #1473.
##
## Recorre oficina, calle, casa y sueño sobre dia.tscn con la cámara jugable.
## Para cada fase guarda una captura con los VFX ligeros activos y otra con
## únicamente esa capa desmontada. Mide además el tiempo medio de frame en la
## misma ejecución y registra el presupuesto de partículas/superficies.
##
## Las métricas son diagnósticas: el runner compartido no representa el hardware
## del jugador y este script no emite PASS/FAIL artístico.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 8
const FRAMES_MEDICION := 45

const CASOS := [
	{"id": "oficina", "fase": "archivo", "mirada": 0.0, "inclinacion": -8.0},
	{"id": "calle", "fase": "trayecto", "mirada": 180.0, "inclinacion": -6.0},
	{"id": "casa", "fase": "casa", "mirada": 0.0, "inclinacion": -10.0},
	{
		"id": "sueno",
		"fase": "sueño",
		"escena": "crucero",
		"mirada": 0.0,
		"inclinacion": -8.0,
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-vfx-1473")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	TranslationServer.set_locale("es")
	root.size = TAMANO
	var dia = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	await process_frame

	if dia._entrada != null:
		dia._entrada.saltar()
		await process_frame
	dia.set_process(false)

	var manifiesto := {
		"issue": 1473,
		"escena": "res://escenas/dia.tscn",
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"locale": TranslationServer.get_locale(),
		"camara": "jugable",
		"renderer": String(
			ProjectSettings.get_setting("rendering/renderer/rendering_method", "desconocido")
		),
		"muestras_frames": FRAMES_MEDICION,
		"criterio": "evidencia_para_revision_humana",
		"comparacion_rendimiento": "diagnostico_misma_ejecucion_sin_umbral",
		"veredicto_automatico": false,
		"casos": [],
	}

	for caso in CASOS:
		if String(caso["fase"]) == "sueño":
			dia.jornada["sueno_escenas"] = [String(caso["escena"])]
			dia.jornada["sueno_total"] = Sueno.segundos_de_noche(dia.jornada["sueno_escenas"])
			dia.jornada["sueno_resto"] = dia.jornada["sueno_total"]

		dia._entrar_en(String(caso["fase"]))
		await process_frame
		_preparar_camara(dia, caso)
		_ocultar_hud(dia)
		await _estabilizar()

		var auditoria_activa := _auditar_vfx(dia._mundo)
		var ms_activo := await _medir_frames()
		var activo := "%s_activo.png" % String(caso["id"])
		var ruta_activa := salida.path_join(activo)
		if not await _guardar_captura(ruta_activa):
			quit(1)
			return

		_desmontar_vfx_ligeros(dia._mundo)
		await _estabilizar()
		var auditoria_inactiva := _auditar_vfx(dia._mundo)
		var ms_inactivo := await _medir_frames()
		var inactivo := "%s_inactivo.png" % String(caso["id"])
		var ruta_inactiva := salida.path_join(inactivo)
		if not await _guardar_captura(ruta_inactiva):
			quit(1)
			return

		manifiesto["casos"].append(
			{
				"id": String(caso["id"]),
				"fase": String(caso["fase"]),
				"activo": activo,
				"inactivo": inactivo,
				"sha256_activo": FileAccess.get_sha256(ruta_activa),
				"sha256_inactivo": FileAccess.get_sha256(ruta_inactiva),
				"ms_frame_activo": ms_activo,
				"ms_frame_inactivo": ms_inactivo,
				"delta_ms_frame": ms_activo - ms_inactivo,
				"particulas_vfx_activo": int(auditoria_activa["particulas"]),
				"particulas_vfx_inactivo": int(auditoria_inactiva["particulas"]),
				"emisores_vfx_activo": int(auditoria_activa["emisores"]),
				"emisores_vfx_inactivo": int(auditoria_inactiva["emisores"]),
				"superficies_vfx_activo": int(auditoria_activa["superficies"]),
				"superficies_vfx_inactivo": int(auditoria_inactiva["superficies"]),
			}
		)

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo_manifiesto == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("evidencia #1473 -> %s" % salida)
	quit(0)


func _preparar_camara(dia, caso: Dictionary) -> void:
	var entrada: Vector3 = dia._espacio_actual.get("entrada", Vector3.ZERO)
	dia._caminante.situar(entrada, float(caso["mirada"]))
	dia._caminante.set_physics_process(false)
	var camara := dia._caminante.get_node("Camara") as Camera3D
	camara.fov = FOV
	camara.rotation.x = deg_to_rad(float(caso["inclinacion"]))


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


func _estabilizar() -> void:
	for i in FRAMES_ESTABILIZACION:
		await RenderingServer.frame_post_draw


func _medir_frames() -> float:
	var inicio := Time.get_ticks_usec()
	for i in FRAMES_MEDICION:
		await RenderingServer.frame_post_draw
	var transcurrido_ms := float(Time.get_ticks_usec() - inicio) / 1000.0
	return transcurrido_ms / float(FRAMES_MEDICION)


func _guardar_captura(destino: String) -> bool:
	await RenderingServer.frame_post_draw
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Viewport vacío para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("captura -> %s" % destino)
	return true


func _auditar_vfx(mundo: Node3D) -> Dictionary:
	var particulas := 0
	var emisores := 0
	var superficies := 0
	var raiz := mundo.get_node_or_null(EfectosLigeros.NOMBRE)

	if raiz != null:
		for nodo in raiz.find_children("*", "GPUParticles3D", true, false):
			var emisor := nodo as GPUParticles3D
			if emisor != null:
				emisores += 1
				particulas += emisor.amount
		for nodo in raiz.find_children("*", "MeshInstance3D", true, false):
			if nodo is MeshInstance3D:
				superficies += 1

	for nodo in mundo.find_children(EfectosLigeros.NOMBRE_VAPOR, "GPUParticles3D", true, false):
		var vapor := nodo as GPUParticles3D
		if vapor != null:
			emisores += 1
			particulas += vapor.amount

	for cristal in mundo.find_children("CristalVista3D", "MeshInstance3D", true, false):
		if cristal.get_node_or_null("Gotas") != null:
			superficies += 1

	return {
		"particulas": particulas,
		"emisores": emisores,
		"superficies": superficies,
	}


func _desmontar_vfx_ligeros(mundo: Node3D) -> void:
	var raiz := mundo.get_node_or_null(EfectosLigeros.NOMBRE)
	if raiz != null:
		raiz.free()

	for nodo in mundo.find_children(EfectosLigeros.NOMBRE_VAPOR, "GPUParticles3D", true, false):
		nodo.free()

	for cristal in mundo.find_children("CristalVista3D", "MeshInstance3D", true, false):
		var gotas := cristal.get_node_or_null("Gotas")
		if gotas != null:
			gotas.free()
