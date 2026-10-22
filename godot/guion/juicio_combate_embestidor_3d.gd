## Runtime 3D reutilizable del arquetipo EMBESTIDOR (#2130).
##
## Traduce la politica pura a movimiento y telegraph. No detecta colisiones,
## no aplica dano y no resuelve consecuencias: el host entrega linea/choque.
class_name JuicioCombateEmbestidor3D
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const ARQUETIPO_HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")
const REGLAS = preload("res://guion/juicio_combate_reglas.gd")

const LINEA_ALCANCE := 9.0
const LINEA_ANCHO := 0.65
const VELOCIDAD_REPOSICION := 2.4
const VELOCIDAD_CARGA := 9.0


static func montar_linea(anfitrion: Node3D) -> MeshInstance3D:
	var linea := MeshInstance3D.new()
	linea.name = "LineaEmbestidor"
	var malla := BoxMesh.new()
	malla.size = Vector3(LINEA_ANCHO, 0.035, LINEA_ALCANCE)
	linea.mesh = malla
	var material := FEEDBACK.material(Color(0.95, 0.24, 0.10, 0.46), true)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	linea.material_override = material
	linea.visible = false
	anfitrion.add_child(linea)

	# Dos señales físicas acompañan la trayectoria: de dónde parte la carga
	# y dónde termina. Son solo geometría, nunca hitboxes ni detectores.
	for nombre in ["MarcaOrigen", "MarcaDestino"]:
		var marca := MeshInstance3D.new()
		marca.name = nombre
		var disco := CylinderMesh.new()
		disco.top_radius = 0.38 if nombre == "MarcaOrigen" else 0.52
		disco.bottom_radius = disco.top_radius
		disco.height = 0.025
		disco.radial_segments = 16
		marca.mesh = disco
		marca.position = Vector3(
			0.0, 0.03, -LINEA_ALCANCE * 0.5 if nombre == "MarcaOrigen" else LINEA_ALCANCE * 0.5
		)
		marca.material_override = (
			FEEDBACK
			. material(
				(
					Color(0.98, 0.76, 0.24, 0.74)
					if nombre == "MarcaOrigen"
					else Color(1.0, 0.27, 0.16, 0.78)
				),
				true,
			)
		)
		linea.add_child(marca)
	return linea


static func avanzar(
	unidad: Dictionary,
	delta: float,
	posicion_rival: Vector3,
	posicion_jugador: Vector3,
	linea_libre: bool = true,
	choque: bool = false,
) -> Dictionary:
	var estado_anterior := String(unidad.get("estado", ""))
	var hacia := posicion_jugador - posicion_rival
	hacia.y = 0.0
	var contexto := {
		"distancia": hacia.length(),
		"rumbo_objetivo": atan2(hacia.x, hacia.z) if hacia.length() > 0.01 else 0.0,
		"linea_libre": linea_libre,
		"choque": choque,
	}
	var paso := ARQUETIPOS.avanzar(unidad, delta, contexto)
	var nueva: Dictionary = paso["unidad"]
	nueva["_intencion_runtime"] = String(paso.get("intencion", ""))
	var estado := String(nueva.get("estado", ""))
	return {
		"unidad": nueva,
		"telegraph": String(paso.get("telegraph", "")),
		"inicio_agresion":
		estado == ARQUETIPOS.TELEGRAFIAR and estado_anterior != ARQUETIPOS.TELEGRAFIAR,
		"inicio_carga": estado == ARQUETIPOS.CARGAR and estado_anterior != ARQUETIPOS.CARGAR,
		"abrir_ventana": estado == ARQUETIPOS.RECUPERAR and estado_anterior != ARQUETIPOS.RECUPERAR,
	}


static func mover(
	posicion_jugador: Vector3,
	posicion_rival: Vector3,
	rotacion_y_rival: float,
	unidad: Dictionary,
	radio_arena: float,
	delta: float,
) -> Dictionary:
	var hacia := posicion_jugador - posicion_rival
	hacia.y = 0.0
	var estado := String(unidad.get("estado", ""))
	var rumbo := float(unidad.get("rumbo_bloqueado", rotacion_y_rival))
	var rotacion := (
		rumbo if estado in [ARQUETIPOS.TELEGRAFIAR, ARQUETIPOS.CARGAR] else rotacion_y_rival
	)
	var direccion := Vector3.ZERO

	if estado == ARQUETIPOS.CARGAR:
		direccion = ARQUETIPO_HOST.direccion_linea(rumbo)
	elif hacia.length() > 0.01 and estado not in [ARQUETIPOS.TELEGRAFIAR, ARQUETIPOS.RECUPERAR]:
		var normal := hacia.normalized()
		match String(unidad.get("_intencion_runtime", "")):
			"acercarse":
				direccion = normal
			"alejarse":
				direccion = -normal
			"buscar_linea":
				direccion = Vector3(normal.z, 0.0, -normal.x)
		rotacion = atan2(hacia.x, hacia.z)

	var cargando := estado == ARQUETIPOS.CARGAR
	var andando := not direccion.is_zero_approx() and estado != ARQUETIPOS.TELEGRAFIAR
	var velocidad := VELOCIDAD_CARGA if cargando else VELOCIDAD_REPOSICION
	var posicion := posicion_rival
	if andando:
		posicion = REGLAS.limitar_a_arena(
			posicion_rival + direccion * velocidad * delta, radio_arena
		)
	return {
		"posicion": posicion,
		"rotacion_y": rotacion,
		"andando": andando,
		"cargando": cargando,
	}


static func pintar_linea(
	linea: MeshInstance3D, posicion_rival: Vector3, unidad: Dictionary, telegraph: String
) -> void:
	if linea == null:
		return
	var estado := String(unidad.get("estado", ""))
	var preparando := telegraph == "carga_lineal"
	var cargando := estado == ARQUETIPOS.CARGAR
	var recuperando := estado == ARQUETIPOS.RECUPERAR
	linea.visible = preparando or cargando or recuperando
	if not linea.visible:
		return
	var rumbo := float(unidad.get("rumbo_bloqueado", 0.0))
	var direccion := ARQUETIPO_HOST.direccion_linea(rumbo)
	linea.position = posicion_rival + Vector3(0.0, 0.06, 0.0) + direccion * (LINEA_ALCANCE * 0.5)
	linea.rotation = Vector3(0.0, rumbo, 0.0)

	# Ámbar: aviso anticipado; rojo: carga en marcha; azul y trayectoria corta:
	# recuperación vulnerable. El rumbo sigue congelado, incluso al esquivar.
	linea.scale.z = 0.32 if recuperando else 1.0
	var material := linea.material_override as StandardMaterial3D
	if material != null:
		var color := Color(0.31, 0.78, 0.93, 0.38) if recuperando else Color(0.98, 0.19, 0.10, 0.65)
		if preparando:
			color = Color(0.98, 0.60, 0.12, 0.53)
		material.albedo_color = color
		material.emission = color
	for nombre in ["MarcaOrigen", "MarcaDestino"]:
		var marca := linea.get_node_or_null(nombre) as MeshInstance3D
		if marca != null:
			marca.visible = not recuperando
