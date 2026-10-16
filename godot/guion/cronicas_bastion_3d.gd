## Vertical independiente de Crónicas de las Siete Esferas (#2589).
## Monta una sola sala original. No guarda ni altera SIGA, sueños o Hastur.
class_name CronicasBastion3D
extends Node3D

signal completado

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")
const LECTURAS_NECESARIAS := 2
const COLOR_PIEDRA := Color(0.26, 0.28, 0.31)
const COLOR_PIEDRA_CLARA := Color(0.37, 0.36, 0.33)
const COLOR_BRONCE := Color(0.48, 0.31, 0.18)
const COLOR_INSCRIPCION := Color(0.82, 0.71, 0.47)

var _lecturas := 0
var _interpretacion := 1
var _duelo_resuelto := false
var _en_combate := false
var _completado := false

var _caminante: CharacterBody3D
var _combate: JuicioCombate3D
var _texto: Label
var _hud: HUDLayer
var _guardian: Interactuable3D
var _salida: Interactuable3D


func _ready() -> void:
	_montar_mundo()
	_montar_interactuables()
	_montar_hud()
	_caminante = ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	_caminante.name = "Caminante"
	_caminante.position = Vector3(0, 1.0, 7.0)
	add_child(_caminante)
	# El Caminante crea un prompt propio; anexarlo al HUD evita que quede huérfano.
	_caminante.call("conectar_hud", _hud)


## Lecturas y victorias son únicamente estados LOCALES de esta escena.
## No equivalen a "cronicas_jugadas" en el guardado real de Expediente Legado.
func estado_local() -> Dictionary:
	return {
		"lecturas": _lecturas,
		"interpretacion": _interpretacion,
		"duelo_resuelto": _duelo_resuelto,
		"en_combate": _en_combate,
		"completado": _completado,
	}


func registrar_lectura() -> void:
	if _en_combate or _completado:
		return
	if _lecturas < LECTURAS_NECESARIAS:
		_lecturas += 1
		if _lecturas == 1:
			_mensaje(
				(
					"Crónica I — La torre cayó antes del juramento. "
					+ "El escriba insiste en que nadie la defendió. Vuelve a leer."
				)
			)
		else:
			_mensaje(
				(
					"Crónica II — La torre sigue en pie en otro registro. "
					+ "Dos interpretaciones elegibles: [1] La Torre Caída / [2] El Bastión Inviolable. "
					+ "Acércate al custodio o interactúa de nuevo para revisar la lectura."
				)
			)
	else:
		_interpretacion = 2 if _interpretacion == 1 else 1
		var texto_interp := (
			"Interpretación I: La torre cayó por abandono del juramento."
			if _interpretacion == 1
			else "Interpretación II: El bastión perdura en la memoria inviolable."
		)
		_mensaje(
			(
				"Revisión de lectura — %s " % texto_interp
				+ "La respuesta del custodio cambiará ante el duelo. Acércate a él o interactúa de nuevo."
			)
		)
	_actualizar_interacciones()


func puede_combatir() -> bool:
	return _lecturas >= LECTURAS_NECESARIAS and not _en_combate and not _completado


func puede_salir() -> bool:
	return _duelo_resuelto and not _en_combate and not _completado


func registrar_resultado_duelo(gano: bool) -> void:
	_en_combate = false
	if gano:
		_duelo_resuelto = true
		_mensaje(
			(
				"El custodio cede ante tu interpretación. La verdad del reino sigue disputada: "
				+ "esta victoria no constituye prueba para SIGA. Busca el umbral."
			)
		)
	else:
		_mensaje(
			(
				"El custodio rechaza tu interpretación, pero no te ha vencido para siempre. "
				+ "Puedes revisar las crónicas o volver a desafiarlo."
			)
		)
	_actualizar_interacciones()


