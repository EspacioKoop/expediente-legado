## Vertical standalone inspirado específicamente en el Popol Wuj k’iche’ (#655).
##
## Traduce parejas, eco y correspondencia a una regla espacial propia de SIGA-98.
## No reconstruye Xibalbá, no representa pruebas rituales y no exige conocimiento
## cultural externo: la puerta responde únicamente a equivalencias visibles.
class_name SuenoPopolWuj
extends Node3D

const ID_MITO := "popol_wuj"
const CLAVE_SEMILLA := "semilla_onirica_popol_wuj"
const FUENTE_VIGILIA := "libro:popol_wuj_98"

const ARCHIVO_OESTE := "archivo_oeste"
const ARCHIVO_ESTE := "archivo_este"
const TELEFONO_OESTE := "telefono_oeste"
const TELEFONO_ESTE := "telefono_este"
const ELEMENTOS := [ARCHIVO_OESTE, ARCHIVO_ESTE, TELEFONO_OESTE, TELEFONO_ESTE]

const PAREJAS := {
	ARCHIVO_OESTE: ARCHIVO_ESTE,
	ARCHIVO_ESTE: ARCHIVO_OESTE,
	TELEFONO_OESTE: TELEFONO_ESTE,
	TELEFONO_ESTE: TELEFONO_OESTE,
}

const POSICIONES := {
	ARCHIVO_OESTE: Vector3(-5.2, 0.0, -2.8),
	ARCHIVO_ESTE: Vector3(5.2, 0.0, -2.8),
	TELEFONO_OESTE: Vector3(-5.2, 0.0, 2.2),
	TELEFONO_ESTE: Vector3(5.2, 0.0, 2.2),
}

const ESTADO_INICIAL := {
	ARCHIVO_OESTE: 0,
	ARCHIVO_ESTE: 1,
	TELEFONO_OESTE: 2,
	TELEFONO_ESTE: 0,
}

const COLOR_OESTE := Color(0.24, 0.31, 0.33)
const COLOR_ESTE := Color(0.31, 0.26, 0.25)
const COLOR_ECO := Color(0.73, 0.62, 0.34)
const COLOR_REFLEJO := Color(0.32, 0.42, 0.46)
const COLOR_RETORNO := Color(0.25, 0.47, 0.38)
const COLOR_PUERTA_CERRADA := Color(0.43, 0.24, 0.22)
const COLOR_PUERTA_ABIERTA := Color(0.28, 0.52, 0.34)

var _estado: Dictionary = ESTADO_INICIAL.duplicate(true)
var _montado := false
var _puerta: MeshInstance3D


static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


