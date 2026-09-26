## Vertical standalone del sueño de Yggdrasil y las Nornas (#653).
##
## La escena se lee como un grafo físico: tres nodos separados están unidos por
## raíces/cables visibles y cada intervención altera SIEMPRE otro nodo. La
## solución no depende de conocer mitología nórdica; basta seguir conexiones.
class_name SuenoYggdrasil
extends Node3D

const ID_MITO := "yggdrasil"
const CLAVE_SEMILLA := "semilla_onirica_yggdrasil"
const FUENTE_VIGILIA := "poster:yggdrasil_98"

const NODO_RAIZ := "raiz_archivo"
const NODO_TRONCO := "tronco_terminal"
const NODO_RAMA := "rama_pasarela"
const NODOS := [NODO_RAIZ, NODO_TRONCO, NODO_RAMA]

## Cada origen afecta a un destino distinto y físicamente separado.
const CONEXIONES := {
	NODO_RAIZ: NODO_RAMA,
	NODO_RAMA: NODO_TRONCO,
	NODO_TRONCO: NODO_RAIZ,
}

## Acciones explícitas: el efecto remoto es estable y puede anticiparse leyendo
## la raíz/cable que une origen y destino.
const ACCIONES := {
	NODO_RAIZ: {"accion": "alimentar", "efecto": "luz", "delta": 1},
	NODO_RAMA: {"accion": "tensar", "efecto": "altura", "delta": 1},
	NODO_TRONCO: {"accion": "bloquear", "efecto": "acceso", "delta": 1},
}

const POSICIONES := {
	NODO_RAIZ: Vector3(-5.0, 0.0, 2.5),
	NODO_TRONCO: Vector3(0.0, 0.0, -3.0),
	NODO_RAMA: Vector3(5.0, 0.0, 2.5),
}

const COLOR_RAIZ := Color(0.24, 0.16, 0.10)
const COLOR_TRONCO := Color(0.30, 0.20, 0.12)
const COLOR_RAMA := Color(0.33, 0.27, 0.14)
const COLOR_CONEXION := Color(0.46, 0.36, 0.18)
const COLOR_ACTIVO := Color(0.74, 0.62, 0.30)
const COLOR_BLOQUEO := Color(0.48, 0.16, 0.12)
const COLOR_RETORNO := Color(0.26, 0.48, 0.38)

var reduccion_movimiento := false

var _estado := {
	NODO_RAIZ: 0,
	NODO_TRONCO: 0,
	NODO_RAMA: 0,
}
var _montado := false


static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


static func registrar_semilla(
	estado: Dictionary,
	inspecciones: int,
	conexion_reconocida: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if inspecciones < 2 or not conexion_reconocida:
		return false
	if estado.has("dia"):
		return SemillasOniricas.activar_semilla_onirica(estado, ID_MITO, fuente, intensidad)
	estado[CLAVE_SEMILLA] = true
	return true


static func plan_presentacion(reduccion_movimiento: bool) -> Dictionary:
	return {
		"modo": "corte_fundido" if reduccion_movimiento else "transicion_breve",
		"duracion": 0.0 if reduccion_movimiento else 0.20,
		"desplazar_sala": not reduccion_movimiento,
		"feedback_causal": true,
	}


func _ready() -> void:
	preparar()


func preparar() -> void:
	if _montado:
		return
	_montado = true
	_montar_nodos()
	_montar_conexiones()
	_montar_retorno()
	_montar_luz_y_camara()
	_aplicar_estado_visual()


func estado_reproducible() -> Dictionary:
	return _estado.duplicate(true)


func conexiones_visibles() -> Dictionary:
	return CONEXIONES.duplicate(true)


func ruta_retorno_disponible() -> bool:
	return get_node_or_null("Retorno") != null


## Ejecuta la acción propia de un nodo y modifica el nodo remoto conectado.
## Repetir acciones satura en 2: no hay combinaciones exhaustivas ni estados
## irreversibles; el retorno existe en todos los estados.
func intervenir(origen: String, forzar_reduccion_movimiento: bool = false) -> Dictionary:
	preparar()
	if not CONEXIONES.has(origen) or not ACCIONES.has(origen):
		return {"ok": false, "origen": origen, "retorno_disponible": ruta_retorno_disponible()}

	var destino := String(CONEXIONES[origen])
	var regla: Dictionary = ACCIONES[origen]
	_estado[destino] = clampi(int(_estado.get(destino, 0)) + int(regla["delta"]), 0, 2)
	_aplicar_estado_visual()

	var salida := plan_presentacion(reduccion_movimiento or forzar_reduccion_movimiento)
	(
		salida
		. merge(
			{
				"ok": true,
				"origen": origen,
				"destino": destino,
				"accion": String(regla["accion"]),
				"efecto": String(regla["efecto"]),
				"nivel_destino": int(_estado[destino]),
				"retorno_disponible": ruta_retorno_disponible(),
			},
			true
		)
	)
	return salida


## Permite a pruebas/save restaurar un estado exacto sin depender del orden de
## animaciones. Los niveles se acotan para impedir estados imposibles.
func restaurar_estado(estado: Dictionary) -> void:
	for nodo in NODOS:
		_estado[nodo] = clampi(int(estado.get(nodo, 0)), 0, 2)
	if _montado:
		_aplicar_estado_visual()


func _montar_nodos() -> void:
	_crear_nodo(NODO_RAIZ, POSICIONES[NODO_RAIZ], COLOR_RAIZ, "ArchivadoresRaiz")
	_crear_nodo(NODO_TRONCO, POSICIONES[NODO_TRONCO], COLOR_TRONCO, "TerminalTronco")
	_crear_nodo(NODO_RAMA, POSICIONES[NODO_RAMA], COLOR_RAMA, "PasarelaRama")


func _crear_nodo(id: String, posicion: Vector3, color: Color, detalle: String) -> void:
	var contenedor := Node3D.new()
	contenedor.name = id
	contenedor.position = posicion
	add_child(contenedor)
	_crear_caja(contenedor, "Nucleo", Vector3(2.2, 2.2, 2.2), Vector3(0.0, 1.1, 0.0), color)
	_crear_caja(
		contenedor, detalle, Vector3(1.3, 0.35, 1.3), Vector3(0.0, 2.45, 0.0), color.lightened(0.15)
	)
	_crear_caja(
		contenedor, "Indicador", Vector3(0.65, 0.18, 0.65), Vector3(0.0, 2.95, 0.0), COLOR_ACTIVO
	)
	_crear_efecto_visual(contenedor, id)
	_crear_hotspot_nodo(contenedor, id)


## Cada destino expone un cambio distinto: brillo, altura o barrera visual.
## La barrera no tiene colisión; comunica "acceso" sin poder crear un softlock.
func _crear_efecto_visual(padre: Node3D, id: String) -> void:
	if id == NODO_RAMA:
		var luz := OmniLight3D.new()
		luz.name = "LuzRemota"
		luz.position = Vector3(0.0, 3.0, 0.0)
		luz.light_color = COLOR_ACTIVO
		luz.light_energy = 0.15
		luz.omni_range = 4.5
		padre.add_child(luz)
	elif id == NODO_RAIZ:
		_crear_caja(
			padre,
			"BarreraAcceso",
			Vector3(2.8, 0.20, 0.35),
			Vector3(0.0, -0.25, -1.45),
			COLOR_BLOQUEO,
		)


func _crear_hotspot_nodo(padre: Node3D, id: String) -> void:
	var hotspot := Interactuable3D.new()
	hotspot.name = "Interactuar_%s" % id
	hotspot.position = Vector3(0.0, 1.2, 0.0)
	hotspot.verbo = Interactuable3D.Verbo.USAR
	hotspot.nombre_objeto = _nombre_nodo(id)
	hotspot.sonido = Interactuable3D.SIN_SONIDO
	hotspot.collision_mask = 0
	hotspot.activado.connect(_al_intervenir.bind(id))
	padre.add_child(hotspot)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.35, 2.55, 2.35)
	colision.shape = forma
	hotspot.add_child(colision)


