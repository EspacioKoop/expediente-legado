## Superficie visual aislada del editor de autoría.
## Renderiza colocaciones y permite moverlas en el plano XZ con ratón.
extends SubViewportContainer

signal colocacion_seleccionada(indice: int)
signal transformacion_cambiada(indice: int, posicion: Vector3)

const TAMANO_MINIMO := Vector2(640, 420)
const COLOR_SELECCION := Color(0.95, 0.72, 0.18)
const LENGUAJE_CINE := preload("res://guion/lenguaje_cine.gd")
const ESPACIO3D := preload("res://guion/espacio_3d.gd")
const MODELOS := preload("res://guion/modelos.gd")
const CONTRATO := preload("res://debug/editor_niveles_cinematicas_contrato.gd")

var _viewport: SubViewport
var _mundo: Node3D
var _camara: Camera3D
var _marcador_mira: MeshInstance3D
var _nodos_colocacion: Array[Node3D] = []
var _raiz_escenario: Node3D
var _huella_escenario := 0
var _huella_colocaciones := 0
var _indice_arrastrado := -1
var _arrastrando := false
var _plano_arrastre := Plane(Vector3.UP, 0.0)
var _offset_arrastre := Vector3.ZERO


func _ready() -> void:
	custom_minimum_size = TAMANO_MINIMO
	stretch = true
	_montar_escena()


func _montar_escena() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "ViewportAutoría"
	_viewport.size = Vector2i(960, 600)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.own_world_3d = true
	add_child(_viewport)
	_mundo = Node3D.new()
	_mundo.name = "EscenaAutoría"
	_viewport.add_child(_mundo)
	_montar_suelo()
	_montar_luces()
	_camara = Camera3D.new()
	_camara.name = "CamaraEditor"
	_camara.position = Vector3(8.0, 7.0, 10.0)
	_camara.current = true
	_mundo.add_child(_camara)
	_camara.look_at(Vector3.ZERO)
	_marcador_mira = _marcador(Color(0.95, 0.2, 0.15), 0.16)
	_marcador_mira.name = "MiraCinematica"
	_mundo.add_child(_marcador_mira)


func _marcador(color: Color, radio: float) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = radio
	esfera.height = radio * 2.0
	nodo.mesh = esfera
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	nodo.material_override = material
	return nodo


func _montar_suelo() -> void:
	var suelo := MeshInstance3D.new()
	suelo.name = "SueloEditor"
	var malla := PlaneMesh.new()
	malla.size = Vector2(24.0, 24.0)
	suelo.mesh = malla
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.16, 0.19)
	material.roughness = 1.0
	suelo.material_override = material
	_mundo.add_child(suelo)
	var malla_rejilla := ImmediateMesh.new()
	var material_rejilla := StandardMaterial3D.new()
	material_rejilla.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_rejilla.albedo_color = Color(0.33, 0.42, 0.46, 0.55)
	material_rejilla.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	malla_rejilla.surface_begin(Mesh.PRIMITIVE_LINES, material_rejilla)
	for coordenada in range(-12, 13):
		var borde := float(coordenada)
		malla_rejilla.surface_add_vertex(Vector3(borde, 0.015, -12.0))
		malla_rejilla.surface_add_vertex(Vector3(borde, 0.015, 12.0))
		malla_rejilla.surface_add_vertex(Vector3(-12.0, 0.015, borde))
		malla_rejilla.surface_add_vertex(Vector3(12.0, 0.015, borde))
	malla_rejilla.surface_end()
	var rejilla := MeshInstance3D.new()
	rejilla.name = "GuiaSuelo"
	rejilla.mesh = malla_rejilla
	_mundo.add_child(rejilla)


func _montar_luces() -> void:
	var ambiente := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_SKY
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.55, 0.58, 0.62)
	entorno.ambient_light_energy = 0.7
	ambiente.environment = entorno
	_mundo.add_child(ambiente)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	luz.light_energy = 1.3
	_mundo.add_child(luz)


func cargar_escenario(escenario: Dictionary) -> void:
	var huella := hash(escenario)
	if is_instance_valid(_raiz_escenario) and huella == _huella_escenario:
		return
	if is_instance_valid(_raiz_escenario):
		_raiz_escenario.queue_free()
	_raiz_escenario = Node3D.new()
	_raiz_escenario.name = "EscenarioCatalogado"
	_huella_escenario = huella
	_mundo.add_child(_raiz_escenario)
	if not escenario.is_empty():
		ESPACIO3D.construir(_raiz_escenario, escenario)
	var suelo_editor := _mundo.get_node_or_null("SueloEditor") as MeshInstance3D
	var guia_suelo := _mundo.get_node_or_null("GuiaSuelo") as MeshInstance3D
	if suelo_editor != null:
		suelo_editor.visible = escenario.is_empty()
	if guia_suelo != null:
		guia_suelo.visible = escenario.is_empty()


