## Primer vertical standalone del sueño de Gilgamesh (#436).
##
## No entra en la pool nocturna por existir: una Jornada real debe contener la
## semilla común `semilla_onirica_gilgamesh`. El puzzle usa cuatro fragmentos
## con parejas visuales declaradas; un error revierte sin consumir progreso.
class_name SuenoGilgamesh
extends Node3D

const ID_MITO := "gilgamesh"
const CLAVE_SEMILLA := "semilla_onirica_gilgamesh"
const FUENTE_VIGILIA := "libro:arqueologia_uruk_98"
const PAGINAS_MINIMAS := 3
const FRAGMENTOS_NECESARIOS := 4
const TRANSFORMACION_FINAL := "muralla_archivo_continua_por_techo"
const TEXTURAS_FRAGMENTOS := {
	"fragmento_puerta": preload("res://arte/gilgamesh/fragmento_puerta.svg"),
	"fragmento_sello": preload("res://arte/gilgamesh/fragmento_sello.svg"),
	"fragmento_ola": preload("res://arte/gilgamesh/fragmento_ola.svg"),
	"fragmento_archivo": preload("res://arte/gilgamesh/fragmento_archivo.svg"),
}

## Las parejas son explícitas para que el puzzle no dependa de ensayo ciego.
## En la escena cada fragmento y su ancla comparten silueta/proporción y color.
const ENCAJES := {
	"fragmento_puerta": "ancla_puerta",
	"fragmento_sello": "ancla_sello",
	"fragmento_ola": "ancla_ola",
	"fragmento_archivo": "ancla_archivo",
}

const COLORES := {
	"fragmento_puerta": Color(0.74, 0.42, 0.20),
	"fragmento_sello": Color(0.58, 0.22, 0.18),
	"fragmento_ola": Color(0.18, 0.42, 0.55),
	"fragmento_archivo": Color(0.54, 0.49, 0.34),
}

const TAMANOS := {
	"fragmento_puerta": Vector3(0.72, 1.36, 0.24),
	"fragmento_sello": Vector3(1.12, 0.28, 0.82),
	"fragmento_ola": Vector3(1.28, 0.40, 0.24),
	"fragmento_archivo": Vector3(0.58, 0.92, 0.58),
}

const COLOR_LADRILLO := Color(0.42, 0.23, 0.16)
const COLOR_ARCHIVO := Color(0.30, 0.34, 0.31)
const COLOR_PAPEL := Color(0.67, 0.61, 0.46)
const COLOR_RUTA := Color(0.78, 0.68, 0.42)
const COLOR_AGUA_VERTICAL := Color(0.12, 0.32, 0.46)
const COLOR_SELLO_CELESTE := Color(0.62, 0.19, 0.16)

var _estado_puzzle: Dictionary = {}
var _fragmentos: Dictionary = {}
var _anclas: Dictionary = {}
var _barrios: Dictionary = {}
var _muralla_techo: Node3D
var _puerta_bloqueada: MeshInstance3D
var _ruta_final: MeshInstance3D


## Una Jornada real siempre consulta el catálogo común. El fallback plano solo
## conserva compatibilidad con prototipos aislados del vertical.
static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


