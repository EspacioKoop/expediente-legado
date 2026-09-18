## Evidencia reproducible del gate visual de materiales de #399.
##
## Renderiza las cuatro fases del recorrido real desde `dia.tscn`, con el HUD
## oculto y la cámara del jugador. Las PNG se publican como artifact de CI: no se
## versionan porque el repositorio reserva los binarios de imagen para Git LFS.
##
## Esto NO sustituye el juicio humano de legibilidad. Solo garantiza que quien
## revise #399 mira siempre cuatro encuadres reproducibles del juego real.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 24

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
		else OS.get_user_data_dir().path_join("evidencia-materiales-399")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	root.size = TAMANO
	var dia = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	await process_frame

	# La cinemática de entrada no pertenece al gate de materiales. La herramienta
	# aterriza directamente en las fases y desactiva el reloj principal para que
	# el sueño no pueda agotarse durante una captura lenta de CI.
	if dia._entrada != null:
		dia._entrada.saltar()
		await process_frame
	dia.set_process(false)

	var manifiesto := {
		"issue": 399,
		"escena": "res://escenas/dia.tscn",
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"casos": [],
	}

	for caso in CASOS:
		if String(caso["fase"]) == "sueño":
			dia.jornada["sueno_escenas"] = [String(caso["escena"])]
		dia._entrar_en(String(caso["fase"]))
		_estabilizar_camara(dia, caso)

		for i in FRAMES_ESTABILIZACION:
			await process_frame
		_ocultar_hud(dia)
		await RenderingServer.frame_post_draw

		var archivo := "%s.png" % String(caso["id"])
		var destino := salida.path_join(archivo)
		var deformacion: Vector3 = dia._espacio_actual.get("deformacion_textura", Vector3.ONE)
		var contraste := float(dia._espacio_actual.get("contraste_textura", 1.0))
		var contraste_suelo_cambia := _contraste_cambia_textura(
			String(dia._espacio_actual.get("textura_suelo", "")),
			dia._espacio_actual.get("color_suelo", Color.WHITE),
			contraste
		)
		var contraste_muro_cambia := _contraste_cambia_textura(
			String(dia._espacio_actual.get("textura_muro", "")),
			dia._espacio_actual.get("color_muro", Color.WHITE),
			contraste
		)
		var diagnostico_material := _diagnostico_materiales(dia)
		if not _guardar_captura(destino):
			quit(1)
			return

		(
			manifiesto["casos"]
			. append(
				{
					"id": String(caso["id"]),
					"fase": String(caso["fase"]),
					"captura": archivo,
					"mirada": float(caso["mirada"]),
					"inclinacion": float(caso["inclinacion"]),
					"textura_suelo": String(dia._espacio_actual.get("textura_suelo", "")),
					"textura_muro": String(dia._espacio_actual.get("textura_muro", "")),
					"escala_textura": float(dia._espacio_actual.get("escala_textura", 1.0)),
					"contraste_textura": contraste,
					"preservar_detalle_textura":
					bool(dia._espacio_actual.get("preservar_detalle_textura", false)),
					"contraste_cambia_textura_suelo": contraste_suelo_cambia,
					"contraste_cambia_textura_muro": contraste_muro_cambia,
					"materiales_psx": diagnostico_material["materiales_psx"],
					"materiales_texturados": diagnostico_material["materiales_texturados"],
					"materiales_deformados": diagnostico_material["materiales_deformados"],
					"materiales_detalle": diagnostico_material["materiales_detalle"],
					"deformacion_textura": [deformacion.x, deformacion.y, deformacion.z],
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
	print("evidencia #399 -> %s" % salida)
	quit(0)


func _estabilizar_camara(dia, caso: Dictionary) -> void:
	var entrada: Vector3 = dia._espacio_actual["entrada"]
	# El gameplay puede conservar el rumbo entre fases que no declaran `mirada`.
	# La evidencia no: cada toma necesita un encuadre fijo que enseñe el espacio,
	# no la pared que casualmente quedaba detrás del jugador en la fase anterior.
	var mirada := float(caso["mirada"])
	dia._caminante.situar(entrada, mirada)
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


func _contraste_cambia_textura(nombre: String, base: Color, contraste: float) -> bool:
	if nombre.is_empty() or is_equal_approx(contraste, 1.0):
		return false
	var normal := TexturaProcedural.por_nombre(nombre, base, hash(nombre), 1.0)
	var reforzada := TexturaProcedural.por_nombre(nombre, base, hash(nombre), contraste)
	if normal == null or reforzada == null:
		return false
	var imagen_normal := normal.get_image()
	var imagen_reforzada := reforzada.get_image()
	if imagen_normal == null or imagen_reforzada == null:
		return false
	return imagen_normal.get_data() != imagen_reforzada.get_data()


func _diagnostico_materiales(dia) -> Dictionary:
	var materiales_psx := 0
	var materiales_texturados := 0
	var materiales_deformados := 0
	var materiales_detalle := 0
	for nodo in dia.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		if malla == null:
			continue
		var material := malla.material_override as ShaderMaterial
		if material == null or material.shader == null:
			continue
		if material.shader.resource_path != "res://arte/psx.gdshader":
			continue
		materiales_psx += 1
		if not bool(material.get_shader_parameter("con_textura")):
			continue
		materiales_texturados += 1
		if bool(material.get_shader_parameter("preservar_detalle_textura")):
			materiales_detalle += 1
		var deformacion = material.get_shader_parameter("deformacion_textura")
		if deformacion is Vector3 and not (deformacion as Vector3).is_equal_approx(Vector3.ONE):
			materiales_deformados += 1
	return {
		"materiales_psx": materiales_psx,
		"materiales_texturados": materiales_texturados,
		"materiales_deformados": materiales_deformados,
		"materiales_detalle": materiales_detalle,
	}
