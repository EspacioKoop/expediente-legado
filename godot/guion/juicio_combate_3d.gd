## Juicio por Combate de la Ventanilla (#779).
##
## Es una apelación, no un sustituto de investigar: las pruebas que hicieron
## efecto en el careo reducen la determinación inicial del acusado. El combate
## termina por rendición (determinación a cero), no por muerte.
##
## Si el anfitrión es la Ventanilla con una `Partida` viva, la arena refleja dos
## memorias que ya existen: un Arcano recogido/no gastado y una semilla mitológica
## activa de la jornada. Son presencia visual; no alteran daño, vida ni recargas.
##
## Controles semánticos ya existentes:
## - movimiento: mover_izquierda/derecha/adelante/atras;
## - interactuar: ataque ligero;
## - saltar: ataque fuerte;
## - agacharse: esquiva.
class_name JuicioCombate3D
extends Node3D

signal terminado(gano: bool)

const DETERMINACION_BASE := 8
const DETERMINACION_MINIMA_RIVAL := 4
const VELOCIDAD_JUGADOR := 4.8
const VELOCIDAD_RIVAL := 2.5
const RADIO_ARENA := 5.0
const ALCANCE_LIGERO := 1.75
const ALCANCE_FUERTE := 2.15
const ALCANCE_RIVAL := 1.45

var reduccion_movimiento := false

var _acusado: Dictionary = {}
var _bono_documental := 0
var _determinacion_jugador := DETERMINACION_BASE
var _determinacion_rival := DETERMINACION_BASE
var _acabado := false
var _recarga_jugador := 0.0
var _recarga_rival := 0.0
var _esquiva := 0.0
var _arcano: Dictionary = {}
var _mito_id := ""

var _jugador: CharacterBody3D
var _rival: CharacterBody3D
var _figura_jugador: Node3D
var _figura_rival: Node3D
var _camara: Camera3D
var _barra_jugador: ProgressBar
var _barra_rival: ProgressBar


static func determinacion_rival(bono_documental: int) -> int:
	return maxi(DETERMINACION_MINIMA_RIVAL, DETERMINACION_BASE - maxi(0, bono_documental))


func configurar(acusado: Dictionary, bono_documental: int, reducir_movimiento: bool) -> void:
	_acusado = acusado.duplicate(true)
	_bono_documental = bono_documental
	reduccion_movimiento = reducir_movimiento
	_determinacion_rival = determinacion_rival(_bono_documental)


func _ready() -> void:
	_resolver_capa_simbolica()
	_montar_arena()
	_montar_hud()
	_actualizar_hud()


func _process(delta: float) -> void:
	if _acabado:
		return
	_recarga_jugador = maxf(0.0, _recarga_jugador - delta)
	_recarga_rival = maxf(0.0, _recarga_rival - delta)
	_esquiva = maxf(0.0, _esquiva - delta)
	_mover_jugador(delta)
	_mover_rival(delta)
	_actualizar_camara()

	if Input.is_action_just_pressed("interactuar"):
		_atacar(1, ALCANCE_LIGERO, 0.28)
	if Input.is_action_just_pressed("saltar"):
		_atacar(2, ALCANCE_FUERTE, 0.58)
	if Input.is_action_just_pressed("agacharse"):
		_esquivar()


func abandonar() -> void:
	_terminar(false)


func _mover_jugador(delta: float) -> void:
	var direccion := Vector2(
		Input.get_axis("mover_izquierda", "mover_derecha"),
		Input.get_axis("mover_adelante", "mover_atras")
	)
	if direccion.length_squared() > 1.0:
		direccion = direccion.normalized()
	var multiplicador := 2.25 if _esquiva > 0.0 else 1.0
	_jugador.position += (
		Vector3(direccion.x, 0.0, direccion.y) * VELOCIDAD_JUGADOR * multiplicador * delta
	)
	_jugador.position = _limitar(_jugador.position)
	if direccion.length_squared() > 0.01:
		_jugador.rotation.y = atan2(direccion.x, direccion.y)


func _mover_rival(delta: float) -> void:
	var hacia := _jugador.position - _rival.position
	hacia.y = 0.0
	var distancia := hacia.length()
	if distancia > ALCANCE_RIVAL:
		var direccion := hacia.normalized()
		_rival.position += direccion * VELOCIDAD_RIVAL * delta
		_rival.position = _limitar(_rival.position)
		_rival.rotation.y = atan2(direccion.x, direccion.z)
	elif _recarga_rival <= 0.0:
		_recarga_rival = 1.15
		if _esquiva <= 0.0:
			_determinacion_jugador = maxi(0, _determinacion_jugador - 1)
			_reaccion(_figura_jugador, -0.18)
			_actualizar_hud()
			if _determinacion_jugador <= 0:
				_terminar(false)


func _atacar(dano: int, alcance: float, recarga: float) -> void:
	if _recarga_jugador > 0.0:
		return
	_recarga_jugador = recarga
	var hacia := _rival.position - _jugador.position
	hacia.y = 0.0
	if hacia.length() > 0.01:
		_jugador.rotation.y = atan2(hacia.x, hacia.z)
	if hacia.length() > alcance:
		return
	_determinacion_rival = maxi(0, _determinacion_rival - dano)
	_reaccion(_figura_rival, 0.25 + float(dano) * 0.08)
	_actualizar_hud()
	if _determinacion_rival <= 0:
		_terminar(true)


