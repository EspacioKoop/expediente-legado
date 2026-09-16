## Presentación 3D de la montaña onírica (#284).
##
## La física sigue siendo la familia CONVERGENTE ya construida por Espacio3D.
## Esta capa oculta únicamente su malla de sala cerrada y coloca encima una cima
## visual abierta: nieve, laderas, mar de nubes, cabaña y documento congelado.
## No crea StaticBody3D ni CollisionShape3D nuevos.
class_name SuenoMontana3D
extends Node3D

const ESCENA_CABANA := preload("res://escenas/suenos/props_284/cabana_nieve.tscn")
const CABANA_CERCA := Vector3(5.8, 0.05, 1.8)
const CABANA_LEJOS := Vector3(8.9, 0.05, 6.2)

var _cabana: Node3D
var _cabana_lejos := false
var _estaba_fuera_de_vista := false


static func montar(mundo: Node3D, espacio: Dictionary) -> Node3D:
	if mundo == null or String(espacio.get("identidad_onirica", "")) != SuenoMontana.ID:
		return null
	var presentacion := SuenoMontana3D.new()
	presentacion.name = "PresentacionMontana284"
	mundo.add_child(presentacion)
	presentacion._configurar(espacio)
	return presentacion


func _configurar(espacio: Dictionary) -> void:
	_ocultar_sala_cerrada()
	var contorno: PackedVector2Array = espacio.get("contorno", PackedVector2Array())
	_montar_cima(contorno)
	_montar_mar_de_nubes()
	_montar_huellas()

	_cabana = ESCENA_CABANA.instantiate() as Node3D
	_cabana.name = "CabanaQueCambiaDistancia"
	_cabana.position = CABANA_CERCA
	add_child(_cabana)

	var crujidos := AudioStreamPlayer3D.new()
	crujidos.name = "CrujidosTrasPuerta"
	crujidos.stream = SuenoMontanaAudio.viento_y_madera()
	crujidos.position = Vector3(0.0, 1.7, 0.0)
	crujidos.volume_db = -17.0
	crujidos.unit_size = 7.0
	crujidos.max_distance = 48.0
	_cabana.add_child(crujidos)
	crujidos.play()

	var hielo_pos: Vector3 = espacio.get("montana_hielo_pos", Vector3(-6, 0, 2))
	_montar_documento_hielo(hielo_pos)


func _process(_delta: float) -> void:
	if _cabana == null:
		return
	var camara := get_viewport().get_camera_3d()
	if camara == null:
		return
	var hacia_cabana := _cabana.global_position - camara.global_position
	if hacia_cabana.length_squared() < 0.001:
		return
	var delante := -camara.global_transform.basis.z.normalized()
	var visible_aprox := delante.dot(hacia_cabana.normalized()) > 0.18

	# Solo cambia mientras queda fuera del campo frontal. Al volver a mirar no
	# hay desplazamiento visible: simplemente la cabaña está a otra distancia.
	if not visible_aprox and not _estaba_fuera_de_vista:
		_cabana_lejos = not _cabana_lejos
		_cabana.position = CABANA_LEJOS if _cabana_lejos else CABANA_CERCA
		_estaba_fuera_de_vista = true
	elif visible_aprox:
		_estaba_fuera_de_vista = false


func _ocultar_sala_cerrada() -> void:
	var mundo := get_parent()
	if mundo == null:
		return
	for hijo in mundo.get_children():
		if not hijo is StaticBody3D:
			continue
		var visual := hijo.get_node_or_null("Malla")
		if visual is MeshInstance3D:
			visual.visible = false
			return


