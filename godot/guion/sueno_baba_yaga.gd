## Vertical standalone del sueño de Baba Yaga (#652).
##
## No representa a Baba Yaga como boss. La mecánica está en el bosque y la
## cabaña: elementos cotidianos cambian de posición solo al cruzar un umbral o
## cuando quedan fuera de campo. Las marcas del jugador permanecen en el mundo
## y permiten deducir qué se movió sin ensayo exhaustivo ni azar.
class_name SuenoBabaYaga
extends Node3D

const ID_MITO := "baba_yaga"
const CLAVE_SEMILLA := "semilla_onirica_baba_yaga"
const FUENTE_VIGILIA := "libro:cuentos_eslavos_98"
const LECTURAS_MINIMAS := 2

const OBJETO_ARBOL := "arbol_tabique"
const OBJETO_VALLA := "valla_archivo"
const OBJETO_ARCHIVADOR := "archivador_hito"
const OBJETO_CABANA := "cabana_ancla"
const OBJETOS_MARCA := [OBJETO_ARBOL, OBJETO_VALLA, OBJETO_ARCHIVADOR, OBJETO_CABANA]

const EVENTO_UMBRAL := "cruzar_umbral"
const EVENTO_FUERA_CAMPO := "perder_de_vista"

const POSICIONES_ARBOL := [
	Vector3(-4.8, 0.0, -2.8),
	Vector3(-2.8, 0.0, -4.2),
	Vector3(-5.2, 0.0, 0.8),
	Vector3(-3.4, 0.0, 3.0),
]
const POSICIONES_VALLA := [
	Vector3(2.8, 0.0, -2.8),
	Vector3(4.4, 0.0, -0.4),
	Vector3(1.8, 0.0, 2.8),
	Vector3(3.8, 0.0, 3.4),
]
const POSICIONES_ARCHIVADOR := [
	Vector3(-0.8, 0.0, 2.8),
	Vector3(1.0, 0.0, 3.8),
	Vector3(-1.8, 0.0, 4.1),
]
const POSICIONES_CABANA := [
	Vector3(0.0, 0.0, -1.0),
	Vector3(1.4, 0.0, -0.2),
	Vector3(0.2, 0.0, 1.0),
	Vector3(-1.4, 0.0, -0.1),
]

const COLOR_SUELO := Color(0.13, 0.15, 0.13)
const COLOR_BOSQUE := Color(0.19, 0.27, 0.18)
const COLOR_MADERA := Color(0.32, 0.23, 0.15)
const COLOR_ARCHIVO := Color(0.28, 0.31, 0.30)
const COLOR_CABANA := Color(0.42, 0.31, 0.20)
const COLOR_INTERIOR := Color(0.54, 0.43, 0.27)
const COLOR_MARCA := Color(0.72, 0.62, 0.30)
const COLOR_RETORNO := Color(0.28, 0.50, 0.37)

var _fase_umbral := 0
var _fase_fuera_campo := 0
var _marcas: Dictionary = {}
var _montado := false


static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


