## Una pieza de fauna ambiental 3D (#1396, #1403).
##
## No tiene _process(), colisión, navegación ni interacción. El
## AnimadorAmbiental3D compartido decide cuándo merece actualizarse. Cuando la
## pieza está cerca consulta la cámara activa y aplica una reacción puramente
## visual; fuera de ese aviso no ejecuta trabajo.
class_name AnimalAmbiental3D
extends Node3D

var reduccion_movimiento := false

var _dato: Dictionary = {}
var _origen := Vector3.ZERO
var _fase := 0.0
var _id := ""
var _movimiento := "quieto"
var _reaccion := "ninguna"
var _distancia_alerta := 0.0
var _intensidad_reaccion := 0.0
var _visual: Node3D = null
var _animador: AnimadorAmbiental3D = null
var _partes: Dictionary = {}
var _rotaciones_base: Dictionary = {}
var _materiales: Dictionary = {}


func configurar(
	dato: Dictionary,
	animador: AnimadorAmbiental3D = null,
	reducir_movimiento: bool = false,
) -> void:
	_dato = dato.duplicate(true)
	_animador = animador
	reduccion_movimiento = reducir_movimiento
	_id = String(_dato.get("id", ""))
	_movimiento = String(_dato.get("movimiento", "quieto"))
	_reaccion = String(_dato.get("reaccion", "ninguna"))
	_distancia_alerta = float(_dato.get("distancia_alerta", 0.0))
	_intensidad_reaccion = float(_dato.get("intensidad_reaccion", 0.0))
	_fase = float(_dato.get("fase", 0.0))
	_origen = _dato.get("pos", Vector3.ZERO)
	position = _origen
	set_meta("fauna_id", _id)
	set_meta("especie", String(_dato.get("especie", "")))
	set_meta("fauna_ambiental", true)
	set_meta("reaccion_fauna", _reaccion)
	_montar_visual()


func id_fauna() -> String:
	return _id


func especie() -> String:
	return String(_dato.get("especie", ""))


func origen() -> Vector3:
	return _origen


func reaccion() -> String:
	return _reaccion


func distancia_alerta() -> float:
	return _distancia_alerta


func desplazamiento_en(tiempo: float) -> Vector3:
	var t := tiempo + _fase
	match _movimiento:
		"suelo_ave":
			return Vector3(
				sin(t * 0.83) * 0.34,
				maxf(sin(t * 3.1), 0.0) * 0.028,
				cos(t * 0.61) * 0.24,
			)
		"deambular":
			return Vector3(sin(t * 0.23) * 0.72, 0.0, cos(t * 0.19) * 0.38)
		"vuelo":
			return Vector3(sin(t * 0.62) * 1.18, sin(t * 1.31) * 0.22, cos(t * 0.62) * 1.18)
		"orbita":
			return Vector3(sin(t * 1.42) * 0.58, sin(t * 2.17) * 0.36, cos(t * 1.42) * 0.58)
	return Vector3.ZERO


## Respuesta pura y comprobable a una posición de observador expresada en el
## mismo espacio local que [param posicion_base].
func respuesta_proximidad(observador_local: Vector3, posicion_base: Vector3) -> Dictionary:
	var respuesta := _respuesta_vacia()
	if _distancia_alerta <= 0.0 or _reaccion == "ninguna":
		return respuesta

	var separacion := posicion_base - observador_local
	separacion.y = 0.0
	var distancia := separacion.length()
	if distancia >= _distancia_alerta:
		return respuesta

	var peso := 1.0 - clampf(distancia / _distancia_alerta, 0.0, 1.0)
	var direccion := separacion
	if direccion.length_squared() < 0.000001:
		direccion = Vector3.FORWARD
	else:
		direccion = direccion.normalized()

	respuesta["peso"] = peso
	match _reaccion:
		"huir":
			respuesta["desplazamiento"] = direccion * _intensidad_reaccion * peso
		"subir":
			respuesta["desplazamiento"] = (
				direccion * _intensidad_reaccion * 0.25 * peso
				+ Vector3.UP * _intensidad_reaccion * peso
			)
		"observar":
			respuesta["mirar"] = true
			respuesta["factor_movimiento"] = maxf(0.35, 1.0 - peso * 0.65)
		"vigilar":
			respuesta["mirar"] = true
			respuesta["factor_movimiento"] = maxf(0.08, 1.0 - peso * 0.92)
	return respuesta