func mostrar_nivel(escenario: Dictionary, colocaciones: Array) -> void:
	cargar_escenario(escenario)
	cargar_colocaciones(colocaciones)


func mostrar_decorado(decorado: Variant) -> void:
	var escenario: Dictionary = {}
	var objetos: Array = []
	if decorado is Dictionary:
		escenario = decorado.duplicate(true)
		var bultos: Variant = escenario.get("bultos", [])
		if bultos is Array:
			objetos = bultos
		escenario.erase("bultos")
	cargar_escenario(CONTRATO.espacio_para_vista(escenario))
	cargar_colocaciones(objetos)


func cargar_colocaciones(colocaciones: Array) -> void:
	if _arrastrando:
		return
	var huella := hash(colocaciones)
	if huella == _huella_colocaciones and not _nodos_colocacion.is_empty():
		return
	_huella_colocaciones = huella
	for nodo in _nodos_colocacion:
		if is_instance_valid(nodo):
			nodo.queue_free()
	_nodos_colocacion.clear()
	for indice in colocaciones.size():
		var entrada: Variant = colocaciones[indice]
		if not entrada is Dictionary:
			continue
		var nodo := _crear_representacion(entrada, indice)
		_mundo.add_child(nodo)
		_nodos_colocacion.append(nodo)


func _crear_representacion(entrada: Dictionary, indice: int) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Colocacion_%d_%s" % [indice, String(entrada.get("id", "sin_id"))]
	raiz.set_meta("indice_documento", indice)
	var transform: Dictionary = entrada.get("transform", {})
	var posicion: Variant = transform.get(
		"posicion", entrada.get("pos", [float(indice % 4) * 1.5, 0.5, float(indice / 4) * 1.5])
	)
	if posicion is Array and posicion.size() == 3:
		raiz.position = Vector3(float(posicion[0]), float(posicion[1]), float(posicion[2]))
	var rotacion: Variant = transform.get("rotacion", entrada.get("rotacion", [0.0, 0.0, 0.0]))
	if rotacion is Array and rotacion.size() == 3:
		raiz.rotation_degrees = Vector3(float(rotacion[0]), float(rotacion[1]), float(rotacion[2]))
	var escala: Variant = transform.get("escala", entrada.get("escala", [1.0, 1.0, 1.0]))
	if escala is Array and escala.size() == 3:
		raiz.scale = Vector3(float(escala[0]), float(escala[1]), float(escala[2]))

	var extra: Variant = entrada.get("extra", {})
	var extra_datos: Dictionary = extra if extra is Dictionary else {}
	var tam_dato: Variant = extra_datos.get("tam", entrada.get("tam", [2.0, 0.75, 1.0]))
	var tam := Vector3(2.0, 0.75, 1.0)
	if tam_dato is Array and tam_dato.size() == 3:
		tam = Vector3(float(tam_dato[0]), float(tam_dato[1]), float(tam_dato[2]))
	var recurso := String(entrada.get("recurso", entrada.get("modelo", "")))
	# Cualquier asset del proyecto, no solo los cinco nombres catalogados: la
	# previsualización tiene que mostrar lo mismo que montará `Espacio3D` en el
	# juego, y ese resuelve el modelo con el mismo `Modelos.hay/cargar`.
	var hay_modelo := not recurso.is_empty() and MODELOS.hay(recurso)
	if hay_modelo and MODELOS.mueble(raiz, recurso, tam, Color(0.45, 0.44, 0.42)):
		return raiz
	if hay_modelo:
		push_warning("No se pudo cargar el modelo '%s'; se muestra una caja" % recurso)
	var malla := MeshInstance3D.new()
	malla.name = "Representacion"
	var cubo := BoxMesh.new()
	cubo.size = tam
	malla.mesh = cubo
	var material := StandardMaterial3D.new()
	material.albedo_color = _color_tipo(String(entrada.get("tipo", "")))
	material.roughness = 0.82
	malla.material_override = material
	malla.set_meta("indice_documento", indice)
	malla.position.y = tam.y / 2.0
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	raiz.add_child(malla)
	return raiz


func _color_tipo(tipo: String) -> Color:
	match tipo:
		"figura":
			return Color(0.34, 0.68, 0.82)
		"luz":
			return Color(0.96, 0.78, 0.27)
		"salida":
			return Color(0.32, 0.75, 0.42)
		"ventana":
			return Color(0.5, 0.68, 0.9)
		"pantalla":
			return Color(0.64, 0.46, 0.78)
		_:
			return Color(0.72, 0.55, 0.38)


