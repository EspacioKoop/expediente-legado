## Vertical independiente del Patio de los Juramentos en Crónicas (#2589).
## Puzzle de versiones contradictorias: compara tres inscripciones, impugna
## un testimonio falaz/contradictorio y abre la puerta del patio.
## No guarda ni altera SIGA, sueños o Hastur.
class_name CronicasPatioJuramentos3D
extends Node3D

signal completado

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")
const TOTAL_JURAMENTOS := 3

const COLOR_PATIO_PIEDRA := Color(0.24, 0.26, 0.30)
const COLOR_PATIO_DETALLE := Color(0.38, 0.37, 0.34)
const COLOR_BRONCE := Color(0.50, 0.32, 0.18)
const COLOR_INSCRIPCION := Color(0.85, 0.73, 0.48)
const COLOR_PUERTA := Color(0.28, 0.22, 0.18)

const TEXTO_JURAMENTO_I := (
	"I. «El primer pacto se firmó en el estuario bajo "
	+ "el sol de mediodía. Ningún linaje rompió la tregua.»"
)
const TEXTO_JURAMENTO_II := (
	"II. «El primer pacto se firmó a medianoche en las "
	+ "torres. El linaje traicionó la tregua antes del alba.»"
)
const TEXTO_JURAMENTO_III := (
	"III. «El primer pacto se firmó en el estuario a "
	+ "medianoche. La tregua se mantuvo hasta que cayó la torre.»"
)

var _juramentos_leidos := [false, false, false]
var _testimonio_impugnado := -1
var _puerta_desbloqueada := false
var _completado := false

var _caminante: CharacterBody3D
var _texto: Label
var _hud: HUDLayer
var _inscripciones: Array[Interactuable3D] = []
var _puerta: Interactuable3D


func _ready() -> void:
	_montar_mundo()
	_montar_interactuables()
	_montar_hud()
	_caminante = ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	_caminante.name = "Caminante"
	_caminante.position = Vector3(0, 1.0, 8.0)
	add_child(_caminante)
	_caminante.call("conectar_hud", _hud)


## Estado local determinista para consulta de progreso sin side effects.
func estado_local() -> Dictionary:
	return {
		"juramentos_leidos": _juramentos_leidos.duplicate(),
		"testimonio_impugnado": _testimonio_impugnado,
		"puerta_desbloqueada": _puerta_desbloqueada,
		"completado": _completado,
	}


func todos_juramentos_leidos() -> bool:
	for leido in _juramentos_leidos:
		if not leido:
			return false
	return true


func leer_juramento(indice: int) -> void:
	if indice < 0 or indice >= TOTAL_JURAMENTOS or _completado:
		return
	_juramentos_leidos[indice] = true
	var num_leidos := 0
	for l in _juramentos_leidos:
		if l:
			num_leidos += 1

	var texto_juramento := ""
	match indice:
		0:
			texto_juramento = TEXTO_JURAMENTO_I
		1:
			texto_juramento = TEXTO_JURAMENTO_II
		2:
			texto_juramento = TEXTO_JURAMENTO_III

	if todos_juramentos_leidos():
		_mensaje(
			(
				(
					"%s\n[Leídos %d/3] ¡Todas las fuentes consultadas! "
					+ "Compara sus afirmaciones e interactúa con una inscripción para impugnarla."
				)
				% [texto_juramento, num_leidos]
			)
		)
	else:
		_mensaje(
			(
				"%s\n[Leídos %d/3] Examina las demás inscripciones del patio para comparar las versiones."
				% [texto_juramento, num_leidos]
			)
		)
	_actualizar_interacciones()


