## Nivel 3D "Puente de la Ausencia" para Crónicas de las Siete Esferas (#2589).
## Nivel autónomo de 3 tramos con indicios visuales e inscripciones sobre la ruta segura.
## Los errores devuelven al checkpoint del tramo actual sin perder vida ni reiniciar la campaña.
class_name CronicasPuenteAusencia3D
extends Node3D

signal completado

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")
const COLOR_PIEDRA := Color(0.24, 0.26, 0.29)
const COLOR_PIEDRA_CLARA := Color(0.35, 0.36, 0.38)
const COLOR_BRONCE := Color(0.48, 0.31, 0.18)
const COLOR_INSCRIPCION := Color(0.82, 0.71, 0.47)

const POS_CHECKPOINT_1 := Vector3(0.0, 1.0, 12.0)
const POS_CHECKPOINT_2 := Vector3(0.0, 1.0, 1.0)
const POS_CHECKPOINT_3 := Vector3(0.0, 1.0, -10.0)

# Ruta segura por tramo: 0 = Izquierda, 1 = Centro, 2 = Derecha
const RUTA_SEGURA := [1, 0, 2]

var _tramo_actual := 1
var _tramos_completados := 0
var _intentos_fallidos := 0
var _completado := false

var _caminante: CharacterBody3D
var _hud: HUDLayer
var _texto_objetivo: Label
var _salida: Interactuable3D
var _inscripciones: Array[Interactuable3D] = []


func _ready() -> void:
	_montar_mundo()
	_montar_interactuables()
	_montar_hud()
	_caminante = ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	_caminante.name = "Caminante"
	_caminante.position = POS_CHECKPOINT_1
	add_child(_caminante)
	_caminante.call("conectar_hud", _hud)


func _physics_process(_delta: float) -> void:
	if not _completado and is_instance_valid(_caminante):
		if _caminante.position.y < -2.5:
			_al_fallar_tramo(_tramo_actual)


## Devuelve el estado de progreso local del Puente de la Ausencia.
func estado_local() -> Dictionary:
	return {
		"tramo_actual": _tramo_actual,
		"tramos_completados": _tramos_completados,
		"intentos_fallidos": _intentos_fallidos,
		"completado": _completado,
	}


func puede_salir() -> bool:
	return _tramos_completados >= 3 and not _completado


func avanzar_tramo(tramo: int, carril_elegido: int) -> bool:
	if _completado or tramo != _tramo_actual:
		return false

	var carril_correcto: int = RUTA_SEGURA[tramo - 1]
	if carril_elegido == carril_correcto:
		_tramos_completados = maxi(_tramos_completados, tramo)
		if _tramo_actual < 3:
			_tramo_actual += 1
			_trasladar_a_checkpoint(_obtener_posicion_checkpoint(_tramo_actual))
			_mensaje(
				(
					"Tramo %d superado. Has alcanzado el checkpoint del Tramo %d."
					% [tramo, _tramo_actual]
				)
			)
		else:
			_mensaje(
				(
					"Has superado los tres tramos del Puente de la Ausencia. "
					+ "El umbral de salida está abierto ante ti."
				)
			)
		_actualizar_interacciones()
		return true

	_al_fallar_tramo(tramo)
	return false


func _al_fallar_tramo(tramo: int) -> void:
	_intentos_fallidos += 1
	var pos_cp := _obtener_posicion_checkpoint(tramo)
	_trasladar_a_checkpoint(pos_cp)
	_mensaje(
		(
			"La pisada errónea se desvanece en la bruma. "
			+ "Vuelves al checkpoint local del Tramo %d (intento %d)." % [tramo, _intentos_fallidos]
		)
	)


func _trasladar_a_checkpoint(posicion: Vector3) -> void:
	if is_instance_valid(_caminante):
		_caminante.position = posicion
		_caminante.velocity = Vector3.ZERO


func _obtener_posicion_checkpoint(tramo: int) -> Vector3:
	match tramo:
		1:
			return POS_CHECKPOINT_1
		2:
			return POS_CHECKPOINT_2
		3:
			return POS_CHECKPOINT_3
		_:
			return POS_CHECKPOINT_1