func animar_pieza(id: String, tiempo: float, _transcurrido: float, lod: String) -> void:
	if id != _id or reduccion_movimiento:
		return

	var desplazamiento := desplazamiento_en(tiempo)
	var posicion_base := _origen + desplazamiento
	var respuesta := _respuesta_actual(posicion_base)
	var factor_movimiento := float(respuesta.get("factor_movimiento", 1.0))
	var desplazamiento_reactivo: Vector3 = respuesta.get("desplazamiento", Vector3.ZERO)
	desplazamiento *= factor_movimiento
	position = _origen + desplazamiento + desplazamiento_reactivo

	if lod != AnimacionAmbiental.LOD_LEJOS:
		_orientar(tiempo, desplazamiento, respuesta)
		_animar_gesto(tiempo, float(respuesta.get("peso", 0.0)))

	if _animador != null and is_inside_tree():
		_animador.mover(_id, global_position)


func _respuesta_actual(posicion_base: Vector3) -> Dictionary:
	var respuesta := _respuesta_vacia()
	if not is_inside_tree():
		return respuesta
	var camara := get_viewport().get_camera_3d()
	if camara == null:
		return respuesta

	var observador := camara.global_position
	var padre := get_parent() as Node3D
	if padre != null:
		observador = padre.to_local(observador)

	respuesta = respuesta_proximidad(observador, posicion_base)
	respuesta["observador"] = observador
	return respuesta


func _respuesta_vacia() -> Dictionary:
	return {
		"peso": 0.0,
		"desplazamiento": Vector3.ZERO,
		"mirar": false,
		"factor_movimiento": 1.0,
		"observador": Vector3.ZERO,
	}


func _orientar(tiempo: float, desplazamiento: Vector3, respuesta: Dictionary) -> void:
	if bool(respuesta.get("mirar", false)) and float(respuesta.get("peso", 0.0)) > 0.0:
		var observador: Vector3 = respuesta.get("observador", Vector3.ZERO)
		var hacia_observador := observador - position
		hacia_observador.y = 0.0
		if hacia_observador.length_squared() > 0.000001:
			rotation.y = atan2(-hacia_observador.x, -hacia_observador.z)
		return

	var siguiente := desplazamiento_en(tiempo + 0.08)
	var avance := siguiente - desplazamiento
	if Vector2(avance.x, avance.z).length_squared() > 0.000001:
		rotation.y = atan2(-avance.x, -avance.z)


func _animar_gesto(tiempo: float, peso_reaccion: float) -> void:
	if _visual == null:
		return
	var t := tiempo + _fase
	_visual.rotation.z = sin(t * 2.1) * 0.035
	match especie():
		"paloma", "gorrion":
			_aplicar_rotacion_gesto("Cabeza", Vector3(sin(t * 3.2) * 0.10, 0.0, 0.0))
			var ala_suelo := absf(sin(t * 2.4)) * 0.045
			_aplicar_rotacion_gesto("AlaI", Vector3(0.0, 0.0, ala_suelo))
			_aplicar_rotacion_gesto("AlaD", Vector3(0.0, 0.0, -ala_suelo))
		"cuervo":
			var batido_cuervo := absf(sin(t * 4.4)) * 0.48
			_aplicar_rotacion_gesto("AlaI", Vector3(0.0, 0.0, batido_cuervo))
			_aplicar_rotacion_gesto("AlaD", Vector3(0.0, 0.0, -batido_cuervo))
			_aplicar_rotacion_gesto("Cabeza", Vector3(0.0, sin(t * 0.9) * 0.08, 0.0))
		"perro":
			_aplicar_rotacion_gesto("Cola", Vector3(0.0, sin(t * 3.0) * 0.55, 0.0))
			_aplicar_rotacion_gesto(
				"Cabeza",
				Vector3(sin(t * 1.7) * 0.07 * (1.0 - peso_reaccion), 0.0, 0.0),
			)
		"polilla":
			var batido_polilla := sin(t * 6.2) * 0.72
			_aplicar_rotacion_gesto("AlaI", Vector3(0.0, 0.0, batido_polilla))
			_aplicar_rotacion_gesto("AlaD", Vector3(0.0, 0.0, -batido_polilla))
		"ciervo":
			_aplicar_rotacion_gesto(
				"Cabeza",
				Vector3(0.0, sin(t * 0.55) * 0.08 * (1.0 - peso_reaccion), 0.0),
			)


