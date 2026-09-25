## Vertical 3D del sueño de Ryū (#440).
##
## No simula fluidos ni crea un renderer paralelo: un pequeño estado declarativo
## reconfigura el cauce, se reconstruye una Curve3D y el dragón procedural se
## muestrea sobre ella. Las compuertas usan el contrato común Interactuable3D.
class_name SuenoRyu
extends Node3D

const ID_MITO := "dragon_japones"
const ESTADO_OBJETIVO := [true, false, true]
const CANTIDAD_COMPUERTAS := 3
const SEGMENTOS_DRAGON := 15
# El ojo/luminaria alcanza y=7.4 en coordenadas locales (centro 6.0 + radio 1.4).
# Con el ancla nocturna habitual en y=0.55, 0.30 deja su borde superior en 2.77 m,
# dentro del techo de 2.8 m de Espacio3D en vez de recortarlo.
const ESCALA_ENCUENTRO := 0.30

const COLOR_AGUA_ACTIVA := Color(0.18, 0.72, 0.82, 0.82)
const COLOR_METAL := Color(0.25, 0.29, 0.31)
const COLOR_GUIA := Color(0.38, 0.88, 0.74)
const COLOR_DRAGON := Color(0.18, 0.48, 0.42)
const COLOR_DRAGON_CLARO := Color(0.42, 0.72, 0.58)
const COLOR_OJO := Color(0.78, 0.86, 0.52)

@export var reduccion_movimiento := false

# Las tres compuertas parten en la orientación opuesta al objetivo. Así las
# guías se pueden leer espacialmente y cada interacción necesaria es visible.
var _estado_compuertas := [false, true, false]
var _compuertas_tocadas := [false, false, false]
var _compuertas: Array[Interactuable3D] = []
var _brazos: Array[MeshInstance3D] = []
var _segmentos_dragon: Array[Node3D] = []
var _curva := Curve3D.new()
var _canal: Node3D
var _lluvia: Node3D
var _puente: MeshInstance3D
var _ojo_luna: MeshInstance3D
var _tiempo := 0.0
var _resuelto := false


func _ready() -> void:
	preparar()


func preparar() -> void:
	if get_node_or_null("ArquitecturaRyu") != null:
		return
	var arquitectura := Node3D.new()
	arquitectura.name = "ArquitecturaRyu"
	add_child(arquitectura)
	_montar_plataformas(arquitectura)
	_montar_compuertas(arquitectura)
	_montar_dragon(arquitectura)
	_montar_prop_compuerta_ritual(arquitectura)
	_montar_lluvia(arquitectura)
	_montar_iluminacion(arquitectura)
	_recalcular_flujo()


func _process(delta: float) -> void:
	if _segmentos_dragon.is_empty() or _curva.get_baked_length() <= 0.01:
		return
	var velocidad := 0.10 if reduccion_movimiento else 0.26
	_tiempo += delta * velocidad
	_animar_dragon()
	_animar_lluvia(delta)


func estado_compuertas() -> Array:
	return _estado_compuertas.duplicate()


func resuelto() -> bool:
	return _resuelto


func _montar_plataformas(raiz: Node3D) -> void:
	_crear_caja(
		raiz,
		"PasarelaSuspendida",
		Vector3(18.0, 0.35, 2.2),
		Vector3(0.0, -0.15, 4.4),
		COLOR_METAL,
	)
	_crear_caja(
		raiz,
		"CanalElevado",
		Vector3(7.0, 0.3, 1.2),
		Vector3(0.0, 3.2, 0.0),
		COLOR_METAL,
	)
	_puente = _crear_caja(
		raiz,
		"PuenteDelCauce",
		Vector3(4.2, 0.3, 1.5),
		Vector3(6.1, 2.6, 3.0),
		COLOR_METAL,
	)
	_puente.rotation_degrees.z = -18.0

	var ojo_malla := SphereMesh.new()
	ojo_malla.radius = 1.4
	ojo_malla.height = 2.8
	_ojo_luna = MeshInstance3D.new()
	_ojo_luna.name = "OjoLuna"
	_ojo_luna.mesh = ojo_malla
	_ojo_luna.position = Vector3(8.2, 6.0, -0.5)
	_ojo_luna.material_override = _material(COLOR_OJO, true)
	raiz.add_child(_ojo_luna)