static func registrar_semilla(
	estado: Dictionary,
	lecturas: int,
	libro_abierto: bool,
	comparo_versiones: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if lecturas < LECTURAS_MINIMAS or not libro_abierto or not comparo_versiones:
		return false
	if estado.has("dia"):
		return SemillasOniricas.activar_semilla_onirica(estado, ID_MITO, fuente, intensidad)
	estado[CLAVE_SEMILLA] = true
	return true


static func plan_transicion(reduccion_movimiento: bool) -> Dictionary:
	return {
		"modo": "corte_fundido" if reduccion_movimiento else "fundido_desplazamiento",
		"duracion": 0.0 if reduccion_movimiento else 0.24,
		"animar_geometria": not reduccion_movimiento,
		"mover_camara": false,
		"desplazar_jugador": false,
		"flash": false,
	}


func _ready() -> void:
	preparar()


func preparar() -> void:
	if _montado:
		return
	_montado = true
	_montar_bosque()
	_montar_cabana()
	_montar_retorno()
	_montar_marcas()
	_montar_luz_y_camara()
	_aplicar_estado_visual()


func posiciones_actuales() -> Dictionary:
	return {
		OBJETO_ARBOL: POSICIONES_ARBOL[_fase_umbral % POSICIONES_ARBOL.size()],
		OBJETO_VALLA: POSICIONES_VALLA[_fase_umbral % POSICIONES_VALLA.size()],
		OBJETO_ARCHIVADOR: POSICIONES_ARCHIVADOR[_fase_fuera_campo % POSICIONES_ARCHIVADOR.size()],
		OBJETO_CABANA: POSICIONES_CABANA[_fase_umbral % POSICIONES_CABANA.size()],
	}


func marcas_persistentes() -> Dictionary:
	return _marcas.duplicate(true)


func dejar_marca(nombre: String, objetivo: String) -> bool:
	preparar()
	var id := nombre.strip_edges()
	if id.is_empty() or not OBJETOS_MARCA.has(objetivo) or _marcas.has(id):
		return false
	var posiciones := posiciones_actuales()
	_marcas[id] = {
		"objetivo": objetivo,
		"posicion": posiciones[objetivo],
	}
	_sincronizar_marcas_visual()
	return true


func comparar_marca(nombre: String) -> Dictionary:
	if not _marcas.has(nombre):
		return {"ok": false, "movido": false}
	var marca: Dictionary = _marcas[nombre]
	var objetivo := String(marca.get("objetivo", ""))
	var origen: Vector3 = marca.get("posicion", Vector3.ZERO)
	var actual: Vector3 = posiciones_actuales().get(objetivo, origen)
	return {
		"ok": true,
		"objetivo": objetivo,
		"origen": origen,
		"actual": actual,
		"movido": not origen.is_equal_approx(actual),
		"distancia": origen.distance_to(actual),
	}


## Regla espacial:
## - cruzar el umbral mueve árbol, valla y cabaña a su siguiente estado;
## - perder de vista solo mueve el archivador si el consumidor confirma que el
##   objeto quedó fuera de campo.
## No existe temporizador, RNG ni movimiento espontáneo.
func aplicar_evento(
	evento: String,
	fuera_de_campo: bool = false,
	reduccion_movimiento: bool = false,
) -> Dictionary:
	preparar()
	var cambiado := false
	if evento == EVENTO_UMBRAL:
		_fase_umbral = (_fase_umbral + 1) % POSICIONES_CABANA.size()
		cambiado = true
	elif evento == EVENTO_FUERA_CAMPO and fuera_de_campo:
		_fase_fuera_campo = (_fase_fuera_campo + 1) % POSICIONES_ARCHIVADOR.size()
		cambiado = true

	if cambiado:
		_aplicar_estado_visual()

	var salida := plan_transicion(reduccion_movimiento)
	(
		salida
		. merge(
			{
				"ok": cambiado,
				"evento": evento,
				"posiciones": posiciones_actuales(),
				"marcas": marcas_persistentes(),
				"cabana_visible": cabana_visible(),
				"retorno_disponible": ruta_retorno_disponible(),
			},
			true,
		)
	)
	return salida


func cabana_visible() -> bool:
	var cabana := get_node_or_null("CabanaAncla")
	return cabana != null and cabana.visible


func ruta_retorno_disponible() -> bool:
	return get_node_or_null("RetornoSeguro") != null


func estado_reproducible() -> Dictionary:
	return {
		"fase_umbral": _fase_umbral,
		"fase_fuera_campo": _fase_fuera_campo,
		"marcas": _marcas.duplicate(true),
	}


func restaurar_estado(estado: Dictionary) -> void:
	_fase_umbral = posmod(int(estado.get("fase_umbral", 0)), POSICIONES_CABANA.size())
	_fase_fuera_campo = posmod(int(estado.get("fase_fuera_campo", 0)), POSICIONES_ARCHIVADOR.size())
	var marcas = estado.get("marcas", {})
	_marcas = marcas.duplicate(true) if typeof(marcas) == TYPE_DICTIONARY else {}
	if _montado:
		_aplicar_estado_visual()
		_sincronizar_marcas_visual()


func _montar_bosque() -> void:
	_crear_caja(
		self,
		"SueloBosque",
		Vector3(15.0, 0.25, 12.0),
		Vector3(0.0, -0.14, 0.0),
		COLOR_SUELO,
	)

	var bosque := Node3D.new()
	bosque.name = "BosqueMovil"
	add_child(bosque)

	var arbol := Node3D.new()
	arbol.name = "ArbolTabique"
	bosque.add_child(arbol)
	_crear_caja(
		arbol, "TroncoTabique", Vector3(1.0, 4.2, 0.8), Vector3(0.0, 2.1, 0.0), COLOR_BOSQUE
	)
	_crear_caja(
		arbol, "PanelOficina", Vector3(2.8, 1.5, 0.18), Vector3(0.0, 2.2, 0.0), COLOR_ARCHIVO
	)

	var valla := Node3D.new()
	valla.name = "VallaArchivo"
	bosque.add_child(valla)
	for i in 3:
		_crear_caja(
			valla,
			"Poste%d" % (i + 1),
			Vector3(0.22, 2.2, 0.22),
			Vector3(-1.0 + i, 1.1, 0.0),
			COLOR_MADERA,
		)
	_crear_caja(valla, "Travesano", Vector3(2.5, 0.22, 0.22), Vector3(0.0, 1.2, 0.0), COLOR_MADERA)

	var archivador := Node3D.new()
	archivador.name = "ArchivadorHito"
	bosque.add_child(archivador)
	_crear_caja(
		archivador,
		"Cuerpo",
		Vector3(1.2, 2.1, 1.0),
		Vector3(0.0, 1.05, 0.0),
		COLOR_ARCHIVO,
	)
	_crear_caja(
		archivador,
		"CintaHito",
		Vector3(0.82, 0.18, 0.05),
		Vector3(0.0, 1.5, -0.53),
		COLOR_MARCA,
	)


func _montar_cabana() -> void:
	var cabana := Node3D.new()
	cabana.name = "CabanaAncla"
	add_child(cabana)

	_crear_caja(cabana, "Cuerpo", Vector3(3.0, 2.4, 2.6), Vector3(0.0, 2.2, 0.0), COLOR_CABANA)
	_crear_caja(cabana, "Techo", Vector3(3.5, 0.35, 3.1), Vector3(0.0, 3.55, 0.0), COLOR_MADERA)
	_crear_caja(
		cabana, "PataIndustrialA", Vector3(0.45, 1.8, 0.45), Vector3(-0.8, 0.9, 0.0), COLOR_ARCHIVO
	)
	_crear_caja(
		cabana, "PataIndustrialB", Vector3(0.45, 1.8, 0.45), Vector3(0.8, 0.9, 0.0), COLOR_ARCHIVO
	)

	var interior := Node3D.new()
	interior.name = "InteriorImposible"
	cabana.add_child(interior)
	_crear_caja(
		interior,
		"SueloInterior",
		Vector3(5.2, 0.12, 4.6),
		Vector3(0.0, 1.08, 0.0),
		COLOR_INTERIOR,
	)
	_crear_caja(
		interior,
		"MarcoPuerta",
		Vector3(1.25, 2.0, 0.18),
		Vector3(0.0, 2.0, -1.4),
		COLOR_MARCA,
	)


func _montar_retorno() -> void:
	_crear_caja(
		self,
		"RetornoSeguro",
		Vector3(2.2, 0.18, 2.2),
		Vector3(0.0, 0.10, 5.2),
		COLOR_RETORNO,
	)


func _montar_marcas() -> void:
	var marcas := Node3D.new()
	marcas.name = "MarcasPersistentes"
	add_child(marcas)
	_sincronizar_marcas_visual()


func _montar_luz_y_camara() -> void:
	var luz := DirectionalLight3D.new()
	luz.name = "LuzGeneral"
	luz.rotation_degrees = Vector3(-56.0, -24.0, 0.0)
	luz.light_energy = 0.95
	add_child(luz)

	var camara := Camera3D.new()
	camara.name = "CamaraStandalone"
	camara.position = Vector3(0.0, 9.0, 15.5)
	camara.rotation_degrees = Vector3(-28.0, 0.0, 0.0)
	camara.current = true
	add_child(camara)


func _aplicar_estado_visual() -> void:
	if not _montado:
		return
	var posiciones := posiciones_actuales()
	get_node("BosqueMovil/ArbolTabique").position = posiciones[OBJETO_ARBOL]
	get_node("BosqueMovil/VallaArchivo").position = posiciones[OBJETO_VALLA]
	get_node("BosqueMovil/ArchivadorHito").position = posiciones[OBJETO_ARCHIVADOR]
	get_node("CabanaAncla").position = posiciones[OBJETO_CABANA]
	get_node("CabanaAncla").visible = true
	get_node("RetornoSeguro").visible = true


func _sincronizar_marcas_visual() -> void:
	var contenedor := get_node_or_null("MarcasPersistentes")
	if contenedor == null:
		return
	for hijo in contenedor.get_children():
		hijo.queue_free()
	var ids: Array = _marcas.keys()
	ids.sort()
	for id in ids:
		var marca: Dictionary = _marcas[id]
		var posicion: Vector3 = marca.get("posicion", Vector3.ZERO)
		_crear_caja(
			contenedor,
			"Marca_%s" % String(id).validate_node_name(),
			Vector3(0.55, 0.08, 0.55),
			posicion + Vector3(0.0, 0.06, 0.0),
			COLOR_MARCA,
		)


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
