## Vertical standalone del sueño de Simurgh (#658).
##
## La mecánica no escala físicamente al jugador: intercambia capas completas del
## mismo espacio. Las anclas conservan silueta, color y posición relativa para
## que una pluma pequeña pueda leerse como pasarela monumental sin HUD.
class_name SuenoSimurgh
extends Node3D

const ID_MITO := "simurgh"
const CLAVE_SEMILLA := "semilla_onirica_simurgh"
const FUENTE_VIGILIA := "lamina:simurgh_98"
const INSPECCIONES_MINIMAS := 2
const CAPAS := ["escritorio", "monumental"]
const ANCLA_PLUMA := "pluma_puente"
const ANCLA_ARCHIVOS := "archivos_montanas"
const ANCLA_LAMPARA := "lampara_nido"

const COLOR_PLUMA := Color(0.72, 0.46, 0.20)
const COLOR_ARCHIVO := Color(0.28, 0.31, 0.30)
const COLOR_LUZ := Color(0.84, 0.67, 0.34)
const COLOR_SUELO := Color(0.16, 0.17, 0.18)
const COLOR_RETORNO := Color(0.32, 0.52, 0.42)
const COLOR_SOMBRA := Color(0.05, 0.05, 0.06)

var reduccion_movimiento := false

var _capas: Array[Node3D] = []
var _capa_actual := 0


static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


