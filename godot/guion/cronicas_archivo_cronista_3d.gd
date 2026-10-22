## Escena 3D de investigación para el Archivo del Cronista Velado (#2589).
## Ofrece tres actas incompatibles que se inspeccionan y contrastan con el cronista.
## La versión fundamentada abre la fuga; se puede reintentar y es estrictamente local.
class_name CronicasArchivoCronista3D
extends Node3D

signal completado

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")
const TOTAL_ACTAS := 3
const ACTA_FUNDAMENTADA := 1  # Acta II (índice 1) es la versión fundamentada.

const COLOR_PARED := Color(0.22, 0.24, 0.28)
const COLOR_PIEDRA_CLARA := Color(0.35, 0.36, 0.38)
const COLOR_MADERA_OSCURA := Color(0.32, 0.22, 0.15)
const COLOR_DORADO_ORO := Color(0.78, 0.65, 0.38)
const COLOR_TEXTO_INSCRIPCION := Color(0.85, 0.75, 0.52)

var _actas_inspeccionadas: Array[int] = []
var _acta_seleccionada := -1
var _cronista_consultado := false
var _fuga_abierta := false
var _completado := false
var _version_propuesta := -1

var _caminante: CharacterBody3D
var _hud: HUDLayer
var _texto_objetivo: Label
var _acta_nodes: Array[Interactuable3D] = []
var _cronista_node: Interactuable3D
var _salida_node: Interactuable3D


func _ready() -> void:
	_montar_mundo()
	_montar_interactuables()
	_montar_hud()
	_caminante = ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	_caminante.name = "Caminante"
	_caminante.position = Vector3(0.0, 1.0, 6.0)
	add_child(_caminante)
	_caminante.call("conectar_hud", _hud)


## Devuelve el estado puramente local de la escena de investigación.
func estado_local() -> Dictionary:
	return {
		"actas_inspeccionadas": _actas_inspeccionadas.duplicate(),
		"conteo_actas": _actas_inspeccionadas.size(),
		"cronista_consultado": _cronista_consultado,
		"acta_seleccionada": _acta_seleccionada,
		"fuga_abierta": _fuga_abierta,
		"completado": _completado,
	}


## Registra la inspección de una de las tres actas incompatibles (0, 1 o 2).
func inspeccionar_acta(indice: int) -> void:
	if _completado or indice < 0 or indice >= TOTAL_ACTAS:
		return

	if not _actas_inspeccionadas.has(indice):
		_actas_inspeccionadas.append(indice)
		_actas_inspeccionadas.sort()

	match indice:
		0:
			_mensaje(
				"Acta I — Afirma que la fortaleza se entregó pacíficamente tras un pacto secreto."
			)
		1:
			_mensaje(
				(
					"Acta II — Documenta un asedio sangriento y la posterior falsificación "
					+ "de las crónicas oficiales."
				)
			)
		2:
			_mensaje(
				"Acta III — Sostiene que la fortaleza es una alegoría y nunca existió realmente."
			)

	# Tras conocer las tres versiones, tocar cualquier acta la propone al
	# Cronista. La última leída queda seleccionada, pero puede cambiarse.
	if _actas_inspeccionadas.size() == TOTAL_ACTAS:
		_version_propuesta = indice
		if is_instance_valid(_texto_objetivo):
			_texto_objetivo.text += (
				"\n\nActa %s propuesta. Contrástala con el Cronista Velado "
				+ "o inspecciona otra acta para cambiar de versión."
			) % ["I", "II", "III"][indice]

	_actualizar_interacciones()