func mostrar_plano_cinematica(plano: Dictionary, avance: float = 1.0) -> void:
	if String(plano.get("tipo", "3d")) != "3d":
		_camara.position = Vector3(8.0, 7.0, 10.0)
		_camara.look_at(Vector3.ZERO)
		_marcador_mira.visible = false
		return
	_marcador_mira.visible = true
	var cam: Variant = plano.get("camara", [8.0, 7.0, 10.0])
	var mira: Variant = plano.get("mira", [0.0, 0.0, 0.0])
	if not (cam is Array and cam.size() == 3 and mira is Array and mira.size() == 3):
		return
	var destino := Vector3(float(cam[0]), float(cam[1]), float(cam[2]))
	var destino_mira := Vector3(float(mira[0]), float(mira[1]), float(mira[2]))
	var origen_cam: Variant = plano.get("camara_desde", destino)
	var origen_mira: Variant = plano.get("mira_desde", destino_mira)
	if not (origen_cam is Array and origen_cam.size() == 3):
		origen_cam = cam
	if not (origen_mira is Array and origen_mira.size() == 3):
		origen_mira = mira
	var origen := Vector3(float(origen_cam[0]), float(origen_cam[1]), float(origen_cam[2]))
	var mira_inicial := Vector3(float(origen_mira[0]), float(origen_mira[1]), float(origen_mira[2]))
	var t := clampf(avance, 0.0, 1.0)
	var mira_actual := destino_mira
	if plano.has("camara_desde") or plano.has("mira_desde"):
		var suave := t * t * (3.0 - 2.0 * t)
		_camara.position = origen.lerp(destino, suave)
		mira_actual = mira_inicial.lerp(destino_mira, suave)
	else:
		# Conserva el pequeño acercamiento heredado del reproductor runtime.
		_camara.position = destino + destino.normalized() * -0.25 * t
	_camara.look_at(mira_actual, Vector3.UP)
	_camara.fov = LENGUAJE_CINE.fov_de(plano)
	_marcador_mira.position = mira_actual


func posicion_colocacion(indice: int) -> Vector3:
	var nodo := _nodo_por_indice(indice)
	return nodo.position if nodo != null else Vector3.ZERO


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_comenzar_arrastre(evento.position)
		else:
			_finalizar_arrastre()
		accept_event()
	elif evento is InputEventMouseMotion and _arrastrando:
		_mover_arrastrado(evento.position)
		accept_event()


func _comenzar_arrastre(posicion_raton: Vector2) -> void:
	var origen := _camara.project_ray_origin(posicion_raton)
	var direccion := _camara.project_ray_normal(posicion_raton)
	var consulta := PhysicsRayQueryParameters3D.create(origen, origen + direccion * 300.0)
	consulta.collide_with_areas = true
	var espacio := _viewport.world_3d.direct_space_state
	var impacto := espacio.intersect_ray(consulta)
	var indice := -1
	if not impacto.is_empty():
		var objetivo: Object = impacto.get("collider")
		while objetivo != null and objetivo is Node:
			if objetivo.has_meta("indice_documento"):
				indice = int(objetivo.get_meta("indice_documento"))
				break
			objetivo = objetivo.get_parent()
	# Sin física dinámica en los datos editoriales: selección por proyección
	# geométrica de las cajas visibles, de forma determinista y sin cuerpos ocultos.
	if indice < 0:
		indice = _seleccionar_proyectado(posicion_raton)
	if indice < 0:
		return
	var nodo := _nodo_por_indice(indice)
	if nodo == null:
		return
	_indice_arrastrado = indice
	_arrastrando = true
	_plano_arrastre = Plane(Vector3.UP, -nodo.position.y)
	var punto := _interseccion_rayo(origen, direccion, _plano_arrastre)
	_offset_arrastre = nodo.position - punto if punto != Vector3.INF else Vector3.ZERO
	colocacion_seleccionada.emit(indice)


func _seleccionar_proyectado(posicion_raton: Vector2) -> int:
	var mejor_indice := -1
	var mejor_distancia := 28.0
	for nodo in _nodos_colocacion:
		var pantalla := _camara.unproject_position(nodo.global_position)
		var distancia := pantalla.distance_to(posicion_raton)
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor_indice = int(nodo.get_meta("indice_documento"))
	return mejor_indice


func _mover_arrastrado(posicion_raton: Vector2) -> void:
	var nodo := _nodo_por_indice(_indice_arrastrado)
	if nodo == null:
		return
	var origen := _camara.project_ray_origin(posicion_raton)
	var direccion := _camara.project_ray_normal(posicion_raton)
	var punto := _interseccion_rayo(origen, direccion, _plano_arrastre)
	if punto == Vector3.INF:
		return
	nodo.position = punto + _offset_arrastre
	transformacion_cambiada.emit(_indice_arrastrado, nodo.position)


func _finalizar_arrastre() -> void:
	_arrastrando = false
	_indice_arrastrado = -1


func _interseccion_rayo(origen: Vector3, direccion: Vector3, plano: Plane) -> Vector3:
	var punto: Variant = plano.intersects_ray(origen, direccion)
	return punto if punto is Vector3 else Vector3.INF


func _nodo_por_indice(indice: int) -> Node3D:
	for nodo in _nodos_colocacion:
		if is_instance_valid(nodo) and int(nodo.get_meta("indice_documento", -1)) == indice:
			return nodo
	return null
