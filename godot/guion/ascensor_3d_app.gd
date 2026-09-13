## Presentación 3D del ascensor de #135.
##
## Hereda el reproductor común: skip, acortado y conteo de vistas siguen siendo
## exactamente los mismos. Esta capa solo construye un set 3D temporal —cabina,
## panel, puertas y portal— y responde al plano activo con cambios visuales.
extends "res://guion/cinematica_app.gd"

const ORIGEN := AscensorCinematica.ORIGEN

const ACERO := Color("666a6c")
const ACERO_OSCURO := Color("343638")
const PARED := Color("56595a")
const SUELO := Color("242526")
const PANEL := Color("1d1e20")
const LUZ_ON := Color("d69a48")
const LUZ_OFF := Color("4a4b4c")
const PORTAL := Color("8a806f")
const EXTERIOR := Color("111317")

var _cabina: Node3D
var _puerta_izquierda: MeshInstance3D
var _puerta_derecha: MeshInstance3D
var _luces_panel: Array[MeshInstance3D] = []
var _luz_techo: OmniLight3D


func _ready() -> void:
	_montar_cabina()
	plano_entrado.connect(_al_entrar_plano)
	super._ready()


func _montar_cabina() -> void:
	_cabina = Node3D.new()
	_cabina.name = "Cabina3D"
	_cabina.position = ORIGEN
	add_child(_cabina)

	# Caja del ascensor: proporciones estrechas, techo bajo y metal mate para
	# que se lea como un lugar concreto y no como otra sala rectangular.
	_caja("Suelo", Vector3(0, -1.45, 0), Vector3(3.8, 0.12, 3.8), SUELO, 0.05, 0.92)
	_caja("Techo", Vector3(0, 1.55, 0), Vector3(3.8, 0.12, 3.8), ACERO_OSCURO, 0.45, 0.48)
	_caja("ParedFondo", Vector3(0, 0, 1.9), Vector3(3.8, 3.0, 0.12), PARED, 0.30, 0.62)
	_caja("ParedIzquierda", Vector3(-1.9, 0, 0), Vector3(0.12, 3.0, 3.8), PARED, 0.30, 0.62)
	_caja("ParedDerecha", Vector3(1.9, 0, 0), Vector3(0.12, 3.0, 3.8), PARED, 0.30, 0.62)

	# Frente y marco. Las hojas son dos nodos independientes porque el último
	# plano las desliza físicamente antes de enseñar el portal.
	_caja("JambaIzquierda", Vector3(-1.62, 0, -1.9), Vector3(0.55, 3.0, 0.14), ACERO, 0.65, 0.38)
	_caja("JambaDerecha", Vector3(1.62, 0, -1.9), Vector3(0.55, 3.0, 0.14), ACERO, 0.65, 0.38)
	_caja("Dintel", Vector3(0, 1.37, -1.9), Vector3(2.75, 0.26, 0.14), ACERO, 0.65, 0.38)
	_puerta_izquierda = _caja(
		"PuertaIzquierda", Vector3(-0.82, -0.02, -1.84), Vector3(1.62, 2.68, 0.10), ACERO, 0.72, 0.30
	)
	_puerta_derecha = _caja(
		"PuertaDerecha", Vector3(0.82, -0.02, -1.84), Vector3(1.62, 2.68, 0.10), ACERO, 0.72, 0.30
	)
	_caja("JuntaPuerta", Vector3(0, -0.02, -1.78), Vector3(0.035, 2.62, 0.025), ACERO_OSCURO)

	# Pasamanos y zócalos rompen las superficies planas; siguen siendo geometría
	# muy barata y no añaden assets ni procedencia externa.
	_caja("PasamanosIzq", Vector3(-1.72, -0.28, 0.10), Vector3(0.10, 0.10, 2.85), ACERO, 0.75, 0.26)
	_caja("PasamanosDer", Vector3(1.72, -0.28, 0.10), Vector3(0.10, 0.10, 2.85), ACERO, 0.75, 0.26)
	_caja("ZocaloFondo", Vector3(0, -1.25, 1.78), Vector3(3.45, 0.20, 0.08), ACERO_OSCURO)

	# Panel de cinco plantas: mantiene la idea ya validada por #240 pero ahora
	# forma parte del espacio. No escribe números ni lore; solo desplaza la luz.
	_caja("Panel", Vector3(1.80, 0.18, -1.18), Vector3(0.08, 1.35, 0.54), PANEL, 0.15, 0.82)
	for i in 5:
		var piloto := _caja(
			"Piloto%d" % i,
			Vector3(1.735, 0.72 - float(i) * 0.27, -1.18),
			Vector3(0.035, 0.13, 0.13),
			LUZ_OFF,
			0.0,
			1.0,
			true
		)
		_luces_panel.append(piloto)

	# El plano final no abre a la calle ya montada, sino a un pequeño rellano
	# autocontenido. Así el set no depende de dónde esté el jugador en trayecto.
	_caja("RellanoSuelo", Vector3(0, -1.45, -3.15), Vector3(3.6, 0.12, 2.5), Color("46433e"))
	_caja("RellanoIzq", Vector3(-1.82, 0, -3.15), Vector3(0.12, 3.0, 2.5), PORTAL)
	_caja("RellanoDer", Vector3(1.82, 0, -3.15), Vector3(0.12, 3.0, 2.5), PORTAL)
	_caja("RellanoTecho", Vector3(0, 1.52, -3.15), Vector3(3.6, 0.12, 2.5), PORTAL)
	_caja("FondoPortal", Vector3(0, 0, -4.36), Vector3(3.6, 3.0, 0.10), PORTAL)
	_caja(
		"SalidaExterior",
		Vector3(0, -0.05, -4.28),
		Vector3(1.85, 2.40, 0.04),
		EXTERIOR,
		0.0,
		1.0,
		true
	)

	_luz_techo = OmniLight3D.new()
	_luz_techo.name = "FluorescenteCabina"
	_luz_techo.position = Vector3(0, 1.20, 0.15)
	_luz_techo.light_color = Color("e8e1cf")
	_luz_techo.light_energy = 2.2
	_luz_techo.omni_range = 5.5
	_cabina.add_child(_luz_techo)

	var luz_portal := OmniLight3D.new()
	luz_portal.name = "LuzRellano"
	luz_portal.position = Vector3(0, 1.05, -3.30)
	luz_portal.light_color = Color("d8bf96")
	luz_portal.light_energy = 1.3
	luz_portal.omni_range = 4.0
	_cabina.add_child(luz_portal)

	_marcar_planta(4)