## Contrasta una versión elegida con el Cronista Velado.
## Si la versión es la fundamentada (Acta II), abre la fuga.
## Si la versión no es válida, permite reintentar sin softlock.
func seleccionar_version(indice: int) -> bool:
	if _completado or indice < 0 or indice >= TOTAL_ACTAS:
		return false

	if _actas_inspeccionadas.size() < TOTAL_ACTAS:
		_mensaje(
			(
				"El Cronista Velado guarda silencio: "
				+ "debes inspeccionar las tres actas incompatibles antes de elegir."
			)
		)
		return false

	_cronista_consultado = true
	_acta_seleccionada = indice

	if indice == ACTA_FUNDAMENTADA:
		_fuga_abierta = true
		_mensaje(
			(
				"El Cronista Velado asiente: el Acta II es la única versión fundamentada "
				+ "por los restos físicos del asedio. La vía de fuga queda libre."
			)
		)
		_actualizar_interacciones()
		return true

	_fuga_abierta = false
	_mensaje(
		(
			"El Cronista Velado señala las contradicciones de esta versión. "
			+ "Debes reflexionar y probar de nuevo."
		)
	)
	_actualizar_interacciones()
	return false


## Permite avanzar el diálogo/contraste interactivo con el Cronista.
func contrastar_con_cronista() -> void:
	if _actas_inspeccionadas.size() < TOTAL_ACTAS:
		_mensaje("Debes inspeccionar las tres actas incompatibles antes de contrastar.")
		return

	# Si la fuga ya está abierta, recordar al jugador que se puede marchar.
	if _fuga_abierta:
		_mensaje("El Cronista Velado ya ha validado tu versión. Dirígete a la vía de fuga.")
		return

	# La decisión sale de las actas físicamente inspeccionadas por el jugador;
	# nunca se fuerza un fallo previo ni se entrega la solución por turnos.
	if _version_propuesta < 0:
		_mensaje("Elige primero un acta en sus atriles para defender una versión.")
		return
	seleccionar_version(_version_propuesta)


## Solicita salir por la vía de fuga tras resolver el archivo.
## Devuelve true si la fuga se efectúa con éxito.
func solicitar_fuga() -> bool:
	if _completado:
		return false

	if not _fuga_abierta:
		_mensaje(
			(
				"La vía de fuga permanece sellada. "
				+ "Inspecciona las tres actas y contrástalas con el Cronista Velado."
			)
		)
		return false

	_completado = true
	_actualizar_interacciones()
	_mensaje("Has atravesado la vía de fuga del Archivo. Investigación completada.")
	completado.emit()
	return true


func _montar_mundo() -> void:
	var mundo := WorldEnvironment.new()
	mundo.name = "AmbienteArchivo"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.04, 0.05, 0.07)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.5, 0.55, 0.65)
	entorno.ambient_light_energy = 0.6
	mundo.environment = entorno
	add_child(mundo)

	var luz := DirectionalLight3D.new()
	luz.name = "LuzArchivo"
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_color = Color(0.6, 0.7, 0.85)
	luz.light_energy = 0.75
	luz.shadow_enabled = true
	add_child(luz)

	_pieza("Suelo", Vector3(0, -0.45, 0), Vector3(16, 0.9, 18), COLOR_PARED)
	_pieza("MuroOeste", Vector3(-8.0, 2.7, 0), Vector3(0.9, 5.4, 18), COLOR_PARED)
	_pieza("MuroEste", Vector3(8.0, 2.7, 0), Vector3(0.9, 5.4, 18), COLOR_PARED)
	_pieza("MuroNorte", Vector3(0, 2.7, -9.0), Vector3(16, 5.4, 0.9), COLOR_PARED)
	_pieza("MuroSur", Vector3(0, 2.7, 9.0), Vector3(16, 5.4, 0.9), COLOR_PARED)

	# Mesas/Pedestales para las 3 actas
	_pieza("AtrilActa1", Vector3(-4.5, 0.7, 1.0), Vector3(1.4, 1.4, 1.2), COLOR_MADERA_OSCURA)
	_pieza("AtrilActa2", Vector3(0.0, 0.7, -1.5), Vector3(1.4, 1.4, 1.2), COLOR_MADERA_OSCURA)
	_pieza("AtrilActa3", Vector3(4.5, 0.7, 1.0), Vector3(1.4, 1.4, 1.2), COLOR_MADERA_OSCURA)

	# Escaño del Cronista
	_pieza("EscarcaCronista", Vector3(0.0, 0.5, -6.5), Vector3(2.6, 1.0, 2.0), COLOR_PIEDRA_CLARA)

	# Umbral de fuga
	_pieza("MarcoFuga", Vector3(0.0, 2.2, -8.5), Vector3(3.2, 4.4, 0.4), COLOR_DORADO_ORO, false)

	var luz_cronista := OmniLight3D.new()
	luz_cronista.name = "LuzCronista"
	luz_cronista.position = Vector3(0.0, 3.0, -6.0)
	luz_cronista.light_color = COLOR_TEXTO_INSCRIPCION
	luz_cronista.light_energy = 1.0
	luz_cronista.omni_range = 7.0
	add_child(luz_cronista)

	_rotulo("ACTA I", Vector3(-4.5, 1.8, 1.0))
	_rotulo("ACTA II", Vector3(0.0, 1.8, -1.5))
	_rotulo("ACTA III", Vector3(4.5, 1.8, 1.0))
	_rotulo("CRONISTA VELADO", Vector3(0.0, 2.2, -6.5))
	_rotulo("VIA DE FUGA", Vector3(0.0, 3.8, -8.3))


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

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	visual.material_override = mat

	raiz.add_child(visual)
	add_child(raiz)


