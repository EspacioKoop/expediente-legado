## Scene 3D del Scriptorium de Crónicas de las Siete Esferas (#2589).
## Permite ordenar tres de cuatro folios contradictorios según la cronología
## deducible de las actas del escenario, con reintento/deshacer sin penalización.
class_name CronicasScriptoriumVersiones3D
extends Node3D

signal completado

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")
const SECUENCIA_CORRECTA: Array[int] = [1, 2, 3]

const COLOR_PIEDRA := Color(0.24, 0.22, 0.21)
const COLOR_PIEDRA_CLARA := Color(0.35, 0.32, 0.28)
const COLOR_MADERA := Color(0.38, 0.24, 0.15)
const COLOR_PERGAMINO := Color(0.85, 0.78, 0.62)
const COLOR_TINTA_DORADA := Color(0.88, 0.75, 0.42)

var _actas_leidas: Array[String] = []
var _folios_colocados: Array[int] = []
var _orden_correcto := false
var _completado := false

var _caminante: CharacterBody3D
var _hud: HUDLayer
var _texto: Label
var _puerta: Interactuable3D
var _btn_deshacer: Interactuable3D
var _folio_interactuables: Dictionary = {}


func _ready() -> void:
	_montar_mundo()
	_montar_interactuables()
	_montar_hud()
	_caminante = ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	_caminante.name = "Caminante"
	_caminante.position = Vector3(0, 1.0, 7.0)
	add_child(_caminante)
	_caminante.call("conectar_hud", _hud)


## Devuelve la consulta de progreso local de esta escena autónoma.
func estado_local() -> Dictionary:
	return {
		"actas_leidas": _actas_leidas.duplicate(),
		"folios_colocados": _folios_colocados.duplicate(),
		"orden_correcto": _orden_correcto,
		"completado": _completado,
	}


func registrar_lectura_acta(id_acta: String, contenido: String) -> void:
	if not _actas_leidas.has(id_acta):
		_actas_leidas.append(id_acta)
	_mensaje(contenido)


func seleccionar_folio(id_folio: int) -> void:
	if _completado:
		return
	if _orden_correcto:
		_mensaje("El orden ya es correcto y el acceso está abierto.")
		return
	if _folios_colocados.has(id_folio):
		_mensaje("Ese folio ya forma parte de la secuencia elegida.")
		return
	if _folios_colocados.size() >= 3:
		_mensaje(
			(
				"Ya has colocado 3 folios en la mesa. "
				+ "Usa «Reorganizar folios» para reintentar otra combinación."
			)
		)
		return

	_folios_colocados.append(id_folio)
	var nombre_folio := _nombre_folio(id_folio)
	if _folios_colocados.size() < 3:
		_mensaje(
			(
				"Añadido "
				+ nombre_folio
				+ " (posición "
				+ str(_folios_colocados.size())
				+ " de 3). Sigue examinando o coloca más folios."
			)
		)
	else:
		_comprobar_secuencia()
	_actualizar_interacciones()


func deshacer() -> void:
	if _completado:
		return
	_folios_colocados.clear()
	_orden_correcto = false
	_mensaje("Secuencia de folios reiniciada sin penalización. Puedes volver a ordenarlos.")
	_actualizar_interacciones()


func solicitar_salida() -> bool:
	if not _orden_correcto:
		_mensaje(
			"El acceso permanece sellado. Ordena los tres folios según la cronología de las actas."
		)
		return false
	if _completado:
		return false
	_completado = true
	_mensaje("Has descifrado la cronología del Scriptorium. Acceso libre.")
	_actualizar_interacciones()
	completado.emit()
	return true


func _comprobar_secuencia() -> void:
	var coincide := true
	if _folios_colocados.size() != SECUENCIA_CORRECTA.size():
		coincide = false
	else:
		for i in range(SECUENCIA_CORRECTA.size()):
			if _folios_colocados[i] != SECUENCIA_CORRECTA[i]:
				coincide = false
				break

	if coincide:
		_orden_correcto = true
		_mensaje(
			(
				"¡Secuencia cronológica correcta! "
				+ "(I: Decreto → II: Memoria → III: Tratado). El umbral del Scriptorium se ha abierto."
			)
		)
	else:
		_mensaje(
			(
				"La secuencia elegida entra en contradicción con las actas. "
				+ "Usa «Reorganizar folios» para probar de nuevo."
			)
		)


