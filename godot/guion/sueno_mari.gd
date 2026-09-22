## Vertical standalone del sueño de Mari (#651).
##
## Mari no aparece como enemiga ni NPC: su presencia se expresa mediante un
## paisaje que cambia con el frente meteorológico. El grafo espacial es estable
## y las acciones del jugador cambian de forma determinista qué rutas se leen y
## cuáles quedan transitables.
class_name SuenoMari
extends Node3D

const ID_MITO := "mari"
const CLAVE_SEMILLA := "semilla_onirica_mari"
const FUENTE_VIGILIA := "folleto:cuevas_montana_98"
const INSPECCIONES_MINIMAS := 2

const CLIMA_CALMA := "calma"
const CLIMA_LLUVIA := "lluvia"
const CLIMA_VIENTO := "viento"
const CLIMA_NIEBLA := "niebla"
const CLIMA_TORMENTA := "tormenta"
const CLIMAS := [CLIMA_CALMA, CLIMA_LLUVIA, CLIMA_VIENTO, CLIMA_NIEBLA, CLIMA_TORMENTA]

const RUTA_RETORNO := "retorno"
const RUTA_CAUCE := "cauce_revelado"
const RUTA_CORNISA := "cornisa_viento"
const RUTA_CUEVA := "cueva_tormenta"

## No hay reloj ni tirada aleatoria. Cada cambio proviene de una interacción
## física reconocible y puede repetirse exactamente en pruebas o al recargar.
const ACCIONES_CLIMA := {
	"restablecer": CLIMA_CALMA,
	"abrir_compuerta": CLIMA_LLUVIA,
	"abrir_conducto": CLIMA_VIENTO,
	"cerrar_conducto": CLIMA_NIEBLA,
	"refugiarse": CLIMA_TORMENTA,
}

## El retorno permanece abierto en todos los estados. Las otras tres conexiones
## cambian de disponibilidad con el clima y expresan reglas distintas.
const RUTAS_POR_CLIMA := {
	CLIMA_CALMA:
	{
		RUTA_RETORNO: true,
		RUTA_CAUCE: false,
		RUTA_CORNISA: false,
		RUTA_CUEVA: false,
	},
	CLIMA_LLUVIA:
	{
		RUTA_RETORNO: true,
		RUTA_CAUCE: true,
		RUTA_CORNISA: false,
		RUTA_CUEVA: false,
	},
	CLIMA_VIENTO:
	{
		RUTA_RETORNO: true,
		RUTA_CAUCE: false,
		RUTA_CORNISA: true,
		RUTA_CUEVA: false,
	},
	CLIMA_NIEBLA:
	{
		RUTA_RETORNO: true,
		RUTA_CAUCE: false,
		RUTA_CORNISA: false,
		RUTA_CUEVA: false,
	},
	CLIMA_TORMENTA:
	{
		RUTA_RETORNO: true,
		RUTA_CAUCE: true,
		RUTA_CORNISA: true,
		RUTA_CUEVA: true,
	},
}

const COLOR_SUELO := Color(0.17, 0.18, 0.17)
const COLOR_ARCHIVO := Color(0.28, 0.31, 0.30)
const COLOR_ROCA := Color(0.25, 0.24, 0.21)
const COLOR_ROCA_CLARA := Color(0.36, 0.34, 0.29)
const COLOR_AGUA := Color(0.24, 0.40, 0.48)
const COLOR_VIENTO := Color(0.66, 0.63, 0.50)
const COLOR_CUEVA := Color(0.30, 0.24, 0.18)
const COLOR_RETORNO := Color(0.28, 0.48, 0.37)
const COLOR_NIEBLA := Color(0.57, 0.60, 0.58)
const COLOR_TORMENTA := Color(0.17, 0.19, 0.23)
const COLOR_LUZ := Color(0.75, 0.72, 0.55)

var reduccion_movimiento := false

var _clima := CLIMA_CALMA
var _montado := false


static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


