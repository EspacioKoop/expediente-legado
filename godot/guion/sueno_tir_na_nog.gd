## Vertical standalone de Tír na nÓg (#654).
##
## Dos versiones temporales del MISMO espacio comparten planta y objetos. El
## jugador cruza un umbral reversible y compara qué cambios persisten,
## envejecen o dejan huella al otro lado. La lógica no exige conocer a Oisín.
class_name SuenoTirNaNog
extends Node3D

const ID_MITO := "tir_na_nog"
const CLAVE_SEMILLA := "semilla_onirica_tir_na_nog"
const FUENTE_VIGILIA := "radio:radio_oeste_98:islas_fuera_del_tiempo"

const VERSION_RECIENTE := "reciente"
const VERSION_ENVEJECIDA := "envejecida"
const VERSIONES := [VERSION_RECIENTE, VERSION_ENVEJECIDA]
const MAX_VERSIONES_SIMULTANEAS := 2
const UMBRAL_PRINCIPAL := "puerta_archivo"

const OBJ_TAZA := "taza"
const OBJ_SILLA := "silla"
const OBJ_ARCHIVADOR := "archivador"
const OBJETOS := [OBJ_TAZA, OBJ_SILLA, OBJ_ARCHIVADOR]

## Cada acción tiene una consecuencia explícita y reconocible en la otra versión.
## Las cadenas son ids de estado, no texto narrativo ni conocimiento folklórico.
const REGLAS_OBJETOS := {
	OBJ_TAZA:
	{
		"reciente": "alfeizar",
		"reflejo_envejecido": "marca_circular_alfeizar",
		"envejecida": "alfeizar_agrietado",
		"reflejo_reciente": "alfeizar_desgastado",
	},
	OBJ_SILLA:
	{
		"reciente": "junto_puerta",
		"reflejo_envejecido": "silueta_polvo_junto_puerta",
		"envejecida": "junto_puerta_rota",
		"reflejo_reciente": "junto_puerta_desgastada",
	},
	OBJ_ARCHIVADOR:
	{
		"reciente": "pared_norte",
		"reflejo_envejecido": "huella_oxido_pared_norte",
		"envejecida": "pared_norte_oxidada",
		"reflejo_reciente": "pared_norte_decolorada",
	},
}

const COLOR_RECIENTE := Color(0.63, 0.67, 0.62)
const COLOR_ENVEJECIDA := Color(0.34, 0.31, 0.25)
const COLOR_SUELO_RECIENTE := Color(0.31, 0.37, 0.34)
const COLOR_SUELO_ENVEJECIDO := Color(0.20, 0.18, 0.15)
const COLOR_UMBRAL := Color(0.43, 0.55, 0.47)
const COLOR_ARROYO := Color(0.18, 0.42, 0.48)
const COLOR_RETORNO := Color(0.30, 0.50, 0.38)

@export var reduccion_movimiento := false

var _version_actual := VERSION_RECIENTE
var _estado_objetos := {
	OBJ_TAZA: {VERSION_RECIENTE: "mesa", VERSION_ENVEJECIDA: "mesa_envejecida"},
	OBJ_SILLA: {VERSION_RECIENTE: "pasillo", VERSION_ENVEJECIDA: "pasillo_envejecido"},
	OBJ_ARCHIVADOR: {VERSION_RECIENTE: "pared_este", VERSION_ENVEJECIDA: "pared_este_oxidada"},
}
var _montado := false


static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


