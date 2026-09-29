## Tercer desvío corto del trayecto (#1774): paso cubierto lateral.
##
## Es presentación pura sobre la calle existente. No crea fase, recompensa,
## inventario ni estado persistente. La geometría queda abierta y sin cuerpos
## sólidos para que entrar/salir nunca pueda bloquear el camino principal.
class_name DesvioRefugio3D
extends Node3D

const NOMBRE := "DesvioRefugioCubierto"
const POSICION := Vector3(-3.95, 0.0, 7.1)

const COLOR_METAL := Color(0.18, 0.19, 0.20)
const COLOR_HORMIGON := Color(0.34, 0.33, 0.31)
const COLOR_SUELO_SECO := Color(0.43, 0.39, 0.33)
const COLOR_AGUA := Color(0.17, 0.25, 0.31)
const COLOR_NIEVE := Color(0.78, 0.80, 0.78)


static func montar(calle: Node3D, jornada: Dictionary) -> DesvioRefugio3D:
	if calle == null:
		return null
	var existente := calle.get_node_or_null(NOMBRE) as DesvioRefugio3D
	if existente != null:
		return existente

	var refugio := DesvioRefugio3D.new()
	refugio.name = NOMBRE
	refugio.position = POSICION
	calle.add_child(refugio)

	var clima := clima_actual(jornada)
	refugio.set_meta("clima", clima)
	refugio.set_meta("precipitacion", Clima.precipitacion(clima))
	refugio._montar_base()
	refugio._montar_contexto_clima(clima)
	return refugio


static func clima_actual(jornada: Dictionary) -> String:
	var forzado := String(jornada.get("clima_forzado", "")).strip_edges()
	if not forzado.is_empty():
		return forzado
	return Clima.estado(int(jornada.get("dia", 1)))


func _montar_base() -> void:
	# Entrada y salida separadas hacen legible el bucle lateral sin puerta ni
	# teletransporte. Son marcadores, no triggers de progreso.
	_marcador("EntradaDesvio", Vector3(1.15, 0.0, -1.05))
	_marcador("SalidaDesvio", Vector3(1.15, 0.0, 1.05))
	_marcador("FondoRefugio", Vector3(-0.65, 0.0, 0.0))

	_caja(
		"TechoRefugio",
		Vector3(-0.15, 2.35, 0.0),
		Vector3(2.55, 0.14, 2.85),
		COLOR_METAL,
	)
	_caja(
		"ParedRefugio",
		Vector3(-1.30, 1.18, 0.0),
		Vector3(0.12, 2.36, 2.85),
		COLOR_HORMIGON,
	)
	_caja(
		"SueloSeco",
		Vector3(-0.12, 0.035, 0.0),
		Vector3(2.30, 0.07, 2.60),
		COLOR_SUELO_SECO,
	)
	_caja(
		"BancoRefugio",
		Vector3(-0.92, 0.52, 0.0),
		Vector3(0.48, 0.10, 1.35),
		Color(0.30, 0.23, 0.17),
	)

	# Nada de StaticBody3D/CollisionShape3D: el refugio no puede cerrar rutas.
	set_meta("sin_colision", true)
	set_meta("retorno_principal", true)


func _montar_contexto_clima(clima: String) -> void:
	if clima == Clima.LLUVIA:
		for z in [-1.12, -0.56, 0.0, 0.56, 1.12]:
			_caja(
				"GoteoBorde_%s" % str(z).replace(".", "_"),
				Vector3(1.12, 1.70, z),
				Vector3(0.025, 1.05, 0.025),
				Color(0.45, 0.62, 0.70),
			)
		_caja(
			"CharcoExterior",
			Vector3(1.28, 0.025, 0.0),
			Vector3(0.52, 0.05, 2.30),
			COLOR_AGUA,
		)
	elif clima == Clima.NIEVE:
		_caja(
			"NieveBordeTecho",
			Vector3(1.08, 2.45, 0.0),
			Vector3(0.16, 0.09, 2.70),
			COLOR_NIEVE,
		)
	elif clima == Clima.NIEBLA:
		_caja(
			"BalizaRefugio",
			Vector3(-1.16, 1.78, 0.0),
			Vector3(0.08, 0.22, 0.08),
			Color(0.88, 0.70, 0.38),
		)


func _marcador(nombre: String, posicion: Vector3) -> void:
	var marcador := Marker3D.new()
	marcador.name = nombre
	marcador.position = posicion
	add_child(marcador)


func _caja(nombre: String, posicion: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	malla.position = posicion
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	Modelos._pintar(malla, color)
	add_child(malla)
