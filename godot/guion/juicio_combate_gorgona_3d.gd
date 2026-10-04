## Presentación autónoma de Gorgona sobre CONTROLADOR (#2328 / #2087).
##
## Consume exclusivamente la salida pública del runtime CONTROLADOR. No avanza
## timers, no aplica daño/petrificación y no decide selección cultural.
class_name JuicioCombateGorgona3D
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const CONTROLADOR = preload("res://guion/juicio_combate_controlador_3d.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")

const COLOR_PREPARAR := Color(0.58, 0.72, 0.38, 0.34)
const COLOR_ACTIVA := Color(0.72, 0.92, 0.42, 0.58)
const COLOR_OJO := Color(0.82, 0.90, 0.62)
const ALTURA_CONO := 0.045


static func montar(anfitrion: Node3D) -> Dictionary:
	if anfitrion == null:
		return {}
	var raiz := Node3D.new()
	raiz.name = "GorgonaControlador2328"
	anfitrion.add_child(raiz)

	var ojo := MeshInstance3D.new()
	ojo.name = "Ojo"
	var esfera := SphereMesh.new()
	esfera.radius = 0.13
	esfera.height = 0.26
	ojo.mesh = esfera
	ojo.position = Vector3(0.0, 1.55, 0.0)
	ojo.material_override = FEEDBACK.material(COLOR_OJO, true)
	raiz.add_child(ojo)

	var cono := MeshInstance3D.new()
	cono.name = "ConoMirada"
	cono.mesh = _malla_cono()
	cono.position.y = ALTURA_CONO
	cono.visible = false
	raiz.add_child(cono)

	return {
		"raiz": raiz,
		"ojo": ojo,
		"cono": cono,
		"estado_visual": "",
	}


static func pintar(
	presentacion: Dictionary,
	salida_controlador: Dictionary,
	reduccion_movimiento: bool,
) -> void:
	var raiz := presentacion.get("raiz") as Node3D
	var ojo := presentacion.get("ojo") as MeshInstance3D
	var cono := presentacion.get("cono") as MeshInstance3D
	if raiz == null or ojo == null or cono == null:
		return

	var unidad: Dictionary = salida_controlador.get("unidad", {})
	var estado := String(unidad.get("estado", ""))
	var geometria: Dictionary = salida_controlador.get(
		"geometria",
		CONTROLADOR.geometria(unidad),
	)
	var rumbo := float(geometria.get("rumbo", 0.0))
	var origen: Vector3 = geometria.get("origen", Vector3.ZERO)

	raiz.position = origen
	raiz.rotation = Vector3(0.0, rumbo, 0.0)
	cono.visible = estado in [ARQUETIPOS.MARCAR_ZONA, ARQUETIPOS.ACTIVAR_ZONA]

	if estado == ARQUETIPOS.MARCAR_ZONA:
		cono.material_override = _material_cono(COLOR_PREPARAR)
		ojo.scale = Vector3.ONE
		presentacion["estado_visual"] = "preparar"
	elif estado == ARQUETIPOS.ACTIVAR_ZONA:
		cono.material_override = _material_cono(COLOR_ACTIVA)
		ojo.scale = Vector3(1.12, 1.12, 1.12) if not reduccion_movimiento else Vector3.ONE
		presentacion["estado_visual"] = "activa"
	elif estado == ARQUETIPOS.RECUPERAR:
		cono.visible = false
		ojo.scale = Vector3(1.0, 0.72, 1.0)
		presentacion["estado_visual"] = "recuperar"
	else:
		cono.visible = false
		ojo.scale = Vector3.ONE
		presentacion["estado_visual"] = "espera"


static func limpiar(presentacion: Dictionary) -> void:
	var raiz := presentacion.get("raiz") as Node3D
	if raiz != null and is_instance_valid(raiz):
		raiz.queue_free()
	presentacion.clear()


static func _malla_cono() -> ImmediateMesh:
	var malla := ImmediateMesh.new()
	var mitad := CONTROLADOR.ZONA_ANCHO * 0.72
	var largo := CONTROLADOR.ZONA_LARGO
	malla.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	malla.surface_add_vertex(Vector3.ZERO)
	malla.surface_add_vertex(Vector3(-mitad, 0.0, largo))
	malla.surface_add_vertex(Vector3(mitad, 0.0, largo))
	malla.surface_end()
	return malla


static func _material_cono(color: Color) -> StandardMaterial3D:
	var material := FEEDBACK.material(color, true)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
