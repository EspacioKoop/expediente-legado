extends SceneTree

## Gate visual reproducible para #275.
##
## Instancia la misma figura que usa la oficina —el avatar realista de cada
## compañero, o `persona.fbx` con los autoloads reales de vestuario + corrección
## visual para quien aún no lo tenga. Después congela el idle y
## guarda capturas comparables desde frente y 3/4 para TODO el roster. Los NPCs
## históricos añaden perfil y primer plano para revisar cara/cabello sin tener
## que recorrer una partida concreta.
##
## Uso:
## godot4 --path godot --script res://pruebas/capturas_npc_275.gd -- /ruta/salida

const TAM := Vector2i(480, 720)
const OBJETIVO_CUERPO := Vector3(0.0, 0.92, 0.0)
const OBJETIVO_CARA := Vector3(0.0, 1.50, 0.0)
const VISTAS_BASE := [
	{"nombre": "frente", "angulo": 0.0, "distancia": 3.25, "fov": 38.0},
	{"nombre": "tres_cuartos", "angulo": 35.0, "distancia": 3.25, "fov": 38.0},
]
const VISTAS_HISTORICAS := [
	{"nombre": "perfil", "angulo": 90.0, "distancia": 3.25, "fov": 38.0},
	{"nombre": "primer_plano", "angulo": 0.0, "distancia": 1.45, "fov": 32.0},
]

var _viewport: SubViewport
var _mundo: Node3D
var _camara: Camera3D
var _modelo_actual: Node3D
var _salida := ""
var _manifest := PackedStringArray()
var _fallos := 0
var _capturas := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_salida = _resolver_salida()
	var error_dir := DirAccess.make_dir_recursive_absolute(_salida)
	if error_dir != OK:
		push_error("No se puede crear %s: %s" % [_salida, error_dir])
		quit(1)
		return

	_montar_estudio()
	_manifest.append("# Capturas visuales NPC #275")
	_manifest.append("")
	_manifest.append("Generadas con el pipeline real de `Modelos.persona()` + autoloads.")
	_manifest.append("")
	_manifest.append("| NPC | Vista | Archivo |")
	_manifest.append("| --- | --- | --- |")

	var roster := [Companeros.CUNADO] + Array(Companeros.ROSTER)
	for quien in roster:
		await _capturar_persona(quien as Dictionary)

	_guardar_manifest()
	print("Capturas #275: %d archivos, %d fallos -> %s" % [_capturas, _fallos, _salida])
	quit(1 if _fallos else 0)


func _resolver_salida() -> String:
	var argumentos := OS.get_cmdline_user_args()
	if not argumentos.is_empty():
		return String(argumentos[0])
	return ProjectSettings.globalize_path("user://capturas-npc-275")


func _montar_estudio() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "CapturaNPC275"
	_viewport.size = TAM
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	root.add_child(_viewport)

	_mundo = Node3D.new()
	_mundo.name = "EstudioNPC275"
	_viewport.add_child(_mundo)

	var mundo_ambiente := WorldEnvironment.new()
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.07, 0.075, 0.085)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.82, 0.84, 0.88)
	ambiente.ambient_light_energy = 0.55
	mundo_ambiente.environment = ambiente
	_mundo.add_child(mundo_ambiente)

	var suelo := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(4.0, 0.08, 4.0)
	suelo.mesh = caja
	suelo.position = Vector3(0.0, -0.05, 0.0)
	Modelos._pintar(suelo, Color(0.16, 0.17, 0.19))
	_mundo.add_child(suelo)

	var principal := DirectionalLight3D.new()
	principal.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	principal.light_energy = 1.05
	principal.shadow_enabled = true
	_mundo.add_child(principal)

	var relleno := OmniLight3D.new()
	relleno.position = Vector3(-1.8, 1.8, 2.1)
	relleno.light_energy = 1.25
	relleno.omni_range = 7.0
	_mundo.add_child(relleno)

	_camara = Camera3D.new()
	_camara.name = "CamaraGate275"
	_camara.current = true
	_camara.near = 0.05
	_camara.far = 20.0
	_mundo.add_child(_camara)


