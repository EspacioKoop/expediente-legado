## Presentación 3D del desierto onírico (#284).
##
## La familia FRAGMENTADA conserva la única física. Esta capa oculta la sala
## cerrada y la viste como extensión mineral abierta: arena, horizonte, cabina,
## archivador, huellas imposibles, papel semienterrado y silencio localizado.
class_name SuenoDesierto3D
extends Node3D

const ESCENA_TELEFONO := preload("res://escenas/suenos/props_284/cabina_telefono_desierto.tscn")
const ESCENA_ARCHIVADOR := preload("res://escenas/suenos/props_284/archivador_desierto.tscn")
const RADIO_HORIZONTE := 34.0
const CENTRO_SILENCIO := Vector3(-7.5, 0.0, 4.5)
const RADIO_SILENCIO := 3.4

var _estructura_horizonte: MeshInstance3D
var _papel: MeshInstance3D
var _papel_base := Vector3.ZERO
var _ambiente: AudioStreamPlayer3D
var _tono: AudioStreamPlayer3D
var _tiempo := 0.0


static func montar(mundo: Node3D, espacio: Dictionary) -> Node3D:
	if mundo == null or String(espacio.get("identidad_onirica", "")) != SuenoDesierto.ID:
		return null
	var presentacion := SuenoDesierto3D.new()
	presentacion.name = "PresentacionDesierto284"
	mundo.add_child(presentacion)
	presentacion._configurar(espacio)
	return presentacion


func _configurar(espacio: Dictionary) -> void:
	_ocultar_sala_cerrada()
	var contorno: PackedVector2Array = espacio.get("contorno", PackedVector2Array())
	_montar_suelo(contorno)
	_montar_tabiques_visibles(espacio.get("tabiques_poligonales", []))
	_montar_dunas_lejanas()
	_montar_huellas()
	_montar_sombra_sin_objeto()
	_montar_luz()

	var telefono_pos: Vector3 = espacio.get("desierto_telefono_pos", Vector3(6, 0, -8))
	var telefono := ESCENA_TELEFONO.instantiate() as Node3D
	telefono.name = "TelefonoAislado"
	telefono.position = telefono_pos
	telefono.rotation_degrees.y = -18.0
	add_child(telefono)

	_tono = AudioStreamPlayer3D.new()
	_tono.name = "TonoSinLinea"
	_tono.stream = SuenoDesiertoAudio.tono_telefono()
	_tono.position = Vector3(0, 1.35, 0)
	_tono.volume_db = -22.0
	_tono.unit_size = 5.0
	_tono.max_distance = 24.0
	telefono.add_child(_tono)
	_tono.play()

	var archivador_pos: Vector3 = espacio.get("desierto_archivador_pos", Vector3(-3, 0, 7))
	var archivador := ESCENA_ARCHIVADOR.instantiate() as Node3D
	archivador.name = "ArchivadorAislado"
	archivador.position = archivador_pos
	archivador.rotation_degrees.y = 24.0
	add_child(archivador)

	var papel_pos: Vector3 = espacio.get("desierto_papel_pos", Vector3(9, 0, 8))
	_montar_papel(papel_pos)
	_montar_estructura_horizonte()

	_ambiente = AudioStreamPlayer3D.new()
	_ambiente.name = "VientoConOficina"
	_ambiente.stream = SuenoDesiertoAudio.viento_con_oficina()
	_ambiente.position = Vector3.ZERO
	_ambiente.volume_db = -18.0
	_ambiente.unit_size = 18.0
	_ambiente.max_distance = 70.0
	add_child(_ambiente)
	_ambiente.play()


func _process(delta: float) -> void:
	_tiempo += delta
	if _papel != null:
		_papel.position.y = _papel_base.y + sin(_tiempo * 0.72) * 0.055
		_papel.rotation_degrees.y = 14.0 + sin(_tiempo * 0.41) * 5.0

	var camara := get_viewport().get_camera_3d()
	if camara == null:
		return
	var local_cam := to_local(camara.global_position)
	var horizontal := Vector3(local_cam.x, 0, local_cam.z)

	# La estructura conserva distancia aparente: el jugador anda, pero el
	# horizonte se desplaza con él en vez de acercarse al ritmo esperado.
	if _estructura_horizonte != null:
		var direccion := Vector3(0.72, 0, 0.69).normalized()
		_estructura_horizonte.position = horizontal + direccion * RADIO_HORIZONTE

	var en_silencio := horizontal.distance_to(CENTRO_SILENCIO) < RADIO_SILENCIO
	if _ambiente != null:
		_ambiente.volume_db = -80.0 if en_silencio else -18.0
	if _tono != null:
		_tono.volume_db = -80.0 if en_silencio else -22.0


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


func _montar_suelo(contorno: PackedVector2Array) -> void:
	if contorno.size() < 3:
		return
	var indices := Geometry2D.triangulate_polygon(contorno)
	if indices.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, indices.size(), 3):
		for indice in [indices[i], indices[i + 2], indices[i + 1]]:
			var punto := contorno[indice]
			var altura := sin(punto.x * 0.21 + punto.y * 0.13) * 0.055
			st.add_vertex(Vector3(punto.x, 0.035 + altura, punto.y))
	st.generate_normals()
	var suelo := MeshInstance3D.new()
	suelo.name = "ArenaCaminable"
	suelo.mesh = st.commit()
	suelo.material_override = _material(Color(0.58, 0.39, 0.20), 0.96)
	add_child(suelo)


