## Galería de Identidades de Crónicas de las Siete Esferas (#2589).
## Escena 3D autónoma con tres espejos interactuables que proponen
## identidades incompatibles del Guardián Sin Nombre.
## No modifica ni persiste en SIGA, sueños o Expediente Legado.
class_name CronicasGaleriaIdentidades3D
extends Node3D

signal completado

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")
const COLOR_PIEDRA := Color(0.22, 0.24, 0.28)
const COLOR_PIEDRA_CLARA := Color(0.35, 0.36, 0.40)
const COLOR_ESPEJO_MARCO := Color(0.58, 0.48, 0.32)
const COLOR_ESPEJO_CRISTAL := Color(0.42, 0.55, 0.62)
const COLOR_INSCRIPCION := Color(0.85, 0.76, 0.52)

const ESPEJO_ESTIRPE := "estirpe"
const ESPEJO_USURPADOR := "usurpador"
const ESPEJO_SIMULACRO := "simulacro"

var _espejos_inspeccionados := {
	ESPEJO_ESTIRPE: false,
	ESPEJO_USURPADOR: false,
	ESPEJO_SIMULACRO: false,
}
var _hipotesis_elegida := ""
var _completado := false

var _caminante: CharacterBody3D
var _texto: Label
var _hud: HUDLayer
var _espejo_estirpe_node: Interactuable3D
var _espejo_usurpador_node: Interactuable3D
var _espejo_simulacro_node: Interactuable3D
var _umbral_node: Interactuable3D


func _ready() -> void:
	_montar_mundo()
	_montar_interactuables()
	_montar_hud()
	_caminante = ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	_caminante.name = "Caminante"
	_caminante.position = Vector3(0, 1.0, 7.5)
	add_child(_caminante)
	_caminante.call("conectar_hud", _hud)


## Estado puramente LOCAL de esta escena.
func estado_local() -> Dictionary:
	return {
		"espejos_inspeccionados": _espejos_inspeccionados.duplicate(),
		"inspeccionados_cnt": _conteo_inspeccionados(),
		"hipotesis_elegida": _hipotesis_elegida,
		"completado": _completado,
		"umbral_accesible": puede_salir(),
	}


func _conteo_inspeccionados() -> int:
	var total := 0
	for clave in _espejos_inspeccionados:
		if bool(_espejos_inspeccionados[clave]):
			total += 1
	return total


func inspeccionar_espejo(id_espejo: String) -> void:
	if _completado:
		return
	if not _espejos_inspeccionados.has(id_espejo):
		return

	_espejos_inspeccionados[id_espejo] = true
	_hipotesis_elegida = id_espejo
	_actualizar_interacciones()

	var total := _conteo_inspeccionados()
	var texto_reaccion := ""

	match id_espejo:
		ESPEJO_ESTIRPE:
			texto_reaccion = (
				"Espejo I — Muestra el blasón roto de la Casa de las Cenizas. "
				+ "Propone que el Guardián es el último heredero de sangre, "
				+ "obligado a olvidar su cuna para no sucumbir al juramento. "
				+ "Hipótesis asumida: Estirpe Caída."
			)
		ESPEJO_USURPADOR:
			texto_reaccion = (
				"Espejo II — Muestra un rostro cubierto por un velo de plomo. "
				+ "Propone que el Guardián arrebató la fortaleza durante el eclipse "
				+ "y reescribió los registros oficiales. "
				+ "Hipótesis asumida: Usurpador Velado."
			)
		ESPEJO_SIMULACRO:
			texto_reaccion = (
				"Espejo III — Muestra una silueta difusa que parpadea como luz tenue. "
				+ "Propone que el Guardián no existe en carne y hueso: "
				+ "es un simulacro tejido por la memoria del castillo. "
				+ "Hipótesis asumida: Simulacro Onírico."
			)

	if total >= 3:
		texto_reaccion += (
			" Has examinado las tres hipótesis incompatibles. "
			+ "El umbral de salida se abre: ninguna opción borra las otras versiones."
		)

	_mensaje(texto_reaccion)


func puede_salir() -> bool:
	return _conteo_inspeccionados() >= 3 and not _completado


func solicitar_salida() -> bool:
	if not puede_salir():
		_mensaje(
			(
				"El umbral permanece cerrado. Debes inspeccionar los tres espejos "
				+ "y contemplar sus hipótesis incompatibles antes de avanzar."
			)
		)
		return false
	_completado = true
	_actualizar_interacciones()
	_mensaje(
		(
			"Galería de Identidades atravesada. "
			+ "Llegas al umbral reconociendo la pluralidad del Guardián sin imponer un canon real único."
		)
	)
	completado.emit()
	return true


