## Vertical standalone del sueño de Anansi con raíz akan/ashanti (#656).
##
## La red de causalidad es una abstracción jugable propia: no se presenta como
## símbolo ritual akan. La escena reutiliza oficina, cableado, clips y teléfonos
## para convertir relaciones causa/efecto en algo visible y reversible.
class_name SuenoAnansiAkan
extends Node3D

const ID_MITO := "anansi_akan"
const CLAVE_SEMILLA := "semilla_onirica_anansi_akan"
const FUENTE_VIGILIA := "cassette:anansi_akan_relato_98"
const PASOS_RELATO_MINIMOS := 3
const ACCIONES_VALIDAS := ["tensar", "aflojar", "cortar", "reconectar"]

const COLOR_SUELO := Color(0.16, 0.16, 0.17)
const COLOR_NODO := Color(0.47, 0.43, 0.35)
const COLOR_HILO := Color(0.74, 0.67, 0.48)
const COLOR_HILO_TENSO := Color(0.88, 0.76, 0.35)
const COLOR_SENUELO := Color(0.38, 0.36, 0.35)
const COLOR_PISTA := Color(0.72, 0.26, 0.18)

const NODOS_BASE := {
	"telefono": {"pos": Vector3(-4.8, 0.7, 2.8), "valor": 0},
	"impresora": {"pos": Vector3(-1.4, 0.7, -2.6), "valor": 0},
	"archivador": {"pos": Vector3(2.2, 0.7, -2.0), "valor": 0},
	"puerta": {"pos": Vector3(5.0, 1.2, 2.6), "valor": 0},
}

## Tres relaciones reales permiten resolver el estado. La cuarta es un señuelo
## observable: su orientación de tensión no coincide en ambos extremos.
const CONEXIONES_BASE := {
	"telefono_impresora": {
		"origen": "telefono",
		"destino": "impresora",
		"real": true,
		"polaridad": 1,
		"pista": "tension_continua",
	},
	"impresora_archivador": {
		"origen": "impresora",
		"destino": "archivador",
		"real": true,
		"polaridad": 1,
		"pista": "tension_continua",
	},
	"archivador_puerta": {
		"origen": "archivador",
		"destino": "puerta",
		"real": true,
		"polaridad": -1,
		"pista": "tension_invertida_legible",
	},
	"telefono_puerta_senuelo": {
		"origen": "telefono",
		"destino": "puerta",
		"real": false,
		"polaridad": 0,
		"pista": "orientacion_incompatible_en_destino",
	},
}

const OBJETIVO := {
	"impresora": 1,
	"archivador": 1,
	"puerta": -1,
}

@export var reduccion_movimiento := false

var _estado: Dictionary = {}
var _nodos_visuales: Dictionary = {}
var _hilos_visuales: Dictionary = {}


static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