func _nombre_folio(id_folio: int) -> String:
	match id_folio:
		1:
			return "Folio I: Decreto del Cisma"
		2:
			return "Folio II: Memoria de los Siete"
		3:
			return "Folio III: Tratado de los Nombres"
		4:
			return "Folio IV: Acta Apócrifa"
		_:
			return "Folio Desconocido"


func _montar_mundo() -> void:
	var mundo := WorldEnvironment.new()
	mundo.name = "AmbienteScriptorium"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.06, 0.05, 0.04)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.62, 0.58, 0.48)
	entorno.ambient_light_energy = 0.6
	mundo.environment = entorno
	add_child(mundo)

	var luz_calida := DirectionalLight3D.new()
	luz_calida.name = "LuzAntorcha"
	luz_calida.rotation_degrees = Vector3(-50, -30, 0)
	luz_calida.light_color = Color(0.92, 0.78, 0.55)
	luz_calida.light_energy = 0.85
	luz_calida.shadow_enabled = true
	add_child(luz_calida)

	_pieza("Suelo", Vector3(0, -0.45, 0), Vector3(16, 0.9, 20), COLOR_PIEDRA)
	_pieza("MuroIzquierdo", Vector3(-8.0, 2.7, 0), Vector3(0.9, 5.4, 20), COLOR_PIEDRA)
	_pieza("MuroDerecho", Vector3(8.0, 2.7, 0), Vector3(0.9, 5.4, 20), COLOR_PIEDRA)
	_pieza("MuroNorte", Vector3(0, 2.7, -9.7), Vector3(16, 5.4, 0.9), COLOR_PIEDRA)
	_pieza("MuroSur", Vector3(0, 2.7, 9.7), Vector3(16, 5.4, 0.9), COLOR_PIEDRA)

	# Columnas del Scriptorium
	for x in [-5.0, 5.0]:
		for z in [-6.0, 0.0, 5.0]:
			_pieza(
				"Columna_%s_%s" % [str(x), str(z)],
				Vector3(x, 2.15, z),
				Vector3(1.0, 4.3, 1.0),
				COLOR_PIEDRA_CLARA,
			)

	# Mesas y Atriles
	_pieza("MesaCentral", Vector3(0, 0.75, 0), Vector3(3.6, 0.8, 1.8), COLOR_MADERA)
	_pieza("AtrilActa1", Vector3(-4.5, 0.85, -3.5), Vector3(1.4, 0.9, 1.1), COLOR_MADERA)
	_pieza("AtrilActa2", Vector3(4.5, 0.85, -3.5), Vector3(1.4, 0.9, 1.1), COLOR_MADERA)
	_pieza("AtrilReorganizar", Vector3(0, 0.75, 2.8), Vector3(1.6, 0.8, 1.0), COLOR_MADERA)

	# Umbral de Salida
	_pieza("Umbral", Vector3(0, 2.25, -9.1), Vector3(3.2, 4.5, 0.3), COLOR_MADERA, false)
	_pieza("MarcoIzquierdo", Vector3(-2.0, 2.3, -8.9), Vector3(0.7, 4.6, 0.8), COLOR_PIEDRA_CLARA)
	_pieza("MarcoDerecho", Vector3(2.0, 2.3, -8.9), Vector3(0.7, 4.6, 0.8), COLOR_PIEDRA_CLARA)

	_rotulo("ACTAS PRIMERAS", Vector3(-4.5, 2.1, -4.0))
	_rotulo("ACTAS SEGUNDAS", Vector3(4.5, 2.1, -4.0))
	_rotulo("MESA DE FOLIOS", Vector3(0, 2.0, -0.8))
	_rotulo("REORGANIZAR", Vector3(0, 1.9, 2.3))
	_rotulo("ACCESO AL ARCHIVO", Vector3(0, 3.5, -8.7))


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
	rotulo.name = texto.replace(" ", "_")
	rotulo.text = texto
	rotulo.position = posicion
	rotulo.pixel_size = 0.006
	rotulo.font_size = 32
	rotulo.modulate = COLOR_TINTA_DORADA
	add_child(rotulo)


