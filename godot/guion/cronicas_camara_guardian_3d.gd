## Microarena 3D independiente: Cámara del Guardián (#2589).
## Reutiliza Caminante, Interactuable3D, HUDLayer y JuicioCombate3D.
## Proporciona espacio amplio de esquiva, telegráfos claros, reintento sin duplicar
## enemigos y umbral de salida tras la victoria.
class_name CronicasCamaraGuardian3D
extends Node3D

signal completado

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")
const COLOR_PIEDRA := Color(0.22, 0.24, 0.28)
const COLOR_PIEDRA_CLARA := Color(0.35, 0.35, 0.38)
const COLOR_BRONCE := Color(0.52, 0.36, 0.20)
const COLOR_RUNA := Color(0.85, 0.75, 0.45)

var _inspecciones := 0
var _guardian_vencido := false
var _en_combate := false
var _completado := false

var _caminante: CharacterBody3D
var _combate: JuicioCombate3D
var _texto: Label
var _hud: HUDLayer
var _estela: Interactuable3D
var _guardian: Interactuable3D
var _umbral: Interactuable3D


func _ready() -> void:
	_montar_entorno()
	_montar_interactuables()
	_montar_hud()
	_caminante = ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	_caminante.name = "Caminante"
	_caminante.position = Vector3(0, 1.0, 8.0)
	add_child(_caminante)
	_caminante.call("conectar_hud", _hud)


## Consulta de progreso local determinista.
func progreso_local() -> Dictionary:
	return {
		"inspecciones": _inspecciones,
		"guardian_vencido": _guardian_vencido,
		"en_combate": _en_combate,
		"completado": _completado,
	}


## Alias para compatibilidad con suites de estado local.
func estado_local() -> Dictionary:
	return progreso_local()


func registrar_inspeccion() -> void:
	if _en_combate or _completado:
		return
	_inspecciones += 1
	if _inspecciones == 1:
		_mensaje(
			(
				"Estela del Guardián — «Aquel que desafíe al Guardián debe disponer de espacio "
				+ "para esquivar sus embates y leer sus marcas»."
			)
		)
	else:
		_mensaje(
			(
				"Estela del Guardián — La inscripción permanece intacta. "
				+ "El Guardián aguarda en el centro de la arena."
			)
		)
	_actualizar_interacciones()


func puede_combatir() -> bool:
	return not _en_combate and not _completado


func puede_salir() -> bool:
	return _guardian_vencido and not _en_combate and not _completado


func registrar_resultado_duelo(gano: bool) -> void:
	_en_combate = false
	if gano:
		_guardian_vencido = true
		_mensaje(
			(
				"El Guardián de la Cámara ha sido superado. "
				+ "El umbral de salida al fondo de la arena se ha abierto."
			)
		)
	else:
		_mensaje(
			(
				"Has sido derrotado por el Guardián, pero la prueba no ha concluido. "
				+ "Puedes volver a desafiarlo cuando lo desees."
			)
		)
	_actualizar_interacciones()


func solicitar_salida() -> bool:
	if not puede_salir():
		_mensaje("El umbral permanece sellado hasta vencer al Guardián de la Cámara.")
		return false
	_completado = true
	_actualizar_interacciones()
	_mensaje("Cámara del Guardián superada: has atravesado el umbral.")
	completado.emit()
	return true