func solicitar_salida() -> bool:
	if not puede_salir():
		_mensaje("El umbral permanece cerrado. Consulta ambas crónicas y habla con el custodio.")
		return false
	_completado = true
	_actualizar_interacciones()
	_mensaje("Fin de la primera sala: el Bastión recuerda que lo has atravesado.")
	completado.emit()
	return true


func _montar_mundo() -> void:
	var mundo := WorldEnvironment.new()
	mundo.name = "AmbienteBastion"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.055, 0.066, 0.085)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.57, 0.62, 0.72)
	entorno.ambient_light_energy = 0.55
	mundo.environment = entorno
	add_child(mundo)

	var luna := DirectionalLight3D.new()
	luna.name = "LuzFria"
	luna.rotation_degrees = Vector3(-55, -22, 0)
	luna.light_color = Color(0.56, 0.68, 0.83)
	luna.light_energy = 0.82
	luna.shadow_enabled = true
	add_child(luna)

	_pieza("Suelo", Vector3(0, -0.45, 0), Vector3(17, 0.9, 22), COLOR_PIEDRA)
	_pieza("MuroIzquierdo", Vector3(-8.5, 2.7, 0), Vector3(0.9, 5.4, 22), COLOR_PIEDRA)
	_pieza("MuroDerecho", Vector3(8.5, 2.7, 0), Vector3(0.9, 5.4, 22), COLOR_PIEDRA)
	_pieza("MuroNorte", Vector3(0, 2.7, -10.7), Vector3(17, 5.4, 0.9), COLOR_PIEDRA)
	_pieza("MuroSur", Vector3(0, 2.7, 10.7), Vector3(17, 5.4, 0.9), COLOR_PIEDRA)
	# Contrafuertes y dos pasillos de lectura: silueta original, sin mapa importado.
	for x in [-6.0, 6.0]:
		for z in [-7.0, -1.5, 4.2]:
			_pieza(
				"Pilar_%s_%s" % [str(x), str(z)],
				Vector3(x, 2.15, z),
				Vector3(1.1, 4.3, 1.1),
				COLOR_PIEDRA_CLARA,
			)
	_pieza("FranjaPrimera", Vector3(0, 0.04, 1.2), Vector3(10, 0.08, 0.24), COLOR_BRONCE, false)
	_pieza("FranjaSegunda", Vector3(0, 0.04, -4.5), Vector3(10, 0.08, 0.24), COLOR_BRONCE, false)

	_pieza("Atril", Vector3(0, 0.74, -2.6), Vector3(1.8, 1.48, 1.15), COLOR_BRONCE)
	_pieza("LosaCustodio", Vector3(4.2, 0.14, -6.6), Vector3(2.5, 0.28, 2.5), COLOR_PIEDRA_CLARA)
	_pieza("Umbral", Vector3(0, 2.25, -10.12), Vector3(3.3, 4.5, 0.32), COLOR_BRONCE, false)
	_pieza("JambaIzquierda", Vector3(-2.1, 2.3, -9.9), Vector3(0.75, 4.6, 0.85), COLOR_PIEDRA_CLARA)
	_pieza("JambaDerecha", Vector3(2.1, 2.3, -9.9), Vector3(0.75, 4.6, 0.85), COLOR_PIEDRA_CLARA)

	var luz_atril := OmniLight3D.new()
	luz_atril.name = "LuzInscripciones"
	luz_atril.position = Vector3(0, 3.2, -3.0)
	luz_atril.light_color = COLOR_INSCRIPCION
	luz_atril.light_energy = 0.9
	luz_atril.omni_range = 8.0
	add_child(luz_atril)

	_rotulo("LAS DOS CRONICAS", Vector3(0, 2.25, -3.5))
	_rotulo("CUSTODIO", Vector3(4.2, 2.2, -7.3))
	_rotulo("UMBRAL", Vector3(0, 3.65, -9.72))


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
	material.roughness = 0.95
	visual.material_override = material
	raiz.add_child(visual)
	add_child(raiz)