## La contraparte de vigilia exige varias acciones deliberadas y llegar a la
## reproducción de la tablilla; ver el libro de fondo no basta.
static func registrar_semilla(
	estado: Dictionary,
	paginas_examinadas: int,
	tablilla_observada: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if paginas_examinadas < PAGINAS_MINIMAS or not tablilla_observada:
		return false
	if estado.has("dia"):
		return (
			SemillasOniricas
			. activar_semilla_onirica(
				estado,
				ID_MITO,
				fuente,
				intensidad,
			)
		)
	estado[CLAVE_SEMILLA] = true
	return true


## Contrato lógico del puzzle. Devuelve un estado nuevo y nunca destruye el
## anterior: una pareja incorrecta pide reversión y deja el progreso intacto.
static func evaluar_colocacion(estado: Dictionary, fragmento: String, ancla: String) -> Dictionary:
	var siguiente := estado.duplicate(true)
	if not ENCAJES.has(fragmento) or String(ENCAJES[fragmento]) != ancla:
		return {
			"aceptada": false,
			"revertir": true,
			"estado": siguiente,
			"total": siguiente.size(),
			"completa": siguiente.size() == FRAGMENTOS_NECESARIOS,
		}

	siguiente[fragmento] = true
	return {
		"aceptada": true,
		"revertir": false,
		"estado": siguiente,
		"total": siguiente.size(),
		"completa": siguiente.size() == FRAGMENTOS_NECESARIOS,
	}


## La preferencia de movimiento solo cambia la presentación. Nunca modifica
## encajes, progreso, gating o resultado final.
static func plan_transformacion(reduccion_movimiento: bool, aciertos: int) -> Dictionary:
	return {
		"modo": "corte_fundido" if reduccion_movimiento else "interpolacion_arquitectura",
		"duracion": 0.0 if reduccion_movimiento else 0.65,
		"sacudida_camara": false,
		"desplazar_camara": false,
		"transformacion_final": TRANSFORMACION_FINAL if aciertos >= FRAGMENTOS_NECESARIOS else "",
	}


func _ready() -> void:
	_montar_prototipo()


## Permite preparar el vertical fuera del árbol antes de insertarlo en una
## noche real. `_montar_prototipo` es idempotente, así que la llamada posterior
## de `_ready` no duplica geometría ni interacción.
func preparar() -> void:
	_montar_prototipo()


func progreso() -> int:
	return _estado_puzzle.size()


func resuelto() -> bool:
	return progreso() == FRAGMENTOS_NECESARIOS


## Punto de entrada para una interacción 3D posterior: la lógica ya es jugable
## sin acoplarla a HUD, drag-and-drop 2D ni un controlador nocturno paralelo.
func colocar_fragmento(
	fragmento: String, ancla: String, reduccion_movimiento: bool = false
) -> Dictionary:
	var ya_colocado := _estado_puzzle.has(fragmento)
	var resultado := evaluar_colocacion(_estado_puzzle, fragmento, ancla)
	if not bool(resultado["aceptada"]):
		return resultado

	_estado_puzzle = resultado["estado"]
	if not ya_colocado:
		_aplicar_acierto(fragmento, reduccion_movimiento)
	if bool(resultado["completa"]):
		_abrir_ruta(reduccion_movimiento)
	return resultado


func _montar_prototipo() -> void:
	if get_node_or_null("CiudadImposible") != null:
		return

	var ciudad := Node3D.new()
	ciudad.name = "CiudadImposible"
	add_child(ciudad)

	_crear_caja(
		ciudad,
		"SueloLadrillo",
		Vector3(22.0, 0.35, 18.0),
		Vector3(0.0, -0.18, 0.0),
		COLOR_LADRILLO,
	)
	_crear_caja(
		ciudad,
		"MurallaOeste",
		Vector3(0.7, 5.5, 18.0),
		Vector3(-10.6, 2.75, 0.0),
		COLOR_LADRILLO,
	)
	_crear_caja(
		ciudad,
		"MurallaEste",
		Vector3(0.7, 5.5, 18.0),
		Vector3(10.6, 2.75, 0.0),
		COLOR_LADRILLO,
	)
	_montar_muralla_archivo(ciudad)
	_montar_identidad_uruk(ciudad)
	_montar_barrios(ciudad)
	_montar_puzzle(ciudad)
	_montar_salida(ciudad)
	_montar_iluminacion()
	_montar_camara()


func _montar_muralla_archivo(ciudad: Node3D) -> void:
	var vertical := Node3D.new()
	vertical.name = "MurallaVertical"
	ciudad.add_child(vertical)
	for i in 6:
		_crear_caja(
			vertical,
			"ModuloArchivo%d" % (i + 1),
			Vector3(3.2, 1.05, 0.85),
			Vector3(-7.8 + i * 3.15, 4.9 + (i % 2) * 0.52, -7.1),
			COLOR_ARCHIVO if i % 2 == 0 else COLOR_LADRILLO,
		)

	_muralla_techo = Node3D.new()
	_muralla_techo.name = "MurallaArchivoTecho"
	_muralla_techo.visible = false
	ciudad.add_child(_muralla_techo)
	for i in 7:
		_crear_caja(
			_muralla_techo,
			"ArchivoCenital%d" % (i + 1),
			Vector3(2.4, 0.72, 2.15),
			Vector3(0.0, 8.0, -6.2 + i * 2.05),
			COLOR_ARCHIVO if i % 2 == 0 else COLOR_LADRILLO,
		)


## Hitos de puesta en escena para que el sueño se lea como Gilgamesh/SIGA desde
## cámara jugable y no como otro castillo genérico. Son formas simbólicas sin
## texto factual: terraza escalonada, puerta monumental, agua imposible y sellos.
func _montar_identidad_uruk(ciudad: Node3D) -> void:
	var hitos := Node3D.new()
	hitos.name = "HitosUruk"
	ciudad.add_child(hitos)

	var zigurat := Node3D.new()
	zigurat.name = "ZiguratArchivo"
	hitos.add_child(zigurat)
	for nivel in 4:
		var escala := 1.0 - float(nivel) * 0.17
		_crear_caja(
			zigurat,
			"Terraza%d" % (nivel + 1),
			Vector3(7.2 * escala, 0.72, 4.8 * escala),
			Vector3(-6.1, 0.55 + nivel * 0.72, -5.0),
			COLOR_LADRILLO if nivel % 2 == 0 else COLOR_ARCHIVO,
		)

	var puerta := Node3D.new()
	puerta.name = "PuertaMonumentalArchivo"
	hitos.add_child(puerta)
	_crear_caja(puerta, "TorreIzquierda", Vector3(2.15, 6.2, 1.6), Vector3(-2.9, 3.1, -6.7), COLOR_LADRILLO)
	_crear_caja(puerta, "TorreDerecha", Vector3(2.15, 6.2, 1.6), Vector3(2.9, 3.1, -6.7), COLOR_LADRILLO)
	_crear_caja(puerta, "DintelArchivo", Vector3(4.1, 1.1, 1.45), Vector3(0.0, 5.25, -6.7), COLOR_ARCHIVO)

	var inundacion := Node3D.new()
	inundacion.name = "InundacionVertical"
	hitos.add_child(inundacion)
	for tramo in 5:
		_crear_caja(
			inundacion,
			"CanalPared%d" % (tramo + 1),
			Vector3(0.12, 1.0, 2.5),
			Vector3(10.18, 0.8 + tramo * 1.0, -4.8 + tramo * 1.6),
			COLOR_AGUA_VERTICAL,
			true,
		)

	var sellos := Node3D.new()
	sellos.name = "SellosCelestes"
	hitos.add_child(sellos)
	for i in 3:
		var sello := _crear_caja(
			sellos,
			"Sello%d" % (i + 1),
			Vector3(1.0 + i * 0.18, 0.28, 1.0 + i * 0.18),
			Vector3(-3.4 + i * 3.4, 6.4 + i * 0.55, -1.6 - i * 0.8),
			COLOR_SELLO_CELESTE,
			true,
		)
		sello.rotation_degrees = Vector3(18.0 + i * 9.0, 22.0 - i * 15.0, 12.0 + i * 17.0)


func _montar_barrios(ciudad: Node3D) -> void:
	var posiciones := {
		"fragmento_puerta": Vector3(-6.6, 2.1, -2.0),
		"fragmento_sello": Vector3(-2.2, 2.8, -3.3),
		"fragmento_ola": Vector3(2.6, 2.4, -2.6),
		"fragmento_archivo": Vector3(6.7, 3.3, -3.5),
	}
	for fragmento in ENCAJES.keys():
		var barrio := Node3D.new()
		barrio.name = "Barrio_%s" % fragmento.trim_prefix("fragmento_")
		barrio.position = posiciones[fragmento]
		barrio.visible = false
		ciudad.add_child(barrio)
		_crear_caja(
			barrio,
			"Torre",
			Vector3(2.2, 4.2, 2.2),
			Vector3.ZERO,
			COLORES[fragmento],
		)
		_crear_caja(
			barrio,
			"ArchivoSuperior",
			Vector3(2.9, 0.7, 2.9),
			Vector3(0.0, 2.4, 0.0),
			COLOR_ARCHIVO,
		)
		_barrios[fragmento] = barrio


func _montar_puzzle(ciudad: Node3D) -> void:
	var puzzle := Node3D.new()
	puzzle.name = "PuzzleTablilla"
	ciudad.add_child(puzzle)
	var ids: Array = ENCAJES.keys()
	ids.sort()
	for i in ids.size():
		var fragmento: String = ids[i]
		var color: Color = COLORES[fragmento]
		var tam: Vector3 = TAMANOS[fragmento]
		var pieza := _crear_caja(
			puzzle,
			fragmento,
			tam,
			Vector3(-5.4 + i * 3.6, 1.15, 4.9),
			color,
			true,
		)
		_montar_motivo_visual(pieza, fragmento, tam)
		_fragmentos[fragmento] = pieza

		var ancla_id: String = ENCAJES[fragmento]
		var tam_ancla := tam + Vector3(0.16, 0.10, 0.16)
		var ancla := _crear_caja(
			puzzle,
			ancla_id,
			tam_ancla,
			Vector3(-5.4 + i * 3.6, 0.48, 1.8),
			color.darkened(0.42),
		)
		_montar_motivo_visual(ancla, fragmento, tam_ancla, true)
		_anclas[fragmento] = ancla


## Las piezas y sus anclas comparten el mismo motivo propio. La lámina cuelga
## del MeshInstance3D dinámico: al ocultarse una pieza resuelta desaparece con
## ella y no puede quedar desincronizada del estado lógico del puzzle.
func _montar_motivo_visual(
	soporte: MeshInstance3D,
	fragmento: String,
	tam: Vector3,
	ancla: bool = false,
) -> void:
	if not TEXTURAS_FRAGMENTOS.has(fragmento):
		return
	var lamina := MeshInstance3D.new()
	lamina.name = "MotivoVisual"
	var malla := QuadMesh.new()
	malla.size = Vector2(max(0.26, tam.x * 0.78), max(0.26, tam.y * 0.78))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = TEXTURAS_FRAGMENTOS[fragmento]
	material.albedo_color = Color(1.0, 1.0, 1.0, 0.38 if ancla else 1.0)
	malla.material = material
	lamina.mesh = malla
	lamina.position = Vector3(0.0, 0.0, tam.z * 0.5 + 0.012)
	soporte.add_child(lamina)


func _montar_salida(ciudad: Node3D) -> void:
	_puerta_bloqueada = _crear_caja(
		ciudad,
		"PuertaBloqueada",
		Vector3(3.2, 5.2, 0.7),
		Vector3(0.0, 2.6, -7.35),
		COLOR_ARCHIVO,
	)
	_ruta_final = _crear_caja(
		ciudad,
		"RutaFinal",
		Vector3(3.0, 0.18, 7.0),
		Vector3(0.0, 0.12, -10.4),
		COLOR_RUTA,
		true,
	)
	_ruta_final.visible = false


func _aplicar_acierto(fragmento: String, reduccion_movimiento: bool) -> void:
	if _fragmentos.has(fragmento):
		(_fragmentos[fragmento] as MeshInstance3D).visible = false
	if _anclas.has(fragmento):
		var ancla := _anclas[fragmento] as MeshInstance3D
		ancla.material_override = _material(COLORES[fragmento], true)
	if not _barrios.has(fragmento):
		return
	var barrio := _barrios[fragmento] as Node3D
	barrio.visible = true
	if reduccion_movimiento:
		barrio.scale = Vector3.ONE
		return
	barrio.scale = Vector3(1.0, 0.06, 1.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(barrio, "scale", Vector3.ONE, 0.45)


func _abrir_ruta(reduccion_movimiento: bool) -> void:
	if _puerta_bloqueada != null:
		_puerta_bloqueada.visible = false
	if _ruta_final != null:
		_ruta_final.visible = true
	if _muralla_techo == null or _muralla_techo.visible:
		return

	_muralla_techo.visible = true
	var plan := plan_transformacion(reduccion_movimiento, progreso())
	if String(plan["modo"]) == "corte_fundido":
		_muralla_techo.scale = Vector3.ONE
		return
	_muralla_techo.scale = Vector3(1.0, 0.04, 1.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	(
		tween
		. tween_property(
			_muralla_techo,
			"scale",
			Vector3.ONE,
			float(plan["duracion"]),
		)
	)


func _montar_iluminacion() -> void:
	var general := DirectionalLight3D.new()
	general.name = "LuzGeneral"
	general.rotation_degrees = Vector3(-52.0, -26.0, 0.0)
	general.light_color = Color(0.78, 0.63, 0.46)
	general.light_energy = 1.25
	add_child(general)

	var lectura := OmniLight3D.new()
	lectura.name = "LuzTablilla"
	lectura.position = Vector3(0.0, 3.8, 4.0)
	lectura.light_color = Color(0.72, 0.48, 0.28)
	lectura.light_energy = 4.2
	lectura.omni_range = 12.0
	add_child(lectura)


func _montar_camara() -> void:
	var camara := Camera3D.new()
	camara.name = "CamaraStandalone"
	camara.position = Vector3(0.0, 6.2, 17.5)
	camara.current = true
	add_child(camara)
	camara.look_at(Vector3(0.0, 2.5, -1.8), Vector3.UP)


func _crear_caja(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
	emision: bool = false,
) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = _material(color, emision)
	padre.add_child(nodo)
	return nodo


func _material(color: Color, emision: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if emision:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.35
	return material
