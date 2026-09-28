## Evidencia visual reproducible de las equivalencias de escala de Simurgh (#658).
##
## Captura las tres anclas en escritorio y monumental con encuadres comparables.
## El manifiesto comprueba identidad semántica y framing, pero no autoaprueba que
## una persona entienda la equivalencia sin HUD.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 58.0
const FRAMES_ESTABILIZACION := 8

const CASOS := [
	{
		"id": "pluma_escritorio",
		"capa": "escritorio",
		"ancla": "pluma_puente",
		"meta_path": "CapaEscritorio/Pluma",
		"target_path": "CapaEscritorio/Pluma",
		"camara": Vector3(0.0, 2.2, 5.2),
		"mirada": Vector3(0.0, 0.35, 0.2),
	},
	{
		"id": "archivos_escritorio",
		"capa": "escritorio",
		"ancla": "archivos_montanas",
		"meta_path": "CapaEscritorio/Archivadores",
		"target_path": "CapaEscritorio/Archivadores/Archivador2",
		"camara": Vector3(0.0, 3.0, 7.0),
		"mirada": Vector3(0.0, 1.0, -2.0),
	},
	{
		"id": "lampara_escritorio",
		"capa": "escritorio",
		"ancla": "lampara_nido",
		"meta_path": "CapaEscritorio/Lampara",
		"target_path": "CapaEscritorio/Lampara",
		"camara": Vector3(8.0, 5.0, 7.0),
		"mirada": Vector3(3.7, 3.2, -1.8),
	},
	{
		"id": "pluma_monumental",
		"capa": "monumental",
		"ancla": "pluma_puente",
		"meta_path": "CapaMonumental/PasarelaPluma",
		"target_path": "CapaMonumental/PasarelaPluma",
		"camara": Vector3(0.0, 3.3, 9.0),
		"mirada": Vector3(0.0, 1.2, 0.2),
	},
	{
		"id": "archivos_monumental",
		"capa": "monumental",
		"ancla": "archivos_montanas",
		"meta_path": "CapaMonumental/CordilleraArchivos",
		"target_path": "CapaMonumental/CordilleraArchivos/Macizo3",
		"camara": Vector3(0.0, 6.0, 12.0),
		"mirada": Vector3(0.0, 3.0, -5.0),
	},
	{
		"id": "lampara_monumental",
		"capa": "monumental",
		"ancla": "lampara_nido",
		"meta_path": "CapaMonumental/NidoLuminaria",
		"target_path": "CapaMonumental/NidoLuminaria",
		"camara": Vector3(10.0, 8.0, 10.0),
		"mirada": Vector3(3.7, 6.2, -1.8),
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-simurgh-658")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	if DirAccess.make_dir_recursive_absolute(salida) != OK:
		printerr("No se pudo crear %s" % salida)
		quit(1)
		return

	root.size = TAMANO
	var mundo := _nuevo_mundo()
	var simurgh := SuenoSimurgh.new()
	simurgh.name = "SimurghEvidencia"
	mundo.add_child(simurgh)
	simurgh.preparar()
	var camara_standalone := simurgh.get_node_or_null("CamaraStandalone")
	if camara_standalone != null:
		simurgh.remove_child(camara_standalone)
		camara_standalone.free()

	var camara := Camera3D.new()
	camara.name = "CamaraRevisionSimurgh"
	camara.fov = FOV
	camara.current = true
	mundo.add_child(camara)

	var manifiesto := {
		"issue": 658,
		"hud": false,
		"veredicto_automatico": false,
		"requiere_revision_humana": true,
		"capas": SuenoSimurgh.CAPAS.duplicate(),
		"casos": [],
	}

	for caso in CASOS:
		if String(caso["capa"]) != simurgh.capa_actual():
			simurgh.cambiar_capa(true)
		if String(caso["capa"]) != simurgh.capa_actual():
			printerr("No se pudo activar capa %s" % caso["capa"])
			quit(1)
			return
		var meta := simurgh.get_node_or_null(String(caso["meta_path"])) as Node3D
		var objetivo := simurgh.get_node_or_null(String(caso["target_path"])) as Node3D
		if meta == null or objetivo == null:
			printerr("Falta ancla %s" % caso["id"])
			quit(1)
			return
		var ancla_meta := String(meta.get_meta("ancla_equivalencia", ""))
		if ancla_meta != String(caso["ancla"]):
			printerr("Metadato de equivalencia incorrecto en %s" % caso["id"])
			quit(1)
			return

		camara.position = caso["camara"]
		camara.look_at(caso["mirada"], Vector3.UP)
		for _i in FRAMES_ESTABILIZACION:
			await process_frame
		await RenderingServer.frame_post_draw
		if not camara.is_position_in_frustum(objetivo.global_position):
			printerr("Ancla fuera de encuadre: %s" % caso["id"])
			quit(1)
			return

		var archivo := "%s.png" % String(caso["id"])
		var destino := salida.path_join(archivo)
		var imagen := root.get_texture().get_image()
		if imagen == null or imagen.is_empty() or imagen.save_png(destino) != OK:
			printerr("No se pudo guardar %s" % destino)
			quit(1)
			return
		manifiesto["casos"].append(
			{
				"id": String(caso["id"]),
				"capa": String(caso["capa"]),
				"ancla": ancla_meta,
				"nodo": String(meta.name),
				"en_frustum": true,
				"pantalla": _v2(camara.unproject_position(objetivo.global_position)),
				"sha256": FileAccess.get_sha256(destino),
			}
		)

	var archivo_manifiesto := FileAccess.open(salida.path_join("manifest.json"), FileAccess.WRITE)
	if archivo_manifiesto == null:
		quit(1)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("evidencia #658 -> %s" % salida)
	quit(0)


func _nuevo_mundo() -> Node3D:
	var mundo := Node3D.new()
	mundo.name = "MundoSimurgh658"
	root.add_child(mundo)
	var entorno_nodo := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.055, 0.06, 0.07)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.60, 0.57, 0.50)
	entorno.ambient_light_energy = 0.72
	entorno_nodo.environment = entorno
	mundo.add_child(entorno_nodo)
	return mundo


func _v2(valor: Vector2) -> Array:
	return [valor.x, valor.y]