func _montar_tabiques_visibles(tabiques: Array) -> void:
	var malla := SuenoGeometria.malla_tabiques(tabiques)
	if malla.get_surface_count() == 0:
		return
	var visual := MeshInstance3D.new()
	visual.name = "TabiquesMineralesFragmentados"
	visual.mesh = malla
	var material := _material(Color(0.30, 0.18, 0.10), 0.98)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	visual.material_override = material
	add_child(visual)


func _montar_dunas_lejanas() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segmentos := 28
	for i in segmentos:
		var a0 := TAU * float(i) / segmentos
		var a1 := TAU * float(i + 1) / segmentos
		var interior_a := Vector3(cos(a0) * 20.0, -0.12, sin(a0) * 20.0)
		var interior_b := Vector3(cos(a1) * 20.0, -0.12, sin(a1) * 20.0)
		var altura_a := 1.4 + sin(a0 * 3.0) * 0.9
		var altura_b := 1.4 + sin(a1 * 3.0) * 0.9
		var exterior_a := Vector3(cos(a0) * 44.0, altura_a, sin(a0) * 44.0)
		var exterior_b := Vector3(cos(a1) * 44.0, altura_b, sin(a1) * 44.0)
		st.add_vertex(interior_a)
		st.add_vertex(exterior_b)
		st.add_vertex(exterior_a)
		st.add_vertex(interior_a)
		st.add_vertex(interior_b)
		st.add_vertex(exterior_b)
	st.generate_normals()
	var dunas := MeshInstance3D.new()
	dunas.name = "HorizonteDeDunas"
	dunas.mesh = st.commit()
	var material_dunas := _material(Color(0.42, 0.25, 0.12), 1.0)
	# El jugador observa el cinturón desde dentro. Con culling por defecto, gran
	# parte del anillo quedaba invisible y la captura de #1011 parecía un vacío
	# beige sin horizonte. Aquí no hay física: solo hacemos visible ambas caras.
	material_dunas.cull_mode = BaseMaterial3D.CULL_DISABLED
	dunas.material_override = material_dunas
	add_child(dunas)


func _montar_huellas() -> void:
	var forma := QuadMesh.new()
	forma.size = Vector2(0.18, 0.36)
	var material := _material(Color(0.31, 0.20, 0.12), 1.0)
	var grupo := Node3D.new()
	grupo.name = "HuellasGeometricas"
	add_child(grupo)
	for i in 14:
		var angulo := TAU * float(i) / 14.0
		var radio := 4.6 if i % 2 == 0 else 6.2
		var huella := MeshInstance3D.new()
		huella.name = "Huella%02d" % (i + 1)
		huella.mesh = forma
		huella.material_override = material
		huella.position = Vector3(cos(angulo) * radio, 0.065, sin(angulo) * radio)
		huella.rotation_degrees = Vector3(-90.0, -rad_to_deg(angulo), 0.0)
		grupo.add_child(huella)


func _montar_sombra_sin_objeto() -> void:
	var forma := QuadMesh.new()
	forma.size = Vector2(1.3, 7.5)
	var sombra := MeshInstance3D.new()
	sombra.name = "SombraSinObjeto"
	sombra.mesh = forma
	sombra.position = Vector3(2.8, 0.052, 2.0)
	sombra.rotation_degrees = Vector3(-90.0, 22.0, 0.0)
	var material := _material(Color(0.10, 0.075, 0.055, 0.62), 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sombra.material_override = material
	add_child(sombra)


func _montar_papel(pos: Vector3) -> void:
	var forma := QuadMesh.new()
	forma.size = Vector2(0.70, 0.92)
	_papel = MeshInstance3D.new()
	_papel.name = "PapelSemienterrado"
	_papel.mesh = forma
	_papel.position = pos + Vector3(0, 0.075, 0)
	_papel.rotation_degrees = Vector3(-78.0, 14.0, 8.0)
	_papel.material_override = _material(Color(0.78, 0.72, 0.56), 0.92)
	_papel_base = _papel.position
	add_child(_papel)


func _montar_estructura_horizonte() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := [
		Vector3(-0.55, 0, -0.42),
		Vector3(0.55, 0, -0.42),
		Vector3(0.48, 0, 0.42),
		Vector3(-0.48, 0, 0.42),
	]
	var cima := [
		Vector3(-0.18, 5.5, -0.16),
		Vector3(0.18, 5.5, -0.16),
		Vector3(0.14, 5.5, 0.16),
		Vector3(-0.14, 5.5, 0.16),
	]
	for i in 4:
		var siguiente := (i + 1) % 4
		st.add_vertex(base[i])
		st.add_vertex(base[siguiente])
		st.add_vertex(cima[siguiente])
		st.add_vertex(base[i])
		st.add_vertex(cima[siguiente])
		st.add_vertex(cima[i])
	st.generate_normals()
	_estructura_horizonte = MeshInstance3D.new()
	_estructura_horizonte.name = "EstructuraQueNoSeAcerca"
	_estructura_horizonte.mesh = st.commit()
	_estructura_horizonte.material_override = _material(Color(0.16, 0.12, 0.09), 1.0)
	add_child(_estructura_horizonte)


func _montar_luz() -> void:
	var sol := DirectionalLight3D.new()
	sol.name = "SolDesierto"
	sol.light_color = Color(1.0, 0.72, 0.42)
	sol.light_energy = 1.35
	sol.rotation_degrees = Vector3(-38.0, -24.0, 0.0)
	sol.shadow_enabled = true
	add_child(sol)


func _material(color: Color, rugosidad: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rugosidad
	return material