static func registrar_semilla(
	estado: Dictionary,
	pasos_escuchados: int,
	relato_terminado: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if pasos_escuchados < PASOS_RELATO_MINIMOS or not relato_terminado:
		return false
	if estado.has("dia"):
		return SemillasOniricas.activar_semilla_onirica(
			estado,
			ID_MITO,
			fuente,
			intensidad,
		)
	estado[CLAVE_SEMILLA] = true
	return true


static func estado_inicial() -> Dictionary:
	var nodos := NODOS_BASE.duplicate(true)
	var conexiones := CONEXIONES_BASE.duplicate(true)
	for id_conexion in conexiones.keys():
		var conexion: Dictionary = conexiones[id_conexion]
		conexion["tension"] = 0
		conexion["activa"] = true
		conexion["reconectable"] = true
		conexiones[id_conexion] = conexion
	return {
		"nodos": nodos,
		"conexiones": conexiones,
		"historial": [],
		"resuelto": false,
	}


## Devuelve una pista espacial, no un dato oculto de gameplay. El señuelo se
## detecta porque la orientación/tensión no continúa en el extremo remoto.
static func observar_conexion(estado: Dictionary, id_conexion: String) -> Dictionary:
	var conexiones: Dictionary = estado.get("conexiones", {})
	if not conexiones.has(id_conexion):
		return {}
	var conexion: Dictionary = conexiones[id_conexion]
	var pista := String(conexion.get("pista", ""))
	return {
		"id": id_conexion,
		"pista_espacial": pista,
		"tension_visible": int(conexion.get("tension", 0)),
		"activa": bool(conexion.get("activa", true)),
		"senuelo_detectable": pista == "orientacion_incompatible_en_destino",
	}


## Toda acción guarda el estado anterior mínimo. Cortar nunca destruye la
## conexión: siempre queda marcada como reconectable y puede deshacerse.
static func manipular_conexion(
	estado: Dictionary, id_conexion: String, accion: String
) -> Dictionary:
	var resultado := estado.duplicate(true)
	var conexiones: Dictionary = resultado.get("conexiones", {})
	var accion_limpia := accion.strip_edges().to_lower()
	if not conexiones.has(id_conexion) or not ACCIONES_VALIDAS.has(accion_limpia):
		resultado["cambio_valido"] = false
		return resultado

	var conexion: Dictionary = conexiones[id_conexion]
	var destino_id := String(conexion.get("destino", ""))
	var nodos: Dictionary = resultado.get("nodos", {})
	var valor_destino_anterior := 0
	if nodos.has(destino_id):
		var destino: Dictionary = nodos[destino_id]
		valor_destino_anterior = int(destino.get("valor", 0))

	var historial: Array = resultado.get("historial", [])
	historial.append({
		"conexion": id_conexion,
		"tension": int(conexion.get("tension", 0)),
		"activa": bool(conexion.get("activa", true)),
		"destino": destino_id,
		"valor_destino": valor_destino_anterior,
	})
	resultado["historial"] = historial

	var efecto_remoto := ""
	match accion_limpia:
		"tensar":
			conexion["tension"] = mini(int(conexion.get("tension", 0)) + 1, 2)
			if bool(conexion.get("real", false)) and bool(conexion.get("activa", true)):
				efecto_remoto = destino_id
				_aplicar_delta_nodo(nodos, destino_id, int(conexion.get("polaridad", 1)))
		"aflojar":
			conexion["tension"] = maxi(int(conexion.get("tension", 0)) - 1, -2)
			if bool(conexion.get("real", false)) and bool(conexion.get("activa", true)):
				efecto_remoto = destino_id
				_aplicar_delta_nodo(nodos, destino_id, -int(conexion.get("polaridad", 1)))
		"cortar":
			conexion["activa"] = false
		"reconectar":
			conexion["activa"] = true

	conexiones[id_conexion] = conexion
	resultado["conexiones"] = conexiones
	resultado["nodos"] = nodos
	resultado["efecto_remoto"] = efecto_remoto
	resultado["cambio_valido"] = true
	resultado["reversible"] = true
	resultado["resuelto"] = objetivo_resuelto(resultado)
	return resultado


static func revertir_ultima(estado: Dictionary) -> Dictionary:
	var resultado := estado.duplicate(true)
	var historial: Array = resultado.get("historial", [])
	if historial.is_empty():
		resultado["revertido"] = false
		return resultado

	var paso: Dictionary = historial.pop_back()
	var conexiones: Dictionary = resultado.get("conexiones", {})
	var id_conexion := String(paso.get("conexion", ""))
	if conexiones.has(id_conexion):
		var conexion: Dictionary = conexiones[id_conexion]
		conexion["tension"] = int(paso.get("tension", 0))
		conexion["activa"] = bool(paso.get("activa", true))
		conexiones[id_conexion] = conexion

	var nodos: Dictionary = resultado.get("nodos", {})
	var destino_id := String(paso.get("destino", ""))
	if nodos.has(destino_id):
		var nodo: Dictionary = nodos[destino_id]
		nodo["valor"] = int(paso.get("valor_destino", 0))
		nodos[destino_id] = nodo

	resultado["historial"] = historial
	resultado["conexiones"] = conexiones
	resultado["nodos"] = nodos
	resultado["efecto_remoto"] = destino_id
	resultado["revertido"] = true
	resultado["resuelto"] = objetivo_resuelto(resultado)
	return resultado


static func objetivo_resuelto(estado: Dictionary) -> bool:
	var nodos: Dictionary = estado.get("nodos", {})
	for id_nodo in OBJETIVO.keys():
		if not nodos.has(id_nodo):
			return false
		var nodo: Dictionary = nodos[id_nodo]
		if int(nodo.get("valor", 0)) != int(OBJETIVO[id_nodo]):
			return false
	return true


## Accesibilidad cambia animación, nunca topología, pistas ni solución.
static func plan_presentacion(movimiento_reducido: bool) -> Dictionary:
	return {
		"modo_efecto_remoto": "estado_discreto" if movimiento_reducido else "desplazamiento_breve",
		"duracion": 0.0 if movimiento_reducido else 0.22,
		"sacudida_camara": false,
		"oscilacion_geometria": false if movimiento_reducido else true,
		"pistas_visuales": true,
	}


static func _aplicar_delta_nodo(nodos: Dictionary, id_nodo: String, delta: int) -> void:
	if not nodos.has(id_nodo):
		return
	var nodo: Dictionary = nodos[id_nodo]
	nodo["valor"] = clampi(int(nodo.get("valor", 0)) + delta, -2, 2)
	nodos[id_nodo] = nodo


func _ready() -> void:
	preparar()


func preparar() -> void:
	if not _estado.is_empty():
		return
	_estado = estado_inicial()
	_montar_prototipo()
	_aplicar_estado_visual()


func estado_actual() -> Dictionary:
	return _estado.duplicate(true)


func usar_conexion(id_conexion: String, accion: String) -> Dictionary:
	preparar()
	_estado = manipular_conexion(_estado, id_conexion, accion)
	_aplicar_estado_visual()
	return _estado.duplicate(true)


func deshacer() -> Dictionary:
	preparar()
	_estado = revertir_ultima(_estado)
	_aplicar_estado_visual()
	return _estado.duplicate(true)


func _al_usar_hilo(_actor: Node, id_conexion: String) -> void:
	var conexiones: Dictionary = _estado.get("conexiones", {})
	var conexion: Dictionary = conexiones.get(id_conexion, {})
	var accion := "reconectar"
	if bool(conexion.get("activa", true)):
		accion = "aflojar" if int(conexion.get("tension", 0)) > 0 else "tensar"
	usar_conexion(id_conexion, accion)


func _montar_prototipo() -> void:
	_crear_caja(self, "Suelo", Vector3(13.0, 0.25, 9.0), Vector3(0.0, -0.15, 0.0), COLOR_SUELO)

	var nodos: Dictionary = _estado["nodos"]
	for id_nodo in nodos.keys():
		var datos: Dictionary = nodos[id_nodo]
		var nodo := Node3D.new()
		nodo.name = "Nodo_%s" % id_nodo
		nodo.position = datos["pos"]
		add_child(nodo)
		_crear_caja(nodo, "Cuerpo", Vector3(1.25, 1.25, 1.25), Vector3.ZERO, COLOR_NODO)
		_nodos_visuales[id_nodo] = nodo

	var conexiones: Dictionary = _estado["conexiones"]
	for id_conexion in conexiones.keys():
		var datos: Dictionary = conexiones[id_conexion]
		var origen_datos: Dictionary = nodos[String(datos["origen"])]
		var destino_datos: Dictionary = nodos[String(datos["destino"])]
		var origen: Vector3 = origen_datos["pos"]
		var destino: Vector3 = destino_datos["pos"]
		var hilo := _crear_hilo(id_conexion, origen, destino, bool(datos.get("real", false)))
		_hilos_visuales[id_conexion] = hilo

	var luz := DirectionalLight3D.new()
	luz.name = "LuzGeneral"
	luz.rotation_degrees = Vector3(-58.0, -24.0, 0.0)
	luz.light_energy = 1.05
	add_child(luz)

	var camara := Camera3D.new()
	camara.name = "CamaraStandalone"
	camara.position = Vector3(0.0, 8.2, 13.0)
	camara.rotation_degrees = Vector3(-25.0, 0.0, 0.0)
	camara.current = true
	add_child(camara)


func _crear_hilo(
	id_conexion: String, origen: Vector3, destino: Vector3, real: bool
) -> Interactuable3D:
	var hilo := Interactuable3D.new()
	hilo.name = "Hilo_%s" % id_conexion
	hilo.verbo = Interactuable3D.Verbo.USAR
	hilo.nombre_objeto = "hilo"
	hilo.sonido = Interactuable3D.SIN_SONIDO
	hilo.position = origen.lerp(destino, 0.5) + Vector3(0.0, 0.65, 0.0)
	hilo.set_meta("anansi_conexion", id_conexion)
	hilo.set_meta("anansi_pista", String(CONEXIONES_BASE[id_conexion]["pista"]))
	hilo.activado.connect(_al_usar_hilo.bind(id_conexion))
	add_child(hilo)
	hilo.look_at(destino + Vector3(0.0, 0.65, 0.0), Vector3.UP)

	var largo := maxf(origen.distance_to(destino), 0.25)
	_crear_caja(
		hilo,
		"Visual",
		Vector3(0.10, 0.10, largo),
		Vector3.ZERO,
		COLOR_HILO if real else COLOR_SENUELO,
	)

	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.38, 0.38, largo)
	colision.shape = forma
	hilo.add_child(colision)

	if not real:
		_crear_caja(
			hilo,
			"PistaOrientacion",
			Vector3(0.75, 0.08, 0.18),
			Vector3(0.0, 0.22, 0.0),
			COLOR_PISTA,
		)
	return hilo


