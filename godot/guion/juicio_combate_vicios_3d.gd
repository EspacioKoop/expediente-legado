## Presentación placeholder de Vicios alegóricos (#2270 / #2088).
##
## Tres siluetas abstractas sin rostro ni atributos humanos. Consume estados
## publicados por JuicioCombateViciosRuntime2088 y no avanza ENJAMBRE.
class_name JuicioCombateVicios3D
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")

const COLOR_CUERPO := Color(0.30, 0.23, 0.34)
const COLOR_ARISTA := Color(0.62, 0.45, 0.28)
const COLOR_AVISO := Color(0.88, 0.28, 0.16, 0.34)


static func montar(actores: Array) -> Dictionary:
	var cuerpos := []
	for indice in range(mini(3, actores.size())):
		var padre := _padre_actor(actores[indice])
		if padre == null:
			cuerpos.append({})
			continue
		cuerpos.append(_montar_cuerpo(padre, indice))
	return {"cuerpos": cuerpos}


static func pintar(
	presentacion: Dictionary,
	salida_runtime: Dictionary,
	reduccion_movimiento: bool,
) -> void:
	var cuerpos: Array = presentacion.get("cuerpos", [])
	var estado: Dictionary = salida_runtime.get("estado", {})
	var unidades: Array = estado.get("unidades", [])
	var resultados: Array = salida_runtime.get("resultados", [])

	for indice in range(cuerpos.size()):
		var cuerpo = cuerpos[indice]
		if not (cuerpo is Dictionary) or cuerpo.is_empty():
			continue
		var raiz := cuerpo.get("raiz") as Node3D
		var pieza_a := cuerpo.get("pieza_a") as MeshInstance3D
		var pieza_b := cuerpo.get("pieza_b") as MeshInstance3D
		var aviso := cuerpo.get("aviso") as MeshInstance3D
		if raiz == null or pieza_a == null or pieza_b == null or aviso == null:
			continue

		var unidad: Dictionary = unidades[indice] if indice < unidades.size() else {}
		var resultado: Dictionary = resultados[indice] if indice < resultados.size() else {}
		var vivo := int(unidad.get("determinacion", 0)) > 0
		var estado_unidad := String(unidad.get("estado", ""))
		var telegraph := String(resultado.get("telegraph", ""))

		raiz.visible = vivo
		if not vivo:
			aviso.visible = false
			continue

		_restaurar_pose(indice, pieza_a, pieza_b)
		aviso.visible = telegraph == "ataque_corto"

		if estado_unidad == ARQUETIPOS.RECUPERAR:
			# La ventana se lee como una figura que pierde tensión y se abre.
			aviso.visible = false
			pieza_a.rotation.z += deg_to_rad(24.0)
			pieza_b.rotation.z -= deg_to_rad(24.0)
			raiz.scale = Vector3(1.12, 0.88, 1.12)
		else:
			raiz.scale = Vector3.ONE

		if reduccion_movimiento:
			# No se usan tweens/oscilaciones: telegraph, visibilidad y pose son
			# señales estáticas con los mismos tiempos que dicta el runtime.
			raiz.rotation = Vector3.ZERO


static func _montar_cuerpo(padre: Node3D, indice: int) -> Dictionary:
	var raiz := Node3D.new()
	raiz.name = "VicioAlegorico%d" % indice
	padre.add_child(raiz)

	var pieza_a: MeshInstance3D
	var pieza_b: MeshInstance3D
	match indice:
		0:
			pieza_a = _caja(
				raiz,
				"PliegueA",
				Vector3(0.28, 1.12, 0.34),
				Vector3(-0.18, 0.92, 0.0),
				COLOR_CUERPO,
			)
			pieza_b = _caja(
				raiz,
				"PliegueB",
				Vector3(0.28, 0.86, 0.34),
				Vector3(0.20, 1.02, 0.0),
				COLOR_ARISTA,
			)
			pieza_a.rotation.z = deg_to_rad(-28.0)
			pieza_b.rotation.z = deg_to_rad(34.0)
		1:
			pieza_a = _caja(
				raiz,
				"Aguja",
				Vector3(0.26, 1.34, 0.30),
				Vector3(0.0, 1.02, 0.0),
				COLOR_ARISTA,
			)
			pieza_b = _caja(
				raiz,
				"Contrapeso",
				Vector3(0.72, 0.22, 0.32),
				Vector3(0.0, 0.76, 0.0),
				COLOR_CUERPO,
			)
			pieza_a.rotation.z = deg_to_rad(12.0)
			pieza_b.rotation.z = deg_to_rad(-14.0)
		_:
			pieza_a = _caja(
				raiz,
				"NudoA",
				Vector3(0.86, 0.24, 0.34),
				Vector3(0.0, 0.98, 0.0),
				COLOR_CUERPO,
			)
			pieza_b = _caja(
				raiz,
				"NudoB",
				Vector3(0.86, 0.24, 0.34),
				Vector3(0.0, 0.98, 0.0),
				COLOR_ARISTA,
			)
			pieza_a.rotation.z = deg_to_rad(42.0)
			pieza_b.rotation.z = deg_to_rad(-42.0)

	var aviso := MeshInstance3D.new()
	aviso.name = "AvisoCorto"
	var malla := CylinderMesh.new()
	malla.top_radius = 1.1
	malla.bottom_radius = 1.1
	malla.height = 0.025
	malla.radial_segments = 24
	aviso.mesh = malla
	aviso.position.y = 0.025
	var material := FEEDBACK.material(COLOR_AVISO, true)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aviso.material_override = material
	aviso.visible = false
	raiz.add_child(aviso)

	return {
		"raiz": raiz,
		"pieza_a": pieza_a,
		"pieza_b": pieza_b,
		"aviso": aviso,
	}


static func _restaurar_pose(
	indice: int,
	pieza_a: MeshInstance3D,
	pieza_b: MeshInstance3D,
) -> void:
	match indice:
		0:
			pieza_a.rotation.z = deg_to_rad(-28.0)
			pieza_b.rotation.z = deg_to_rad(34.0)
		1:
			pieza_a.rotation.z = deg_to_rad(12.0)
			pieza_b.rotation.z = deg_to_rad(-14.0)
		_:
			pieza_a.rotation.z = deg_to_rad(42.0)
			pieza_b.rotation.z = deg_to_rad(-42.0)


static func _padre_actor(actor) -> Node3D:
	if actor is Node3D:
		return actor
	if actor is Dictionary:
		var cuerpo = actor.get("cuerpo")
		return cuerpo as Node3D
	return null


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