func _montar_compuertas(raiz: Node3D) -> void:
	var posiciones := [
		Vector3(-4.8, 0.75, 3.7),
		Vector3(0.0, 0.75, 3.7),
		Vector3(4.8, 0.75, 3.7),
	]
	for indice in range(CANTIDAD_COMPUERTAS):
		var compuerta := Interactuable3D.new()
		compuerta.name = "CompuertaCauce%d" % (indice + 1)
		compuerta.position = posiciones[indice]
		compuerta.verbo = Interactuable3D.Verbo.USAR
		compuerta.nombre_objeto = "compuerta del cauce %d" % (indice + 1)
		compuerta.activado.connect(_alternar_compuerta.bind(indice))
		raiz.add_child(compuerta)

		var colision := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(1.5, 1.5, 1.5)
		colision.shape = forma
		compuerta.add_child(colision)

		var brazo := _crear_caja(
			compuerta,
			"Brazo",
			Vector3(0.28, 0.28, 2.1),
			Vector3.ZERO,
			COLOR_METAL,
		)
		var guia := _crear_caja(
			raiz,
			"GuiaObjetivo%d" % (indice + 1),
			Vector3(0.14, 0.14, 1.7),
			posiciones[indice] + Vector3(0.0, 0.9, 0.0),
			COLOR_GUIA,
		)
		guia.rotation_degrees.y = 90.0 if ESTADO_OBJETIVO[indice] else 0.0
		_compuertas.append(compuerta)
		_brazos.append(brazo)
	_actualizar_compuertas_visuales()


func _montar_dragon(raiz: Node3D) -> void:
	var dragon := Node3D.new()
	dragon.name = "DragonProcedural"
	raiz.add_child(dragon)

	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	dragon.add_child(cabeza)
	_crear_esfera(cabeza, "Craneo", 0.72, Vector3.ZERO, COLOR_DRAGON_CLARO)
	_crear_esfera(cabeza, "Morro", 0.42, Vector3(0.0, -0.05, -0.65), COLOR_DRAGON)
	_crear_cuerno(cabeza, "CuernoIzquierdo", Vector3(-0.42, 0.6, 0.0), -18.0)
	_crear_cuerno(cabeza, "CuernoDerecho", Vector3(0.42, 0.6, 0.0), 18.0)
	_crear_esfera(cabeza, "OjoIzquierdo", 0.11, Vector3(-0.34, 0.18, -0.55), COLOR_OJO)
	_crear_esfera(cabeza, "OjoDerecho", 0.11, Vector3(0.34, 0.18, -0.55), COLOR_OJO)
	_crear_bigote(cabeza, "BigoteIzquierdo", -1.0)
	_crear_bigote(cabeza, "BigoteDerecho", 1.0)
	_segmentos_dragon.append(cabeza)

	for indice in range(1, SEGMENTOS_DRAGON):
		var segmento := Node3D.new()
		segmento.name = "Segmento%02d" % indice
		dragon.add_child(segmento)
		var radio := lerpf(0.62, 0.22, float(indice) / float(SEGMENTOS_DRAGON - 1))
		_crear_esfera(
			segmento,
			"Escama",
			radio,
			Vector3.ZERO,
			COLOR_DRAGON if indice % 2 == 0 else COLOR_DRAGON_CLARO,
		)
		_segmentos_dragon.append(segmento)