## El folleto debe haberse leído y manipulado deliberadamente. Existir en una
## mesa o verse de fondo nunca registra la semilla.
static func registrar_semilla(
	estado: Dictionary,
	inspecciones: int,
	folleto_desplegado: bool,
	ruta_trazada: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if inspecciones < INSPECCIONES_MINIMAS or not folleto_desplegado or not ruta_trazada:
		return false
	if estado.has("dia"):
		return SemillasOniricas.activar_semilla_onirica(estado, ID_MITO, fuente, intensidad)
	estado[CLAVE_SEMILLA] = true
	return true


static func plan_transicion(reduccion_movimiento: bool) -> Dictionary:
	return {
		"modo": "corte_fundido" if reduccion_movimiento else "fundido_climatico",
		"duracion": 0.0 if reduccion_movimiento else 0.24,
		"particulas": false if reduccion_movimiento else true,
		"mover_camara": false,
		"flash": false,
	}


func _ready() -> void:
	preparar()


func preparar() -> void:
	if _montado:
		return
	_montado = true
	_montar_arquitectura()
	_montar_rutas()
	_montar_controles_climaticos()
	_montar_indicios_climaticos()
	_montar_luz_y_camara()
	_aplicar_estado_visual()


func clima_actual() -> String:
	return _clima


func rutas_disponibles() -> Dictionary:
	return Dictionary(RUTAS_POR_CLIMA[_clima]).duplicate(true)


func referencias_visibles() -> Dictionary:
	return {
		"cercana": true,
		"lejana": _clima != CLIMA_NIEBLA,
	}


func ruta_retorno_disponible() -> bool:
	return (
		bool(rutas_disponibles().get(RUTA_RETORNO, false))
		and get_node_or_null("Rutas/RutaRetorno") != null
	)


## Cambia el tiempo solo como respuesta a una acción declarada. El retorno y la
## referencia cercana sobreviven a todo estado, de modo que niebla/tormenta nunca
## convierten el prototipo en una trampa.
func aplicar_accion(accion: String, reduccion_movimiento: bool = false) -> Dictionary:
	preparar()
	if not ACCIONES_CLIMA.has(accion):
		return {
			"ok": false,
			"accion": accion,
			"clima": _clima,
			"rutas": rutas_disponibles(),
			"referencias": referencias_visibles(),
			"retorno_disponible": ruta_retorno_disponible(),
		}

	_clima = String(ACCIONES_CLIMA[accion])
	_aplicar_estado_visual()
	var salida := plan_transicion(reduccion_movimiento)
	(
		salida
		. merge(
			{
				"ok": true,
				"accion": accion,
				"clima": _clima,
				"rutas": rutas_disponibles(),
				"referencias": referencias_visibles(),
				"retorno_disponible": ruta_retorno_disponible(),
			},
			true,
		)
	)
	return salida


func estado_reproducible() -> Dictionary:
	return {"clima": _clima}


func restaurar_estado(estado: Dictionary) -> void:
	var clima := String(estado.get("clima", CLIMA_CALMA))
	_clima = clima if CLIMAS.has(clima) else CLIMA_CALMA
	if _montado:
		_aplicar_estado_visual()


func _montar_arquitectura() -> void:
	var cotidiano := Node3D.new()
	cotidiano.name = "ArquitecturaCotidiana"
	add_child(cotidiano)
	_crear_caja(
		cotidiano, "SueloOficina", Vector3(15.0, 0.30, 11.0), Vector3(0.0, -0.18, 0.0), COLOR_SUELO
	)
	for i in 4:
		_crear_caja(
			cotidiano,
			"Archivador%d" % (i + 1),
			Vector3(1.3, 2.2, 1.1),
			Vector3(-5.0 + i * 1.55, 1.1, -3.7),
			COLOR_ARCHIVO,
		)
	_crear_caja(
		cotidiano, "Fluorescente", Vector3(5.0, 0.12, 0.32), Vector3(1.0, 4.2, -1.8), COLOR_LUZ
	)

	var cueva := Node3D.new()
	cueva.name = "VolumenCueva"
	cueva.position = Vector3(4.8, 0.0, -1.4)
	add_child(cueva)
	_crear_caja(
		cueva, "EstratoIzquierdo", Vector3(2.2, 5.0, 5.0), Vector3(-2.0, 2.5, 0.0), COLOR_ROCA
	)
	_crear_caja(cueva, "EstratoDerecho", Vector3(2.2, 5.0, 5.0), Vector3(2.0, 2.5, 0.0), COLOR_ROCA)
	_crear_caja(
		cueva, "TechoRoca", Vector3(6.2, 1.2, 5.0), Vector3(0.0, 5.0, 0.0), COLOR_ROCA_CLARA
	)
	_crear_caja(
		cueva, "LaderaInterior", Vector3(4.6, 0.35, 5.5), Vector3(0.0, 0.65, -2.0), COLOR_ROCA_CLARA
	)


func _montar_rutas() -> void:
	var rutas := Node3D.new()
	rutas.name = "Rutas"
	add_child(rutas)
	_crear_caja(
		rutas, "RutaRetorno", Vector3(2.2, 0.14, 2.2), Vector3(-5.6, 0.08, 3.5), COLOR_RETORNO
	)
	_crear_caja(rutas, "RutaCauce", Vector3(4.6, 0.12, 1.0), Vector3(-0.4, 0.08, 2.5), COLOR_AGUA)
	_crear_caja(
		rutas, "RutaCornisa", Vector3(4.0, 0.18, 0.85), Vector3(2.1, 1.35, 0.3), COLOR_VIENTO
	)
	_crear_caja(rutas, "RutaCueva", Vector3(1.5, 0.16, 4.1), Vector3(4.8, 0.95, -1.4), COLOR_CUEVA)


func _montar_controles_climaticos() -> void:
	var controles := Node3D.new()
	controles.name = "ControlesClimaticos"
	add_child(controles)
	_crear_control_clima(
		controles,
		"CompuertaLluvia",
		"abrir_compuerta",
		"compuerta de drenaje",
		Vector3(-3.4, 0.9, 1.8),
		Vector3(1.0, 1.6, 0.25),
		COLOR_AGUA,
	)
	_crear_control_clima(
		controles,
		"ConductoViento",
		"abrir_conducto",
		"conducto de aire",
		Vector3(0.8, 2.2, -3.2),
		Vector3(1.2, 0.45, 0.25),
		COLOR_VIENTO,
	)
	_crear_control_clima(
		controles,
		"ConductoNiebla",
		"cerrar_conducto",
		"compuerta de ventilación",
		Vector3(-0.8, 2.2, -3.2),
		Vector3(1.2, 0.45, 0.25),
		COLOR_NIEBLA,
	)
	_crear_control_clima(
		controles,
		"RefugioTormenta",
		"refugiarse",
		"hueco de refugio",
		Vector3(3.8, 1.0, -2.8),
		Vector3(1.0, 2.0, 0.5),
		COLOR_TORMENTA,
	)
	_crear_control_clima(
		controles,
		"RestablecerCalma",
		"restablecer",
		"baliza de retorno",
		Vector3(-4.9, 0.7, 3.0),
		Vector3(0.55, 1.0, 0.55),
		COLOR_RETORNO,
	)


func _crear_control_clima(
	padre: Node3D,
	nombre: String,
	accion: String,
	nombre_objeto: String,
	posicion: Vector3,
	tam: Vector3,
	color: Color,
) -> void:
	var control := Interactuable3D.new()
	control.name = nombre
	control.position = posicion
	control.verbo = Interactuable3D.Verbo.USAR
	control.nombre_objeto = nombre_objeto
	control.sonido = Interactuable3D.SIN_SONIDO
	control.collision_mask = 0
	control.activado.connect(_al_accion_clima.bind(accion))
	padre.add_child(control)

	_crear_caja(control, "Indicador", tam * 0.82, Vector3.ZERO, color)
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	control.add_child(colision)


func _al_accion_clima(_actor: Node, accion: String) -> void:
	aplicar_accion(accion, reduccion_movimiento)


func _montar_indicios_climaticos() -> void:
	var indicios := Node3D.new()
	indicios.name = "IndiciosClimaticos"
	add_child(indicios)
	_crear_caja(
		indicios, "HuellaAgua", Vector3(2.6, 0.06, 0.38), Vector3(-1.2, 0.11, 1.8), COLOR_AGUA
	)
	_crear_caja(
		indicios, "HojasViento", Vector3(2.8, 0.08, 0.25), Vector3(1.6, 0.80, 1.0), COLOR_VIENTO
	)
	_crear_caja(
		indicios, "NieblaLejana", Vector3(6.0, 2.4, 0.12), Vector3(0.0, 1.2, -4.9), COLOR_NIEBLA
	)
	_crear_caja(
		indicios, "FrenteTormenta", Vector3(7.0, 0.45, 3.0), Vector3(1.3, 5.5, -0.8), COLOR_TORMENTA
	)
	_crear_caja(
		indicios, "ReferenciaLejana", Vector3(0.7, 3.6, 0.7), Vector3(0.0, 1.8, -4.4), COLOR_LUZ
	)
	_crear_caja(
		indicios, "BalizaCercana", Vector3(0.55, 0.9, 0.55), Vector3(-4.4, 0.45, 2.8), COLOR_RETORNO
	)
	_crear_caja(
		indicios,
		"PresenciaPaisaje",
		Vector3(0.24, 3.8, 5.2),
		Vector3(6.2, 2.1, -1.4),
		COLOR_TORMENTA
	)


func _montar_luz_y_camara() -> void:
	var luz := DirectionalLight3D.new()
	luz.name = "LuzGeneral"
	luz.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	luz.light_energy = 0.95
	add_child(luz)

	var camara := Camera3D.new()
	camara.name = "CamaraStandalone"
	camara.position = Vector3(0.0, 7.5, 14.5)
	camara.rotation_degrees = Vector3(-24.0, 0.0, 0.0)
	camara.current = true
	add_child(camara)


func _aplicar_estado_visual() -> void:
	if not _montado:
		return
	var rutas := rutas_disponibles()
	(get_node("Rutas/RutaRetorno") as MeshInstance3D).visible = bool(rutas[RUTA_RETORNO])
	(get_node("Rutas/RutaCauce") as MeshInstance3D).visible = bool(rutas[RUTA_CAUCE])
	(get_node("Rutas/RutaCornisa") as MeshInstance3D).visible = bool(rutas[RUTA_CORNISA])
	(get_node("Rutas/RutaCueva") as MeshInstance3D).visible = bool(rutas[RUTA_CUEVA])

	(get_node("IndiciosClimaticos/HuellaAgua") as MeshInstance3D).visible = (
		_clima in [CLIMA_LLUVIA, CLIMA_TORMENTA]
	)
	(get_node("IndiciosClimaticos/HojasViento") as MeshInstance3D).visible = (
		_clima in [CLIMA_VIENTO, CLIMA_TORMENTA]
	)
	(get_node("IndiciosClimaticos/NieblaLejana") as MeshInstance3D).visible = _clima == CLIMA_NIEBLA
	(get_node("IndiciosClimaticos/FrenteTormenta") as MeshInstance3D).visible = (
		_clima == CLIMA_TORMENTA
	)
	(get_node("IndiciosClimaticos/ReferenciaLejana") as MeshInstance3D).visible = (
		_clima != CLIMA_NIEBLA
	)
	(get_node("IndiciosClimaticos/BalizaCercana") as MeshInstance3D).visible = true
	(get_node("IndiciosClimaticos/PresenciaPaisaje") as MeshInstance3D).visible = (
		_clima == CLIMA_TORMENTA
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
	material.roughness = 0.86
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo
