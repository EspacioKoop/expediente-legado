## Evidencia reproducible del gate visual de #673.
##
## Captura el portal real en dos jornadas deterministas usando dia.tscn y la
## camara jugable. No autoaprueba el gate humano: solo fija encuadres comparables
## para revisar escala, legibilidad y convivencia con la arquitectura de calle.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 58.0
const FRAMES_ESTABILIZACION := 4

const CASOS := [
	{
		"id": "manuela",
		"dia": 7,
		"camara": Vector3(0.0, 0.0, 10.4),
		"mirada": Vector3(-0.35, 1.0, 14.75),
		"objetivos": ["Manuela3B", "TablonComunidad", "FelpudoPortal"],
		"criterio": "Manuela, tablon y felpudo se leen a escala de portal desde camara jugable",
	},
	{
		"id": "repartidor",
		"dia": 8,
		"camara": Vector3(0.0, 0.0, 10.4),
		"mirada": Vector3(0.45, 0.9, 14.75),
		"objetivos": ["RepartidorConfundido", "PaqueteEquivocado", "TablonComunidad"],
		"criterio": "repartidor, paquete y tablon conviven sin tapar recorrido ni senaletica",
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-vecinos-673")
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
	var manifiesto := {
		"issue": 673,
		"escena": "res://escenas/dia.tscn",
		"locale": TranslationServer.get_locale(),
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"camara": "jugable",
		"criterio": "evidencia_para_revision_humana",
		"veredicto_automatico": false,
		"casos": [],
	}

	for caso in CASOS:
		var resultado := await _capturar_caso(caso, salida)
		if not bool(resultado.get("ok", false)):
			quit(1)
			return
		manifiesto["casos"].append(resultado["caso"])

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo_manifiesto == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("evidencia #673 -> %s" % salida)
	quit(0)


func _capturar_caso(caso: Dictionary, salida: String) -> Dictionary:
	var dia = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	await process_frame
	if dia._entrada != null:
		dia._entrada.saltar()
		await process_frame

	dia.jornada["dia"] = int(caso["dia"])
	dia._entrar_en("trayecto")
	await process_frame
	var controller := dia.get_node_or_null("VecinosEdificioController")
	if controller != null and controller.has_method("_process"):
		controller._process(0.0)
	await process_frame

	var vecinos := dia._mundo.get_node_or_null(VecinosEdificio3D.NOMBRE_RAIZ)
	if vecinos == null:
		printerr("No se monto VecinosEdificio3D en dia %d" % int(caso["dia"]))
		dia.queue_free()
		await process_frame
		return {"ok": false}

	var camara := dia._caminante.get_node("Camara") as Camera3D
	if camara == null:
		printerr("No existe la camara jugable")
		dia.queue_free()
		await process_frame
		return {"ok": false}

	dia._caminante.situar(caso["camara"], 0.0)
	dia._caminante.set_physics_process(false)
	camara.fov = FOV
	camara.look_at(caso["mirada"], Vector3.UP)
	_ocultar_hud(dia)

	for i in FRAMES_ESTABILIZACION:
		await process_frame

	var objetivos := {}
	for nombre in caso["objetivos"]:
		var nodo := vecinos.get_node_or_null(String(nombre))
		if nodo == null:
			printerr("Falta objetivo %s en caso %s" % [nombre, caso["id"]])
			dia.queue_free()
			await process_frame
			return {"ok": false}
		objetivos[String(nombre)] = {
			"en_frustum": camara.is_position_in_frustum(nodo.global_position),
			"distancia_camara": camara.global_position.distance_to(nodo.global_position),
			"pantalla": _vector2_a_array(camara.unproject_position(nodo.global_position)),
		}

	await RenderingServer.frame_post_draw
	var archivo := "%s.png" % String(caso["id"])
	var destino := salida.path_join(archivo)
	if not _guardar_captura(destino):
		dia.queue_free()
		await process_frame
		return {"ok": false}

	var ids: Array = vecinos.get_meta("presencias_ids", [])
	var salida_caso := {
		"id": String(caso["id"]),
		"dia": int(caso["dia"]),
		"captura": archivo,
		"criterio": String(caso["criterio"]),
		"presencias_ids": ids,
		"objetivos": objetivos,
		"sha256": FileAccess.get_sha256(destino),
	}
	dia.queue_free()
	await process_frame
	return {"ok": true, "caso": salida_caso}


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


func _guardar_captura(destino: String) -> bool:
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Viewport vacio para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("captura -> %s" % destino)
	return true


func _vector2_a_array(vector: Vector2) -> Array:
	return [vector.x, vector.y]