func _aplicar_rotacion_gesto(nombre: String, delta: Vector3) -> void:
	var parte := _partes.get(nombre) as Node3D
	if parte == null:
		return
	var base: Vector3 = _rotaciones_base.get(nombre, Vector3.ZERO)
	parte.rotation = base + delta


func _montar_visual() -> void:
	if _visual != null:
		_visual.queue_free()
	_partes.clear()
	_rotaciones_base.clear()
	_materiales.clear()
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.scale = Vector3.ONE * float(_dato.get("escala", 1.0))

	var color: Color = _dato.get("color", Color.WHITE)
	match especie():
		"paloma", "gorrion", "cuervo":
			_montar_ave(color)
		"perro":
			_montar_perro(color)
		"polilla":
			_montar_polilla(color)
		"ciervo":
			_montar_ciervo(color)


func _montar_ave(color: Color) -> void:
	_parte_esfera(
		"Cuerpo", Vector3(0.30, 0.22, 0.42), Vector3(0, 0.15, 0), color, Vector3.ZERO, 0.88, true
	)
	_parte_esfera(
		"Cabeza",
		Vector3(0.18, 0.18, 0.18),
		Vector3(0, 0.27, -0.19),
		color.lightened(0.06),
		Vector3.ZERO,
		0.84,
		true,
	)
	_parte_cono(
		"Pico",
		Vector3(0.075, 0.13, 0.075),
		Vector3(0, 0.255, -0.34),
		Color(0.72, 0.52, 0.20),
		Vector3(-90, 0, 0),
		0.72,
	)
	_parte_capsula(
		"Cola",
		Vector3(0.13, 0.25, 0.055),
		Vector3(0, 0.14, 0.31),
		color.darkened(0.16),
		Vector3(-90, 0, 0),
		0.90,
	)
	_parte_esfera(
		"AlaI",
		Vector3(0.27, 0.055, 0.28),
		Vector3(-0.16, 0.15, 0.015),
		color.darkened(0.10),
		Vector3(0, 0, 14),
		0.91,
		true,
	)
	_parte_esfera(
		"AlaD",
		Vector3(0.27, 0.055, 0.28),
		Vector3(0.16, 0.15, 0.015),
		color.darkened(0.10),
		Vector3(0, 0, -14),
		0.91,
		true,
	)
	_parte_esfera(
		"OjoI",
		Vector3(0.030, 0.030, 0.030),
		Vector3(-0.060, 0.285, -0.270),
		Color(0.012, 0.010, 0.010),
		Vector3.ZERO,
		0.36,
	)
	_parte_esfera(
		"OjoD",
		Vector3(0.030, 0.030, 0.030),
		Vector3(0.060, 0.285, -0.270),
		Color(0.012, 0.010, 0.010),
		Vector3.ZERO,
		0.36,
	)
	_parte_cilindro(
		"PataI",
		Vector3(0.025, 0.11, 0.025),
		Vector3(-0.048, 0.04, 0.03),
		Color(0.45, 0.28, 0.20),
		Vector3.ZERO,
		0.82,
	)
	_parte_cilindro(
		"PataD",
		Vector3(0.025, 0.11, 0.025),
		Vector3(0.048, 0.04, 0.03),
		Color(0.45, 0.28, 0.20),
		Vector3.ZERO,
		0.82,
	)


