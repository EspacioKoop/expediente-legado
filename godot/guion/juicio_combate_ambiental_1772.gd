## Primer consumidor runtime del contrato ambiental de #1772.
##
## Deliberadamente solo materializa ACTIVAR. Empujar/volcar permanecen en la
## política pura hasta que un corte posterior resuelva física e IA sin
## convertir toda la arena en destructible. El estado es local al combate.
class_name JuicioCombateAmbiental1772
extends RefCounted

const ID_INTERRUPTOR := "interruptor-arena-1772"
const EFECTO_LUZ := "luz-arena-1772"
const RADIO_USO := 1.8


static func montar(anfitrion: Node3D) -> Dictionary:
	var raiz := Node3D.new()
	raiz.name = "Ambiental1772"
	anfitrion.add_child(raiz)

	var interruptor := Node3D.new()
	interruptor.name = "InterruptorAmbiental1772"
	interruptor.position = Vector3(2.4, 0.0, 0.0)
	raiz.add_child(interruptor)

	var placa := MeshInstance3D.new()
	var malla_placa := BoxMesh.new()
	malla_placa.size = Vector3(0.28, 0.48, 0.10)
	placa.mesh = malla_placa
	placa.position = Vector3(0.0, 0.78, 0.0)
	placa.material_override = _material(Color(0.16, 0.17, 0.15), false)
	interruptor.add_child(placa)

	var palanca := MeshInstance3D.new()
	var malla_palanca := BoxMesh.new()
	malla_palanca.size = Vector3(0.08, 0.20, 0.08)
	palanca.mesh = malla_palanca
	palanca.position = Vector3(0.0, 0.78, -0.08)
	palanca.rotation_degrees.x = -24.0
	palanca.material_override = _material(Color(0.62, 0.57, 0.42), true)
	interruptor.add_child(palanca)

	var luz := OmniLight3D.new()
	luz.name = "LuzAmbiental1772"
	luz.position = Vector3(1.0, 2.5, 0.0)
	luz.light_color = Color(0.82, 0.72, 0.48)
	luz.light_energy = 1.15
	luz.omni_range = 4.0
	luz.shadow_enabled = false
	luz.visible = false
	raiz.add_child(luz)

	return {
		"declaracion":
		(
			InteraccionCombateAmbiental
			. declaracion(
				ID_INTERRUPTOR,
				[InteraccionCombateAmbiental.ACTIVAR],
				EFECTO_LUZ,
			)
		),
		"estado": InteraccionCombateAmbiental.estado_inicial(),
		"prop": interruptor,
		"luz": luz,
	}


static func activar(
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
	var prop := runtime.get("prop") as Node3D
	if prop == null or not is_instance_valid(prop):
		return _rechazo(estado, "prop_ausente")
	if prop.global_position.distance_to(posicion_jugador) > RADIO_USO:
		return _rechazo(estado, "fuera_de_alcance")

	var resultado := (
		InteraccionCombateAmbiental
		. aplicar(
			declarado_bruto as Dictionary,
			estado,
			InteraccionCombateAmbiental.ACTIVAR,
			combate_permitido,
		)
	)
	if not bool(resultado.get("ok", false)):
		return resultado

	runtime["estado"] = (resultado.get("estado", {}) as Dictionary).duplicate(true)
	var luz := runtime.get("luz") as OmniLight3D
	if luz != null and is_instance_valid(luz):
		luz.visible = true
	return resultado


static func _rechazo(estado: Dictionary, motivo: String) -> Dictionary:
	return {
		"ok": false,
		"estado": estado.duplicate(true),
		"verbo": InteraccionCombateAmbiental.ACTIVAR,
		"motivo": motivo,
		"intencion": {},
	}


static func _material(color: Color, emision: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if emision:
		material.emission_enabled = true
		material.emission = color * 0.35
		material.emission_energy_multiplier = 0.55
	return material
