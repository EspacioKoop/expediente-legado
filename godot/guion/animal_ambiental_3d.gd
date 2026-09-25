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
	_parte("Cuerpo", Vector3(0.22, 0.18, 0.34), Vector3(0, 0.13, 0), color)
	_parte("Cabeza", Vector3(0.15, 0.15, 0.16), Vector3(0, 0.23, -0.18), color.lightened(0.06))
	_parte("Pico", Vector3(0.065, 0.035, 0.10), Vector3(0, 0.23, -0.30), Color(0.72, 0.52, 0.20))
	_parte("Cola", Vector3(0.14, 0.04, 0.24), Vector3(0, 0.14, 0.26), color.darkened(0.16))
	_parte(
		"AlaI",
		Vector3(0.24, 0.025, 0.22),
		Vector3(-0.16, 0.14, 0.02),
		color.darkened(0.10),
		Vector3(0, 0, 14),
	)
	_parte(
		"AlaD",
		Vector3(0.24, 0.025, 0.22),
		Vector3(0.16, 0.14, 0.02),
		color.darkened(0.10),
		Vector3(0, 0, -14),
	)
	_parte("OjoI", Vector3(0.025, 0.025, 0.025), Vector3(-0.055, 0.255, -0.258), Color(0.01, 0.01, 0.01))
	_parte("OjoD", Vector3(0.025, 0.025, 0.025), Vector3(0.055, 0.255, -0.258), Color(0.01, 0.01, 0.01))
	_parte(
		"PataI",
		Vector3(0.025, 0.12, 0.025),
		Vector3(-0.045, 0.01, 0.04),
		Color(0.45, 0.28, 0.20),
	)
	_parte(
		"PataD",
		Vector3(0.025, 0.12, 0.025),
		Vector3(0.045, 0.01, 0.04),
		Color(0.45, 0.28, 0.20),
	)


func _montar_perro(color: Color) -> void:
	_parte("Cuerpo", Vector3(0.42, 0.38, 0.82), Vector3(0, 0.42, 0), color)
	_parte("Pecho", Vector3(0.34, 0.43, 0.30), Vector3(0, 0.48, -0.34), color.lightened(0.05))
	_parte("Cabeza", Vector3(0.34, 0.34, 0.38), Vector3(0, 0.68, -0.55), color.lightened(0.08))
	_parte("Morro", Vector3(0.23, 0.18, 0.25), Vector3(0, 0.59, -0.78), color.darkened(0.10))
	_parte("Nariz", Vector3(0.12, 0.10, 0.08), Vector3(0, 0.61, -0.93), Color(0.035, 0.03, 0.03))
	_parte("OrejaI", Vector3(0.13, 0.22, 0.09), Vector3(-0.12, 0.87, -0.55), color.darkened(0.12), Vector3(0, 0, -14))
	_parte("OrejaD", Vector3(0.13, 0.22, 0.09), Vector3(0.12, 0.87, -0.55), color.darkened(0.12), Vector3(0, 0, 14))
	for x in [-0.14, 0.14]:
		for z in [-0.24, 0.24]:
			_parte("Pata", Vector3(0.09, 0.42, 0.10), Vector3(x, 0.16, z), color.darkened(0.07))
	_parte(
		"Cola",
		Vector3(0.08, 0.08, 0.48),
		Vector3(0, 0.53, 0.58),
		color.darkened(0.08),
		Vector3(28, 0, 0),
	)


func _montar_polilla(color: Color) -> void:
	_parte("Cuerpo", Vector3(0.10, 0.12, 0.28), Vector3.ZERO, color.darkened(0.25))
	_parte("AlaI", Vector3(0.48, 0.025, 0.34), Vector3(-0.25, 0, 0), color, Vector3(0, 12, 18))
	_parte("AlaD", Vector3(0.48, 0.025, 0.34), Vector3(0.25, 0, 0), color, Vector3(0, -12, -18))
	_parte("MarcaI", Vector3(0.11, 0.03, 0.11), Vector3(-0.29, 0.025, -0.02), color.darkened(0.30))
	_parte("MarcaD", Vector3(0.11, 0.03, 0.11), Vector3(0.29, 0.025, -0.02), color.darkened(0.30))
	_parte(
		"AntenaI",
		Vector3(0.018, 0.018, 0.24),
		Vector3(-0.05, 0.04, -0.21),
		color.darkened(0.30),
		Vector3(-18, -14, 0),
	)
	_parte(
		"AntenaD",
		Vector3(0.018, 0.018, 0.24),
		Vector3(0.05, 0.04, -0.21),
		color.darkened(0.30),
		Vector3(-18, 14, 0),
	)


func _montar_ciervo(color: Color) -> void:
	_parte("Cuerpo", Vector3(0.48, 0.52, 1.05), Vector3(0, 0.72, 0), color)
	_parte(
		"Cuello",
		Vector3(0.26, 0.72, 0.28),
		Vector3(0, 1.05, -0.42),
		color.lightened(0.04),
		Vector3(-18, 0, 0),
	)
	_parte("Cabeza", Vector3(0.28, 0.30, 0.45), Vector3(0, 1.38, -0.62), color.lightened(0.07))
	_parte("Morro", Vector3(0.20, 0.16, 0.22), Vector3(0, 1.32, -0.91), color.darkened(0.09))
	_parte("OrejaI", Vector3(0.10, 0.22, 0.08), Vector3(-0.16, 1.55, -0.62), color.lightened(0.04), Vector3(0, 0, -25))
	_parte("OrejaD", Vector3(0.10, 0.22, 0.08), Vector3(0.16, 1.55, -0.62), color.lightened(0.04), Vector3(0, 0, 25))
	for x in [-0.16, 0.16]:
		for z in [-0.32, 0.32]:
			_parte("Pata", Vector3(0.085, 0.80, 0.09), Vector3(x, 0.30, z), color.darkened(0.10))
			_parte("Pezuña", Vector3(0.10, 0.08, 0.14), Vector3(x, -0.08, z - 0.025), Color(0.07, 0.055, 0.045))
	_parte(
		"AstaI",
		Vector3(0.035, 0.46, 0.035),
		Vector3(-0.10, 1.66, -0.60),
		Color(0.16, 0.12, 0.09),
		Vector3(0, 0, -12),
	)
	_parte(
		"AstaD",
		Vector3(0.035, 0.46, 0.035),
		Vector3(0.10, 1.66, -0.60),
		Color(0.16, 0.12, 0.09),
		Vector3(0, 0, 12),
	)
	_parte("PuntaAstaI", Vector3(0.025, 0.24, 0.025), Vector3(-0.18, 1.82, -0.60), Color(0.16, 0.12, 0.09), Vector3(0, 0, -38))
	_parte("PuntaAstaD", Vector3(0.025, 0.24, 0.025), Vector3(0.18, 1.82, -0.60), Color(0.16, 0.12, 0.09), Vector3(0, 0, 38))


func _parte(
	nombre: String,
	tamano: Vector3,
	posicion_local: Vector3,
	color: Color,
	giro_grados: Vector3 = Vector3.ZERO,
) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tamano
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92

	var parte := MeshInstance3D.new()
	parte.name = nombre
	parte.mesh = malla
	parte.material_override = material
	parte.position = posicion_local
	parte.rotation_degrees = giro_grados
	parte.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parte.visibility_range_end = 58.0
	_visual.add_child(parte)
	if not _partes.has(nombre):
		_partes[nombre] = parte
		_rotaciones_base[nombre] = parte.rotation
	return parte
