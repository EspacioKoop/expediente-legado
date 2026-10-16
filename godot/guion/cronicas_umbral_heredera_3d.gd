## Vertical independiente de Crónicas de las Siete Esferas (#2589).
## Encuentro 3D con la Heredera del Umbral sobre autoría histórica.
## Presenta dos posturas legítimas que abren accesos físicos distintos (Ala Oeste y Ala Este).
## No modifica ni guarda estado global en SIGA, sueños o Expediente Legado.
class_name CronicasUmbralHeredera3D
extends Node3D

signal completado

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")
const COLOR_PIEDRA := Color(0.24, 0.26, 0.29)
const COLOR_PIEDRA_CLARA := Color(0.35, 0.36, 0.38)
const COLOR_BRONCE := Color(0.48, 0.31, 0.18)
const COLOR_ORO := Color(0.85, 0.72, 0.42)
const COLOR_MEMORIA := Color(0.28, 0.55, 0.72)
const COLOR_REGISTRO := Color(0.72, 0.45, 0.28)

var _postura_elegida := ""
var _acceso_abierto := ""
var _pasaje_recorrido := false
var _completado := false

var _caminante: CharacterBody3D
var _hud: HUDLayer
var _texto: Label

var _heredera: Interactuable3D
var _stela_memoria: Interactuable3D
var _stela_registro: Interactuable3D
var _salida_oeste: Interactuable3D
var _salida_este: Interactuable3D

var _puerta_oeste: Node3D
var _puerta_este: Node3D


func _ready() -> void:
	_montar_mundo()
	_montar_interactuables()
	_montar_hud()
	_caminante = ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	_caminante.name = "Caminante"
	_caminante.position = Vector3(0, 1.0, 8.0)
	add_child(_caminante)
	_caminante.call("conectar_hud", _hud)


## La postura y los accesos son únicamente estados LOCALES de esta escena.
## No modifican ni equivalen a guardado real de Expediente Legado.
func estado_local() -> Dictionary:
	return {
		"postura_elegida": _postura_elegida,
		"acceso_abierto": _acceso_abierto,
		"pasaje_recorrido": _pasaje_recorrido,
		"completado": _completado,
	}


func elegir_postura(postura: String) -> void:
	if _completado:
		return
	if postura != "MEMORIA" and postura != "REGISTRO":
		return

	_postura_elegida = postura
	if _postura_elegida == "MEMORIA":
		_acceso_abierto = "OESTE"
		_abrir_puerta_oeste()
		_mensaje(
			(
				"Postura asumida: Memoria Colectiva. La crónica vive en la comunidad "
				+ "y la tradición oral. Se ha abierto el Ala Oeste."
			)
		)
	elif _postura_elegida == "REGISTRO":
		_acceso_abierto = "ESTE"
		_abrir_puerta_este()
		_mensaje(
			(
				"Postura asumida: Registro Inmutable. La crónica es documento "
				+ "sellado e inalterable. Se ha abierto el Ala Este."
			)
		)
	_actualizar_interacciones()


func puede_salir(ruta: String) -> bool:
	if _completado:
		return false
	if _postura_elegida.is_empty() or _acceso_abierto.is_empty():
		return false
	return (
		(ruta == "OESTE" and _acceso_abierto == "OESTE")
		or (ruta == "ESTE" and _acceso_abierto == "ESTE")
	)


func solicitar_salida(ruta: String) -> bool:
	if not puede_salir(ruta):
		_mensaje(
			(
				"El acceso físico permanece cerrado para esta postura. "
				+ "Selecciona una postura o usa la ruta abierta."
			)
		)
		return false
	_pasaje_recorrido = true
	_completado = true
	_actualizar_interacciones()
	_mensaje(
		(
			"Fin del encuentro: has recorrido el %s con la postura %s."
			% [
				"Ala Oeste (Memoria)" if ruta == "OESTE" else "Ala Este (Registro)",
				_postura_elegida,
			]
		)
	)
	completado.emit()
	return true


