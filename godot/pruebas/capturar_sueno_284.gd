## Evidencia comparativa de las cuatro identidades fuertes de #284.
##
## Renderiza castillo, montaña, desierto y escuela sin HUD, a altura de jugador
## y con el mismo FOV. Desde #798 la escuela se captura desde dos ángulos:
## silueta general e integración del contenido del día. No sustituye el pase
## humano de #398/#798: produce entradas comparables y reproducibles.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const ALTURA_JUGADOR := 1.65
const FRASE_CONOCIDA := "EXPEDIENTE CONOCIDO"

const CASOS := [
	{
		"id": "castillo",
		"forma": "patio",
		"camara": Vector3(-13.0, ALTURA_JUGADOR, 11.5),
		"objetivo": Vector3(-1.5, 1.55, 0.0),
	},
	{
		"id": "montana",
		"forma": "embudo",
		"camara": Vector3(-10.5, ALTURA_JUGADOR, -11.5),
		"objetivo": Vector3(5.2, 1.25, 2.0),
	},
	{
		"id": "desierto",
		"forma": "peine",
		"camara": Vector3(-9.5, ALTURA_JUGADOR, -9.0),
		"objetivo": Vector3(5.0, 1.35, 0.0),
	},
	{
		"id": "escuela",
		"forma": "crucero",
		"captura": "escuela_general.png",
		"camara": Vector3(-9.5, ALTURA_JUGADOR, -10.5),
		"objetivo": Vector3(2.0, 1.35, 2.5),
	},
	{
		"id": "escuela",
		"forma": "crucero",
		"captura": "escuela_contenido.png",
		"camara": Vector3(6.5, ALTURA_JUGADOR, -5.0),
		"objetivo": Vector3(-3.0, 1.45, -0.6),
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-sueno-284")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	root.size = TAMANO
	var manifiesto := {
		"issue": 284,
		"gate_humano": 398,
		"gate_humano_crucero": 798,
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"altura_jugador": ALTURA_JUGADOR,
		"hud": false,
		"casos": [],
	}

	for caso in CASOS:
		var mundo := Node3D.new()
		var captura := String(caso.get("captura", "%s.png" % String(caso["id"])))
		mundo.name = "EvidenciaSueno284_%s" % captura.get_basename()
		root.add_child(mundo)

		var espacio := _espacio_para(String(caso["id"]), String(caso["forma"]))
		_montar_entorno(mundo, espacio)
		# El capturador debe reproducir el runtime real. Antes solo montaba la
		# presentación; #1263 dejó al descubierto ese error porque escuela ya no
		# redibuja una arquitectura paralela sobre la base poligonal.
		Espacio3D.construir(mundo, espacio)
		var camara := _montar_camara(
			mundo,
			Vector3(caso["camara"]),
			Vector3(caso["objetivo"]),
		)
		var presentacion := _montar_presentacion(mundo, espacio)
		if presentacion == null:
			printerr("No se pudo montar la identidad %s" % String(caso["id"]))
			quit(1)
			return

		for i in 14:
			await process_frame
		camara.look_at(Vector3(caso["objetivo"]), Vector3.UP)
		await RenderingServer.frame_post_draw

		var archivo := captura
		var destino := salida.path_join(archivo)
		if not _guardar_captura(destino):
			quit(1)
			return

		(
			manifiesto["casos"]
			. append(
				{
					"id": String(caso["id"]),
					"forma": String(caso["forma"]),
					"captura": archivo,
					"camara": _vector_a_array(Vector3(caso["camara"])),
					"objetivo": _vector_a_array(Vector3(caso["objetivo"])),
					"identidad_onirica": String(espacio.get("identidad_onirica", "")),
				}
			)
		)

		mundo.queue_free()
		await process_frame

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo_manifiesto == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("manifiesto -> %s" % ruta_manifiesto)
	quit(0)


func _espacio_para(id: String, forma: String) -> Dictionary:
	var contenido := {"frases": [FRASE_CONOCIDA]}
	var espacio := Sueno.espacio(forma, 0, contenido)
	match id:
		"montana":
			return SuenoMontana.adaptar_espacio(espacio, {"variante_cabana": 0})
		"desierto":
			return SuenoDesierto.adaptar_espacio(espacio, {"variante_horizonte": 0})
		"escuela":
			return SuenoEscuela.adaptar_espacio(espacio, {"variante_aulas": 0})
		_:
			return espacio


func _montar_presentacion(mundo: Node3D, espacio: Dictionary) -> Node3D:
	match String(espacio.get("identidad_onirica", "")):
		SuenoCastillo.ID:
			return SuenoCastillo3D.montar(mundo, espacio)
		SuenoMontana.ID:
			return SuenoMontana3D.montar(mundo, espacio)
		SuenoDesierto.ID:
			return SuenoDesierto3D.montar(mundo, espacio)
		SuenoEscuela.ID:
			return SuenoEscuela3D.montar(mundo, espacio)
		_:
			return null


func _montar_entorno(mundo: Node3D, espacio: Dictionary) -> void:
	var ambiente: Color = espacio.get("ambiente", Color(0.22, 0.21, 0.24))
	var exterior := bool(espacio.get("exterior", false))
	var world_environment := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = ambiente.lightened(0.28) if exterior else ambiente.darkened(0.42)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = ambiente.lightened(0.26)
	entorno.ambient_light_energy = maxf(0.38, float(espacio.get("ambiente_energia", 0.42)))
	world_environment.environment = entorno
	mundo.add_child(world_environment)

	var sol := DirectionalLight3D.new()
	sol.name = "LuzComparativa"
	sol.rotation_degrees = Vector3(-46.0, -28.0, 0.0)
	sol.light_color = Color(0.84, 0.81, 0.74)
	sol.light_energy = maxf(0.42, float(espacio.get("sol", 0.05)) * 1.45)
	sol.shadow_enabled = true
	mundo.add_child(sol)


func _montar_camara(mundo: Node3D, posicion: Vector3, objetivo: Vector3) -> Camera3D:
	var camara := Camera3D.new()
	camara.name = "CamaraJugadorSinHUD"
	camara.position = posicion
	camara.fov = FOV
	camara.current = true
	mundo.add_child(camara)
	camara.look_at(objetivo, Vector3.UP)
	return camara


func _guardar_captura(destino: String) -> bool:
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Viewport vacío para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("sueño -> %s" % destino)
	return true


func _vector_a_array(vector: Vector3) -> Array:
	return [vector.x, vector.y, vector.z]
