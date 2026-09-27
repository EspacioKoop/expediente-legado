extends SceneTree

## Evidencia visual reproducible de #1319.
##
## Monta la oficina real y cuatro compañeros Rocketbox por la misma ruta de
## runtime. Cada uno queda en un estado distinto: reposo de pie, trabajo sentado,
## teléfono y conversación. El script falla si el clip efectivo no pertenece a
## la biblioteca Rocketbox o si una postura de pie atraviesa/se separa del suelo.
##
## El workflow de GitHub genera un PREVIEW con Lavapipe. El pase de aceptación
## final se hace en GPU real:
## env DISPLAY=:0 SIGA98_GPU_REAL=1 godot4 --rendering-method forward_plus --path godot \\
##   --script res://pruebas/capturar_rocketbox_oficina_1319.gd -- /ruta/salida

const TAM := Vector2i(1280, 720)
const PIE_MIN := -0.05
const PIE_MAX := 0.20
const CABEZA_MIN := 1.10

const ESTADOS := [
	{"nombre": "telefono", "clip": "telefono", "indice": 0},
	{"nombre": "sentado", "clip": "sentado_hablando", "indice": 1},
	{"nombre": "pie", "clip": "idle", "indice": 2},
	{"nombre": "conversacion", "clip": "conversar", "indice": 3},
]

var _viewport: SubViewport
var _mundo: Node3D
var _camara: Camera3D
var _salida := ""
var _fallos := 0
var _casos := []


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_salida = _resolver_salida()
	if DirAccess.make_dir_recursive_absolute(_salida) != OK:
		_fallar("no se pudo crear la salida %s" % _salida)
		quit(1)
		return

	_montar_oficina()
	for _i in 12:
		await process_frame

	var plantilla := Companeros.plantilla(1319)
	var sitios: Array = EspaciosCatalogo.OFICINA.get("sitios_companeros", [])
	if plantilla.size() < ESTADOS.size() or sitios.size() < ESTADOS.size():
		_fallar("la oficina no tiene cuatro compañeros/sitios para la matriz")
		quit(1)
		return

	for estado in ESTADOS:
		await _montar_caso(estado as Dictionary, plantilla, sitios)

	_guardar_manifest()
	print("Evidencia Rocketbox #1319: %d casos, %d fallos -> %s" % [_casos.size(), _fallos, _salida])
	quit(1 if _fallos else 0)


func _resolver_salida() -> String:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		return String(args[0])
	return ProjectSettings.globalize_path("user://evidencia-rocketbox-oficina-1319")


func _montar_oficina() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "RocketboxOficina1319"
	_viewport.size = TAM
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	root.add_child(_viewport)

	_mundo = Node3D.new()
	_mundo.name = "OficinaReal1319"
	_viewport.add_child(_mundo)

	var entorno := WorldEnvironment.new()
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.05, 0.05, 0.06)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = EspaciosCatalogo.OFICINA.get(
		"ambiente", Color(0.42, 0.43, 0.45)
	)
	ambiente.ambient_light_energy = EspaciosCatalogo.OFICINA.get("ambiente_energia", 0.55)
	entorno.environment = ambiente
	_mundo.add_child(entorno)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_energy = EspaciosCatalogo.OFICINA.get("sol", 0.25)
	_mundo.add_child(sol)

	var espacio := EspaciosCatalogo.OFICINA.duplicate(true)
	espacio["figuras"] = []
	Espacio3D.construir(_mundo, espacio)

	var dressing_script := load("res://guion/dia_dressing_cc0_app.gd")
	var dressing = dressing_script.new()
	dressing.call("_vestir_archivo_cc0", _mundo)
	dressing.free()
	OficinaUtileria.montar(_mundo)
	OficinaAssetsCc0.montar(_mundo)
	PostersOficina.montar(_mundo)
	CuadrosOficina.montar(_mundo)
	SenaleticaOficina98.montar(_mundo)

	_camara = Camera3D.new()
	_camara.current = true
	_camara.near = 0.05
	_camara.far = 35.0
	_camara.fov = 58.0
	_mundo.add_child(_camara)


func _montar_caso(estado: Dictionary, plantilla: Array, sitios: Array) -> void:
	var indice := int(estado["indice"])
	var quien: Dictionary = plantilla[indice]
	var sitio: Vector3 = sitios[indice]
	var soporte := Node3D.new()
	soporte.name = "Caso_%s" % String(estado["nombre"])
	soporte.position = sitio
	_mundo.add_child(soporte)

	var modelo := Companeros.cuerpo_de(quien)
	if not Modelos.persona(
		soporte,
		modelo,
		quien.get("color", Color(0.3, 0.3, 0.3)),
		String(quien.get("retrato", ""))
	):
		_fallar("%s no pudo montar %s" % [estado["nombre"], modelo])
		soporte.queue_free()
		return
	var pieza := soporte.get_child(0) as Node3D
	var clip := String(estado["clip"])
	if pieza == null or AnimacionesRocketbox.sexo(pieza).is_empty():
		_fallar("%s no es un avatar Rocketbox" % String(estado["nombre"]))
		soporte.queue_free()
		return
	if not AnimacionesRocketbox.tiene(pieza, clip):
		_fallar("%s no dispone del clip %s" % [estado["nombre"], clip])
		soporte.queue_free()
		return

	var idle := CompaneroIdle3D.new()
	idle.name = "Idle_%s" % String(estado["nombre"])
	soporte.add_child(idle)
	match String(estado["nombre"]):
		"telefono":
			idle.configurar(soporte, 0, true, false)
		"sentado":
			idle.configurar(soporte, 0, false, false, true, false, true)
		"conversacion":
			idle.configurar(soporte, 0, false, false)
			idle.conversar(true)
		_:
			idle.configurar(soporte, 0, false, false)

	for _i in 10:
		await process_frame

	var reproductor := Modelos._reproductor(pieza)
	var actual := String(reproductor.current_animation) if reproductor != null else ""
	if not actual.begins_with("rocketbox/"):
		_fallar("%s reproduce %s en vez de Rocketbox" % [estado["nombre"], actual])
	if not actual.ends_with("/%s" % clip):
		_fallar("%s esperaba %s y reproduce %s" % [estado["nombre"], clip, actual])

	var medidas := _medir_postura(pieza, String(estado["nombre"]) == "sentado")
	_casos.append(
		{
			"estado": estado["nombre"],
			"companero": quien.get("id", ""),
			"modelo": modelo,
			"sexo": AnimacionesRocketbox.sexo(pieza),
			"clip": actual,
			"pie_min_y": medidas["pie"],
			"cabeza_y": medidas["cabeza"],
		}
	)

	_camara.position = sitio + Vector3(2.35, 1.55, 2.65)
	_camara.look_at(sitio + Vector3(0.0, 1.05, 0.0), Vector3.UP)
	for _i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var imagen := _viewport.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		_fallar("captura vacía para %s" % String(estado["nombre"]))
	else:
		var ruta := _salida.path_join("%s.png" % String(estado["nombre"]))
		if imagen.save_png(ruta) != OK:
			_fallar("no se pudo guardar %s" % ruta)

	soporte.queue_free()
	await process_frame


func _medir_postura(pieza: Node3D, sentado: bool) -> Dictionary:
	var esqueleto := Modelos._esqueleto(pieza)
	if esqueleto == null:
		_fallar("avatar sin Skeleton3D")
		return {"pie": -999.0, "cabeza": -999.0}
	var pie := minf(
		_hueso_global(esqueleto, "LeftFoot").y,
		_hueso_global(esqueleto, "RightFoot").y
	) - pieza.global_position.y
	var cabeza := _hueso_global(esqueleto, "Head").y - pieza.global_position.y
	if sentado:
		if pie < -CompaneroIdle3D.ALTURA_ASIENTO - 0.02:
			_fallar("sentado atraviesa el suelo: pie %.3f" % pie)
	else:
		if pie < PIE_MIN or pie > PIE_MAX:
			_fallar("postura de pie no pisa el suelo: %.3f" % pie)
		if cabeza < CABEZA_MIN:
			_fallar("postura de pie se desploma: cabeza %.3f" % cabeza)
	return {"pie": pie, "cabeza": cabeza}


func _hueso_global(esqueleto: Skeleton3D, nombre: String) -> Vector3:
	var hueso := esqueleto.find_bone(nombre)
	if hueso < 0:
		_fallar("falta hueso %s" % nombre)
		return esqueleto.global_position
	return esqueleto.to_global(esqueleto.get_bone_global_pose(hueso).origin)


func _guardar_manifest() -> void:
	var manifest := {
		"issue": 1319,
		"sha": OS.get_environment("GITHUB_SHA").strip_edges(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"gpu_real": OS.get_environment("SIGA98_GPU_REAL") == "1",
		"casos": _casos,
	}
	var ruta_json := _salida.path_join("manifest.json")
	var fichero := FileAccess.open(ruta_json, FileAccess.WRITE)
	if fichero == null:
		_fallar("no se pudo escribir manifest.json")
		return
	fichero.store_string(JSON.stringify(manifest, "\\t"))
	fichero.close()

	var readme := FileAccess.open(_salida.path_join("README.md"), FileAccess.WRITE)
	if readme == null:
		_fallar("no se pudo escribir README.md")
		return
	readme.store_string(
		"""# Preview Rocketbox oficina · #1319

Matriz automática de cuatro estados reales del compañero de oficina:
**pie**, **sentado**, **teléfono** y **conversación**.

Este artifact de CI es un **preview de regresión**, no el pase humano/GPU-real
exigido por #1319. El workflow usa un renderer software para poder detectar clips
equivocados, poses hundidas y regresiones obvias de composición.

Para el cierre visual, ejecutar el mismo capturador en una máquina con Vulkan
real mediante DISPLAY=:0 y SIGA98_GPU_REAL=1, revisar los cuatro PNG y confirmar: pies apoyados,
sin flotación, brazos sin torsión, postura legible y contexto de oficina.

El manifest.json registra avatar, sexo, clip efectivo, renderer y medidas de
pie/cabeza para cada estado.
"""
	)
	readme.close()


func _fallar(mensaje: String) -> void:
	_fallos += 1
	push_error("Evidencia Rocketbox #1319: %s" % mensaje)