static func registrar_semilla(
	estado: Dictionary,
	programa_sintonizado: bool,
	segmento_completo: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if not programa_sintonizado or not segmento_completo:
		return false
	if estado.has("dia"):
		return SemillasOniricas.activar_semilla_onirica(estado, ID_MITO, fuente, intensidad)
	estado[CLAVE_SEMILLA] = true
	return true


static func plan_presentacion(reduccion_movimiento: bool) -> Dictionary:
	return {
		"modo": "corte_fundido" if reduccion_movimiento else "cruce_breve",
		"duracion": 0.0 if reduccion_movimiento else 0.18,
		"time_lapse": false,
		"reloj_contrarreloj": false,
	}


func _ready() -> void:
	preparar()


func preparar() -> void:
	if _montado:
		return
	_montado = true
	_montar_version(VERSION_RECIENTE, COLOR_RECIENTE, COLOR_SUELO_RECIENTE)
	_montar_version(VERSION_ENVEJECIDA, COLOR_ENVEJECIDA, COLOR_SUELO_ENVEJECIDO)
	_montar_umbral()
	_montar_retorno()
	_montar_luz_y_camara()
	_aplicar_estado_visual()


func version_actual() -> String:
	return _version_actual


func versiones_disponibles() -> Array:
	return VERSIONES.duplicate()


func ruta_retorno_disponible() -> bool:
	return get_node_or_null("Retorno") != null


func estado_reproducible() -> Dictionary:
	return {
		"version_actual": _version_actual,
		"objetos": _estado_objetos.duplicate(true),
	}


## Cruza entre dos versiones del mismo lugar. Nunca toca inventario/progreso:
## únicamente cambia qué representación temporal está visible.
func cruzar_umbral(
	umbral: String = UMBRAL_PRINCIPAL, reducir_movimiento: Variant = null
) -> Dictionary:
	preparar()
	if umbral != UMBRAL_PRINCIPAL:
		return {
			"ok": false,
			"umbral": umbral,
			"version": _version_actual,
			"retorno_disponible": ruta_retorno_disponible(),
		}

	var desde := _version_actual
	_version_actual = _otra_version(_version_actual)
	_aplicar_estado_visual()
	var reducir := reduccion_movimiento if reducir_movimiento == null else bool(reducir_movimiento)
	var salida := plan_presentacion(reducir)
	(
		salida
		. merge(
			{
				"ok": true,
				"umbral": UMBRAL_PRINCIPAL,
				"desde": desde,
				"hacia": _version_actual,
				"irreversible": false,
				"objetos_criticos_borrados": false,
				"retorno_disponible": ruta_retorno_disponible(),
			},
			true,
		)
	)
	return salida


## Mueve un objeto en la versión actual y deja un reflejo determinista en la
## otra. Repetir la acción es idempotente: no genera estados infinitos.
func mover_objeto(objeto: String) -> Dictionary:
	preparar()
	if not OBJETOS.has(objeto):
		return {
			"ok": false,
			"objeto": objeto,
			"version": _version_actual,
			"retorno_disponible": ruta_retorno_disponible(),
		}

	var otra := _otra_version(_version_actual)
	var regla: Dictionary = REGLAS_OBJETOS[objeto]
	var estado_origen := ""
	var estado_reflejo := ""
	if _version_actual == VERSION_RECIENTE:
		estado_origen = String(regla["reciente"])
		estado_reflejo = String(regla["reflejo_envejecido"])
	else:
		estado_origen = String(regla["envejecida"])
		estado_reflejo = String(regla["reflejo_reciente"])

	_estado_objetos[objeto][_version_actual] = estado_origen
	_estado_objetos[objeto][otra] = estado_reflejo
	_aplicar_estado_visual()
	return {
		"ok": true,
		"objeto": objeto,
		"version_origen": _version_actual,
		"version_reflejo": otra,
		"estado_origen": estado_origen,
		"estado_reflejo": estado_reflejo,
		"rastreable": true,
		"retorno_disponible": ruta_retorno_disponible(),
	}


## Restaura únicamente las dos versiones declaradas y los tres objetos del
## contrato. Un save incompleto cae a estados iniciales conocidos.
func restaurar_estado(guardado: Dictionary) -> void:
	var version := String(guardado.get("version_actual", VERSION_RECIENTE))
	_version_actual = version if VERSIONES.has(version) else VERSION_RECIENTE
	var objetos_guardados = guardado.get("objetos", {})
	if typeof(objetos_guardados) == TYPE_DICTIONARY:
		for objeto in OBJETOS:
			if not objetos_guardados.has(objeto):
				continue
			var estados = objetos_guardados[objeto]
			if typeof(estados) != TYPE_DICTIONARY:
				continue
			for version_id in VERSIONES:
				if estados.has(version_id):
					_estado_objetos[objeto][version_id] = String(estados[version_id])
	if _montado:
		_aplicar_estado_visual()


func _otra_version(version: String) -> String:
	return VERSION_ENVEJECIDA if version == VERSION_RECIENTE else VERSION_RECIENTE


func _montar_version(id_version: String, color_pared: Color, color_suelo: Color) -> void:
	var version := Node3D.new()
	version.name = "Version_%s" % id_version
	add_child(version)

	_crear_caja(version, "Suelo", Vector3(10.0, 0.20, 8.0), Vector3(0.0, -0.10, 0.0), color_suelo)
	_crear_caja(
		version, "ParedNorte", Vector3(10.0, 3.0, 0.20), Vector3(0.0, 1.5, -4.0), color_pared
	)
	_crear_caja(version, "ParedEste", Vector3(0.20, 3.0, 8.0), Vector3(5.0, 1.5, 0.0), color_pared)
	_crear_caja(
		version,
		"Mesa",
		Vector3(2.8, 0.15, 1.2),
		Vector3(-1.8, 0.85, 0.8),
		color_pared.lightened(0.12)
	)
	_crear_caja(version, "Arroyo", Vector3(0.85, 0.04, 8.0), Vector3(0.9, 0.03, 0.0), COLOR_ARROYO)
	_crear_objeto(version, OBJ_TAZA, Vector3(-1.8, 1.06, 0.8), Color(0.62, 0.55, 0.43))
	_crear_objeto(version, OBJ_SILLA, Vector3(-3.1, 0.55, 1.3), Color(0.30, 0.27, 0.22))
	_crear_objeto(version, OBJ_ARCHIVADOR, Vector3(3.9, 1.2, -2.2), Color(0.32, 0.38, 0.36))


func _crear_objeto(version: Node3D, objeto: String, posicion: Vector3, color: Color) -> void:
	var tam := Vector3(0.55, 0.55, 0.55)
	if objeto == OBJ_SILLA:
		tam = Vector3(0.85, 1.10, 0.85)
	elif objeto == OBJ_ARCHIVADOR:
		tam = Vector3(1.20, 2.40, 0.90)
	_crear_caja(version, "Objeto_%s" % objeto, tam, posicion, color)
	_crear_hotspot_objeto(version, objeto, posicion, tam)


func _crear_hotspot_objeto(
	version: Node3D, objeto: String, posicion: Vector3, tam: Vector3
) -> void:
	var hotspot := Interactuable3D.new()
	hotspot.name = "Interactuar_%s" % objeto
	hotspot.position = posicion
	hotspot.verbo = Interactuable3D.Verbo.USAR
	hotspot.nombre_objeto = _nombre_interaccion_objeto(objeto)
	hotspot.sonido = Interactuable3D.SIN_SONIDO
	hotspot.collision_mask = 0
	hotspot.activado.connect(_al_mover_objeto.bind(objeto))
	version.add_child(hotspot)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam + Vector3(0.24, 0.24, 0.24)
	colision.shape = forma
	hotspot.add_child(colision)


func _nombre_interaccion_objeto(objeto: String) -> String:
	if objeto == OBJ_TAZA:
		return "taza desincronizada"
	if objeto == OBJ_SILLA:
		return "silla desincronizada"
	return "archivador desincronizado"


func _al_mover_objeto(_actor: Node, objeto: String) -> void:
	mover_objeto(objeto)


func _al_cruzar_umbral(_actor: Node) -> void:
	cruzar_umbral()


func _montar_umbral() -> void:
	var marco := Node3D.new()
	marco.name = "UmbralPrincipal"
	marco.position = Vector3(0.0, 0.0, 3.35)
	add_child(marco)
	_crear_caja(
		marco, "JambaIzquierda", Vector3(0.25, 2.8, 0.25), Vector3(-1.05, 1.4, 0.0), COLOR_UMBRAL
	)
	_crear_caja(
		marco, "JambaDerecha", Vector3(0.25, 2.8, 0.25), Vector3(1.05, 1.4, 0.0), COLOR_UMBRAL
	)
	_crear_caja(marco, "Dintel", Vector3(2.35, 0.25, 0.25), Vector3(0.0, 2.72, 0.0), COLOR_UMBRAL)

	var cruce := Interactuable3D.new()
	cruce.name = "CruzarUmbral"
	cruce.position = Vector3(0.0, 1.3, 0.0)
	cruce.verbo = Interactuable3D.Verbo.USAR
	cruce.nombre_objeto = "umbral temporal"
	cruce.sonido = Interactuable3D.SIN_SONIDO
	cruce.collision_mask = 0
	cruce.activado.connect(_al_cruzar_umbral)
	marco.add_child(cruce)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.9, 2.5, 0.70)
	colision.shape = forma
	cruce.add_child(colision)


