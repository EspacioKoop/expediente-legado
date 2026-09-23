## Evidencia reproducible del gate visual domestico de #227.
##
## Captura cuatro zonas de la casa real con la camara jugable y HUD oculto:
## entrada, estar, dormitorio y cocina-comedor. El manifiesto inventaria las
## quince instancias que materializan los 13 GLB seleccionados (las sillas se
## reutilizan y el sofa viste el nodo historico) y registra en que encuadres cae
## el centro de cada objeto dentro del frustum.
##
## La presencia en frustum es una senal objetiva de cobertura, no un veredicto
## de escala, clipping u oficio artistico. Esos tres criterios siguen siendo
## revision humana sobre las PNG del mismo build.
extends SceneTree

const TAMANO := Vector2i(1920, 1080)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 3

const CASOS := [
	{
		"id": "entrada",
		"zona": "entrada",
		"posicion": Vector3(0.0, 0.0, 2.45),
		"objetivo_nodo": "CasaHogarCC0/AparadorHogar",
		"criterio": "aparador y lampara leen como recibidor sin clipping ni escala impropia",
	},
	{
		"id": "estar",
		"zona": "estar",
		"posicion": Vector3(0.90, 0.0, 3.45),
		"objetivo_nodo": "CasaHogarCC0/MesaBajaHogar",
		"criterio": "sofa, mesa baja y mueble de TV forman un estar legible y proporcionado",
	},
	{
		"id": "dormitorio",
		"zona": "dormitorio",
		"posicion": Vector3(-0.55, 0.0, -0.95),
		"objetivo_nodo": "CasaHogarCC0/ArmarioHogar",
		"criterio": "el armario se integra en el dormitorio sin invadir paso, cama ni tabiques",
	},
	{
		"id": "cocina_comedor",
		"zona": "cocina_comedor",
		"posicion": Vector3(-0.20, 0.0, 2.05),
		"objetivo": Vector3(3.15, 0.90, -0.70),
		"criterio": "mesa, sillas y electrodomesticos construyen una cocina-comedor reconocible",
	},
]