func solicitar_salida() -> bool:
	if not puede_salir():
		_mensaje(
			(
				"El umbral de la ausencia permanece cerrado. "
				+ "Debes cruzar correctamente los tres tramos antes de salir."
			)
		)
		return false
	_completado = true
	_actualizar_interacciones()
	_mensaje("Has atravesado el Puente de la Ausencia. Fin de la travesía.")
	completado.emit()
	return true


func _montar_mundo() -> void:
	var mundo := WorldEnvironment.new()
	mundo.name = "AmbientePuente"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.04, 0.05, 0.07)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.5, 0.55, 0.65)
	entorno.ambient_light_energy = 0.6
	mundo.environment = entorno
	add_child(mundo)

	var luz_luna := DirectionalLight3D.new()
	luz_luna.name = "LuzLunaPuente"
	luz_luna.rotation_degrees = Vector3(-50, -30, 0)
	luz_luna.light_color = Color(0.52, 0.64, 0.78)
	luz_luna.light_energy = 0.85
	luz_luna.shadow_enabled = true
	add_child(luz_luna)

	# Plataformas de inicio, tramos y santuario
	_pieza("PlataformaInicio", Vector3(0, -0.5, 12.0), Vector3(8, 1, 6), COLOR_PIEDRA)
	_pieza("PlataformaTramo2", Vector3(0, -0.5, 1.0), Vector3(8, 1, 6), COLOR_PIEDRA)
	_pieza("PlataformaTramo3", Vector3(0, -0.5, -10.0), Vector3(8, 1, 6), COLOR_PIEDRA)
	_pieza("SantuarioFinal", Vector3(0, -0.5, -23.0), Vector3(10, 1, 8), COLOR_PIEDRA)

	# Losa de salida
	_pieza("UmbralBase", Vector3(0, 2.0, -25.5), Vector3(4, 4.5, 0.4), COLOR_BRONCE, false)

	# Construir baldosas de paso para los 3 tramos
	_construir_baldosas_tramo(1, 6.5)
	_construir_baldosas_tramo(2, -4.5)
	_construir_baldosas_tramo(3, -15.5)

	# Luces tenues e inscripciones fijas (sin flashes)
	_luces_y_rotulos()


func _construir_baldosas_tramo(tramo: int, z_centro: float) -> void:
	var xs := [-2.8, 0.0, 2.8]
	var nombres_carril := ["Izquierda", "Centro", "Derecha"]
	var carril_seguro: int = RUTA_SEGURA[tramo - 1]

	for i in range(3):
		var x: float = xs[i]
		var es_seguro := i == carril_seguro
		var color_losa := COLOR_PIEDRA_CLARA if es_seguro else COLOR_PIEDRA

		_pieza(
			"Losa_T%d_%s" % [tramo, nombres_carril[i]],
			Vector3(x, -0.2, z_centro),
			Vector3(2.2, 0.4, 3.2),
			color_losa
		)

		var losa_interactiva := _objeto(
			"Paso_T%d_%s" % [tramo, nombres_carril[i]],
			Vector3(x, 0.5, z_centro),
			Vector3(2.0, 1.0, 3.0),
			Interactuable3D.Verbo.USAR,
			"losa %s del tramo %d" % [nombres_carril[i].to_lower(), tramo]
		)
		var c_idx := i
		var t_idx := tramo
		losa_interactiva.activado.connect(
			func(_actor: Node): avanzar_tramo(t_idx, c_idx), CONNECT_DEFERRED
		)


func _luces_y_rotulos() -> void:
	_rotulo("PUENTE DE LA AUSENCIA", Vector3(0, 3.2, 13.5))
	_rotulo("TRAMO I — EL CENTRO", Vector3(0, 2.2, 9.5))
	_rotulo("TRAMO II — LA IZQUIERDA", Vector3(0, 2.2, -1.5))
	_rotulo("TRAMO III — LA DERECHA", Vector3(0, 2.2, -12.5))
	_rotulo("UMBRAL DE SALIDA", Vector3(0, 4.0, -25.0))

	var luz_santuario := OmniLight3D.new()
	luz_santuario.name = "LuzSantuario"
	luz_santuario.position = Vector3(0, 3.5, -23.0)
	luz_santuario.light_color = COLOR_INSCRIPCION
	luz_santuario.light_energy = 0.95
	luz_santuario.omni_range = 10.0
	add_child(luz_santuario)