func impugnar_testimonio(indice: int) -> bool:
	if _completado or not todos_juramentos_leidos():
		if not todos_juramentos_leidos():
			_mensaje("Debes leer las tres inscripciones antes de impugnar cualquier testimonio.")
		return false

	# Interpretaciones legítimas:
	# Indice 0 (I - Sol/Mediodía): Contradicho por II y III que afirman medianoche.
	# Indice 1 (II - Torres/Traición): Contradicho por I y III que afirman estuario y tregua.
	# Indice 2 (III - Sintético): Concuerda parcialmente con I y II; no es impugnable solo.
	if indice == 0:
		_testimonio_impugnado = 0
		_puerta_desbloqueada = true
		_mensaje(
			(
				"Impugnación aceptada — Impugnas la versión del Sol. "
				+ "Prevalecen los testimonios nocturnos y la Puerta del Patio se abre."
			)
		)
		_actualizar_interacciones()
		return true

	if indice == 1:
		_testimonio_impugnado = 1
		_puerta_desbloqueada = true
		_mensaje(
			(
				"Impugnación aceptada — Impugnas la versión de la Traición. "
				+ "Prevalecen los testimonios del Estuario y la Puerta del Patio se abre."
			)
		)
		_actualizar_interacciones()
		return true

	# Error reversible: la impugnación falla sin penalización ni bloqueo.
	_mensaje(
		(
			"Impugnación rechazada — La tercera inscripción concuerda parcialmente "
			+ "con las otras dos fuentes. Compara el lugar y el momento del pacto "
			+ "e impugna una versión contradictoria."
		)
	)
	return false


func solicitar_salida() -> bool:
	if not _puerta_desbloqueada:
		_mensaje(
			(
				"La puerta del patio permanece trancada. "
				+ "Lee las tres inscripciones e impugna un testimonio contradictorio para abrirla."
			)
		)
		return false
	if _completado:
		return false
	_completado = true
	_actualizar_interacciones()
	_mensaje("Fin del Patio de los Juramentos: has resuelto la contradicción y cruzado el umbral.")
	completado.emit()
	return true


func _montar_mundo() -> void:
	var mundo := WorldEnvironment.new()
	mundo.name = "AmbientePatio"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.06, 0.07, 0.09)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.58, 0.60, 0.68)
	entorno.ambient_light_energy = 0.6
	mundo.environment = entorno
	add_child(mundo)

	var antorcha := DirectionalLight3D.new()
	antorcha.name = "LuzPatio"
	antorcha.rotation_degrees = Vector3(-50, -30, 0)
	antorcha.light_color = Color(0.88, 0.78, 0.62)
	antorcha.light_energy = 0.85
	antorcha.shadow_enabled = true
	add_child(antorcha)

	_pieza("Suelo", Vector3(0, -0.45, 0), Vector3(18, 0.9, 22), COLOR_PATIO_PIEDRA)
	_pieza("MuroIzquierdo", Vector3(-9.0, 2.7, 0), Vector3(0.9, 5.4, 22), COLOR_PATIO_PIEDRA)
	_pieza("MuroDerecho", Vector3(9.0, 2.7, 0), Vector3(0.9, 5.4, 22), COLOR_PATIO_PIEDRA)
	_pieza("MuroNorte", Vector3(0, 2.7, -10.7), Vector3(18, 5.4, 0.9), COLOR_PATIO_PIEDRA)
	_pieza("MuroSur", Vector3(0, 2.7, 10.7), Vector3(18, 5.4, 0.9), COLOR_PATIO_PIEDRA)

	_pieza("PedestalI", Vector3(-5.0, 0.8, -2.5), Vector3(1.6, 1.6, 1.2), COLOR_PATIO_DETALLE)
	_pieza("PedestalII", Vector3(0.0, 0.8, -4.5), Vector3(1.6, 1.6, 1.2), COLOR_PATIO_DETALLE)
	_pieza("PedestalIII", Vector3(5.0, 0.8, -2.5), Vector3(1.6, 1.6, 1.2), COLOR_PATIO_DETALLE)

	_pieza("PuertaMadera", Vector3(0, 2.25, -10.12), Vector3(3.2, 4.5, 0.35), COLOR_PUERTA, false)
	_pieza(
		"JambaIzquierda", Vector3(-2.1, 2.3, -9.9), Vector3(0.75, 4.6, 0.85), COLOR_PATIO_DETALLE
	)
	_pieza("JambaDerecha", Vector3(2.1, 2.3, -9.9), Vector3(0.75, 4.6, 0.85), COLOR_PATIO_DETALLE)

	_rotulo("JURAMENTO I", Vector3(-5.0, 2.2, -2.5))
	_rotulo("JURAMENTO II", Vector3(0.0, 2.2, -4.5))
	_rotulo("JURAMENTO III", Vector3(5.0, 2.2, -2.5))
	_rotulo("PUERTA DEL PATIO", Vector3(0.0, 3.65, -9.72))


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
	rotulo.name = "Rotulo_" + texto.replace(" ", "_")
	rotulo.text = texto
	rotulo.position = posicion
	rotulo.pixel_size = 0.006
	rotulo.font_size = 32
	rotulo.modulate = COLOR_INSCRIPCION
	add_child(rotulo)