func _montar_prop_compuerta_ritual(raiz: Node3D) -> void:
	var prop := Mitologias435Props.compuerta_ryu()
	prop.name = "PropCompuertaRyu"
	prop.position = Vector3(7.2, 0.0, -3.6)
	prop.rotation_degrees = Vector3(0.0, -32.0, 0.0)
	prop.scale = Vector3.ONE * 0.64
	prop.set_meta("mitologias_435_solo_visual", true)
	raiz.add_child(prop)


func _montar_lluvia(raiz: Node3D) -> void:
	_lluvia = Node3D.new()
	_lluvia.name = "LluviaSuspendida"
	raiz.add_child(_lluvia)
	var cantidad := 8 if reduccion_movimiento else 26
	for indice in range(cantidad):
		var x := -8.0 + float((indice * 7) % 17)
		var z := -5.0 + float((indice * 11) % 10)
		var y := 1.8 + float((indice * 5) % 7) * 0.65
		_crear_caja(
			_lluvia,
			"Gota%02d" % indice,
			Vector3(0.025, 0.55, 0.025),
			Vector3(x, y, z),
			Color(0.52, 0.72, 0.86, 0.62),
		)


func _montar_iluminacion(raiz: Node3D) -> void:
	var luz := OmniLight3D.new()
	luz.name = "LuzAgua"
	luz.position = Vector3(0.0, 4.0, 1.0)
	luz.light_color = Color(0.34, 0.62, 0.72)
	luz.light_energy = 4.0
	luz.omni_range = 15.0
	raiz.add_child(luz)


func _alternar_compuerta(_actor: Node, indice: int) -> void:
	if indice < 0 or indice >= CANTIDAD_COMPUERTAS or _resuelto:
		return
	_estado_compuertas[indice] = not bool(_estado_compuertas[indice])
	_compuertas_tocadas[indice] = true
	_actualizar_compuertas_visuales()
	_recalcular_flujo()
	_comprobar_resolucion()


func _actualizar_compuertas_visuales() -> void:
	for indice in range(_brazos.size()):
		_brazos[indice].rotation_degrees.y = 90.0 if _estado_compuertas[indice] else 0.0


func _recalcular_flujo() -> void:
	_curva = Curve3D.new()
	var puntos := _puntos_cauce()
	for punto in puntos:
		_curva.add_point(punto)

	if _canal == null:
		_canal = Node3D.new()
		_canal.name = "CauceActivo"
		get_node("ArquitecturaRyu").add_child(_canal)
	else:
		for hijo in _canal.get_children():
			hijo.free()

	for indice in range(puntos.size() - 1):
		_crear_tramo(
			_canal,
			"TramoAgua%02d" % indice,
			puntos[indice],
			puntos[indice + 1],
			0.22,
			COLOR_AGUA_ACTIVA,
		)
	_animar_dragon()


func _puntos_cauce() -> PackedVector3Array:
	var desvio_a := 2.5 if _estado_compuertas[0] else -2.5
	# El estado correcto de la compuerta central eleva el agua: es la anomalía
	# de gravedad principal y se lee como continuidad con el canal suspendido.
	var altura_b := 0.35 if _estado_compuertas[1] else 3.2
	var desvio_c := 2.5 if _estado_compuertas[2] else -2.5
	return PackedVector3Array(
		[
			Vector3(-8.5, 0.35, 0.0),
			Vector3(-6.2, 0.35, 0.0),
			Vector3(-4.2, 0.35, desvio_a),
			Vector3(-2.0, 0.35, 0.0),
			Vector3(0.0, altura_b, 0.0),
			Vector3(2.0, 0.35, 0.0),
			Vector3(4.2, 0.35, desvio_c),
			Vector3(6.4, 1.7, 0.0),
			Vector3(8.2, 5.2, -0.5),
		]
	)