func _montar_entorno() -> void:
	var ambiente := WorldEnvironment.new()
	ambiente.name = "AmbienteCamara"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.04, 0.05, 0.07)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.50, 0.55, 0.68)
	entorno.ambient_light_energy = 0.6
	ambiente.environment = entorno
	add_child(ambiente)

	var luz_sol := DirectionalLight3D.new()
	luz_sol.name = "LuzArena"
	luz_sol.rotation_degrees = Vector3(-50, -30, 0)
	luz_sol.light_color = Color(0.65, 0.72, 0.85)
	luz_sol.light_energy = 0.85
	luz_sol.shadow_enabled = true
	add_child(luz_sol)

	# Microarena 3D amplia para facilitar esquivas y movimiento libre.
	_pieza("SueloArena", Vector3(0, -0.5, 0), Vector3(20, 1.0, 26), COLOR_PIEDRA)
	_pieza("MuroIzquierdo", Vector3(-10.0, 3.0, 0), Vector3(1.0, 6.0, 26), COLOR_PIEDRA)
	_pieza("MuroDerecho", Vector3(10.0, 3.0, 0), Vector3(1.0, 6.0, 26), COLOR_PIEDRA)
	_pieza("MuroNorte", Vector3(0, 3.0, -13.0), Vector3(20, 6.0, 1.0), COLOR_PIEDRA)
	_pieza("MuroSur", Vector3(0, 3.0, 13.0), Vector3(20, 6.0, 1.0), COLOR_PIEDRA)

	# Columnas laterales que delimitan la arena dejando amplio espacio central.
	for z_pos in [-8.0, 0.0, 6.0]:
		_pieza(
			"ColumnaIzda_%f" % z_pos,
			Vector3(-7.0, 2.5, z_pos),
			Vector3(1.2, 5.0, 1.2),
			COLOR_PIEDRA_CLARA
		)
		_pieza(
			"ColumnaDcha_%f" % z_pos,
			Vector3(7.0, 2.5, z_pos),
			Vector3(1.2, 5.0, 1.2),
			COLOR_PIEDRA_CLARA
		)

	# Elementos de escenario: pedestal de la estela, plinto del guardián y marco del umbral.
	_pieza("PedestalEstela", Vector3(-5.0, 0.6, 4.0), Vector3(1.6, 1.2, 1.2), COLOR_BRONCE)
	_pieza("PlintoGuardian", Vector3(0, 0.2, -4.0), Vector3(3.0, 0.4, 3.0), COLOR_PIEDRA_CLARA)
	_pieza("MarcoUmbral", Vector3(0, 2.5, -12.4), Vector3(4.0, 5.0, 0.4), COLOR_BRONCE, false)

	var luz_guardian := OmniLight3D.new()
	luz_guardian.name = "LuzGuardian"
	luz_guardian.position = Vector3(0, 3.5, -4.0)
	luz_guardian.light_color = COLOR_RUNA
	luz_guardian.light_energy = 1.0
	luz_guardian.omni_range = 10.0
	add_child(luz_guardian)

	_rotulo("ESTELA", Vector3(-5.0, 1.8, 4.0))
	_rotulo("GUARDIAN", Vector3(0, 2.5, -4.0))
	_rotulo("UMBRAL", Vector3(0, 4.2, -12.0))


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
	material.roughness = 0.90
	visual.material_override = material
	raiz.add_child(visual)
	add_child(raiz)


func _rotulo(texto: String, posicion: Vector3) -> void:
	var rotulo := Label3D.new()
	rotulo.name = "Rotulo_" + texto
	rotulo.text = texto
	rotulo.position = posicion
	rotulo.pixel_size = 0.006
	rotulo.font_size = 36
	rotulo.modulate = COLOR_RUNA
	add_child(rotulo)


func _montar_interactuables() -> void:
	_estela = _crear_objeto(
		"EstelaGuardian",
		Vector3(-5.0, 1.2, 4.0),
		Vector3(1.8, 2.0, 1.8),
		Interactuable3D.Verbo.EXAMINAR,
		"estela del guardián",
	)
	_estela.activado.connect(func(_actor: Node): registrar_inspeccion())

	_guardian = _crear_objeto(
		"GuardianCamara",
		Vector3(0, 1.2, -4.0),
		Vector3(2.5, 2.5, 2.5),
		Interactuable3D.Verbo.USAR,
		"guardián de la cámara",
	)
	_guardian.activado.connect(func(_actor: Node): _iniciar_combate())

	_umbral = _crear_objeto(
		"UmbralSalida",
		Vector3(0, 1.2, -11.5),
		Vector3(3.5, 3.0, 1.5),
		Interactuable3D.Verbo.USAR,
		"umbral de la cámara",
	)
	_umbral.activado.connect(func(_actor: Node): solicitar_salida())

	_actualizar_interacciones()


func _crear_objeto(
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
	if is_instance_valid(_umbral):
		_umbral.habilitado = puede_salir()


func _montar_hud() -> void:
	_hud = HUDLayer.new()
	_hud.name = "InterfazGuardian"
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
			"Cámara del Guardián — Desafía al Guardián en la microarena. "
			+ "Usa los controles habituales de movimiento, esquiva e interacción."
		)
	)


func _mensaje(contenido: String) -> void:
	if is_instance_valid(_texto):
		_texto.text = contenido


func _iniciar_combate() -> void:
	if not puede_combatir():
		return
	if is_instance_valid(_combate):
		_combate.queue_free()
		_combate = null

	_en_combate = true
	_actualizar_interacciones()
	_caminante.process_mode = Node.PROCESS_MODE_DISABLED
	_caminante.visible = false

	_combate = JuicioCombate3D.new()
	_combate.name = "DueloGuardian"
	(
		_combate
		. configurar(
			{
				"id": "cronicas_guardian_camara",
				"nombre": "Guardián de la Cámara",
				"ataques": [],
			},
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
	if is_instance_valid(camara):
		camara.current = true
	registrar_resultado_duelo(gano)