func _montar_perro(color: Color) -> void:
	_parte_capsula(
		"Cuerpo",
		Vector3(0.46, 0.72, 0.46),
		Vector3(0, 0.46, 0),
		color,
		Vector3(-90, 0, 0),
		0.86,
		true,
	)
	_parte_esfera(
		"Pecho",
		Vector3(0.37, 0.48, 0.34),
		Vector3(0, 0.50, -0.30),
		color.lightened(0.05),
		Vector3.ZERO,
		0.88,
		true,
	)
	_parte_esfera(
		"Cabeza",
		Vector3(0.38, 0.38, 0.40),
		Vector3(0, 0.72, -0.58),
		color.lightened(0.08),
		Vector3.ZERO,
		0.84,
		true,
	)
	_parte_capsula(
		"Morro",
		Vector3(0.24, 0.31, 0.20),
		Vector3(0, 0.63, -0.82),
		color.darkened(0.10),
		Vector3(-90, 0, 0),
		0.80,
	)
	_parte_esfera(
		"Nariz",
		Vector3(0.13, 0.10, 0.10),
		Vector3(0, 0.63, -0.98),
		Color(0.035, 0.03, 0.03),
		Vector3.ZERO,
		0.34,
	)
	_parte_esfera(
		"OrejaI",
		Vector3(0.14, 0.24, 0.08),
		Vector3(-0.13, 0.91, -0.57),
		color.darkened(0.12),
		Vector3(0, 0, -15),
		0.92,
	)
	_parte_esfera(
		"OrejaD",
		Vector3(0.14, 0.24, 0.08),
		Vector3(0.13, 0.91, -0.57),
		color.darkened(0.12),
		Vector3(0, 0, 15),
		0.92,
	)
	for x in [-0.15, 0.15]:
		for z in [-0.25, 0.25]:
			_parte_capsula(
				"Pata",
				Vector3(0.09, 0.30, 0.09),
				Vector3(x, 0.19, z),
				color.darkened(0.07),
				Vector3.ZERO,
				0.90,
			)
	_parte_capsula(
		"Cola",
		Vector3(0.085, 0.43, 0.085),
		Vector3(0, 0.57, 0.57),
		color.darkened(0.08),
		Vector3(58, 0, 0),
		0.90,
	)


func _montar_polilla(color: Color) -> void:
	_parte_capsula(
		"Cuerpo",
		Vector3(0.11, 0.30, 0.11),
		Vector3.ZERO,
		color.darkened(0.25),
		Vector3(-90, 0, 0),
		0.78,
		true,
	)
	_parte_esfera(
		"AlaI",
		Vector3(0.53, 0.045, 0.38),
		Vector3(-0.26, 0, 0),
		color,
		Vector3(0, 12, 18),
		0.93,
		true,
	)
	_parte_esfera(
		"AlaD",
		Vector3(0.53, 0.045, 0.38),
		Vector3(0.26, 0, 0),
		color,
		Vector3(0, -12, -18),
		0.93,
		true,
	)
	_parte_esfera(
		"MarcaI",
		Vector3(0.12, 0.050, 0.12),
		Vector3(-0.30, 0.025, -0.02),
		color.darkened(0.30),
		Vector3.ZERO,
		0.86,
	)
	_parte_esfera(
		"MarcaD",
		Vector3(0.12, 0.050, 0.12),
		Vector3(0.30, 0.025, -0.02),
		color.darkened(0.30),
		Vector3.ZERO,
		0.86,
	)
	_parte_cilindro(
		"AntenaI",
		Vector3(0.018, 0.24, 0.018),
		Vector3(-0.05, 0.04, -0.22),
		color.darkened(0.30),
		Vector3(-18, -14, 0),
		0.88,
	)
	_parte_cilindro(
		"AntenaD",
		Vector3(0.018, 0.24, 0.018),
		Vector3(0.05, 0.04, -0.22),
		color.darkened(0.30),
		Vector3(-18, 14, 0),
		0.88,
	)


func _montar_ciervo(color: Color) -> void:
	_parte_capsula(
		"Cuerpo",
		Vector3(0.52, 0.88, 0.52),
		Vector3(0, 0.76, 0),
		color,
		Vector3(-90, 0, 0),
		0.87,
		true,
	)
	_parte_capsula(
		"Cuello",
		Vector3(0.28, 0.66, 0.28),
		Vector3(0, 1.08, -0.40),
		color.lightened(0.04),
		Vector3(-18, 0, 0),
		0.88,
		true,
	)
	_parte_esfera(
		"Cabeza",
		Vector3(0.31, 0.32, 0.43),
		Vector3(0, 1.43, -0.65),
		color.lightened(0.07),
		Vector3.ZERO,
		0.84,
		true,
	)
	_parte_capsula(
		"Morro",
		Vector3(0.20, 0.26, 0.18),
		Vector3(0, 1.36, -0.91),
		color.darkened(0.09),
		Vector3(-90, 0, 0),
		0.79,
	)
	_parte_esfera(
		"OrejaI",
		Vector3(0.11, 0.24, 0.075),
		Vector3(-0.17, 1.61, -0.63),
		color.lightened(0.04),
		Vector3(0, 0, -26),
		0.91,
	)
	_parte_esfera(
		"OrejaD",
		Vector3(0.11, 0.24, 0.075),
		Vector3(0.17, 1.61, -0.63),
		color.lightened(0.04),
		Vector3(0, 0, 26),
		0.91,
	)
	_parte_esfera(
		"OjoI",
		Vector3(0.032, 0.032, 0.032),
		Vector3(-0.090, 1.47, -0.825),
		Color(0.015, 0.012, 0.01),
		Vector3.ZERO,
		0.33,
	)
	_parte_esfera(
		"OjoD",
		Vector3(0.032, 0.032, 0.032),
		Vector3(0.090, 1.47, -0.825),
		Color(0.015, 0.012, 0.01),
		Vector3.ZERO,
		0.33,
	)
	for x in [-0.17, 0.17]:
		for z in [-0.34, 0.34]:
			_parte_capsula(
				"Pata",
				Vector3(0.085, 0.56, 0.085),
				Vector3(x, 0.34, z),
				color.darkened(0.10),
				Vector3.ZERO,
				0.91,
			)
			_parte_esfera(
				"Pezuña",
				Vector3(0.11, 0.075, 0.16),
				Vector3(x, 0.02, z - 0.025),
				Color(0.07, 0.055, 0.045),
				Vector3.ZERO,
				0.68,
			)
	_parte_cilindro(
		"AstaI",
		Vector3(0.035, 0.48, 0.035),
		Vector3(-0.10, 1.73, -0.61),
		Color(0.16, 0.12, 0.09),
		Vector3(0, 0, -12),
		0.76,
	)
	_parte_cilindro(
		"AstaD",
		Vector3(0.035, 0.48, 0.035),
		Vector3(0.10, 1.73, -0.61),
		Color(0.16, 0.12, 0.09),
		Vector3(0, 0, 12),
		0.76,
	)
	_parte_cilindro(
		"PuntaAstaI",
		Vector3(0.025, 0.25, 0.025),
		Vector3(-0.18, 1.90, -0.61),
		Color(0.16, 0.12, 0.09),
		Vector3(0, 0, -38),
		0.76,
	)
	_parte_cilindro(
		"PuntaAstaD",
		Vector3(0.025, 0.25, 0.025),
		Vector3(0.18, 1.90, -0.61),
		Color(0.16, 0.12, 0.09),
		Vector3(0, 0, 38),
		0.76,
	)