func _comprobar_resolucion() -> void:
	if not _todas_tocadas() or _estado_compuertas != ESTADO_OBJETIVO:
		return
	_resuelto = true
	for compuerta in _compuertas:
		compuerta.habilitado = false
	if reduccion_movimiento:
		_puente.position.y = 0.7
		_puente.rotation_degrees.z = 0.0
		_ojo_luna.scale = Vector3.ONE * 1.2
		return
	var tween := create_tween()
	tween.set_parallel(true)
	var destino_puente := Vector3(_puente.position.x, 0.7, _puente.position.z)
	tween.tween_property(_puente, "position", destino_puente, 0.8)
	tween.tween_property(_puente, "rotation_degrees", Vector3.ZERO, 0.8)
	tween.tween_property(_ojo_luna, "scale", Vector3.ONE * 1.35, 0.8)


func _todas_tocadas() -> bool:
	for tocada in _compuertas_tocadas:
		if not tocada:
			return false
	return true


func _animar_dragon() -> void:
	if _segmentos_dragon.is_empty():
		return
	var largo := _curva.get_baked_length()
	if largo <= 0.01:
		return
	var avance_base := fposmod(_tiempo, 1.0)
	var separacion := 0.024 if reduccion_movimiento else 0.032
	var oscilacion := 0.04 if reduccion_movimiento else 0.22
	for indice in range(_segmentos_dragon.size()):
		var avance := fposmod(avance_base - float(indice) * separacion, 1.0)
		var posicion := _curva.sample_baked(avance * largo, true)
		posicion.y += sin((_tiempo * 6.0) - float(indice) * 0.55) * oscilacion
		_segmentos_dragon[indice].position = posicion


func _animar_lluvia(delta: float) -> void:
	if _lluvia == null:
		return
	var velocidad := 0.12 if reduccion_movimiento else 0.7
	_lluvia.position.y = fposmod(_lluvia.position.y - delta * velocidad + 1.0, 1.0) - 1.0


func _crear_tramo(
	padre: Node3D,
	nombre: String,
	desde: Vector3,
	hasta: Vector3,
	grosor: float,
	color: Color,
) -> MeshInstance3D:
	var longitud := desde.distance_to(hasta)
	var nodo := _crear_caja(
		padre,
		nombre,
		Vector3(grosor, grosor, longitud),
		desde.lerp(hasta, 0.5),
		color,
	)
	nodo.look_at(hasta, Vector3.UP)
	return nodo


func _crear_caja(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = _material(color, color.a < 0.99)
	padre.add_child(nodo)
	return nodo


func _crear_esfera(
	padre: Node3D,
	nombre: String,
	radio: float,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var malla := SphereMesh.new()
	malla.radius = radio
	malla.height = radio * 2.0
	malla.radial_segments = 10
	malla.rings = 6
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = _material(color)
	padre.add_child(nodo)
	return nodo


func _crear_cuerno(padre: Node3D, nombre: String, posicion: Vector3, giro_z: float) -> void:
	var malla := CylinderMesh.new()
	malla.top_radius = 0.06
	malla.bottom_radius = 0.16
	malla.height = 0.9
	malla.radial_segments = 6
	var cuerno := MeshInstance3D.new()
	cuerno.name = nombre
	cuerno.mesh = malla
	cuerno.position = posicion
	cuerno.rotation_degrees.z = giro_z
	cuerno.material_override = _material(Color(0.72, 0.68, 0.50))
	padre.add_child(cuerno)


func _crear_bigote(padre: Node3D, nombre: String, lado: float) -> void:
	var bigote := _crear_caja(
		padre,
		nombre,
		Vector3(1.5, 0.035, 0.035),
		Vector3(lado * 0.9, -0.05, -0.55),
		Color(0.72, 0.78, 0.64),
	)
	bigote.rotation_degrees.z = lado * -12.0


func _material(color: Color, transparente: bool = false) -> StandardMaterial3D:
	if color == COLOR_METAL:
		return Mitologias435Materiales.crear("metal_archivo_oxidado", color, transparente)
	if color == COLOR_DRAGON or color == COLOR_DRAGON_CLARO:
		return Mitologias435Materiales.crear("jade_ryu_humedo", color, transparente)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.58
	if transparente:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