func _al_entrar_plano(_indice: int, plano: Dictionary) -> void:
	match String(plano.get("nombre", "")):
		"planta-4":
			_cerrar_puertas()
			_marcar_planta(4)
		"bajada":
			_animar_bajada()
		"portal":
			_marcar_planta(0)
			_abrir_puertas()


func _animar_bajada() -> void:
	_marcar_planta(4)
	var panel := create_tween()
	for planta in [3, 2, 1]:
		panel.tween_interval(0.20)
		panel.tween_callback(_marcar_planta.bind(planta))

	# Un pequeño cambio de intensidad comunica movimiento mecánico sin marear ni
	# desplazar la cámara; reducción de movimiento sigue íntegra en el reproductor.
	var pulso := create_tween()
	pulso.tween_property(_luz_techo, "light_energy", 1.55, 0.14)
	pulso.tween_property(_luz_techo, "light_energy", 2.2, 0.20)


func _abrir_puertas() -> void:
	var puertas := create_tween().set_parallel(true)
	puertas.tween_property(_puerta_izquierda, "position:x", -1.58, 0.55)
	puertas.tween_property(_puerta_derecha, "position:x", 1.58, 0.55)


func _cerrar_puertas() -> void:
	_puerta_izquierda.position.x = -0.82
	_puerta_derecha.position.x = 0.82


func _marcar_planta(planta: int) -> void:
	var activa := clampi(4 - planta, 0, 4)
	for i in _luces_panel.size():
		_luces_panel[i].material_override = _material(
			LUZ_ON if i == activa else LUZ_OFF, 0.0, 1.0, true
		)


func _caja(
	nombre: String,
	posicion: Vector3,
	tamano: Vector3,
	color: Color,
	metalico: float = 0.0,
	rugosidad: float = 0.78,
	sin_luz: bool = false
) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var malla := BoxMesh.new()
	malla.size = tamano
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = _material(color, metalico, rugosidad, sin_luz)
	_cabina.add_child(nodo)
	return nodo


func _material(
	color: Color, metalico: float = 0.0, rugosidad: float = 0.78, sin_luz: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metalico
	material.roughness = rugosidad
	if sin_luz:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
