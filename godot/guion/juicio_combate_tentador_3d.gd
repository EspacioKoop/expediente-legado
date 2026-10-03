## Presentación placeholder del Tentador miniado (#2266 / #2088).
##
## Referencia formal: marginalia dracónica de Walters W.99, fol. 169r (CC0).
## Toma solo rasgos generales de drollerie: contorno oscuro, cuerpo plegado,
## gesto autorreferencial y posición marginal. No reproduce la miniatura ni
## incorpora figuras devocionales, texto litúrgico o símbolos sagrados.
class_name JuicioCombateTentador3D
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")

const COLOR_TINTA := Color(0.13, 0.10, 0.09)
const COLOR_PERGAMINO := Color(0.73, 0.61, 0.40)
const COLOR_ECO := Color(0.42, 0.56, 0.72, 0.34)
const COLOR_AVISO := Color(0.78, 0.34, 0.20, 0.38)


static func montar(rival: Node3D) -> Dictionary:
	if rival == null:
		return {}

	var raiz := Node3D.new()
	raiz.name = "TentadorMiniado"
	rival.add_child(raiz)

	var cuerpo := _caja(
		raiz,
		"CuerpoMarginal",
		Vector3(0.58, 1.08, 0.36),
		Vector3(0.0, 1.02, 0.0),
		COLOR_PERGAMINO,
	)
	cuerpo.rotation.z = deg_to_rad(-14.0)

	var lomo := _caja(
		raiz,
		"ContornoTinta",
		Vector3(0.68, 0.12, 0.42),
		Vector3(0.02, 1.47, 0.0),
		COLOR_TINTA,
	)
	lomo.rotation.z = deg_to_rad(18.0)

	var ala := _caja(
		raiz,
		"AlaMordida",
		Vector3(0.54, 0.58, 0.12),
		Vector3(-0.42, 1.18, -0.02),
		COLOR_TINTA,
	)
	ala.rotation.z = deg_to_rad(38.0)

	var hocico := _caja(
		raiz,
		"HocicoPlegado",
		Vector3(0.44, 0.22, 0.32),
		Vector3(0.29, 1.56, 0.07),
		COLOR_PERGAMINO,
	)
	hocico.rotation.z = deg_to_rad(-24.0)

	var eco := Node3D.new()
	eco.name = "EcoMimetico"
	eco.position = Vector3(0.26, 0.04, -0.18)
	eco.visible = false
	raiz.add_child(eco)
	_caja(
		eco,
		"EcoCuerpo",
		Vector3(0.58, 1.08, 0.36),
		Vector3(0.0, 1.02, 0.0),
		COLOR_ECO,
		true,
	).rotation.z = deg_to_rad(-14.0)
	_caja(
		eco,
		"EcoAla",
		Vector3(0.54, 0.58, 0.12),
		Vector3(-0.42, 1.18, -0.02),
		COLOR_ECO,
		true,
	).rotation.z = deg_to_rad(38.0)

	var aviso_linea := _aviso(
		raiz,
		"AvisoLinea",
		Vector3(0.18, 0.035, 4.8),
		Vector3(0.0, 0.04, -2.5),
	)
	var aviso_carga := _aviso(
		raiz,
		"AvisoCarga",
		Vector3(0.70, 0.035, 5.2),
		Vector3(0.0, 0.045, -2.7),
	)
	var aviso_corto := _aviso(
		raiz,
		"AvisoCorto",
		Vector3(1.65, 0.035, 1.65),
		Vector3(0.0, 0.04, -0.85),
	)
	var aviso_zona := _aviso(
		raiz,
		"AvisoZona",
		Vector3(2.20, 0.035, 2.20),
		Vector3(0.0, 0.04, -1.25),
	)

	return {
		"raiz": raiz,
		"cuerpo": cuerpo,
		"lomo": lomo,
		"ala": ala,
		"hocico": hocico,
		"eco": eco,
		"avisos": {
			"linea": aviso_linea,
			"carga_lineal": aviso_carga,
			"ataque_corto": aviso_corto,
			"zona": aviso_zona,
		},
	}


static func pintar(
	presentacion: Dictionary,
	salida_runtime: Dictionary,
	reduccion_movimiento: bool,
) -> void:
	var raiz := presentacion.get("raiz") as Node3D
	var cuerpo := presentacion.get("cuerpo") as MeshInstance3D
	var ala := presentacion.get("ala") as MeshInstance3D
	var hocico := presentacion.get("hocico") as MeshInstance3D
	var eco := presentacion.get("eco") as Node3D
	var avisos: Dictionary = presentacion.get("avisos", {})
	if raiz == null or cuerpo == null or ala == null or hocico == null or eco == null:
		return

	var estado_runtime: Dictionary = salida_runtime.get("estado", {})
	var unidad: Dictionary = estado_runtime.get("unidad", {})
	var estado := String(unidad.get("estado", ""))
	var patron := String(salida_runtime.get("patron_eco", ""))
	var telegraph := String(salida_runtime.get("telegraph", ""))
	var ventana := bool(salida_runtime.get("ventana_respuesta", false))
	var mostrando_eco := (
		estado in [ARQUETIPOS.TELEGRAFIAR_ECO, ARQUETIPOS.REPETIR]
		or not telegraph.is_empty()
	)

	raiz.rotation = Vector3.ZERO
	cuerpo.rotation.z = deg_to_rad(-14.0)
	ala.rotation.z = deg_to_rad(38.0)
	hocico.rotation.z = deg_to_rad(-24.0)
	eco.visible = mostrando_eco

	for clave in avisos:
		var aviso := avisos[clave] as MeshInstance3D
		if aviso != null:
			aviso.visible = mostrando_eco and clave == patron

	if estado == ARQUETIPOS.RECUPERAR or ventana:
		# La recuperación rompe el pliegue autorreferencial: silueta abierta,
		# eco apagado y sin aviso residual.
		eco.visible = false
		for clave in avisos:
			var aviso := avisos[clave] as MeshInstance3D
			if aviso != null:
				aviso.visible = false
		cuerpo.rotation.z = deg_to_rad(8.0)
		ala.rotation.z = deg_to_rad(72.0)
		hocico.rotation.z = deg_to_rad(12.0)
	elif estado == ARQUETIPOS.REPETIR:
		raiz.rotation.x = deg_to_rad(-8.0)
		hocico.rotation.z = deg_to_rad(-36.0)

	if reduccion_movimiento:
		# No hay tween ni oscilación decorativa: el mismo contrato se lee con
		# poses estáticas y visibilidad de eco/telegraph.
		raiz.rotation.x = 0.0


static func _aviso(
	padre: Node3D,
	nombre: String,
	tamano: Vector3,
	posicion: Vector3,
) -> MeshInstance3D:
	var aviso := _caja(padre, nombre, tamano, posicion, COLOR_AVISO, true)
	aviso.visible = false
	return aviso


static func _caja(
	padre: Node3D,
	nombre: String,
	tamano: Vector3,
	posicion: Vector3,
	color: Color,
	transparente: bool = false,
) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.name = nombre
	var malla := BoxMesh.new()
	malla.size = tamano
	pieza.mesh = malla
	pieza.position = posicion
	var material := FEEDBACK.material(color, transparente)
	if transparente:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pieza.material_override = material
	padre.add_child(pieza)
	return pieza
