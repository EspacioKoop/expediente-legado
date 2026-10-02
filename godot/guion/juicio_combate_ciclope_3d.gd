## Presentación placeholder del Cíclope de Cantera (#2091/#2128).
##
## Esta capa consume estados del runtime EMBESTIDOR y solo cambia lectura visual.
## No mueve al rival, no calcula rumbo, no detecta colisiones y no aplica daño.
class_name JuicioCombateCiclope3D
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")

const COLOR_PIEDRA := Color(0.34, 0.30, 0.24)
const COLOR_PIEDRA_CLARA := Color(0.46, 0.40, 0.31)
const COLOR_OJO := Color(1.0, 0.56, 0.12)


static func montar(rival: Node3D) -> Dictionary:
	if rival == null:
		return {}

	var raiz := Node3D.new()
	raiz.name = "CiclopeCantera"
	rival.add_child(raiz)

	var torso := _caja(
		raiz,
		"TorsoPesado",
		Vector3(1.12, 1.36, 0.68),
		Vector3(0.0, 1.16, 0.0),
		COLOR_PIEDRA,
	)
	_caja(
		raiz,
		"HombroIzq",
		Vector3(0.46, 0.42, 0.58),
		Vector3(-0.67, 1.48, 0.0),
		COLOR_PIEDRA_CLARA,
	)
	_caja(
		raiz,
		"HombroDer",
		Vector3(0.46, 0.42, 0.58),
		Vector3(0.67, 1.48, 0.0),
		COLOR_PIEDRA_CLARA,
	)

	var cabeza := MeshInstance3D.new()
	cabeza.name = "Cabeza"
	var malla_cabeza := SphereMesh.new()
	malla_cabeza.radius = 0.43
	malla_cabeza.height = 0.78
	cabeza.mesh = malla_cabeza
	cabeza.position = Vector3(0.0, 2.08, 0.02)
	cabeza.material_override = FEEDBACK.material(COLOR_PIEDRA_CLARA)
	raiz.add_child(cabeza)

	var ojo := MeshInstance3D.new()
	ojo.name = "OjoCentral"
	var malla_ojo := SphereMesh.new()
	malla_ojo.radius = 0.105
	malla_ojo.height = 0.19
	ojo.mesh = malla_ojo
	ojo.scale = Vector3(1.2, 0.88, 0.55)
	ojo.position = Vector3(0.0, 2.09, 0.39)
	ojo.material_override = FEEDBACK.material(COLOR_OJO, true)
	raiz.add_child(ojo)

	var estela := MeshInstance3D.new()
	estela.name = "EstelaCarga"
	var malla_estela := BoxMesh.new()
	malla_estela.size = Vector3(0.82, 0.06, 1.8)
	estela.mesh = malla_estela
	var material_estela := FEEDBACK.material(Color(0.78, 0.30, 0.12, 0.34), true)
	material_estela.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	estela.material_override = material_estela
	estela.position = Vector3(0.0, 0.08, -1.02)
	estela.visible = false
	raiz.add_child(estela)

	return {
		"raiz": raiz,
		"torso": torso,
		"cabeza": cabeza,
		"ojo": ojo,
		"estela": estela,
	}


static func pintar(runtime: Dictionary, estado: String, reduccion_movimiento: bool) -> void:
	var raiz := runtime.get("raiz") as Node3D
	var cabeza := runtime.get("cabeza") as MeshInstance3D
	var ojo := runtime.get("ojo") as MeshInstance3D
	var estela := runtime.get("estela") as MeshInstance3D
	if raiz == null or cabeza == null or ojo == null or estela == null:
		return

	raiz.rotation.x = 0.0
	cabeza.position.y = 2.08
	cabeza.rotation.x = 0.0
	estela.visible = false

	match estado:
		ARQUETIPOS.TELEGRAFIAR:
			raiz.rotation.x = deg_to_rad(-9.0)
			cabeza.position.y = 2.00
			cabeza.rotation.x = deg_to_rad(-7.0)
		ARQUETIPOS.CARGAR:
			raiz.rotation.x = deg_to_rad(-15.0)
			cabeza.position.y = 1.96
			cabeza.rotation.x = deg_to_rad(-12.0)
			estela.visible = not reduccion_movimiento
		ARQUETIPOS.RECUPERAR:
			raiz.rotation.x = deg_to_rad(13.0)
			cabeza.position.y = 1.82
			cabeza.rotation.x = deg_to_rad(18.0)

	var material_ojo := ojo.material_override as StandardMaterial3D
	if material_ojo != null:
		material_ojo.emission_energy_multiplier = (
			1.45
			if estado == ARQUETIPOS.TELEGRAFIAR
			else (
				1.8
				if estado == ARQUETIPOS.CARGAR
				else 0.45 if estado == ARQUETIPOS.RECUPERAR else 0.8
			)
		)


static func _caja(
	padre: Node3D,
	nombre: String,
	tamano: Vector3,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.name = nombre
	var malla := BoxMesh.new()
	malla.size = tamano
	pieza.mesh = malla
	pieza.position = posicion
	pieza.material_override = FEEDBACK.material(color)
	padre.add_child(pieza)
	return pieza
