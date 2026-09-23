## Coste aislado del filtro de pantalla (#1270) en GPU real.
##
## Dentro del día el tiempo de cuadro baila más que lo que cuesta el filtro
## (gente, clima, compilación), así que aquí se mide sobre una escena quieta a
## 1920x1080: la diferencia con y sin filtro es el coste del pase y nada más.
## Alterna control y filtro en varias rondas y da la mediana. Uso:
## env DISPLAY=:0 godot4 --path godot --script res://pruebas/medir_filtro_pantalla.gd
extends SceneTree

const SALIDA := "res://../docs/evidencias/filtro-pantalla/coste_aislado_gpu_ms.json"
const RONDAS := 3
const CUADROS := 60


func _initialize() -> void:
	call_deferred("_medir")


func _medir() -> void:
	root.size = Vector2i(1920, 1080)
	# Sin vsync: se mide lo que tarda la GPU, no se espera al monitor.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var vista := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vista, true)
	var escena := Node3D.new()
	root.add_child(escena)
	var camara := Camera3D.new()
	camara.position = Vector3(0, 1, 3)
	escena.add_child(camara)
	var caja := MeshInstance3D.new()
	caja.mesh = BoxMesh.new()
	escena.add_child(caja)
	escena.add_child(DirectionalLight3D.new())
	var entorno := WorldEnvironment.new()
	entorno.environment = Environment.new()
	escena.add_child(entorno)

	var resultado := {}
	for id in FiltroPantalla.ids():
		if id == FiltroPantalla.NINGUNO:
			continue
		var deltas := []
		for ronda in RONDAS:
			FiltroPantalla.aplicar(entorno, {"filtro_pantalla": FiltroPantalla.NINGUNO})
			var control := await _media(vista)
			FiltroPantalla.aplicar(entorno, {"filtro_pantalla": id})
			var con_filtro := await _media(vista)
			deltas.append(con_filtro - control)
			print("%s ronda %d: %.2f -> %.2f ms" % [id, ronda, control, con_filtro])
		deltas.sort()
		resultado[id] = snappedf(deltas[RONDAS / 2], 0.01)
	var informe := FileAccess.open(ProjectSettings.globalize_path(SALIDA), FileAccess.WRITE)
	informe.store_string(
		JSON.stringify({"resolucion": "1920x1080", "delta_mediana_ms": resultado}, "\t")
	)
	informe.close()
	print(JSON.stringify(resultado))
	quit(0)


func _media(vista: RID) -> float:
	for i in 10:
		await process_frame
	var total := 0.0
	for i in CUADROS:
		await process_frame
		total += RenderingServer.viewport_get_measured_render_time_gpu(vista)
	return total / CUADROS
