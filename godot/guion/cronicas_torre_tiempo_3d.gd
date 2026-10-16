## Escena autónoma de la Torre del Tiempo (#2589).
## Tres dispositivos interactivos rotan entre estados deterministas.
## Un indicio visual permite fijar la secuencia correcta y sincronizar.
class_name CronicasTorreTiempo3D
extends Node3D

signal completado

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")
const SECUENCIA_OBJETIVO: Array[int] = [1, 2, 0]
const NOMBRES_ESTADO := ["Amanecer (I)", "Cenit (II)", "Crepúsculo (III)"]
const COLOR_PIEDRA := Color(0.22, 0.24, 0.28)
const COLOR_PIEDRA_CLARA := Color(0.35, 0.36, 0.38)
const COLOR_BRONCE := Color(0.55, 0.38, 0.22)
const COLOR_DORADO := Color(0.85, 0.72, 0.38)
const COLOR_DESALINEADO := Color(0.72, 0.32, 0.28)

var _estados_dispositivos: Array[int] = [0, 0, 0]
var _indicio_leido := false
var _sincronizado := false
var _reintentos := 0
var _completado := false

var _caminante: CharacterBody3D
var _texto: Label
var _hud: HUDLayer
var _interactuables_dispositivos: Array[Interactuable3D] = []
var _mallas_dispositivos: Array[MeshInstance3D] = []
var _rotulos_dispositivos: Array[Label3D] = []
var _mecanismo: Interactuable3D
var _salida: Interactuable3D


func _ready() -> void:
	_montar_mundo()
	_montar_interactuables()
	_montar_hud()
	_caminante = ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	_caminante.name = "Caminante"
	_caminante.position = Vector3(0, 1.0, 7.0)
	add_child(_caminante)
	_caminante.call("conectar_hud", _hud)


## Estado local de la sala para consulta e inspección determinista.
func estado_local() -> Dictionary:
	return {
		"estados_dispositivos": _estados_dispositivos.duplicate(),
		"indicio_leido": _indicio_leido,
		"reintentos": _reintentos,
		"sincronizado": _sincronizado,
		"completado": _completado,
	}


func registrar_lectura_indicio() -> void:
	_indicio_leido = true
	_mensaje(
		(
			"Indicio de Sincronía — «El primer pendulo busca el Cenit (II), "
			+ "el segundo aguarda el Crepúsculo (III), y el tercero retorna al Amanecer (I).»"
		)
	)


func rotar_dispositivo(indice: int) -> void:
	if _sincronizado or _completado:
		return
	if indice < 0 or indice >= _estados_dispositivos.size():
		return
	_estados_dispositivos[indice] = (_estados_dispositivos[indice] + 1) % 3
	_actualizar_aspecto_dispositivo(indice)
	var nombre_disp := _nombre_dispositivo(indice)
	var estado_nombre: String = NOMBRES_ESTADO[_estados_dispositivos[indice]]
	_mensaje("%s ajustado a posición: %s." % [nombre_disp, estado_nombre])


func intentar_sincronizar() -> bool:
	if _completado:
		return false
	if _sincronizado:
		_mensaje("Los dispositivos ya están sincronizados. El umbral está abierto.")
		return true

	var correcto := true
	for i in range(_estados_dispositivos.size()):
		if _estados_dispositivos[i] != SECUENCIA_OBJETIVO[i]:
			correcto = false
			break

	if correcto:
		_sincronizado = true
		_mensaje(
			(
				"¡Sincronización lograda! Los tres mecanismos resuenan al unísono. "
				+ "El umbral del tiempo se ha abierto."
			)
		)
	else:
		_reintentos += 1
		_mensaje(
			(
				(
					"Fallo de sincronía (Reintento %d): la resonancia no encaja. "
					+ "Revisa la placa de indicio e interactúa con los dispositivos para corregir."
				)
				% _reintentos
			)
		)

	_actualizar_interacciones()
	return _sincronizado


