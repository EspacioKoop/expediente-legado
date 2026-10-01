## Segundo consumidor runtime del contrato ambiental de #1772.
##
## Materializa VOLCAR como un prop authored de un solo uso. El volumen fisico
## solo vive durante la ventana declarada por InteraccionCombateAmbiental; la
## pose volcada permanece como estado final. Este modulo no decide IA ni input.
class_name JuicioCombateAmbientalVolcar1772
extends RefCounted

const ID_PROP := "mueble-volcable-arena-1772"
const RADIO_USO := 1.8
const CAPA_OBSTACULO := 1


static func montar(anfitrion: Node3D) -> Dictionary:
	var raiz := Node3D.new()
	raiz.name = "AmbientalVolcar1772"
	anfitrion.add_child(raiz)

	var prop := StaticBody3D.new()
	prop.name = "MuebleVolcable1772"
	prop.position = Vector3(-2.3, 0.45, 0.0)
	prop.collision_layer = 0
	prop.collision_mask = 0
	raiz.add_child(prop)

	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var malla := BoxMesh.new()
	malla.size = Vector3(0.72, 0.90, 0.36)
	visual.mesh = malla
	visual.material_override = _material(Color(0.28, 0.24, 0.18))
	prop.add_child(visual)

	var colision := CollisionShape3D.new()
	colision.name = "VolumenTemporal"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.72, 0.90, 0.36)
	colision.shape = forma
	prop.add_child(colision)

	return {
		"declaracion":
		(
			InteraccionCombateAmbiental
			. declaracion(
				ID_PROP,
				[InteraccionCombateAmbiental.VOLCAR],
			)
		),
		"estado": InteraccionCombateAmbiental.estado_inicial(),
		"prop": prop,
		"restante": 0.0,
	}


static func volcar(
	runtime: Dictionary, posicion_jugador: Vector3, combate_permitido: bool
) -> Dictionary:
	var estado_bruto: Variant = runtime.get("estado", {})
	var estado := (
		(estado_bruto as Dictionary).duplicate(true)
		if estado_bruto is Dictionary
		else InteraccionCombateAmbiental.estado_inicial()
	)
	var declarado_bruto: Variant = runtime.get("declaracion", {})
	if not declarado_bruto is Dictionary:
		return _rechazo(estado, "sin_declaracion")
	var prop := runtime.get("prop") as StaticBody3D
	if prop == null or not is_instance_valid(prop):
		return _rechazo(estado, "prop_ausente")
	if prop.global_position.distance_to(posicion_jugador) > RADIO_USO:
		return _rechazo(estado, "fuera_de_alcance")

	var resultado := (
		InteraccionCombateAmbiental
		. aplicar(
			declarado_bruto as Dictionary,
			estado,
			InteraccionCombateAmbiental.VOLCAR,
			combate_permitido,
		)
	)
	if not bool(resultado.get("ok", false)):
		return resultado

	runtime["estado"] = (resultado.get("estado", {}) as Dictionary).duplicate(true)
	var intencion: Dictionary = resultado.get("intencion", {})
	runtime["restante"] = maxf(0.0, float(intencion.get("segundos", 0.0)))
	prop.rotation_degrees.z = 90.0
	prop.collision_layer = CAPA_OBSTACULO if float(runtime["restante"]) > 0.0 else 0
	return resultado


static func avanzar(runtime: Dictionary, delta: float) -> void:
	var restante := maxf(0.0, float(runtime.get("restante", 0.0)) - maxf(delta, 0.0))
	runtime["restante"] = restante
	var prop := runtime.get("prop") as StaticBody3D
	if prop == null or not is_instance_valid(prop):
		return
	if restante <= 0.0:
		prop.collision_layer = 0


static func _rechazo(estado: Dictionary, motivo: String) -> Dictionary:
	return {
		"ok": false,
		"estado": estado.duplicate(true),
		"verbo": InteraccionCombateAmbiental.VOLCAR,
		"motivo": motivo,
		"intencion": {},
	}


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material