func _capturar_persona(quien: Dictionary) -> void:
	if _modelo_actual != null:
		_modelo_actual.queue_free()
		await process_frame

	_modelo_actual = Node3D.new()
	_modelo_actual.name = "NPC_%s" % String(quien.get("id", "desconocido"))
	_mundo.add_child(_modelo_actual)

	var retrato := String(quien.get("retrato", ""))
	var creada := Modelos.persona(
		_modelo_actual,
		Companeros.cuerpo_de(quien),
		quien.get("color", Color(0.3, 0.3, 0.3)),
		retrato
	)
	if not creada:
		_fallar("No se pudo instanciar %s" % String(quien.get("id", "")))
		return

	# VestuarioHumano3D reacciona al node_added y CorreccionVisualNPC275 espera
	# además un frame. Cuatro frames dejan el árbol completamente estabilizado.
	for _i in range(4):
		await process_frame

	var esqueleto := _buscar_esqueleto(_modelo_actual)
	if esqueleto == null:
		_fallar("%s no conserva Skeleton3D" % String(quien.get("id", "")))
		return
	# Los avatares realistas traen ropa y cara propias; los pases de vestuario y
	# corrección solo se exigen a quien sigue siendo el maniquí.
	if not Modelos.es_realista(Companeros.cuerpo_de(quien)):
		if not esqueleto.has_meta("vestuario_humano_275"):
			_fallar("%s no recibió vestuario" % String(quien.get("id", "")))
			return
		if not esqueleto.has_meta("correccion_visual_275"):
			_fallar("%s no recibió corrección visual #275" % String(quien.get("id", "")))
			return

	_congelar_animacion(_modelo_actual)

	var vistas := VISTAS_BASE.duplicate(true)
	if not retrato.is_empty():
		vistas.append_array(VISTAS_HISTORICAS)
	for vista in vistas:
		await _capturar_vista(quien, vista as Dictionary)


func _capturar_vista(quien: Dictionary, vista: Dictionary) -> void:
	var angulo := deg_to_rad(float(vista["angulo"]))
	var distancia := float(vista["distancia"])
	var objetivo := OBJETIVO_CARA if String(vista["nombre"]) == "primer_plano" else OBJETIVO_CUERPO
	_camara.fov = float(vista["fov"])
	_camara.position = Vector3(sin(angulo) * distancia, objetivo.y, cos(angulo) * distancia)
	_camara.look_at(objetivo, Vector3.UP)

	await process_frame
	await RenderingServer.frame_post_draw

	var imagen := _viewport.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		_fallar("Viewport vacío para %s/%s" % [quien["id"], vista["nombre"]])
		return

	var nombre := "%s_%s.png" % [String(quien["id"]), String(vista["nombre"])]
	var ruta := _salida.path_join(nombre)
	var error_png := imagen.save_png(ruta)
	if error_png != OK:
		_fallar("No se pudo guardar %s: %s" % [ruta, error_png])
		return

	_capturas += 1
	_manifest.append("| `%s` | `%s` | `%s` |" % [quien["id"], vista["nombre"], nombre])


func _congelar_animacion(nodo: Node) -> void:
	if nodo is AnimationPlayer:
		(nodo as AnimationPlayer).speed_scale = 0.0
	for hijo in nodo.get_children():
		_congelar_animacion(hijo)


func _buscar_esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _buscar_esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null


func _guardar_manifest() -> void:
	var ruta := _salida.path_join("README.md")
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		_fallar("No se pudo escribir %s" % ruta)
		return
	archivo.store_string("\n".join(_manifest) + "\n")
	archivo.close()


func _fallar(mensaje: String) -> void:
	_fallos += 1
	push_error("Gate visual #275: %s" % mensaje)