func puede_salir() -> bool:
	return _sincronizado and not _completado


func solicitar_salida() -> bool:
	if not puede_salir():
		_mensaje("El umbral del tiempo permanece sellado. Sincroniza los tres dispositivos.")
		return false
	_completado = true
	_actualizar_interacciones()
	_mensaje("Has atravesado la Torre del Tiempo. Sincronización completada.")
	completado.emit()
	return true


func _montar_mundo() -> void:
	var mundo := WorldEnvironment.new()
	mundo.name = "AmbienteTorre"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.04, 0.05, 0.07)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.5, 0.55, 0.65)
	entorno.ambient_light_energy = 0.6
	mundo.environment = entorno
	add_child(mundo)

	var luz := DirectionalLight3D.new()
	luna_luz(luz)
	add_child(luz)

	_pieza("Suelo", Vector3(0, -0.45, 0), Vector3(16, 0.9, 20), COLOR_PIEDRA)
	_pieza("MuroIzquierdo", Vector3(-8.0, 2.7, 0), Vector3(0.9, 5.4, 20), COLOR_PIEDRA)
	_pieza("MuroDerecho", Vector3(8.0, 2.7, 0), Vector3(0.9, 5.4, 20), COLOR_PIEDRA)
	_pieza("MuroNorte", Vector3(0, 2.7, -9.7), Vector3(16, 5.4, 0.9), COLOR_PIEDRA)
	_pieza("MuroSur", Vector3(0, 2.7, 9.7), Vector3(16, 5.4, 0.9), COLOR_PIEDRA)

	# Pedestales para los 3 dispositivos
	var posiciones_x: Array[float] = [-4.0, 0.0, 4.0]
	for i in range(3):
		var x: float = posiciones_x[i]
		_pieza("Pedestal_%d" % i, Vector3(x, 0.5, -2.0), Vector3(1.4, 1.0, 1.4), COLOR_PIEDRA_CLARA)

	# Mecanismo central y Umbral
	_pieza("PlacaIndicioBase", Vector3(-5.5, 0.7, 4.0), Vector3(1.2, 1.4, 0.8), COLOR_BRONCE)
	_pieza("MecanismoBase", Vector3(0, 0.4, 2.5), Vector3(2.2, 0.8, 1.6), COLOR_BRONCE)
	_pieza("UmbralMarco", Vector3(0, 2.2, -9.1), Vector3(3.2, 4.4, 0.4), COLOR_BRONCE, false)

	_rotulo("INDICIO DE SINCRONIA", Vector3(-5.5, 1.8, 4.0))
	_rotulo("MECANISMO CENTRAL", Vector3(0, 1.2, 2.5))
	_rotulo("UMBRAL DEL TIEMPO", Vector3(0, 3.5, -8.8))


func luna_luz(luz: DirectionalLight3D) -> void:
	luz.name = "LuzTorre"
	luz.rotation_degrees = Vector3(-60, -30, 0)
	luz.light_color = Color(0.6, 0.7, 0.85)
	luz.light_energy = 0.85
	luz.shadow_enabled = true


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
	material.roughness = 0.8
	visual.material_override = material
	raiz.add_child(visual)
	add_child(raiz)


func _rotulo(texto: String, posicion: Vector3) -> void:
	var rotulo := Label3D.new()
	rotulo.name = texto.replace(" ", "_")
	rotulo.text = texto
	rotulo.position = posicion
	rotulo.pixel_size = 0.005
	rotulo.font_size = 32
	rotulo.modulate = COLOR_DORADO
	add_child(rotulo)