func _montar_cima(contorno: PackedVector2Array) -> void:
	if contorno.size() < 3:
		return
	var indices := Geometry2D.triangulate_polygon(contorno)
	if indices.is_empty():
		return

	var nieve := SurfaceTool.new()
	nieve.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, indices.size(), 3):
		var a := contorno[indices[i]]
		var b := contorno[indices[i + 1]]
		var c := contorno[indices[i + 2]]
		nieve.add_vertex(Vector3(a.x, 0.035, a.y))
		nieve.add_vertex(Vector3(c.x, 0.035, c.y))
		nieve.add_vertex(Vector3(b.x, 0.035, b.y))
	nieve.generate_normals()
	var cima := MeshInstance3D.new()
	cima.name = "CimaNevada"
	cima.mesh = nieve.commit()
	var mat_nieve := StandardMaterial3D.new()
	mat_nieve.albedo_color = Color(0.78, 0.87, 0.93)
	mat_nieve.roughness = 0.86
	cima.material_override = mat_nieve
	add_child(cima)

	var centro := Vector2.ZERO
	for punto in contorno:
		centro += punto
	centro /= float(contorno.size())
	var laderas := SurfaceTool.new()
	laderas.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in contorno.size():
		var a := contorno[i]
		var b := contorno[(i + 1) % contorno.size()]
		var exterior_a := centro + (a - centro) * 1.42
		var exterior_b := centro + (b - centro) * 1.42
		var arriba_a := Vector3(a.x, 0.02, a.y)
		var arriba_b := Vector3(b.x, 0.02, b.y)
		var abajo_a := Vector3(exterior_a.x, -6.4, exterior_a.y)
		var abajo_b := Vector3(exterior_b.x, -6.4, exterior_b.y)
		laderas.add_vertex(arriba_a)
		laderas.add_vertex(abajo_b)
		laderas.add_vertex(abajo_a)
		laderas.add_vertex(arriba_a)
		laderas.add_vertex(arriba_b)
		laderas.add_vertex(abajo_b)
	laderas.generate_normals()
	var roca := MeshInstance3D.new()
	roca.name = "LaderasDeLaCima"
	roca.mesh = laderas.commit()
	var mat_roca := StandardMaterial3D.new()
	mat_roca.albedo_color = Color(0.20, 0.24, 0.28)
	mat_roca.roughness = 1.0
	roca.material_override = mat_roca
	add_child(roca)


func _montar_mar_de_nubes() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.70, 0.80, 0.88, 0.62)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for datos in [
		{"y": -5.2, "tam": 95.0, "giro": 7.0},
		{"y": -5.8, "tam": 82.0, "giro": -11.0},
	]:
		var plano := PlaneMesh.new()
		plano.size = Vector2(float(datos["tam"]), float(datos["tam"]))
		var nube := MeshInstance3D.new()
		nube.name = "MarDeNubes"
		nube.mesh = plano
		nube.material_override = material
		nube.position.y = float(datos["y"])
		nube.rotation_degrees.y = float(datos["giro"])
		add_child(nube)


func _montar_huellas() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.46, 0.56, 0.63)
	material.roughness = 1.0
	var forma := QuadMesh.new()
	forma.size = Vector2(0.18, 0.38)
	var posiciones := [
		Vector3(-0.18, 0.055, -11.4), Vector3(0.20, 0.055, -10.8),
		Vector3(-0.17, 0.055, -9.6), Vector3(0.21, 0.055, -9.0),
		Vector3(-0.15, 0.055, -7.8), Vector3(0.23, 0.055, -7.2),
	]
	var grupo := Node3D.new()
	grupo.name = "HuellasAnticipadas"
	add_child(grupo)
	for i in posiciones.size():
		var huella := MeshInstance3D.new()
		huella.name = "Huella%02d" % (i + 1)
		huella.mesh = forma
		huella.material_override = material
		huella.position = posiciones[i]
		huella.rotation_degrees = Vector3(-90.0, -8.0 if i % 2 == 0 else 9.0, 0.0)
		grupo.add_child(huella)


func _montar_documento_hielo(pos: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arriba := Vector3(0, 1.25, 0)
	var abajo := Vector3(0, -1.15, 0)
	var anillo := [
		Vector3(-0.72, 0, -0.30),
		Vector3(-0.22, 0, -0.72),
		Vector3(0.66, 0, -0.38),
		Vector3(0.58, 0, 0.52),
		Vector3(-0.34, 0, 0.68),
	]
	for i in anillo.size():
		var a: Vector3 = anillo[i]
		var b: Vector3 = anillo[(i + 1) % anillo.size()]
		st.add_vertex(arriba)
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(abajo)
		st.add_vertex(b)
		st.add_vertex(a)
	st.generate_normals()
	var hielo := MeshInstance3D.new()
	hielo.name = "DocumentoCongelado"
	hielo.mesh = st.commit()
	hielo.position = pos + Vector3(0, 1.0, 0)
	var mat_hielo := StandardMaterial3D.new()
	mat_hielo.albedo_color = Color(0.46, 0.78, 0.94, 0.58)
	mat_hielo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_hielo.roughness = 0.16
	hielo.material_override = mat_hielo
	add_child(hielo)

	var papel_mesh := QuadMesh.new()
	papel_mesh.size = Vector2(0.66, 0.88)
	var papel := MeshInstance3D.new()
	papel.name = "PapelDentroDelHielo"
	papel.mesh = papel_mesh
	papel.position = Vector3(0, 0.05, 0.02)
	papel.rotation_degrees = Vector3(0, 14, -9)
	var mat_papel := StandardMaterial3D.new()
	mat_papel.albedo_color = Color(0.83, 0.82, 0.74)
	mat_papel.roughness = 0.9
	papel.material_override = mat_papel
	hielo.add_child(papel)