func _montar_retorno() -> void:
	_crear_caja(self, "Retorno", Vector3(1.8, 0.10, 1.8), Vector3(-3.8, 0.06, 3.1), COLOR_RETORNO)


func _montar_luz_y_camara() -> void:
	var luz := DirectionalLight3D.new()
	luz.name = "Luz"
	luz.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	luz.light_energy = 1.1
	add_child(luz)

	var camara := Camera3D.new()
	camara.name = "Camara"
	camara.position = Vector3(0.0, 7.0, 10.5)
	camara.rotation_degrees = Vector3(-28.0, 0.0, 0.0)
	camara.current = true
	add_child(camara)


func _aplicar_estado_visual() -> void:
	for version_id in VERSIONES:
		var nodo_version := get_node_or_null("Version_%s" % version_id) as Node3D
		if nodo_version == null:
			continue
		var version_visible: bool = String(version_id) == _version_actual
		for hijo in nodo_version.get_children():
			if hijo is VisualInstance3D:
				(hijo as VisualInstance3D).visible = version_visible
		for objeto in OBJETOS:
			var estado := String(_estado_objetos[objeto][version_id])
			var posicion := _posicion_para_estado(objeto, estado)
			var nodo_objeto := nodo_version.get_node_or_null("Objeto_%s" % objeto) as MeshInstance3D
			if nodo_objeto != null:
				nodo_objeto.position = posicion
			var hotspot := (
				nodo_version.get_node_or_null("Interactuar_%s" % objeto) as Interactuable3D
			)
			if hotspot == null:
				continue
			hotspot.position = posicion
			hotspot.habilitado = version_visible
			hotspot.monitorable = version_visible
			hotspot.collision_layer = 1 if version_visible else 0


func _posicion_para_estado(objeto: String, estado: String) -> Vector3:
	var base := Vector3.ZERO
	if objeto == OBJ_TAZA:
		base = Vector3(-1.8, 1.06, 0.8)
	elif objeto == OBJ_SILLA:
		base = Vector3(-3.1, 0.55, 1.3)
	else:
		base = Vector3(3.9, 1.2, -2.2)

	if estado.contains("alfeizar"):
		return Vector3(3.4, base.y, -3.55)
	if estado.contains("junto_puerta"):
		return Vector3(-1.65, base.y, 3.0)
	if estado.contains("pared_norte"):
		return Vector3(1.8, base.y, -3.45)
	return base


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