func _pieza(
	nombre: String, posicion: Vector3, tamano: Vector3, color: Color, colision := true
) -> void:
	var raiz: Node3D
	if colision:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = tamano
		forma.shape = caja
		cuerpo.add_child(forma)
		raiz = cuerpo
	else:
		raiz = Node3D.new()
	raiz.name = nombre
	raiz.position = posicion

	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	visual.mesh = malla
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	visual.material_override = material
	raiz.add_child(visual)
	add_child(raiz)


func _rotulo(texto: String, posicion: Vector3) -> void:
	var rotulo := Label3D.new()
	rotulo.name = texto.replace(" ", "_").replace("—", "_")
	rotulo.text = texto
	rotulo.position = posicion
	rotulo.pixel_size = 0.006
	rotulo.font_size = 32
	rotulo.modulate = COLOR_INSCRIPCION
	add_child(rotulo)


func _montar_interactuables() -> void:
	var insc_1 := _objeto(
		"Inscripcion_1",
		Vector3(0, 1.2, 9.5),
		Vector3(1.8, 1.5, 0.8),
		Interactuable3D.Verbo.LEER,
		"inscripción I"
	)
	insc_1.activado.connect(
		func(_actor: Node):
			_mensaje(
				(
					"Inscripción I — Quien camine la ausencia debe pisar firme "
					+ "en el centro para superar el primer tramo."
				)
			)
	)
	_inscripciones.append(insc_1)

	var insc_2 := _objeto(
		"Inscripcion_2",
		Vector3(0, 1.2, -1.5),
		Vector3(1.8, 1.5, 0.8),
		Interactuable3D.Verbo.LEER,
		"inscripción II"
	)
	insc_2.activado.connect(
		func(_actor: Node):
			_mensaje(
				(
					"Inscripción II — En la memoria distorsionada, "
					+ "el segundo paso se desvía siempre a la izquierda."
				)
			)
	)
	_inscripciones.append(insc_2)

	var insc_3 := _objeto(
		"Inscripcion_3",
		Vector3(0, 1.2, -12.5),
		Vector3(1.8, 1.5, 0.8),
		Interactuable3D.Verbo.LEER,
		"inscripción III"
	)
	insc_3.activado.connect(
		func(_actor: Node):
			_mensaje(
				"Inscripción III — Al borde del abismo, " + "el paso definitivo nace en la derecha."
			)
	)
	_inscripciones.append(insc_3)

	_salida = _objeto(
		"Salida",
		Vector3(0, 1.3, -24.5),
		Vector3(2.5, 2.5, 0.8),
		Interactuable3D.Verbo.USAR,
		"umbral de la ausencia"
	)
	_salida.activado.connect(func(_actor: Node): solicitar_salida())
	_actualizar_interacciones()


func _objeto(
	nombre: String, posicion: Vector3, tamano: Vector3, verbo: int, titulo: String
) -> Interactuable3D:
	var objeto := Interactuable3D.new()
	objeto.name = nombre
	objeto.position = posicion
	objeto.verbo = verbo
	objeto.nombre_objeto = titulo
	objeto.sonido = Interactuable3D.SIN_SONIDO

	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = tamano
	forma.shape = caja
	objeto.add_child(forma)
	add_child(objeto)
	return objeto


func _actualizar_interacciones() -> void:
	if is_instance_valid(_salida):
		_salida.habilitado = puede_salir()


func _montar_hud() -> void:
	_hud = HUDLayer.new()
	_hud.name = "InterfazPuente"
	_hud.layer = 8
	add_child(_hud)

	var caja := MarginContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	caja.add_theme_constant_override("margin_left", 24)
	caja.add_theme_constant_override("margin_right", 24)
	caja.add_theme_constant_override("margin_top", 18)
	_hud.add_child(caja)

	_texto_objetivo = Label.new()
	_texto_objetivo.name = "Objetivo"
	_texto_objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto_objetivo.custom_minimum_size = Vector2(0, 80)
	caja.add_child(_texto_objetivo)

	_mensaje(
		(
			"Puente de la Ausencia — Lee las inscripciones de cada tramo "
			+ "y elige las losas correctas para cruzar el abismo."
		)
	)


func _mensaje(contenido: String) -> void:
	if is_instance_valid(_texto_objetivo):
		_texto_objetivo.text = contenido