func _rotulo(texto: String, posicion: Vector3) -> void:
	var rotulo := Label3D.new()
	rotulo.name = texto.replace(" ", "_")
	rotulo.text = texto
	rotulo.position = posicion
	rotulo.pixel_size = 0.006
	rotulo.font_size = 32
	rotulo.modulate = COLOR_TEXTO_INSCRIPCION
	add_child(rotulo)


func _montar_interactuables() -> void:
	_acta_nodes.clear()

	var posiciones_actas := [
		Vector3(-4.5, 1.3, 1.0),
		Vector3(0.0, 1.3, -1.5),
		Vector3(4.5, 1.3, 1.0),
	]

	for i in range(TOTAL_ACTAS):
		var pos: Vector3 = posiciones_actas[i]
		var acta := _objeto(
			"Acta_%d" % (i + 1),
			pos,
			Vector3(1.4, 1.6, 1.2),
			Interactuable3D.Verbo.LEER,
			"Acta %d" % (i + 1),
		)
		var indice_acta := i
		acta.activado.connect(func(_actor: Node): inspeccionar_acta(indice_acta))
		_acta_nodes.append(acta)

	_cronista_node = _objeto(
		"CronistaVelado",
		Vector3(0.0, 1.3, -5.5),
		Vector3(2.2, 2.2, 1.5),
		Interactuable3D.Verbo.USAR,
		"Cronista Velado",
	)
	_cronista_node.activado.connect(func(_actor: Node): contrastar_con_cronista())

	_salida_node = _objeto(
		"SalidaFuga",
		Vector3(0.0, 1.3, -8.0),
		Vector3(2.5, 2.5, 0.8),
		Interactuable3D.Verbo.USAR,
		"Vía de Fuga",
	)
	_salida_node.activado.connect(func(_actor: Node): solicitar_fuga())

	_actualizar_interacciones()


func _objeto(
	nombre: String,
	posicion: Vector3,
	tamano: Vector3,
	verbo: int,
	titulo: String,
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
	if is_instance_valid(_cronista_node):
		_cronista_node.habilitado = not _completado
	if is_instance_valid(_salida_node):
		_salida_node.habilitado = _fuga_abierta and not _completado


func _montar_hud() -> void:
	_hud = HUDLayer.new()
	_hud.name = "InterfazArchivoCronista"
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
			"Archivo del Cronista Velado — Inspecciona las tres actas incompatibles "
			+ "y contrástalas con el Cronista para hallar la versión fundamentada."
		)
	)


func _mensaje(texto: String) -> void:
	if is_instance_valid(_texto_objetivo):
		_texto_objetivo.text = texto