func _aplicar_estado_visual() -> void:
	if _estado.is_empty():
		return
	var plan := plan_presentacion(reduccion_movimiento)
	var nodos: Dictionary = _estado.get("nodos", {})
	for id_nodo in nodos.keys():
		if not _nodos_visuales.has(id_nodo):
			continue
		var datos: Dictionary = nodos[id_nodo]
		var objetivo: Vector3 = datos["pos"] + Vector3(0.0, float(datos.get("valor", 0)) * 0.45, 0.0)
		var visual: Node3D = _nodos_visuales[id_nodo]
		if reduccion_movimiento:
			visual.position = objetivo
		else:
			var tween := create_tween()
			tween.tween_property(visual, "position", objetivo, float(plan["duracion"]))

	var conexiones: Dictionary = _estado.get("conexiones", {})
	for id_conexion in conexiones.keys():
		if not _hilos_visuales.has(id_conexion):
			continue
		var hilo: Interactuable3D = _hilos_visuales[id_conexion]
		var visual := hilo.get_node_or_null("Visual") as MeshInstance3D
		if visual == null:
			continue
		var datos: Dictionary = conexiones[id_conexion]
		var color := COLOR_SENUELO
		if bool(datos.get("real", false)):
			color = COLOR_HILO_TENSO if int(datos.get("tension", 0)) != 0 else COLOR_HILO
		visual.material_override = _material(color)
		visual.visible = bool(datos.get("activa", true))

	set_meta("anansi_estado", _estado.duplicate(true))
	set_meta("anansi_resuelto", bool(_estado.get("resuelto", false)))


func _crear_caja(
	padre: Node,
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
	material.roughness = 0.78
	return material
