## Movimiento 3D del rival de JuicioCombate3D.
##
## Aplica a cuerpos y presentación el plan producido por las reglas puras.
## No resuelve daño, victoria, doctrinas ni consecuencias.
class_name JuicioCombateRivalMovimiento3D
extends RefCounted

const RIVAL = preload("res://guion/juicio_combate_rival.gd")
const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const ARQUETIPO_HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const HOSTIGADOR_3D = preload("res://guion/juicio_combate_hostigador_3d.gd")
const ENJAMBRE_HOST_3D = preload("res://guion/juicio_combate_enjambre_host_3d.gd")
const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const OBSTACULO_1772 = preload("res://guion/juicio_combate_obstaculo_1772.gd")


static func avanzar(anfitrion, delta: float) -> void:
	var rival: CharacterBody3D = anfitrion.get("_rival")
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	var figura_rival: Node3D = anfitrion.get("_figura_rival")
	if rival == null or jugador == null:
		return

	var arquetipo: Dictionary = anfitrion.get("_arquetipo")
	if JuicioCombateVarianteHost3D.controla_movimiento(arquetipo):
		return

	var mixto: Dictionary = anfitrion.get("_mixto")
	if not mixto.is_empty():
		return

	var enjambre: Dictionary = anfitrion.get("_enjambre")
	if not enjambre.is_empty():
		(
			ENJAMBRE_HOST_3D
			. mover(
				enjambre,
				jugador.position,
				float(anfitrion.get("_radio_arena")),
				float(anfitrion.get("_velocidad_rival")),
				float(anfitrion.get("_enredo")),
				anfitrion.get("_ritual"),
				delta,
			)
		)
		rival.position = ENJAMBRE_HOST_3D.centro(enjambre, rival.position)
		return

	if bool(anfitrion.get("_ataque_rival_pendiente")):
		anfitrion.call("_actualizar_telegrafo_rival", delta)
		return

	if String(arquetipo.get("tipo", "")) == ARQUETIPOS.HOSTIGADOR:
		var host := (
			HOSTIGADOR_3D
			. mover(
				jugador.position,
				rival.position,
				rival.rotation.y,
				arquetipo,
				float(anfitrion.get("_radio_arena")),
				delta,
			)
		)
		rival.position = host["posicion"]
		rival.rotation.y = float(host["rotacion_y"])
		JuicioCombateEscenografia3D.andar(figura_rival, bool(host["andando"]))
		return

	if not ARQUETIPO_HOST.permite_iniciar_ataque(arquetipo):
		JuicioCombateEscenografia3D.andar(figura_rival, false)
		return

	var estado_temporal = anfitrion.get("_estado_temporal")
	var paso := (
		RIVAL
		. plan_movimiento(
			jugador.position,
			rival.position,
			float(estado_temporal.get("recarga_rival")),
			float(anfitrion.get("_velocidad_rival")),
			float(anfitrion.get("_enredo")),
			anfitrion.get("_ritual"),
			delta,
		)
	)
	var moviendo := bool(paso["mover"])
	var desplazamiento: Vector3 = paso.get("desplazamiento", Vector3.ZERO)
	if moviendo:
		var rodeo := plan_volcar(anfitrion, rival.position, jugador.position)
		match String(rodeo.get("intencion", "directo")):
			"esperar":
				moviendo = false
			"rodear":
				var direccion: Vector3 = rodeo.get("direccion", Vector3.ZERO)
				if direccion.is_zero_approx():
					moviendo = false
				else:
					desplazamiento = direccion.normalized() * desplazamiento.length()

	JuicioCombateEscenografia3D.andar(figura_rival, moviendo)
	if moviendo:
		rival.position = (
			REGLAS
			. limitar_a_arena(
				rival.position + desplazamiento,
				float(anfitrion.get("_radio_arena")),
			)
		)
		if arquetipo.is_empty():
			rival.rotation.y = atan2(desplazamiento.x, desplazamiento.z)
	elif bool(paso["iniciar_ataque"]):
		anfitrion.call("_iniciar_ataque_rival")


static func plan_volcar(
	anfitrion: Node3D,
	posicion_rival: Vector3,
	posicion_objetivo: Vector3,
) -> Dictionary:
	var runtime_bruto: Variant = anfitrion.get("_volcar_1772")
	if not runtime_bruto is Dictionary:
		return {}
	var runtime: Dictionary = runtime_bruto
	if runtime.is_empty() or float(runtime.get("restante", 0.0)) <= 0.0:
		return {}
	var prop := runtime.get("prop") as StaticBody3D
	if prop == null or not is_instance_valid(prop):
		return {}
	var volumen := prop.get_node_or_null("VolumenTemporal") as CollisionShape3D
	if volumen == null or not volumen.shape is BoxShape3D:
		return {}
	var radio := _radio_plano(prop, volumen, volumen.shape as BoxShape3D)
	if radio <= 0.0:
		return {}
	var obstaculo := {
		"activo": true,
		"centro": anfitrion.to_local(volumen.global_position),
		"radio": radio,
	}
	return (
		OBSTACULO_1772
		. planear(
			posicion_rival,
			posicion_objetivo,
			float(anfitrion.get("_radio_arena")),
			obstaculo,
			int(anfitrion.get("_raiz")),
		)
	)


static func _radio_plano(
	prop: StaticBody3D,
	volumen: CollisionShape3D,
	forma: BoxShape3D,
) -> float:
	var base := prop.transform.basis * volumen.transform.basis
	var mitad := forma.size * 0.5
	var alcance_x := absf(base.x.x) * mitad.x + absf(base.y.x) * mitad.y + absf(base.z.x) * mitad.z
	var alcance_z := absf(base.x.z) * mitad.x + absf(base.y.z) * mitad.y + absf(base.z.z) * mitad.z
	return Vector2(alcance_x, alcance_z).length()
