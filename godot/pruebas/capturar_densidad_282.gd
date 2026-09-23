## Evidencia reproducible del gate de densidad 3D de #282.
##
## Renderiza las cuatro fases del recorrido real desde `dia.tscn`, con HUD
## oculto y cámara del jugador. Para no convertir un único encuadre en falso
## negativo, cada fase se captura desde el mismo spawn en tres direcciones:
## frente y laterales a ±90 grados.
##
## Además registra señales objetivas de composición: bultos declarativos
## modelados/proxy, tipos de malla e interactuables presentes.
##
## Las métricas NO deciden si el espacio "se ve terminado": una BoxMesh puede ser
## correcta para un objeto prismático y una ArrayMesh puede seguir siendo pobre.
## Sirven para revisar siempre el mismo estado junto a las capturas.
extends SceneTree

const Densidad := preload("res://guion/densidad_3d.gd")

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 2

const VISTAS := [
	{"id": "frente", "offset_mirada": 0.0},
	{"id": "izquierda", "offset_mirada": -90.0},
	{"id": "derecha", "offset_mirada": 90.0},
]

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
		else OS.get_user_data_dir().path_join("evidencia-densidad-282")
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
		"issue": 282,
		"escena": "res://escenas/dia.tscn",
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"locale": TranslationServer.get_locale(),
		"vistas_por_fase": VISTAS.size(),
		"criterio": "evidencia_para_revision_humana",
		"casos": [],
	}

	for caso in CASOS:
		if String(caso["fase"]) == "sueño":
			dia.jornada["sueno_escenas"] = [String(caso["escena"])]
		dia._entrar_en(String(caso["fase"]))
		if String(caso["fase"]) == "trayecto" and not _validar_rotulos_calle(dia):
			quit(1)
			return

		var vistas: Array[Dictionary] = []
		for vista in VISTAS:
			var mirada := _estabilizar_camara(dia, caso, vista)

			for i in FRAMES_ESTABILIZACION:
				await process_frame
			_ocultar_hud(dia)
			await RenderingServer.frame_post_draw

			var archivo := "%s_%s.png" % [String(caso["id"]), String(vista["id"])]
			var destino := salida.path_join(archivo)
			if not _guardar_captura(destino):
				quit(1)
				return
			(
				vistas
				. append(
					{
						"id": String(vista["id"]),
						"captura": archivo,
						"mirada": mirada,
						"inclinacion": float(caso["inclinacion"]),
						"sha256": FileAccess.get_sha256(destino),
					}
				)
			)

		var auditoria := Densidad.auditar(dia._espacio_actual)
		var diagnostico := _diagnostico_runtime(dia)
		(
			manifiesto["casos"]
			. append(
				{
					"id": String(caso["id"]),
					"fase": String(caso["fase"]),
					"captura": String(vistas[0]["captura"]),
					"mirada": float(vistas[0]["mirada"]),
					"inclinacion": float(caso["inclinacion"]),
					"vistas": vistas,
					"bultos_total": int(auditoria["total"]),
					"bultos_modelados": int(auditoria["modelados"]),
					"bultos_proxy": int(auditoria["proxies"]),
					"ratio_bultos_modelados": float(auditoria["ratio_modelado"]),
					"mallas_total": diagnostico["mallas_total"],
					"mallas_caja": diagnostico["mallas_caja"],
					"mallas_planas": diagnostico["mallas_planas"],
					"mallas_array": diagnostico["mallas_array"],
					"mallas_primitivas_otras": diagnostico["mallas_primitivas_otras"],
					"lotes_multimesh": diagnostico["lotes_multimesh"],
					"interactuables": diagnostico["interactuables"],
					"interactuables_habilitados": diagnostico["interactuables_habilitados"],
					"sha256": String(vistas[0]["sha256"]),
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
	print("evidencia #282 -> %s" % salida)
	quit(0)


func _estabilizar_camara(dia, caso: Dictionary, vista: Dictionary) -> float:
	var entrada: Vector3 = dia._espacio_actual["entrada"]
	var mirada := fposmod(
		float(caso["mirada"]) + float(vista["offset_mirada"]),
		360.0,
	)
	dia._caminante.situar(entrada, mirada)
	dia._caminante.set_physics_process(false)
	var camara := dia._caminante.get_node("Camara") as Camera3D
	camara.fov = FOV
	camara.rotation.x = deg_to_rad(float(caso["inclinacion"]))
	return mirada


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


func _validar_rotulos_calle(dia) -> bool:
	var calle := dia._mundo.get_node_or_null("CalleIdentidad") as Node3D
	if calle == null:
		printerr("El trayecto no monto CalleIdentidad")
		return false
	for nodo in calle.find_children("*", "Label3D", true, false):
		var rotulo := nodo as Label3D
		if rotulo != null and rotulo.text.begins_with("CALLE_"):
			printerr("Rotulo sin traducir en evidencia #282: %s" % rotulo.text)
			return false
	return true


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


func _diagnostico_runtime(dia) -> Dictionary:
	var total := 0
	var cajas := 0
	var planas := 0
	var arrays := 0
	var primitivas_otras := 0
	var multimesh := 0
	var interactuables := 0
	var interactuables_habilitados := 0

	for nodo in dia._mundo.find_children("*", "MeshInstance3D", true, false):
		var instancia := nodo as MeshInstance3D
		if instancia == null or instancia.mesh == null:
			continue
		total += 1
		if instancia.mesh is BoxMesh:
			cajas += 1
		elif instancia.mesh is PlaneMesh or instancia.mesh is QuadMesh:
			planas += 1
		elif instancia.mesh is ArrayMesh:
			arrays += 1
		else:
			primitivas_otras += 1

	for nodo in dia._mundo.find_children("*", "MultiMeshInstance3D", true, false):
		if nodo is MultiMeshInstance3D:
			multimesh += 1

	for nodo in dia._mundo.find_children("*", "Area3D", true, false):
		if nodo is Interactuable3D:
			interactuables += 1
			if nodo.habilitado:
				interactuables_habilitados += 1

	return {
		"mallas_total": total,
		"mallas_caja": cajas,
		"mallas_planas": planas,
		"mallas_array": arrays,
		"mallas_primitivas_otras": primitivas_otras,
		"lotes_multimesh": multimesh,
		"interactuables": interactuables,
		"interactuables_habilitados": interactuables_habilitados,
	}