const OBJETOS := [
	{"nodo": "CasaHogarCC0/MuebleTVHogar", "modelo": "tv_cabinet_01", "zona": "estar"},
	{"nodo": "CasaHogarCC0/MesaBajaHogar", "modelo": "coffee_table_01", "zona": "estar"},
	{"nodo": "SofaCasa/VisualHogar", "modelo": "2_seat_sofa_01", "zona": "estar"},
	{"nodo": "CasaHogarCC0/ArmarioHogar", "modelo": "wardrobe_01", "zona": "dormitorio"},
	{"nodo": "CasaHogarCC0/MesaComedorHogar", "modelo": "dine_table_01", "zona": "cocina_comedor"},
	{"nodo": "CasaHogarCC0/SillaComedorOeste", "modelo": "chair_01", "zona": "cocina_comedor"},
	{"nodo": "CasaHogarCC0/SillaComedorOesteB", "modelo": "chair_01", "zona": "cocina_comedor"},
	{"nodo": "CasaHogarCC0/SillaComedorEste", "modelo": "chair_01", "zona": "cocina_comedor"},
	{"nodo": "CasaHogarCC0/HornoHogar", "modelo": "stove_01", "zona": "cocina_comedor"},
	{
		"nodo": "CasaHogarCC0/LavadoraHogar",
		"modelo": "washing_machine_01",
		"zona": "cocina_comedor"
	},
	{"nodo": "CasaHogarCC0/MicroondasHogar", "modelo": "microwave_01", "zona": "cocina_comedor"},
	{"nodo": "CasaHogarCC0/TostadoraHogar", "modelo": "toaster_01", "zona": "cocina_comedor"},
	{"nodo": "CasaHogarCC0/HervidorHogar", "modelo": "kettle_01", "zona": "cocina_comedor"},
	{"nodo": "CasaHogarCC0/AparadorHogar", "modelo": "cupboard_01", "zona": "entrada"},
	{"nodo": "CasaHogarCC0/LamparaMesaHogar", "modelo": "table_lamp_01", "zona": "entrada"},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-hogar-227")
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
	dia._entrar_en("casa")
	await process_frame

	var lote := dia._mundo.get_node_or_null("CasaHogarCC0") as Node3D
	if lote == null:
		printerr("Falta CasaHogarCC0: #227 no esta montado en la casa real")
		quit(1)
		return

	var objetos := _inventariar_objetos(dia._mundo)
	if objetos.size() != OBJETOS.size():
		quit(1)
		return

	var manifiesto := {
		"issue": 227,
		"escena": "res://escenas/dia.tscn",
		"fase": "casa",
		"locale": TranslationServer.get_locale(),
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"camara": "jugable",
		"criterio": "evidencia_para_revision_humana",
		"veredicto_automatico": false,
		"instancias_cc0": objetos.size(),
		"objetos": objetos,
		"casos": [],
	}

	for caso in CASOS:
		var camara := _preparar_camara(dia, caso)
		if camara == null:
			quit(1)
			return
		for i in FRAMES_ESTABILIZACION:
			await process_frame
		_ocultar_hud(dia)
		await RenderingServer.frame_post_draw

		_registrar_cobertura(objetos, dia._mundo, camara, String(caso["id"]))

		var archivo := "%s.png" % String(caso["id"])
		var destino := salida.path_join(archivo)
		if not _guardar_captura(destino):
			quit(1)
			return
		var registro_caso := {
			"id": String(caso["id"]),
			"zona": String(caso["zona"]),
			"captura": archivo,
			"criterio": String(caso["criterio"]),
			"sha256": FileAccess.get_sha256(destino),
		}
		manifiesto["casos"].append(registro_caso)

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo_manifiesto == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("evidencia #227 -> %s" % salida)
	quit(0)


func _inventariar_objetos(mundo: Node3D) -> Array:
	var inventario := []
	for ficha in OBJETOS:
		var ruta := String(ficha["nodo"])
		var nodo := mundo.get_node_or_null(ruta) as Node3D
		if nodo == null:
			printerr("Falta instancia domestica de #227: %s" % ruta)
			continue
		if nodo.get_node_or_null("AssetCc0") == null:
			printerr("%s no conserva su visual AssetCc0" % ruta)
			continue
		var registro := {
			"nodo": ruta,
			"modelo": String(ficha["modelo"]),
			"zona": String(ficha["zona"]),
			"vistas": [],
			"pantalla_por_vista": {},
		}
		inventario.append(registro)
	return inventario


func _preparar_camara(dia, caso: Dictionary) -> Camera3D:
	dia._caminante.situar(Vector3(caso["posicion"]), 0.0)
	dia._caminante.set_physics_process(false)
	var camara := dia._caminante.get_node("Camara") as Camera3D
	if camara == null:
		printerr("No existe la camara jugable")
		return null
	camara.fov = FOV

	var objetivo: Vector3
	if caso.has("objetivo_nodo"):
		var nodo := dia._mundo.get_node_or_null(String(caso["objetivo_nodo"])) as Node3D
		if nodo == null:
			printerr("No existe objetivo de camara: %s" % String(caso["objetivo_nodo"]))
			return null
		objetivo = nodo.global_position
	else:
		objetivo = Vector3(caso["objetivo"])
	camara.look_at(objetivo, Vector3.UP)
	return camara


func _registrar_cobertura(objetos: Array, mundo: Node3D, camara: Camera3D, vista: String) -> void:
	for objeto in objetos:
		var nodo := mundo.get_node_or_null(String(objeto["nodo"])) as Node3D
		if nodo == null or not camara.is_position_in_frustum(nodo.global_position):
			continue
		objeto["vistas"].append(vista)
		var punto := camara.unproject_position(nodo.global_position)
		objeto["pantalla_por_vista"][vista] = [roundi(punto.x), roundi(punto.y)]


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
	if imagen.get_size() != TAMANO:
		printerr("Resolucion inesperada para #227: %s; esperada %s" % [imagen.get_size(), TAMANO])
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("captura -> %s" % destino)
	return true