static func registrar_semilla(
	estado: Dictionary,
	inspecciones: int,
	pareja_comparada: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if inspecciones < 2 or not pareja_comparada:
		return false
	if estado.has("dia"):
		return SemillasOniricas.activar_semilla_onirica(estado, ID_MITO, fuente, intensidad)
	estado[CLAVE_SEMILLA] = true
	return true


static func plan_presentacion(reduccion_movimiento: bool) -> Dictionary:
	return {
		"modo": "corte_fundido" if reduccion_movimiento else "eco_breve",
		"duracion": 0.0 if reduccion_movimiento else 0.24,
		"desplazar_camara": false,
		"eco_visual": true,
		"eco_sonoro": true,
	}


func _ready() -> void:
	preparar()


func preparar() -> void:
	if _montado:
		return
	_montado = true
	_montar_arquitectura()
	_montar_elementos()
	_montar_ecos()
	_montar_retorno_y_puerta()
	_montar_luz_y_camara()
	_aplicar_estado_visual()


func estado_reproducible() -> Dictionary:
	return _estado.duplicate(true)


func pareja_de(elemento: String) -> String:
	return String(PAREJAS.get(elemento, ""))


func parejas_equivalentes() -> Dictionary:
	return {
		"archivadores": int(_estado[ARCHIVO_OESTE]) == int(_estado[ARCHIVO_ESTE]),
		"telefonos": int(_estado[TELEFONO_OESTE]) == int(_estado[TELEFONO_ESTE]),
	}


func puerta_abierta() -> bool:
	var equivalencias := parejas_equivalentes()
	return bool(equivalencias["archivadores"]) and bool(equivalencias["telefonos"])


func ruta_retorno_disponible() -> bool:
	return get_node_or_null("Retorno") != null


## Cada intervención cambia el origen un paso y produce un eco de dos pasos en
## su pareja. La relación es simétrica y modular (0..2), así que nunca exige
## sincronía ni reflejos rápidos: basta observar cuándo ambos estados coinciden.
func intervenir(elemento: String, reduccion_movimiento: bool = false) -> Dictionary:
	preparar()
	if not PAREJAS.has(elemento):
		return {
			"ok": false,
			"origen": elemento,
			"retorno_disponible": ruta_retorno_disponible(),
		}

	var pareja := String(PAREJAS[elemento])
	_estado[elemento] = wrapi(int(_estado[elemento]) + 1, 0, 3)
	_estado[pareja] = wrapi(int(_estado[pareja]) + 2, 0, 3)
	_aplicar_estado_visual()

	var salida := plan_presentacion(reduccion_movimiento)
	(
		salida
		. merge(
			{
				"ok": true,
				"origen": elemento,
				"eco_destino": pareja,
				"estado_origen": int(_estado[elemento]),
				"estado_eco": int(_estado[pareja]),
				"equivalencias": parejas_equivalentes(),
				"puerta_abierta": puerta_abierta(),
				"eco_util": true,
				"retorno_disponible": ruta_retorno_disponible(),
			},
			true
		)
	)
	return salida


func restaurar_estado(estado: Dictionary) -> void:
	for elemento in ELEMENTOS:
		_estado[elemento] = clampi(int(estado.get(elemento, ESTADO_INICIAL[elemento])), 0, 2)
	if _montado:
		_aplicar_estado_visual()


func _montar_arquitectura() -> void:
	_crear_caja(
		self,
		"CorredorOeste",
		Vector3(4.2, 0.18, 8.5),
		Vector3(-5.2, 0.0, 0.0),
		COLOR_OESTE.darkened(0.45)
	)
	_crear_caja(
		self,
		"CorredorEste",
		Vector3(4.2, 0.18, 8.5),
		Vector3(5.2, 0.0, 0.0),
		COLOR_ESTE.darkened(0.45)
	)
	_crear_caja(
		self,
		"VacioCentral",
		Vector3(3.6, 0.08, 8.5),
		Vector3(0.0, -0.18, 0.0),
		Color(0.04, 0.04, 0.05)
	)
	_crear_caja(
		self, "ReflejoArchivadores", Vector3(0.12, 2.8, 2.2), Vector3(0.0, 1.4, -2.8), COLOR_REFLEJO
	)
	_crear_caja(
		self, "ReflejoTelefonos", Vector3(0.12, 2.0, 2.2), Vector3(0.0, 1.0, 2.2), COLOR_REFLEJO
	)


func _montar_elementos() -> void:
	_crear_elemento(ARCHIVO_OESTE, POSICIONES[ARCHIVO_OESTE], COLOR_OESTE, Vector3(1.7, 2.4, 1.3))
	_crear_elemento(ARCHIVO_ESTE, POSICIONES[ARCHIVO_ESTE], COLOR_ESTE, Vector3(1.7, 2.4, 1.3))
	_crear_elemento(TELEFONO_OESTE, POSICIONES[TELEFONO_OESTE], COLOR_OESTE, Vector3(1.4, 1.0, 1.2))
	_crear_elemento(TELEFONO_ESTE, POSICIONES[TELEFONO_ESTE], COLOR_ESTE, Vector3(1.4, 1.0, 1.2))


func _crear_elemento(id: String, posicion: Vector3, color: Color, tam: Vector3) -> void:
	var contenedor := Node3D.new()
	contenedor.name = id
	contenedor.position = posicion
	add_child(contenedor)
	_crear_caja(contenedor, "Nucleo", tam, Vector3(0.0, tam.y * 0.5, 0.0), color)
	_crear_caja(
		contenedor,
		"Indicador",
		Vector3(0.55, 0.16, 0.55),
		Vector3(0.0, tam.y + 0.24, 0.0),
		COLOR_ECO,
	)


func _montar_ecos() -> void:
	var ecos := Node3D.new()
	ecos.name = "EcosCausales"
	add_child(ecos)
	_crear_tramo(ecos, "EcoArchivadores", POSICIONES[ARCHIVO_OESTE], POSICIONES[ARCHIVO_ESTE])
	_crear_tramo(ecos, "EcoTelefonos", POSICIONES[TELEFONO_OESTE], POSICIONES[TELEFONO_ESTE])


func _crear_tramo(padre: Node3D, nombre: String, a: Vector3, b: Vector3) -> void:
	var altura := Vector3(0.0, 0.45, 0.0)
	var inicio := a + altura
	var fin := b + altura
	var centro := (inicio + fin) * 0.5
	var longitud := inicio.distance_to(fin)
	var tramo := _crear_caja(padre, nombre, Vector3(0.16, 0.12, longitud), centro, COLOR_ECO)
	tramo.look_at_from_position(centro, fin, Vector3.UP)


func _montar_retorno_y_puerta() -> void:
	_crear_caja(self, "Retorno", Vector3(2.2, 0.20, 2.2), Vector3(-5.2, 0.12, 4.6), COLOR_RETORNO)
	_puerta = _crear_caja(
		self,
		"PuertaEquivalencia",
		Vector3(2.4, 3.4, 0.35),
		Vector3(5.2, 1.7, -4.35),
		COLOR_PUERTA_CERRADA
	)


func _montar_luz_y_camara() -> void:
	var luz := DirectionalLight3D.new()
	luz.name = "LuzGeneral"
	luz.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	luz.light_energy = 1.0
	add_child(luz)

	var camara := Camera3D.new()
	camara.name = "CamaraStandalone"
	camara.position = Vector3(0.0, 12.5, 16.5)
	camara.rotation_degrees = Vector3(-36.0, 0.0, 0.0)
	camara.current = true
	add_child(camara)


func _aplicar_estado_visual() -> void:
	for elemento in ELEMENTOS:
		var contenedor := get_node_or_null(elemento)
		if contenedor == null:
			continue
		var nivel := int(_estado[elemento])
		var indicador := contenedor.get_node_or_null("Indicador") as MeshInstance3D
		if indicador != null:
			indicador.scale = Vector3(1.0 + nivel * 0.18, 1.0, 1.0 + nivel * 0.18)
			indicador.position.y += 0.0
	if _puerta != null:
		var material := StandardMaterial3D.new()
		material.albedo_color = COLOR_PUERTA_ABIERTA if puerta_abierta() else COLOR_PUERTA_CERRADA
		material.roughness = 0.82
		material.emission_enabled = puerta_abierta()
		if material.emission_enabled:
			material.emission = COLOR_PUERTA_ABIERTA
			material.emission_energy_multiplier = 0.35
		_puerta.material_override = material


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
