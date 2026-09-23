## Evidencia reproducible del último gate visual de #787.
##
## Renderiza el gato real de casa y la guía real del sueño desde la cámara
## jugable. Las capturas no autoaprueban el criterio: sirven para que una
## persona compare silueta, escala y legibilidad entre ambos contextos.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 55.0
const FRAMES_ESTABILIZACION := 4
const ALTURA_MIRADA_GATO := 0.28

const CASOS := [
	{
		"id": "casa",
		"fase": "casa",
		"camara": Vector3(2.8, 0.0, 3.35),
		"criterio": "el gato se reconoce en casa con silueta y proporciones legibles",
	},
	{
		"id": "sueno",
		"fase": "sueño",
		"escena": "crucero",
		"criterio":
		"el mismo gato se reconoce en sueño sin heredar deformación ni escala del decorado",
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-gato-787")
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
	dia.jornada["gato"]["presente"] = true
	dia.jornada["gato"]["dias_sin_comer"] = 0

	var manifiesto := {
		"issue": 787,
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
		var gato: Gato = await _montar_caso(dia, caso)
		if not is_instance_valid(gato):
			quit(1)
			return
		if not _preparar_camara(dia, gato, caso):
			quit(1)
			return

		for i in FRAMES_ESTABILIZACION:
			await process_frame
		_ocultar_hud(dia)
		await RenderingServer.frame_post_draw

		var archivo := "%s.png" % String(caso["id"])
		var destino := salida.path_join(archivo)
		if not _guardar_captura(destino):
			quit(1)
			return

		var escala := gato.global_basis.get_scale()
		var camara := dia._caminante.get_node("Camara") as Camera3D
		(
			manifiesto["casos"]
			. append(
				{
					"id": String(caso["id"]),
					"fase": String(caso["fase"]),
					"captura": archivo,
					"criterio": String(caso["criterio"]),
					"gato_top_level": gato.top_level,
					"escala_global": _vector_a_array(escala),
					"distancia_camara": camara.global_position.distance_to(gato.global_position),
					"sha256": FileAccess.get_sha256(destino),
				}
			)
		)

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo_manifiesto == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("evidencia #787 -> %s" % salida)
	quit(0)


func _montar_caso(dia, caso: Dictionary) -> Gato:
	var fase := String(caso["fase"])
	if fase == "sueño":
		var escenas := [String(caso["escena"])]
		dia.jornada["sueno_escenas"] = escenas
		dia.jornada["sueno_total"] = Sueno.segundos_de_noche(escenas)
		dia.jornada["sueno_resto"] = dia.jornada["sueno_total"]
	dia._entrar_en(fase)
	await process_frame

	var gato: Gato = dia._gato if fase == "casa" else dia._gato_guia
	if not is_instance_valid(gato):
		printerr("No se montó el gato requerido para %s" % String(caso["id"]))
		return null
	return gato


func _preparar_camara(dia, gato: Gato, caso: Dictionary) -> bool:
	var entrada: Vector3 = dia._espacio_actual.get("entrada", Vector3.ZERO)
	var posicion: Vector3 = caso.get("camara", entrada)
	dia._caminante.situar(posicion, 0.0)
	dia._caminante.set_physics_process(false)
	var camara := dia._caminante.get_node("Camara") as Camera3D
	if camara == null:
		printerr("No existe la cámara jugable")
		return false
	camara.fov = FOV
	camara.look_at(gato.global_position + Vector3(0.0, ALTURA_MIRADA_GATO, 0.0), Vector3.UP)
	return true


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


func _guardar_captura(destino: String) -> bool:
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


func _vector_a_array(vector: Vector3) -> Array:
	return [vector.x, vector.y, vector.z]