func _montar_interactuables() -> void:
	_inscripciones.clear()

	var insc0 := _crear_interactuable(
		"InscripcionI",
		Vector3(-5.0, 1.4, -1.9),
		Vector3(1.8, 1.8, 0.8),
		Interactuable3D.Verbo.LEER,
		"primer juramento",
	)
	insc0.activado.connect(
		func(_actor: Node):
			if not todos_juramentos_leidos():
				leer_juramento(0)
			else:
				impugnar_testimonio(0)
	)
	_inscripciones.append(insc0)

	var insc1 := _crear_interactuable(
		"InscripcionII",
		Vector3(0.0, 1.4, -3.9),
		Vector3(1.8, 1.8, 0.8),
		Interactuable3D.Verbo.LEER,
		"segundo juramento",
	)
	insc1.activado.connect(
		func(_actor: Node):
			if not todos_juramentos_leidos():
				leer_juramento(1)
			else:
				impugnar_testimonio(1)
	)
	_inscripciones.append(insc1)

	var insc2 := _crear_interactuable(
		"InscripcionIII",
		Vector3(5.0, 1.4, -1.9),
		Vector3(1.8, 1.8, 0.8),
		Interactuable3D.Verbo.LEER,
		"tercer juramento",
	)
	insc2.activado.connect(
		func(_actor: Node):
			if not todos_juramentos_leidos():
				leer_juramento(2)
			else:
				impugnar_testimonio(2)
	)
	_inscripciones.append(insc2)

	_puerta = _crear_interactuable(
		"PuertaPatio",
		Vector3(0.0, 1.3, -9.25),
		Vector3(2.2, 2.6, 0.8),
		Interactuable3D.Verbo.USAR,
		"puerta del patio",
	)
	_puerta.activado.connect(func(_actor: Node): solicitar_salida())
	_actualizar_interacciones()


func _crear_interactuable(
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
	var leidos_todos := todos_juramentos_leidos()
	for i in range(_inscripciones.size()):
		var obj := _inscripciones[i]
		if is_instance_valid(obj):
			if _completado:
				obj.habilitado = false
			elif leidos_todos:
				obj.verbo = Interactuable3D.Verbo.USAR
				match i:
					0:
						obj.nombre_objeto = "impugnar primer juramento (Sol/Mediodía)"
					1:
						obj.nombre_objeto = "impugnar segundo juramento (Torres/Traición)"
					2:
						obj.nombre_objeto = "impugnar tercer juramento (Medianoche/Estuario)"
			else:
				obj.verbo = Interactuable3D.Verbo.LEER

	if is_instance_valid(_puerta):
		_puerta.habilitado = not _completado


func _montar_hud() -> void:
	_hud = HUDLayer.new()
	_hud.name = "InterfazPatio"
	_hud.layer = 8
	add_child(_hud)

	var caja := MarginContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	caja.add_theme_constant_override("margin_left", 24)
	caja.add_theme_constant_override("margin_right", 24)
	caja.add_theme_constant_override("margin_top", 18)
	_hud.add_child(caja)

	_texto = Label.new()
	_texto.name = "Objetivo"
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(0, 80)
	caja.add_child(_texto)

	_mensaje(
		(
			"Patio de los Juramentos — Lee las tres inscripciones y compara sus afirmaciones "
			+ "contradictorias para impugnar el testimonio falaz y abrir la puerta."
		)
	)


func _mensaje(contenido: String) -> void:
	if is_instance_valid(_texto):
		_texto.text = contenido