## La lámina solo activa la familia después de varias inspecciones deliberadas
## y de girarla hasta reconocer la relación pluma/nido. Estar de fondo no basta.
static func registrar_semilla(
	estado: Dictionary,
	inspecciones: int,
	lamina_girada: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if inspecciones < INSPECCIONES_MINIMAS or not lamina_girada:
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


static func plan_transicion(reduccion: bool) -> Dictionary:
	return {
		"modo": "corte_fundido" if reduccion else "fundido_breve",
		"duracion": 0.0 if reduccion else 0.22,
		"zoom_camara": false,
		"mover_camara": false,
		"escalar_jugador": false,
	}


static func equivalencias() -> Dictionary:
	return {
		ANCLA_PLUMA: {"escritorio": "Pluma", "monumental": "PasarelaPluma"},
		ANCLA_ARCHIVOS: {"escritorio": "Archivadores", "monumental": "CordilleraArchivos"},
		ANCLA_LAMPARA: {"escritorio": "Lampara", "monumental": "NidoLuminaria"},
	}


func _ready() -> void:
	_montar_prototipo()


func preparar() -> void:
	_montar_prototipo()


func capa_actual() -> String:
	return String(CAPAS[_capa_actual])


func cambiar_capa(forzar_reduccion_movimiento: bool = false) -> Dictionary:
	_montar_prototipo()
	_capa_actual = (_capa_actual + 1) % CAPAS.size()
	_aplicar_capa_visible()
	var plan := plan_transicion(reduccion_movimiento or forzar_reduccion_movimiento)
	plan["capa"] = capa_actual()
	plan["retorno_disponible"] = ruta_retorno_disponible()
	return plan


func ruta_retorno_disponible() -> bool:
	if _capas.size() != CAPAS.size():
		return false
	for capa in _capas:
		if capa.get_node_or_null("Retorno") == null:
			return false
	return true


func _montar_prototipo() -> void:
	if not _capas.is_empty():
		return

	var escritorio := Node3D.new()
	escritorio.name = "CapaEscritorio"
	add_child(escritorio)
	_montar_escritorio(escritorio)
	_capas.append(escritorio)

	var monumental := Node3D.new()
	monumental.name = "CapaMonumental"
	add_child(monumental)
	_montar_monumental(monumental)
	_capas.append(monumental)

	_montar_luz_y_camara()
	_aplicar_capa_visible()


func _montar_escritorio(capa: Node3D) -> void:
	_crear_caja(capa, "Mesa", Vector3(12.0, 0.35, 8.0), Vector3(0.0, -0.20, 0.0), COLOR_SUELO)
	_crear_caja(capa, "Pluma", Vector3(3.8, 0.10, 0.36), Vector3(0.0, 0.18, 0.2), COLOR_PLUMA)
	_crear_punto_cambio(
		capa,
		"pluma",
		Vector3(0.0, 0.55, 0.2),
		Vector3(4.2, 1.0, 1.0),
	)
	var archivos := Node3D.new()
	archivos.name = "Archivadores"
	capa.add_child(archivos)
	for i in 4:
		_crear_caja(
			archivos,
			"Archivador%d" % (i + 1),
			Vector3(1.25, 1.4 + i * 0.12, 1.0),
			Vector3(-3.2 + i * 2.1, 0.70, -2.0),
			COLOR_ARCHIVO,
		)
	_crear_caja(capa, "Lampara", Vector3(2.4, 0.22, 2.4), Vector3(3.7, 3.2, -1.8), COLOR_LUZ)
	_crear_caja(capa, "Retorno", Vector3(1.4, 0.12, 1.4), Vector3(-4.7, 0.10, 2.8), COLOR_RETORNO)


func _montar_monumental(capa: Node3D) -> void:
	_crear_caja(capa, "Suelo", Vector3(24.0, 0.35, 18.0), Vector3(0.0, -0.20, 0.0), COLOR_SUELO)
	_crear_caja(
		capa,
		"PasarelaPluma",
		Vector3(11.0, 0.28, 1.15),
		Vector3(0.0, 1.1, 0.2),
		COLOR_PLUMA,
	)
	_crear_punto_cambio(
		capa,
		"pasarela de pluma",
		Vector3(0.0, 1.65, 0.2),
		Vector3(4.0, 1.2, 1.7),
	)
	var cordillera := Node3D.new()
	cordillera.name = "CordilleraArchivos"
	capa.add_child(cordillera)
	for i in 6:
		_crear_caja(
			cordillera,
			"Macizo%d" % (i + 1),
			Vector3(2.4, 3.0 + (i % 3) * 1.2, 2.2),
			Vector3(-7.0 + i * 2.8, 1.5, -5.0),
			COLOR_ARCHIVO,
		)
	var nido := Node3D.new()
	nido.name = "NidoLuminaria"
	nido.position = Vector3(3.7, 6.2, -1.8)
	capa.add_child(nido)
	for i in 7:
		var angulo := TAU * float(i) / 7.0
		_crear_caja(
			nido,
			"Segmento%d" % (i + 1),
			Vector3(2.8, 0.28, 0.55),
			Vector3(cos(angulo) * 1.4, 0.0, sin(angulo) * 1.4),
			COLOR_LUZ,
		)
	_crear_caja(
		capa, "SombraSimurgh", Vector3(8.0, 0.08, 2.0), Vector3(-1.2, 7.8, -5.5), COLOR_SOMBRA
	)
	_crear_caja(capa, "Retorno", Vector3(2.2, 0.18, 2.2), Vector3(-8.0, 0.12, 6.0), COLOR_RETORNO)


func _crear_punto_cambio(
	padre: Node3D,
	nombre_objeto: String,
	posicion: Vector3,
	tam: Vector3,
) -> void:
	var hotspot := Interactuable3D.new()
	hotspot.name = "PuntoCambio"
	hotspot.position = posicion
	hotspot.verbo = Interactuable3D.Verbo.EXAMINAR
	hotspot.nombre_objeto = nombre_objeto
	hotspot.sonido = Interactuable3D.SIN_SONIDO
	hotspot.collision_mask = 0
	hotspot.activado.connect(_al_cambiar_capa)
	padre.add_child(hotspot)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	hotspot.add_child(colision)


func _al_cambiar_capa(_actor: Node) -> void:
	cambiar_capa(reduccion_movimiento)


func _aplicar_capa_visible() -> void:
	for i in _capas.size():
		var activa := i == _capa_actual
		_capas[i].visible = activa
		var punto := _capas[i].get_node_or_null("PuntoCambio") as Area3D
		if punto != null:
			# Un Area3D oculto sigue pudiendo entrar en consultas físicas. Quitar su
			# layer evita interactuar con la capa que no está materializada.
			punto.collision_layer = 1 if activa else 0


func _montar_luz_y_camara() -> void:
	var luz := DirectionalLight3D.new()
	luz.name = "LuzGeneral"
	luz.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	luz.light_energy = 1.05
	add_child(luz)

	var camara := Camera3D.new()
	camara.name = "CamaraStandalone"
	camara.position = Vector3(0.0, 7.2, 13.5)
	camara.rotation_degrees = Vector3(-22.0, 0.0, 0.0)
	camara.current = true
	add_child(camara)


func _crear_caja(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = _material(color)
	padre.add_child(nodo)
	return nodo


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material