func _montar_interactuables() -> void:
	var acta1 := _objeto(
		"Acta1",
		Vector3(-4.5, 1.4, -3.5),
		Vector3(1.2, 1.2, 0.8),
		Interactuable3D.Verbo.LEER,
		"Anales del Scriptorium (I)",
	)
	acta1.activado.connect(
		func(_actor: Node):
			registrar_lectura_acta(
				"acta_1",
				(
					"Acta I — 'El Decreto del Cisma precedió a la llegada de los Siete. "
					+ "Toda acta apócrifa cita erróneamente el Cisma como posterior.'"
				)
			)
	)

	var acta2 := _objeto(
		"Acta2",
		Vector3(4.5, 1.4, -3.5),
		Vector3(1.2, 1.2, 0.8),
		Interactuable3D.Verbo.LEER,
		"Anales del Scriptorium (II)",
	)
	acta2.activado.connect(
		func(_actor: Node):
			registrar_lectura_acta(
				"acta_2",
				(
					"Acta II — 'El Tratado de los Nombres es el cierre de la trilogía canónica. "
					+ "La Memoria de los Siete se redactó inmediatamente después del Decreto.'"
				)
			)
	)

	_folio_interactuables[1] = _objeto(
		"Folio1",
		Vector3(-1.2, 1.2, 0.0),
		Vector3(0.8, 0.8, 0.8),
		Interactuable3D.Verbo.COGER,
		"Folio I: Decreto del Cisma",
	)
	_folio_interactuables[1].activado.connect(func(_actor: Node): seleccionar_folio(1))

	_folio_interactuables[2] = _objeto(
		"Folio2",
		Vector3(-0.4, 1.2, 0.0),
		Vector3(0.8, 0.8, 0.8),
		Interactuable3D.Verbo.COGER,
		"Folio II: Memoria de los Siete",
	)
	_folio_interactuables[2].activado.connect(func(_actor: Node): seleccionar_folio(2))

	_folio_interactuables[3] = _objeto(
		"Folio3",
		Vector3(0.4, 1.2, 0.0),
		Vector3(0.8, 0.8, 0.8),
		Interactuable3D.Verbo.COGER,
		"Folio III: Tratado de los Nombres",
	)
	_folio_interactuables[3].activado.connect(func(_actor: Node): seleccionar_folio(3))

	_folio_interactuables[4] = _objeto(
		"Folio4",
		Vector3(1.2, 1.2, 0.0),
		Vector3(0.8, 0.8, 0.8),
		Interactuable3D.Verbo.COGER,
		"Folio IV: Acta Apócrifa",
	)
	_folio_interactuables[4].activado.connect(func(_actor: Node): seleccionar_folio(4))

	_btn_deshacer = _objeto(
		"BtnDeshacer",
		Vector3(0, 1.2, 2.8),
		Vector3(1.4, 0.8, 0.8),
		Interactuable3D.Verbo.USAR,
		"Reorganizar folios",
	)
	_btn_deshacer.activado.connect(func(_actor: Node): deshacer())

	_puerta = _objeto(
		"PuertaAcceso",
		Vector3(0, 1.3, -8.5),
		Vector3(2.0, 2.5, 0.6),
		Interactuable3D.Verbo.USAR,
		"Acceso al Archivo",
	)
	_puerta.activado.connect(func(_actor: Node): solicitar_salida())

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
	if is_instance_valid(_puerta):
		_puerta.habilitado = _orden_correcto and not _completado
	if is_instance_valid(_btn_deshacer):
		_btn_deshacer.habilitado = not _completado and not _folios_colocados.is_empty()
	for id_folio in _folio_interactuables:
		var interactuable: Interactuable3D = _folio_interactuables[id_folio]
		if is_instance_valid(interactuable):
			interactuable.habilitado = (
				not _completado and not _orden_correcto and not _folios_colocados.has(id_folio)
			)


func _montar_hud() -> void:
	_hud = HUDLayer.new()
	var capa := _hud
	capa.name = "InterfazScriptorium"
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
			"Scriptorium — Lee las actas en los atriles y selecciona 3 de los 4 folios "
			+ "en el orden cronológico correcto."
		)
	)


func _mensaje(contenido: String) -> void:
	if is_instance_valid(_texto):
		_texto.text = contenido