func _esquivar() -> void:
	if _esquiva > 0.0:
		return
	_esquiva = 0.34
	if reduccion_movimiento:
		return
	_reaccion(_figura_jugador, 0.12)


func _terminar(gano: bool) -> void:
	if _acabado:
		return
	_acabado = true
	terminado.emit(gano)


func _limitar(posicion: Vector3) -> Vector3:
	var plano := Vector2(posicion.x, posicion.z)
	if plano.length() > RADIO_ARENA:
		plano = plano.normalized() * RADIO_ARENA
	return Vector3(plano.x, 0.0, plano.y)


func _resolver_capa_simbolica() -> void:
	var estado := _estado_partida_anfitrion()
	if estado.is_empty():
		return
	var clave := String(_acusado.get("id", _acusado.get("nombre", "acusado")))
	var tarot = estado.get("tarot", [])
	if typeof(tarot) == TYPE_ARRAY:
		_arcano = JuicioSimbolico.arcano_para(tarot, clave)
	var jornada = estado.get("jornada", {})
	if typeof(jornada) == TYPE_DICTIONARY:
		_mito_id = JuicioSimbolico.mito_para(jornada, clave)


func _estado_partida_anfitrion() -> Dictionary:
	var anfitrion := get_parent()
	if anfitrion == null:
		return {}
	var tiene_partida := false
	for bruto in anfitrion.get_property_list():
		if typeof(bruto) == TYPE_DICTIONARY and String(bruto.get("name", "")) == "partida":
			tiene_partida = true
			break
	if not tiene_partida:
		return {}
	var partida_actual = anfitrion.get("partida")
	if partida_actual is Partida:
		return partida_actual.estado
	return {}


func _montar_arena() -> void:
	var mundo := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.025, 0.027, 0.032)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.48, 0.50, 0.46)
	entorno.ambient_light_energy = 0.65
	mundo.environment = entorno
	add_child(mundo)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	luz.light_energy = 1.25
	add_child(luz)

	var suelo := MeshInstance3D.new()
	var malla_suelo := CylinderMesh.new()
	malla_suelo.top_radius = RADIO_ARENA + 0.8
	malla_suelo.bottom_radius = RADIO_ARENA + 0.8
	malla_suelo.height = 0.16
	malla_suelo.radial_segments = 32
	suelo.mesh = malla_suelo
	suelo.position.y = -0.12
	suelo.material_override = _material(Color(0.16, 0.17, 0.15))
	add_child(suelo)

	# Archivadores hacen de límite visual: sigue siendo la institución, no una
	# arena medieval genérica.
	for i in 8:
		var angulo := TAU * float(i) / 8.0
		var archivador := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.9, 1.8, 0.55)
		archivador.mesh = caja
		archivador.position = Vector3(sin(angulo) * 5.7, 0.9, cos(angulo) * 5.7)
		archivador.rotation.y = angulo
		archivador.material_override = _material(Color(0.28, 0.31, 0.28))
		add_child(archivador)

	JuicioSimbolico3D.montar(self, _arcano, _mito_id)

	_jugador = CharacterBody3D.new()
	_jugador.position = Vector3(0.0, 0.0, 2.4)
	add_child(_jugador)
	_figura_jugador = FiguraSilueta.construir(_jugador, Vector3.ZERO, Color(0.68, 0.70, 0.64))

	_rival = CharacterBody3D.new()
	_rival.position = Vector3(0.0, 0.0, -2.4)
	add_child(_rival)
	var clave := String(_acusado.get("id", _acusado.get("nombre", "acusado")))
	var matiz := 0.52 + float(absi(hash(clave)) % 14) / 100.0
	_figura_rival = FiguraSilueta.construir(_rival, Vector3.ZERO, Color.from_hsv(matiz, 0.34, 0.72))

	_camara = Camera3D.new()
	_camara.fov = 52.0
	add_child(_camara)
	_actualizar_camara()


func _montar_hud() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 5
	add_child(capa)

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_top", 18)
	capa.add_child(margen)

	var columnas := HBoxContainer.new()
	columnas.add_theme_constant_override("separation", 32)
	margen.add_child(columnas)

	_barra_jugador = ProgressBar.new()
	_barra_jugador.max_value = DETERMINACION_BASE
	_barra_jugador.show_percentage = false
	_barra_jugador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columnas.add_child(_barra_jugador)

	var nombre := Label.new()
	nombre.text = tr(String(_acusado.get("nombre", "")))
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columnas.add_child(nombre)

	_barra_rival = ProgressBar.new()
	_barra_rival.max_value = determinacion_rival(_bono_documental)
	_barra_rival.show_percentage = false
	_barra_rival.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columnas.add_child(_barra_rival)


func _actualizar_hud() -> void:
	if _barra_jugador == null or _barra_rival == null:
		return
	_barra_jugador.value = _determinacion_jugador
	_barra_rival.value = _determinacion_rival


func _actualizar_camara() -> void:
	if _camara == null or _jugador == null or _rival == null:
		return
	var centro := (_jugador.position + _rival.position) * 0.5
	_camara.position = centro + Vector3(0.0, 7.2, 8.2)
	_camara.look_at(centro + Vector3(0.0, 0.9, 0.0), Vector3.UP)


func _reaccion(figura: Node3D, desplazamiento: float) -> void:
	if reduccion_movimiento or figura == null:
		return
	var origen := figura.position
	var tween := create_tween()
	tween.tween_property(figura, "position:z", origen.z + desplazamiento, 0.08)
	tween.tween_property(figura, "position:z", origen.z, 0.16)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