func _montar_mundo() -> void:
	var mundo := WorldEnvironment.new()
	mundo.name = "AmbienteGaleria"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.04, 0.05, 0.07)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.52, 0.58, 0.68)
	entorno.ambient_light_energy = 0.5
	mundo.environment = entorno
	add_child(mundo)

	var luz := DirectionalLight3D.new()
	luz.name = "LuzGaleria"
	luz.rotation_degrees = Vector3(-60, -15, 0)
	luz.light_color = Color(0.6, 0.7, 0.82)
	luz.light_energy = 0.75
	luz.shadow_enabled = true
	add_child(luz)

	_pieza("Suelo", Vector3(0, -0.45, 0), Vector3(18, 0.9, 20), COLOR_PIEDRA)
	_pieza("MuroIzquierdo", Vector3(-9.0, 2.7, 0), Vector3(0.9, 5.4, 20), COLOR_PIEDRA)
	_pieza("MuroDerecho", Vector3(9.0, 2.7, 0), Vector3(0.9, 5.4, 20), COLOR_PIEDRA)
	_pieza("MuroNorte", Vector3(0, 2.7, -10.0), Vector3(18, 5.4, 0.9), COLOR_PIEDRA)
	_pieza("MuroSur", Vector3(0, 2.7, 10.0), Vector3(18, 5.4, 0.9), COLOR_PIEDRA)

	# Columnas ornamentales
	for x in [-5.5, 5.5]:
		for z in [-6.0, 0.0, 5.0]:
			_pieza(
				"Pilar_%s_%s" % [str(x), str(z)],
				Vector3(x, 2.15, z),
				Vector3(1.0, 4.3, 1.0),
				COLOR_PIEDRA_CLARA,
			)

	# Marcos y cristal de los tres espejos
	# Espejo 1 (Oeste)
	_pieza("MarcoEstirpe", Vector3(-5.2, 1.8, -3.0), Vector3(0.3, 3.2, 2.0), COLOR_ESPEJO_MARCO)
	_pieza(
		"CristalEstirpe",
		Vector3(-5.0, 1.8, -3.0),
		Vector3(0.1, 2.8, 1.6),
		COLOR_ESPEJO_CRISTAL,
		false
	)
	_rotulo("I — ESTIRPE", Vector3(-5.0, 3.7, -3.0))

	# Espejo 2 (Norte / Centro)
	_pieza("MarcoUsurpador", Vector3(0.0, 1.8, -9.5), Vector3(2.0, 3.2, 0.3), COLOR_ESPEJO_MARCO)
	_pieza(
		"CristalUsurpador",
		Vector3(0.0, 1.8, -9.3),
		Vector3(1.6, 2.8, 0.1),
		COLOR_ESPEJO_CRISTAL,
		false
	)
	_rotulo("II — USURPADOR", Vector3(0.0, 3.7, -9.3))

	# Espejo 3 (Este)
	_pieza("MarcoSimulacro", Vector3(5.2, 1.8, -3.0), Vector3(0.3, 3.2, 2.0), COLOR_ESPEJO_MARCO)
	_pieza(
		"CristalSimulacro",
		Vector3(5.0, 1.8, -3.0),
		Vector3(0.1, 2.8, 1.6),
		COLOR_ESPEJO_CRISTAL,
		false
	)
	_rotulo("III — SIMULACRO", Vector3(5.0, 3.7, -3.0))

	# Umbral (Norte - Salida)
	_pieza("UmbralMarco", Vector3(0, 2.25, -9.8), Vector3(3.2, 4.5, 0.3), COLOR_ESPEJO_MARCO, false)
	_rotulo("UMBRAL", Vector3(0, 4.6, -9.5))


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
	rotulo.name = "Rotulo_" + texto.replace(" ", "_").replace("—", "_")
	rotulo.text = texto
	rotulo.position = posicion
	rotulo.pixel_size = 0.006
	rotulo.font_size = 32
	rotulo.modulate = COLOR_INSCRIPCION
	add_child(rotulo)


func _montar_interactuables() -> void:
	_espejo_estirpe_node = _objeto(
		"EspejoEstirpe",
		Vector3(-4.5, 1.5, -3.0),
		Vector3(1.8, 2.8, 2.2),
		Interactuable3D.Verbo.EXAMINAR,
		"espejo de la Estirpe Caída",
	)
	_espejo_estirpe_node.activado.connect(func(_actor: Node): inspeccionar_espejo(ESPEJO_ESTIRPE))

	_espejo_usurpador_node = _objeto(
		"EspejoUsurpador",
		Vector3(0.0, 1.5, -8.6),
		Vector3(2.2, 2.8, 1.8),
		Interactuable3D.Verbo.EXAMINAR,
		"espejo del Usurpador Velado",
	)
	_espejo_usurpador_node.activado.connect(
		func(_actor: Node): inspeccionar_espejo(ESPEJO_USURPADOR)
	)

	_espejo_simulacro_node = _objeto(
		"EspejoSimulacro",
		Vector3(4.5, 1.5, -3.0),
		Vector3(1.8, 2.8, 2.2),
		Interactuable3D.Verbo.EXAMINAR,
		"espejo del Simulacro Onírico",
	)
	_espejo_simulacro_node.activado.connect(
		func(_actor: Node): inspeccionar_espejo(ESPEJO_SIMULACRO)
	)

	_umbral_node = _objeto(
		"Umbral",
		Vector3(0.0, 1.5, -9.0),
		Vector3(3.0, 3.5, 1.5),
		Interactuable3D.Verbo.USAR,
		"umbral de las identidades",
	)
	_umbral_node.activado.connect(func(_actor: Node): solicitar_salida())

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
	if is_instance_valid(_espejo_estirpe_node):
		_espejo_estirpe_node.habilitado = not _completado
	if is_instance_valid(_espejo_usurpador_node):
		_espejo_usurpador_node.habilitado = not _completado
	if is_instance_valid(_espejo_simulacro_node):
		_espejo_simulacro_node.habilitado = not _completado
	if is_instance_valid(_umbral_node):
		_umbral_node.habilitado = puede_salir()


func _montar_hud() -> void:
	_hud = HUDLayer.new()
	var capa := _hud
	capa.name = "InterfazGaleria"
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
			"Galería de Identidades — Inspecciona los tres espejos que proponen identidades "
			+ "incompatibles del Guardián Sin Nombre. Usa «Interactuar» para examinar cada reflejo."
		)
	)


func _mensaje(contenido: String) -> void:
	if is_instance_valid(_texto):
		_texto.text = contenido