func _abrir_puerta_oeste() -> void:
	if is_instance_valid(_puerta_oeste):
		_puerta_oeste.position.y = -6.0
	if is_instance_valid(_puerta_este):
		_puerta_este.position.y = 2.25


func _abrir_puerta_este() -> void:
	if is_instance_valid(_puerta_este):
		_puerta_este.position.y = -6.0
	if is_instance_valid(_puerta_oeste):
		_puerta_oeste.position.y = 2.25


func _montar_mundo() -> void:
	var mundo := WorldEnvironment.new()
	mundo.name = "AmbienteUmbral"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.06, 0.07, 0.09)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.6, 0.65, 0.75)
	entorno.ambient_light_energy = 0.6
	mundo.environment = entorno
	add_child(mundo)

	var luz := DirectionalLight3D.new()
	luz.name = "LuzSuperior"
	luz.rotation_degrees = Vector3(-60, -15, 0)
	luz.light_color = Color(0.7, 0.75, 0.85)
	luz.light_energy = 0.85
	luz.shadow_enabled = true
	add_child(luz)

	# Estructura principal
	_pieza("SueloCentral", Vector3(0, -0.45, 0), Vector3(18, 0.9, 22), COLOR_PIEDRA)
	_pieza("MuroNorte", Vector3(0, 2.7, -10.7), Vector3(18, 5.4, 0.9), COLOR_PIEDRA)
	_pieza("MuroSur", Vector3(0, 2.7, 10.7), Vector3(18, 5.4, 0.9), COLOR_PIEDRA)

	# Pasajes laterales
	_pieza("MuroOesteExterior", Vector3(-13.5, 2.7, -4.0), Vector3(0.9, 5.4, 14.0), COLOR_PIEDRA)
	_pieza("MuroEsteExterior", Vector3(13.5, 2.7, -4.0), Vector3(0.9, 5.4, 14.0), COLOR_PIEDRA)

	# Separadores y pilares
	_pieza("PilarOesteNorte", Vector3(-6.5, 2.7, -8.0), Vector3(1.2, 5.4, 1.2), COLOR_PIEDRA_CLARA)
	_pieza("PilarOesteSur", Vector3(-6.5, 2.7, 2.0), Vector3(1.2, 5.4, 1.2), COLOR_PIEDRA_CLARA)
	_pieza("PilarEsteNorte", Vector3(6.5, 2.7, -8.0), Vector3(1.2, 5.4, 1.2), COLOR_PIEDRA_CLARA)
	_pieza("PilarEsteSur", Vector3(6.5, 2.7, 2.0), Vector3(1.2, 5.4, 1.2), COLOR_PIEDRA_CLARA)

	# Barreras de paso (Puertas)
	_puerta_oeste = _pieza_retorno(
		"PuertaOeste", Vector3(-6.5, 2.25, -3.0), Vector3(0.8, 4.5, 4.0), COLOR_BRONCE
	)
	_puerta_este = _pieza_retorno(
		"PuertaEste", Vector3(6.5, 2.25, -3.0), Vector3(0.8, 4.5, 4.0), COLOR_BRONCE
	)

	# Altares y podio
	_pieza("PodioHeredera", Vector3(0, 0.5, -3.0), Vector3(2.5, 1.0, 2.5), COLOR_ORO)
	_pieza("AltarMemoria", Vector3(-3.5, 0.6, -1.0), Vector3(1.5, 1.2, 1.2), COLOR_MEMORIA)
	_pieza("AltarRegistro", Vector3(3.5, 0.6, -1.0), Vector3(1.5, 1.2, 1.2), COLOR_REGISTRO)

	var luz_heredera := OmniLight3D.new()
	luz_heredera.name = "LuzPodio"
	luz_heredera.position = Vector3(0, 3.5, -3.0)
	luz_heredera.light_color = COLOR_ORO
	luz_heredera.light_energy = 1.0
	luz_heredera.omni_range = 9.0
	add_child(luz_heredera)

	_rotulo("HEREDERA DEL UMBRAL", Vector3(0, 2.6, -3.0))
	_rotulo("MEMORIA COLECTIVA", Vector3(-3.5, 2.0, -1.0))
	_rotulo("REGISTRO INMUTABLE", Vector3(3.5, 2.0, -1.0))
	_rotulo("ALA OESTE", Vector3(-10.0, 2.5, -7.0))
	_rotulo("ALA ESTE", Vector3(10.0, 2.5, -7.0))


