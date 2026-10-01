## Tercer consumidor runtime del contrato ambiental de #1772.
##
## Materializa EMPUJAR como movimiento authored de un prop concreto. El limite
## de usos y la recarga viven aqui, no en la politica pura: evitan loops de
## interrupcion sin convertir la arena en fisica destructible ni tocar la IA.
class_name JuicioCombateAmbientalEmpujar1772
extends RefCounted

const ID_PROP := "silla-empujable-arena-1772"
const RADIO_USO := 1.8
const DESPLAZAMIENTO := 0.65
const USOS_MAX := 2
const RECARGA_SEGUNDOS := 0.8


static func montar(anfitrion: Node3D) -> Dictionary:
	var raiz := Node3D.new()
	raiz.name = "AmbientalEmpujar1772"
	anfitrion.add_child(raiz)

	var prop := AnimatableBody3D.new()
	prop.name = "SillaEmpujable1772"
	prop.position = Vector3(0.0, 0.45, -2.2)
	prop.collision_layer = 1
	prop.collision_mask = 0
	raiz.add_child(prop)

	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var malla := BoxMesh.new()
	malla.size = Vector3(0.55, 0.90, 0.55)
	visual.mesh = malla
	visual.material_override = _material(Color(0.30, 0.25, 0.18))
	prop.add_child(visual)

	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.55, 0.90, 0.55)
	colision.shape = forma
	prop.add_child(colision)

	return {
		"declaracion":
		(
			InteraccionCombateAmbiental
			. declaracion(
				ID_PROP,
				[InteraccionCombateAmbiental.EMPUJAR],
				"",
				DESPLAZAMIENTO,
			)
		),
		"estado": InteraccionCombateAmbiental.estado_inicial(),
		"prop": prop,
		"usos_restantes": USOS_MAX,
		"recarga": 0.0,
	}


static func empujar(
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
	var prop := runtime.get("prop") as AnimatableBody3D
	if prop == null or not is_instance_valid(prop):
		return _rechazo(estado, "prop_ausente")
	if prop.global_position.distance_to(posicion_jugador) > RADIO_USO:
		return _rechazo(estado, "fuera_de_alcance")

	# La politica es la autoridad para autorizar el verbo fuera/dentro de combate.
	if not combate_permitido:
		return (
			InteraccionCombateAmbiental
			. aplicar(
				declarado_bruto as Dictionary,
				estado,
				InteraccionCombateAmbiental.EMPUJAR,
				false,
			)
		)
	if int(runtime.get("usos_restantes", 0)) <= 0:
		return _rechazo(estado, "sin_usos")
	if float(runtime.get("recarga", 0.0)) > 0.0:
		return _rechazo(estado, "en_recarga")

	var direccion := prop.global_position - posicion_jugador
	direccion.y = 0.0
	if direccion.length() < 0.01:
		return _rechazo(estado, "sin_direccion")

	var resultado := (
		InteraccionCombateAmbiental
		. aplicar(
			declarado_bruto as Dictionary,
			estado,
			InteraccionCombateAmbiental.EMPUJAR,
			true,
		)
	)
	if not bool(resultado.get("ok", false)):
		return resultado

	var intencion: Dictionary = resultado.get("intencion", {})
	var metros := maxf(0.0, float(intencion.get("metros", 0.0)))
	prop.global_position += direccion.normalized() * metros
	runtime["usos_restantes"] = maxi(0, int(runtime.get("usos_restantes", 0)) - 1)
	runtime["recarga"] = RECARGA_SEGUNDOS
	return resultado


static func avanzar(runtime: Dictionary, delta: float) -> void:
	runtime["recarga"] = maxf(
		0.0,
		float(runtime.get("recarga", 0.0)) - maxf(delta, 0.0),
	)


static func _rechazo(estado: Dictionary, motivo: String) -> Dictionary:
	return {
		"ok": false,
		"estado": estado.duplicate(true),
		"verbo": InteraccionCombateAmbiental.EMPUJAR,
		"motivo": motivo,
		"intencion": {},
	}


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