func _nombre_nodo(id: String) -> String:
	if id == NODO_RAIZ:
		return "raíz de archivadores"
	if id == NODO_RAMA:
		return "rama pasarela"
	return "tronco terminal"


func _al_intervenir(_actor: Node, origen: String) -> void:
	intervenir(origen, reduccion_movimiento)


func _montar_conexiones() -> void:
	var conexiones := Node3D.new()
	conexiones.name = "Conexiones"
	add_child(conexiones)
	for origen in NODOS:
		var destino := String(CONEXIONES[origen])
		var a: Vector3 = POSICIONES[origen] + Vector3(0.0, 0.35, 0.0)
		var b: Vector3 = POSICIONES[destino] + Vector3(0.0, 0.35, 0.0)
		_crear_tramo(conexiones, "%s__%s" % [origen, destino], a, b)


func _crear_tramo(padre: Node3D, nombre: String, a: Vector3, b: Vector3) -> void:
	var centro := (a + b) * 0.5
	var longitud := a.distance_to(b)
	var tramo := _crear_caja(padre, nombre, Vector3(0.24, 0.18, longitud), centro, COLOR_CONEXION)
	tramo.look_at(b, Vector3.UP)


func _montar_retorno() -> void:
	_crear_caja(self, "Retorno", Vector3(2.0, 0.20, 2.0), Vector3(0.0, 0.12, 5.4), COLOR_RETORNO)


func _montar_luz_y_camara() -> void:
	var luz := DirectionalLight3D.new()
	luz.name = "LuzGeneral"
	luz.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	luz.light_energy = 1.0
	add_child(luz)

	var camara := Camera3D.new()
	camara.name = "CamaraStandalone"
	camara.position = Vector3(0.0, 10.5, 15.5)
	camara.rotation_degrees = Vector3(-31.0, 0.0, 0.0)
	camara.current = true
	add_child(camara)


func _aplicar_estado_visual() -> void:
	for nodo in NODOS:
		var contenedor := get_node_or_null(nodo)
		if contenedor == null:
			continue
		var nivel := int(_estado[nodo])
		var indicador := contenedor.get_node_or_null("Indicador") as MeshInstance3D
		if indicador != null:
			indicador.scale = Vector3.ONE
		var nucleo := contenedor.get_node_or_null("Nucleo") as MeshInstance3D
		if nucleo != null:
			nucleo.position.y = 1.1

		# El cambio sigue siendo discreto y reproducible, pero ahora la semántica
		# declarada por ACCIONES se reconoce también en la geometría/iluminación.
		if nodo == NODO_RAMA:
			if indicador != null:
				indicador.scale = Vector3.ONE * (1.0 + 0.22 * nivel)
			var luz := contenedor.get_node_or_null("LuzRemota") as OmniLight3D
			if luz != null:
				luz.light_energy = 0.15 + 0.55 * nivel
		elif nodo == NODO_TRONCO:
			if nucleo != null:
				nucleo.position.y = 1.1 + 0.35 * nivel
		elif nodo == NODO_RAIZ:
			var barrera := contenedor.get_node_or_null("BarreraAcceso") as MeshInstance3D
			if barrera != null:
				barrera.position.y = -0.25 + 0.85 * nivel


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
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.84
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo
