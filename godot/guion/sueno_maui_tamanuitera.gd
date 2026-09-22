## Vertical standalone del sueño māori de Māui y Tamanuiterā (#657).
##
## Toma del relato la relación entre luz y tiempo espacial, no una recreación
## literal. Dos tensores discretos reorientan una fuente solar imposible; las
## sombras resultantes pueden solaparse y convertirse en una ruta física.
class_name SuenoMauiTamanuitera
extends Node3D

const ID_MITO := "maui_tamanuitera"
const CLAVE_SEMILLA := "semilla_onirica_maui_tamanuitera"
const FUENTE_VIGILIA := "libro:maui_tamanuitera_98"
const LECTURAS_MINIMAS := 2

const TENSOR_PERSIANA := "persiana"
const TENSOR_CABLE := "cable"
const TENSOR_MIN := 0
const TENSOR_MAX := 2

const COLOR_SUELO := Color(0.18, 0.18, 0.17)
const COLOR_ARCHIVO := Color(0.33, 0.34, 0.31)
const COLOR_TENSOR := Color(0.62, 0.48, 0.26)
const COLOR_SOL := Color(0.95, 0.73, 0.28)
const COLOR_SOMBRA := Color(0.055, 0.055, 0.06)
const COLOR_SALIDA := Color(0.34, 0.52, 0.42)

var _tensor_persiana := 0
var _tensor_cable := 0
var _luz: DirectionalLight3D
var _sol: MeshInstance3D
var _sombra_a: MeshInstance3D
var _sombra_b: MeshInstance3D
var _puente: StaticBody3D
var _puente_colision: CollisionShape3D


static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


