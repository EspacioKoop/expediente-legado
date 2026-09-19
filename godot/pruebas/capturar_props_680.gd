## Evidencia reproducible de los dos props funcionales de #680.
##
## Renderiza el recorrido real de `dia.tscn`: pickups domésticos, persiana
## antes/después de usar la palanca y bombilla fundida sin/con linterna.
## El manifiesto mide exclusivamente el coste incremental de estos props.
extends SceneTree

const Props := preload("res://guion/props_utilizables_cc0.gd")

const TAMANO := Vector2i(1280, 720)
const FOV := 68.0
const FRAMES_ESTABILIZACION := 3
const MAX_TRIANGULOS_PROPS := 2000
const MAX_MALLAS_PROPS := 12
const MAX_SUPERFICIES_PROPS := 16
const MAX_LUCES_DINAMICAS := 1

const CAPTURAS := [
	"pickups_casa.png",
	"persiana_atascada.png",
	"persiana_reparada.png",
	"luz_reducida_sin_linterna.png",
	"luz_reducida_con_linterna.png",
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-props-680")
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

	var detector: Node = dia._caminante.find_child("DetectorInteraccion3D", true, false)
	if detector != null:
		detector.set_physics_process(false)
	dia._entrar_en("casa")
	dia._caminante.set_physics_process(false)
	_ocultar_hud(dia)

	var manifiesto := {
		"issue": 680,
		"escena": "res://escenas/dia.tscn",
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"criterio": "evidencia_reproducible_no_sustituye_revision_humana",
		"archivos": CAPTURAS.duplicate(),
		"presupuesto":
		{
			"triangulos_props_max": MAX_TRIANGULOS_PROPS,
			"mallas_props_max": MAX_MALLAS_PROPS,
			"superficies_props_max": MAX_SUPERFICIES_PROPS,
			"luces_dinamicas_max": MAX_LUCES_DINAMICAS,
			"sombras_luz_portatil_max": 0,
		},
		"capturas": [],
	}

	var inventario := Inventario.nuevo()
	_configurar_estado(dia, inventario, [])
	await _estabilizar()
	_enfocar(dia, "AlmacenamientoCasa", Vector3(0.0, 0.35, -1.45), Vector3(0.0, 0.98, 0.0))
	await _estabilizar()
	var metricas_props := _metricas_props(dia)
	if not _props_en_encuadre(dia):
		printerr("Los dos pickups de #680 no quedan dentro del encuadre de evidencia")
		quit(1)
		return
	_registrar_captura(
		manifiesto,
		salida,
		"pickups_casa",
		"pickups_casa.png",
		{
			"props": metricas_props,
			"ids_visibles": _ids_props_visibles(dia),
		}
	)

	inventario = Inventario.nuevo()
	Inventario.recoger(inventario, Props.objeto_inventario("palanca_kkryy"))
	_configurar_estado(dia, inventario, ["casa_persiana_atascada"])
	await _estabilizar()
	_enfocar(dia, "VentanaCasa", Vector3(1.45, 0.25, 1.55), Vector3.UP * 0.10)
	await _estabilizar()
	_registrar_captura(
		manifiesto,
		salida,
		"persiana_atascada",
		"persiana_atascada.png",
		{
			"consecuencia": "casa_persiana_atascada",
			"herramienta": "palanca_kkryy",
			"reparada": false,
		}
	)

	var persiana := (
		dia._mundo.get_node_or_null("ConsecuenciasCasa/PersianaAtascada") as PersianaAtascada3D
	)
	if persiana == null or not persiana.interactuar(dia._caminante):
		printerr("No se pudo ejecutar el recorrido real de la palanca")
		quit(1)
		return
	await _estabilizar()
	_registrar_captura(
		manifiesto,
		salida,
		"persiana_reparada",
		"persiana_reparada.png",
		{
			"consecuencia": "casa_persiana_atascada",
			"herramienta": "palanca_kkryy",
			"reparada": true,
			"consecuencia_presente":
			Imprevistos.consecuencias(dia.jornada).has("casa_persiana_atascada"),
		}
	)

	inventario = Inventario.nuevo()
	_configurar_estado(dia, inventario, ["casa_luz_reducida"])
	await _estabilizar()
	_enfocar(dia, "LamparaPieCasa", Vector3(1.60, 0.55, -1.50), Vector3.UP * 0.45)
	await _estabilizar()
	_registrar_captura(
		manifiesto,
		salida,
		"luz_reducida_sin_linterna",
		"luz_reducida_sin_linterna.png",
		{
			"consecuencia": "casa_luz_reducida",
			"linterna_carried": false,
			"luces_680": _metricas_luz_680(dia),
		}
	)

	Inventario.recoger(inventario, Props.objeto_inventario("linterna_kkryy"))
	await _estabilizar()
	_registrar_captura(
		manifiesto,
		salida,
		"luz_reducida_con_linterna",
		"luz_reducida_con_linterna.png",
		{
			"consecuencia": "casa_luz_reducida",
			"linterna_carried": true,
			"luces_680": _metricas_luz_680(dia),
		}
	)

	manifiesto["presupuesto_cumplido"] = _presupuesto_cumplido(
		metricas_props, _metricas_luz_680(dia)
	)
	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo.close()
	print(
		(
			"evidencia #680 -> %s | %d triángulos | presupuesto=%s"
			% [
				salida,
				int(metricas_props["triangulos"]),
				str(bool(manifiesto["presupuesto_cumplido"])),
			]
		)
	)
	quit(0)


func _configurar_estado(dia, inventario: Dictionary, consecuencias: Array) -> void:
	dia.partida.estado["inventario"] = inventario
	dia.jornada[Imprevistos.CLAVE_ESTADO] = {
		"version": Imprevistos.VERSION,
		"raiz_plan": int(dia.jornada.get("raiz", 0)),
		"vuelta_plan": int(dia.jornada.get("vuelta", 1)),
		"plan": [],
		"resueltos": [],
		"consecuencias": consecuencias.duplicate(),
	}


func _estabilizar() -> void:
	for _i in FRAMES_ESTABILIZACION:
		await process_frame
	await RenderingServer.frame_post_draw


func _enfocar(dia, ancla_nombre: String, offset: Vector3, objetivo_offset: Vector3) -> void:
	var ancla := dia._mundo.find_child(ancla_nombre, true, false) as Node3D
	if ancla == null:
		printerr("No existe ancla de captura: %s" % ancla_nombre)
		quit(1)
		return
	var camara := dia._caminante.get_node("Camara") as Camera3D
	dia._caminante.global_position = ancla.to_global(offset)
	dia._caminante.rotation = Vector3.ZERO
	camara.rotation = Vector3.ZERO
	camara.fov = FOV
	camara.look_at(ancla.to_global(objetivo_offset), Vector3.UP)


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


func _registrar_captura(
	manifiesto: Dictionary, salida: String, id_caso: String, archivo: String, extra: Dictionary
) -> void:
	var destino := salida.path_join(archivo)
	if not _guardar_captura(destino):
		quit(1)
		return
	var entrada := {
		"id": id_caso,
		"captura": archivo,
		"sha256": FileAccess.get_sha256(destino),
	}
	for clave in extra:
		entrada[clave] = extra[clave]
	manifiesto["capturas"].append(entrada)


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


func _props_en_encuadre(dia) -> bool:
	var raiz: Node = dia._mundo.get_node_or_null("PropsUtilizablesEncontrables680")
	if raiz == null:
		return false
	var camara := dia._caminante.get_node("Camara") as Camera3D
	var margen := Vector2(float(TAMANO.x), float(TAMANO.y)) * 0.08
	var minimo := margen
	var maximo := Vector2(float(TAMANO.x), float(TAMANO.y)) - margen
	var encontrados := 0
	for nodo in raiz.get_children():
		if not nodo is Recogible3D:
			continue
		encontrados += 1
		if camara.is_position_behind(nodo.global_position):
			return false
		var pantalla := camara.unproject_position(nodo.global_position)
		if pantalla.x < minimo.x or pantalla.x > maximo.x:
			return false
		if pantalla.y < minimo.y or pantalla.y > maximo.y:
			return false
	return encontrados == 2


func _ids_props_visibles(dia) -> Array[String]:
	var ids: Array[String] = []
	var raiz: Node = dia._mundo.get_node_or_null("PropsUtilizablesEncontrables680")
	if raiz == null:
		return ids
	for nodo in raiz.get_children():
		if nodo is Recogible3D:
			ids.append(String(nodo.objeto_id))
	ids.sort()
	return ids


func _metricas_props(dia) -> Dictionary:
	var raiz: Node = dia._mundo.get_node_or_null("PropsUtilizablesEncontrables680")
	var mallas := 0
	var superficies := 0
	var triangulos := 0
	var visuales_glb := 0
	var visuales_proxy := 0
	if raiz == null:
		return {
			"mallas": 0,
			"superficies": 0,
			"triangulos": 0,
			"visuales_glb": 0,
			"visuales_proxy": 0,
		}
	for nodo in raiz.find_children("*", "MeshInstance3D", true, false):
		var instancia := nodo as MeshInstance3D
		if instancia == null or instancia.mesh == null:
			continue
		mallas += 1
		superficies += instancia.mesh.get_surface_count()
		triangulos += int(instancia.mesh.get_faces().size() / 3)
	for nodo in raiz.get_children():
		if not nodo is Recogible3D:
			continue
		match String(nodo.get_meta("visual_prop_utilizable", "")):
			"glb":
				visuales_glb += 1
			"proxy":
				visuales_proxy += 1
	return {
		"mallas": mallas,
		"superficies": superficies,
		"triangulos": triangulos,
		"visuales_glb": visuales_glb,
		"visuales_proxy": visuales_proxy,
	}


func _metricas_luz_680(dia) -> Dictionary:
	var camara := dia._caminante.get_node("Camara") as Camera3D
	var luces := 0
	var sombras := 0
	for nodo in camara.get_children():
		if not nodo is SpotLight3D:
			continue
		if String(nodo.get_meta("prop_utilizable_id", "")) != "linterna_kkryy":
			continue
		luces += 1
		if nodo.shadow_enabled:
			sombras += 1
	return {
		"luces": luces,
		"sombras": sombras,
	}


func _presupuesto_cumplido(props: Dictionary, luz: Dictionary) -> bool:
	return (
		int(props.get("triangulos", 0)) <= MAX_TRIANGULOS_PROPS
		and int(props.get("mallas", 0)) <= MAX_MALLAS_PROPS
		and int(props.get("superficies", 0)) <= MAX_SUPERFICIES_PROPS
		and int(luz.get("luces", 0)) <= MAX_LUCES_DINAMICAS
		and int(luz.get("sombras", 0)) == 0
	)