func _montar_interactuables() -> void:
	var indicio := _objeto(
		"IndicioSincronia",
		Vector3(-5.5, 1.4, 4.0),
		Vector3(1.2, 1.4, 0.8),
		Interactuable3D.Verbo.LEER,
		"placa de indicio",
	)
	indicio.activado.connect(func(_actor: Node): registrar_lectura_indicio())

	var posiciones_x: Array[float] = [-4.0, 0.0, 4.0]
	var nombres_disp: Array[String] = [
		"Pendulo del Alba", "Reloj del Cenit", "Campana del Crepúsculo"
	]

	for i in range(3):
		var px: float = posiciones_x[i]
		var disp_nombre: String = nombres_disp[i]

		# Visual mesh del dispositivo que rota según su estado
		var malla_disp := MeshInstance3D.new()
		var caja_mesh := BoxMesh.new()
		caja_mesh.size = Vector3(0.8, 1.2, 0.8)
		malla_disp.mesh = caja_mesh
		malla_disp.name = "MallaDisp_%d" % i
		malla_disp.position = Vector3(px, 1.6, -2.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLOR_DORADO
		malla_disp.material_override = mat
		add_child(malla_disp)
		_mallas_dispositivos.append(malla_disp)

		var label_disp := Label3D.new()
		label_disp.name = "LabelDisp_%d" % i
		label_disp.position = Vector3(px, 2.4, -2.0)
		label_disp.pixel_size = 0.005
		label_disp.font_size = 28
		label_disp.modulate = COLOR_DORADO
		add_child(label_disp)
		_rotulos_dispositivos.append(label_disp)

		var idx := i
		var obj := _objeto(
			"Dispositivo_%d" % i,
			Vector3(px, 1.5, -2.0),
			Vector3(1.4, 1.8, 1.4),
			Interactuable3D.Verbo.USAR,
			disp_nombre.to_lower(),
		)
		obj.activado.connect(func(_actor: Node): rotar_dispositivo(idx))
		_interactuables_dispositivos.append(obj)
		_actualizar_aspecto_dispositivo(i)

	_mecanismo = _objeto(
		"MecanismoSincronia",
		Vector3(0, 1.0, 2.5),
		Vector3(2.2, 1.2, 1.6),
		Interactuable3D.Verbo.USAR,
		"mecanismo central",
	)
	_mecanismo.activado.connect(func(_actor: Node): intentar_sincronizar())

	_salida = _objeto(
		"UmbralTiempo",
		Vector3(0, 1.5, -8.8),
		Vector3(2.5, 3.0, 0.8),
		Interactuable3D.Verbo.USAR,
		"umbral del tiempo",
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


func _nombre_dispositivo(indice: int) -> String:
	var nombres: Array[String] = ["Pendulo del Alba", "Reloj del Cenit", "Campana del Crepúsculo"]
	if indice >= 0 and indice < nombres.size():
		return nombres[indice]
	return "Dispositivo %d" % indice


func _actualizar_aspecto_dispositivo(indice: int) -> void:
	if indice < 0 or indice >= _mallas_dispositivos.size():
		return
	var estado: int = _estados_dispositivos[indice]
	var malla: MeshInstance3D = _mallas_dispositivos[indice]
	malla.rotation_degrees.y = estado * 120.0
	var label: Label3D = _rotulos_dispositivos[indice]
	var estado_txt: String = NOMBRES_ESTADO[estado]
	label.text = "%s\n[%s]" % [_nombre_dispositivo(indice), estado_txt]


func _actualizar_interacciones() -> void:
	for obj in _interactuables_dispositivos:
		if is_instance_valid(obj):
			obj.habilitado = not _sincronizado and not _completado
	if is_instance_valid(_mecanismo):
		_mecanismo.habilitado = not _sincronizado and not _completado
	if is_instance_valid(_salida):
		_salida.habilitado = puede_salir()


func _montar_hud() -> void:
	_hud = HUDLayer.new()
	var capa := _hud
	capa.name = "InterfazTorre"
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
			"Torre del Tiempo — Examina la placa de indicio, ajusta las tres campanas/relojes "
			+ "y activa el mecanismo central para abrir el umbral."
		)
	)


func _mensaje(contenido: String) -> void:
	if is_instance_valid(_texto):
		_texto.text = contenido