## El libro exige lectura deliberada y cierre consciente. Tenerlo en la escena
## o abrirlo una sola vez no activa la familia.
static func registrar_semilla(
	estado: Dictionary,
	paginas_leidas: int,
	libro_cerrado: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if paginas_leidas < LECTURAS_MINIMAS or not libro_cerrado:
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


## La geometría depende solo de los dos estados discretos. No hay tiempo real,
## aleatoriedad ni ventana de precisión: el jugador puede observar cada estado.
static func resolver_geometria(tensor_persiana: int, tensor_cable: int) -> Dictionary:
	var persiana := clampi(tensor_persiana, TENSOR_MIN, TENSOR_MAX)
	var cable := clampi(tensor_cable, TENSOR_MIN, TENSOR_MAX)
	var azimuts := [-48.0, -12.0, 24.0]
	var alturas := [24.0, 41.0, 60.0]
	var sombra_a_x := [-3.2, -1.2, 0.9]
	var sombra_b_x := [3.4, 1.3, -0.8]
	var rotaciones := [-24.0, 0.0, 24.0]
	var solapamiento := persiana == 2 and cable == 1
	return {
		"estado": "%d:%d" % [persiana, cable],
		"tensor_persiana": persiana,
		"tensor_cable": cable,
		"azimut_sol": azimuts[persiana],
		"altura_sol": alturas[cable],
		"sombra_a_x": sombra_a_x[persiana],
		"sombra_b_x": sombra_b_x[cable],
		"rotacion_sombra": rotaciones[persiana],
		"solapamiento": solapamiento,
		"puente_activo": solapamiento,
	}


static func plan_transicion(reduccion_movimiento: bool) -> Dictionary:
	return {
		"modo": "corte_fundido" if reduccion_movimiento else "fundido_breve",
		"duracion": 0.0 if reduccion_movimiento else 0.18,
		"barrido_solar": false,
		"mover_camara": false,
		"timing_precision": false,
	}


func _ready() -> void:
	_montar_prototipo()


func preparar() -> void:
	_montar_prototipo()
	_aplicar_estado()


func estado_actual() -> Dictionary:
	return resolver_geometria(_tensor_persiana, _tensor_cable)


func valor_tensor(nombre: String) -> int:
	if nombre == TENSOR_PERSIANA:
		return _tensor_persiana
	if nombre == TENSOR_CABLE:
		return _tensor_cable
	return -1


## Ajustar un tensor es una decisión por estados. `pasos` puede ser negativo y
## siempre queda acotado; reducción de movimiento no cambia el resultado lógico.
func ajustar_tensor(
	nombre: String,
	pasos: int = 1,
	reduccion_movimiento: bool = false,
) -> Dictionary:
	_montar_prototipo()
	if nombre == TENSOR_PERSIANA:
		_tensor_persiana = clampi(_tensor_persiana + pasos, TENSOR_MIN, TENSOR_MAX)
	elif nombre == TENSOR_CABLE:
		_tensor_cable = clampi(_tensor_cable + pasos, TENSOR_MIN, TENSOR_MAX)
	else:
		return {}
	_aplicar_estado()
	var resultado := estado_actual()
	resultado.merge(plan_transicion(reduccion_movimiento))
	return resultado


func puente_activo() -> bool:
	return estado_actual()["puente_activo"]


func colision_puente_activa() -> bool:
	return _puente_colision != null and not _puente_colision.disabled


func _montar_prototipo() -> void:
	if _luz != null:
		return

	var arquitectura := Node3D.new()
	arquitectura.name = "Arquitectura"
	add_child(arquitectura)

	_crear_bloque_colision(
		arquitectura,
		"PlataformaInicio",
		Vector3(7.0, 0.35, 6.0),
		Vector3(-5.2, -0.18, 0.0),
		COLOR_SUELO,
	)
	_crear_bloque_colision(
		arquitectura,
		"PlataformaSalida",
		Vector3(7.0, 0.35, 6.0),
		Vector3(5.2, -0.18, 0.0),
		COLOR_SUELO,
	)
	_crear_caja(
		arquitectura,
		"ArchivadorA",
		Vector3(1.7, 4.0, 1.4),
		Vector3(-3.0, 2.0, -2.0),
		COLOR_ARCHIVO,
	)
	_crear_caja(
		arquitectura,
		"ArchivadorB",
		Vector3(1.7, 5.2, 1.4),
		Vector3(3.0, 2.6, -2.0),
		COLOR_ARCHIVO,
	)
	_crear_caja(
		arquitectura,
		"TensorPersiana",
		Vector3(0.14, 5.0, 0.14),
		Vector3(-5.8, 2.5, 2.2),
		COLOR_TENSOR,
	)
	_crear_caja(
		arquitectura,
		"TensorCable",
		Vector3(0.14, 5.6, 0.14),
		Vector3(5.8, 2.8, 2.2),
		COLOR_TENSOR,
	)
	_crear_hotspot_tensor(
		arquitectura,
		"UsarTensorPersiana",
		TENSOR_PERSIANA,
		Vector3(-5.8, 2.5, 2.2),
		Vector3(0.8, 5.2, 0.8),
	)
	_crear_hotspot_tensor(
		arquitectura,
		"UsarTensorCable",
		TENSOR_CABLE,
		Vector3(5.8, 2.8, 2.2),
		Vector3(0.8, 5.8, 0.8),
	)

	_sombra_a = _crear_caja(
		arquitectura,
		"SombraArchivadorA",
		Vector3(5.4, 0.08, 1.35),
		Vector3(-3.2, 0.06, 0.3),
		COLOR_SOMBRA,
	)
	_sombra_b = _crear_caja(
		arquitectura,
		"SombraArchivadorB",
		Vector3(5.4, 0.08, 1.35),
		Vector3(3.4, 0.07, -0.3),
		COLOR_SOMBRA,
	)
	_puente = _crear_bloque_colision(
		arquitectura,
		"SombraPuente",
		Vector3(4.0, 0.20, 1.55),
		Vector3(0.0, 0.08, 0.0),
		COLOR_SOMBRA,
	)
	_puente_colision = _puente.get_node("Colision") as CollisionShape3D

	_crear_caja(
		arquitectura,
		"Salida",
		Vector3(1.5, 0.15, 1.5),
		Vector3(6.1, 0.10, 1.8),
		COLOR_SALIDA,
	)

	_sol = _crear_esfera(
		arquitectura,
		"Tamanuitera",
		1.25,
		Vector3(0.0, 7.5, -8.0),
		COLOR_SOL,
	)
	_luz = DirectionalLight3D.new()
	_luz.name = "LuzTamanuitera"
	_luz.light_energy = 1.2
	_luz.shadow_enabled = true
	add_child(_luz)

	var camara := Camera3D.new()
	camara.name = "CamaraStandalone"
	camara.position = Vector3(0.0, 8.5, 15.0)
	camara.rotation_degrees = Vector3(-24.0, 0.0, 0.0)
	camara.current = true
	add_child(camara)

	_aplicar_estado()


func _aplicar_estado() -> void:
	if _luz == null:
		return
	var estado := estado_actual()
	_luz.rotation_degrees = Vector3(
		-float(estado["altura_sol"]),
		float(estado["azimut_sol"]),
		0.0,
	)
	_sol.position.x = float(estado["azimut_sol"]) * 0.08
	_sol.position.y = 4.0 + float(estado["altura_sol"]) * 0.07
	_sombra_a.position.x = float(estado["sombra_a_x"])
	_sombra_b.position.x = float(estado["sombra_b_x"])
	_sombra_a.rotation_degrees.y = float(estado["rotacion_sombra"])
	_sombra_b.rotation_degrees.y = -float(estado["rotacion_sombra"])
	var activa := bool(estado["puente_activo"])
	_puente.visible = activa
	_puente_colision.disabled = not activa


func _al_usar_tensor(_actor: Node, nombre: String) -> void:
	var actual := valor_tensor(nombre)
	var pasos := -TENSOR_MAX if actual >= TENSOR_MAX else 1
	var reduccion := bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	ajustar_tensor(nombre, pasos, reduccion)


func _crear_hotspot_tensor(
	padre: Node3D,
	nombre: String,
	tensor: String,
	posicion: Vector3,
	tam: Vector3,
) -> Interactuable3D:
	var hotspot := Interactuable3D.new()
	hotspot.name = nombre
	hotspot.position = posicion
	hotspot.verbo = Interactuable3D.Verbo.USAR
	hotspot.nombre_objeto = "tensor de persiana" if tensor == TENSOR_PERSIANA else "tensor de cable"
	hotspot.sonido = Interactuable3D.SIN_SONIDO
	hotspot.collision_mask = 0
	hotspot.activado.connect(_al_usar_tensor.bind(tensor))
	padre.add_child(hotspot)

	var forma := BoxShape3D.new()
	forma.size = tam
	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	colision.shape = forma
	hotspot.add_child(colision)
	return hotspot


func _crear_bloque_colision(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.position = posicion
	padre.add_child(cuerpo)

	var malla := BoxMesh.new()
	malla.size = tam
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	visual.mesh = malla
	visual.material_override = _material(color)
	cuerpo.add_child(visual)

	var forma := BoxShape3D.new()
	forma.size = tam
	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	colision.shape = forma
	cuerpo.add_child(colision)
	return cuerpo


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


func _crear_esfera(
	padre: Node3D,
	nombre: String,
	radio: float,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var malla := SphereMesh.new()
	malla.radius = radio
	malla.height = radio * 2.0
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	var material := _material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.1
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material
