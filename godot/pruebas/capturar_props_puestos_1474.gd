## Evidencia reproducible del gate visual de #1474.
##
## Arranca dia.tscn, entra en la oficina real, conserva la utilería que ya se
## asignó a cada puesto y retira los cuerpos de compañeros antes de capturar.
## Así la comparación responde al criterio del issue: los puestos deben poder
## distinguirse por composición incluso sin NPC.
##
## Usa la Camera3D del caminante. Las capturas y firmas de props no autoaprueban
## escala, oclusión ni calidad visual: esas decisiones siguen siendo humanas.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 58.0
const FRAMES_ESTABILIZACION := 5
const PUESTOS := ["PuestoUtileria1", "PuestoUtileria2", "PuestoUtileria3"]
const OBJETIVOS := {
	"PuestoUtileria1": Vector3(-4.0, 0.86, -2.0),
	"PuestoUtileria2": Vector3(-4.0, 0.86, 1.0),
	"PuestoUtileria3": Vector3(1.0, 0.86, -2.0),
}


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-props-1474")
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
	dia._entrar_en("archivo")
	await process_frame

	var perfiles_antes := _perfiles(dia._mundo)
	var retirados := _retirar_companeros(dia._mundo)
	await process_frame

	var camara := dia._caminante.get_node("Camara") as Camera3D
	if camara == null:
		printerr("No existe la cámara jugable")
		quit(1)
		return
	camara.fov = FOV
	dia._caminante.set_physics_process(false)
	_ocultar_hud(dia)

	var manifiesto := {
		"issue": 1474,
		"escena": "res://escenas/dia.tscn",
		"fase": "archivo",
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"locale": TranslationServer.get_locale(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"camara": "jugable",
		"hud": false,
		"companeros_retirados": retirados,
		"companeros_visibles": _contar_companeros(dia._mundo),
		"criterio": "evidencia_para_revision_humana",
		"veredicto_automatico": false,
		"puestos": [],
	}

	for i in PUESTOS.size():
		var nombre := PUESTOS[i]
		var puesto := dia._mundo.find_child(nombre, true, false) as Node3D
		if puesto == null:
			printerr("No se encontró %s" % nombre)
			quit(1)
			return

		var objetivo: Vector3 = OBJETIVOS[nombre]
		var posicion := objetivo + Vector3(0.0, 0.15, 1.35)
		dia._caminante.situar(Vector3(posicion.x, 0.0, posicion.z), 0.0)
		camara.look_at(objetivo, Vector3.UP)
		await _estabilizar()

		var archivo := "puesto-%d.png" % (i + 1)
		var destino := salida.path_join(archivo)
		if not await _guardar_captura(destino):
			quit(1)
			return

		var hijos := _firma_hijos(puesto)
		(
			manifiesto["puestos"]
			. append(
				{
					"id": nombre,
					"captura": archivo,
					"perfil_props": String(puesto.get_meta("perfil_props", "")),
					"perfil_antes_retirar_npc": String(perfiles_antes.get(nombre, "")),
					"hijos": hijos,
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
	print("evidencia #1474 -> %s" % salida)
	quit(0)


func _perfiles(mundo: Node3D) -> Dictionary:
	var perfiles := {}
	for nombre in PUESTOS:
		var puesto := mundo.find_child(nombre, true, false) as Node3D
		if puesto != null:
			perfiles[nombre] = String(puesto.get_meta("perfil_props", ""))
	return perfiles


func _retirar_companeros(mundo: Node3D) -> int:
	var retirar: Array[Node] = []
	for nodo in mundo.find_children("*", "Node3D", true, false):
		if nodo.has_meta("companero_id"):
			retirar.append(nodo)
	for nodo in retirar:
		if is_instance_valid(nodo):
			nodo.free()
	return retirar.size()


func _contar_companeros(mundo: Node3D) -> int:
	var total := 0
	for nodo in mundo.find_children("*", "Node3D", true, false):
		if nodo.has_meta("companero_id"):
			total += 1
	return total


func _firma_hijos(puesto: Node3D) -> Array[String]:
	var nombres: Array[String] = []
	for hijo in puesto.get_children():
		nombres.append(String(hijo.name))
	nombres.sort()
	return nombres


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


func _estabilizar() -> void:
	for i in FRAMES_ESTABILIZACION:
		await RenderingServer.frame_post_draw


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