func _rotulo(texto: String, posicion: Vector3) -> void:
	var rotulo := Label3D.new()
	rotulo.name = texto.replace(" ", "_")
	rotulo.text = texto
	rotulo.position = posicion
	rotulo.pixel_size = 0.006
	rotulo.font_size = 34
	rotulo.modulate = COLOR_INSCRIPCION
	add_child(rotulo)


func _montar_interactuables() -> void:
	var libro := _objeto(
		"DosCronicas",
		Vector3(0, 1.35, -1.95),
		Vector3(1.8, 1.6, 0.65),
		Interactuable3D.Verbo.LEER,
		"las dos crónicas",
	)
	libro.activado.connect(func(_actor: Node): registrar_lectura())
	_guardian = _objeto(
		"Custodio",
		Vector3(4.2, 1.3, -5.8),
		Vector3(1.5, 2.3, 0.85),
		Interactuable3D.Verbo.USAR,
		"custodio del umbral",
	)
	_guardian.activado.connect(func(_actor: Node): _iniciar_combate())
	_salida = _objeto(
		"Salida",
		Vector3(0, 1.3, -9.25),
		Vector3(2.1, 2.5, 0.7),
		Interactuable3D.Verbo.USAR,
		"umbral del bastión",
	)
	_salida.activado.connect(func(_actor: Node): solicitar_salida())
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
	if is_instance_valid(_guardian):
		_guardian.habilitado = puede_combatir()
	if is_instance_valid(_salida):
		_salida.habilitado = puede_salir()


func _montar_hud() -> void:
	_hud = HUDLayer.new()
	var capa := _hud
	capa.name = "InterfazCronicas"
	capa.layer = 8
	add_child(capa)
	var caja := MarginContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	caja.add_theme_constant_override("margin_left", 24)
	caja.add_theme_constant_override("margin_right", 24)
	caja.add_theme_constant_override("margin_top", 18)
	capa.add_child(caja)
	_texto = Label.new()
	_texto.name = "Objetivo"
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(0, 80)
	caja.add_child(_texto)
	_mensaje(
		(
			"Bastión de los Nombres Ausentes — Lee dos versiones del manuscrito. "
			+ "Muévete con los controles habituales de Expediente Legado y usa «Interactuar»."
		)
	)


func _mensaje(contenido: String) -> void:
	if is_instance_valid(_texto):
		_texto.text = contenido


func _iniciar_combate() -> void:
	if not puede_combatir():
		return
	_en_combate = true
	_actualizar_interacciones()
	_caminante.process_mode = Node.PROCESS_MODE_DISABLED
	_caminante.visible = false

	var respuesta_custodio := (
		"Custodio: 'Defiendes la caída de la torre. Demuestra en duelo que la ruina justifica tu paso.'"
		if _interpretacion == 1
		else "Custodio: 'Proclamas que el bastión sigue en pie. Sombra e historia juzgarán tu certeza.'"
	)
	_mensaje(respuesta_custodio)

	_combate = JuicioCombate3D.new()
	_combate.name = "DueloCustodio"
	var nombre_enemigo := (
		"Custodio del umbral (Juicio de la Ruina)"
		if _interpretacion == 1
		else "Custodio del umbral (Juicio del Bastión)"
	)
	(
		_combate
		. configurar(
			{"id": "cronicas_custodio_umbral", "nombre": nombre_enemigo, "ataques": []},
			0,
			bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false)),
			2589,
		)
	)
	_combate.terminado.connect(_al_terminar_combate)
	add_child(_combate)
	for nodo in _combate.get_children():
		if nodo is Camera3D:
			nodo.current = true
			break


func _al_terminar_combate(gano: bool) -> void:
	if is_instance_valid(_combate):
		_combate.queue_free()
	_combate = null
	_caminante.visible = true
	_caminante.process_mode = Node.PROCESS_MODE_INHERIT
	var camara := _caminante.get_node("Camara") as Camera3D
	camara.current = true
	registrar_resultado_duelo(gano)