func _parte_esfera(
	nombre: String,
	escala: Vector3,
	posicion_local: Vector3,
	color: Color,
	giro_grados: Vector3 = Vector3.ZERO,
	rugosidad: float = 0.88,
	sombra: bool = false,
) -> MeshInstance3D:
	return _parte_mesh(
		nombre,
		_malla_esfera(),
		escala,
		posicion_local,
		color,
		giro_grados,
		rugosidad,
		sombra,
	)


func _parte_capsula(
	nombre: String,
	escala: Vector3,
	posicion_local: Vector3,
	color: Color,
	giro_grados: Vector3 = Vector3.ZERO,
	rugosidad: float = 0.88,
	sombra: bool = false,
) -> MeshInstance3D:
	return _parte_mesh(
		nombre,
		_malla_capsula(),
		escala,
		posicion_local,
		color,
		giro_grados,
		rugosidad,
		sombra,
	)


func _parte_cilindro(
	nombre: String,
	escala: Vector3,
	posicion_local: Vector3,
	color: Color,
	giro_grados: Vector3 = Vector3.ZERO,
	rugosidad: float = 0.88,
	sombra: bool = false,
) -> MeshInstance3D:
	return _parte_mesh(
		nombre,
		_malla_cilindro(),
		escala,
		posicion_local,
		color,
		giro_grados,
		rugosidad,
		sombra,
	)


func _parte_cono(
	nombre: String,
	escala: Vector3,
	posicion_local: Vector3,
	color: Color,
	giro_grados: Vector3 = Vector3.ZERO,
	rugosidad: float = 0.82,
	sombra: bool = false,
) -> MeshInstance3D:
	return _parte_mesh(
		nombre,
		_malla_cono(),
		escala,
		posicion_local,
		color,
		giro_grados,
		rugosidad,
		sombra,
	)


func _parte_mesh(
	nombre: String,
	malla: Mesh,
	escala: Vector3,
	posicion_local: Vector3,
	color: Color,
	giro_grados: Vector3,
	rugosidad: float,
	sombra: bool,
) -> MeshInstance3D:
	var parte := MeshInstance3D.new()
	parte.name = nombre
	parte.mesh = malla
	parte.material_override = _material(color, rugosidad)
	parte.position = posicion_local
	parte.rotation_degrees = giro_grados
	parte.scale = escala
	parte.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if sombra
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	parte.visibility_range_end = 58.0
	_visual.add_child(parte)
	if not _partes.has(nombre):
		_partes[nombre] = parte
		_rotaciones_base[nombre] = parte.rotation
	return parte


func _material(color: Color, rugosidad: float) -> StandardMaterial3D:
	var clave := "%s|%.2f" % [color.to_html(), rugosidad]
	if _materiales.has(clave):
		return _materiales[clave] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = clampf(rugosidad, 0.0, 1.0)
	material.metallic = 0.0
	_materiales[clave] = material
	return material


func _malla_esfera() -> SphereMesh:
	var malla := SphereMesh.new()
	malla.radial_segments = 12
	malla.rings = 6
	return malla


func _malla_capsula() -> CapsuleMesh:
	var malla := CapsuleMesh.new()
	malla.radial_segments = 10
	malla.rings = 4
	malla.radius = 0.5
	malla.height = 1.4
	return malla


func _malla_cilindro() -> CylinderMesh:
	var malla := CylinderMesh.new()
	malla.radial_segments = 8
	malla.rings = 1
	malla.top_radius = 0.5
	malla.bottom_radius = 0.5
	malla.height = 1.0
	return malla


func _malla_cono() -> CylinderMesh:
	var malla := CylinderMesh.new()
	malla.radial_segments = 7
	malla.rings = 1
	malla.top_radius = 0.0
	malla.bottom_radius = 0.5
	malla.height = 1.0
	return malla