func _pieza(
	nombre: String, posicion: Vector3, tamano: Vector3, color: Color, colision := true
) -> void:
	var nodo := _pieza_retorno(nombre, posicion, tamano, color, colision)
	add_child(nodo)


func _pieza_retorno(
	nombre: String, posicion: Vector3, tamano: Vector3, color: Color, colision := true
) -> Node3D:
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
	return raiz


func _rotulo(texto: String, posicion: Vector3) -> void:
	var rotulo := Label3D.new()
	rotulo.name = texto.replace(" ", "_")
	rotulo.text = texto
	rotulo.position = posicion
	rotulo.pixel_size = 0.006
	rotulo.font_size = 32
	rotulo.modulate = COLOR_ORO
	add_child(rotulo)


func _montar_interactuables() -> void:
	_heredera = _objeto(
		"Heredera",
		Vector3(0, 1.3, -3.0),
		Vector3(2.0, 2.0, 2.0),
		Interactuable3D.Verbo.EXAMINAR,
		"Heredera del Umbral",
	)
	_heredera.activado.connect(
		func(_actor: Node):
			_mensaje(
				(
					"La Heredera custodia las tradiciones del reino: "
					+ "«Toda historia es proceso vivo o testimonio inalterable. "
					+ "Elige la postura que deba abrir paso»."
				)
			)
	)

	_stela_memoria = _objeto(
		"StelaMemoria",
		Vector3(-3.5, 1.3, -1.0),
		Vector3(1.6, 1.8, 1.4),
		Interactuable3D.Verbo.LEER,
		"estela de la Memoria Colectiva",
	)
	_stela_memoria.activado.connect(func(_actor: Node): elegir_postura("MEMORIA"))

	_stela_registro = _objeto(
		"StelaRegistro",
		Vector3(3.5, 1.3, -1.0),
		Vector3(1.6, 1.8, 1.4),
		Interactuable3D.Verbo.LEER,
		"estela del Registro Inmutable",
	)
	_stela_registro.activado.connect(func(_actor: Node): elegir_postura("REGISTRO"))

	_salida_oeste = _objeto(
		"SalidaOeste",
		Vector3(-10.0, 1.3, -7.0),
		Vector3(2.0, 2.2, 1.5),
		Interactuable3D.Verbo.USAR,
		"umbral de la Memoria (Ala Oeste)",
	)
	_salida_oeste.activado.connect(func(_actor: Node): solicitar_salida("OESTE"))

	_salida_este = _objeto(
		"SalidaEste",
		Vector3(10.0, 1.3, -7.0),
		Vector3(2.0, 2.2, 1.5),
		Interactuable3D.Verbo.USAR,
		"umbral del Registro (Ala Este)",
	)
	_salida_este.activado.connect(func(_actor: Node): solicitar_salida("ESTE"))

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
	if is_instance_valid(_salida_oeste):
		_salida_oeste.habilitado = (not _completado and _acceso_abierto == "OESTE")
	if is_instance_valid(_salida_este):
		_salida_este.habilitado = (not _completado and _acceso_abierto == "ESTE")


func _montar_hud() -> void:
	_hud = HUDLayer.new()
	var capa := _hud
	capa.name = "InterfazHeredera"
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
			"Umbral de la Heredera — Lee las dos estelas de autoría histórica. "
			+ "Elige Memoria Colectiva (Oeste) o Registro Inmutable (Este) para abrir su pasaje."
		)
	)


func _mensaje(contenido: String) -> void:
	if is_instance_valid(_texto):
		_texto.text = contenido
