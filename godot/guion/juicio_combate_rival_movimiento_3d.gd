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


static func avanzar(anfitrion, delta: float) -> void:
	var rival: CharacterBody3D = anfitrion.get("_rival")
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	var figura_rival: Node3D = anfitrion.get("_figura_rival")
	if rival == null or jugador == null:
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

	var arquetipo: Dictionary = anfitrion.get("_arquetipo")
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
	JuicioCombateEscenografia3D.andar(figura_rival, bool(paso["mover"]))
	if bool(paso["mover"]):
		var desplazamiento: Vector3 = paso["desplazamiento"]
		rival.position = (
			REGLAS
			. limitar_a_arena(
				rival.position + desplazamiento,
				float(anfitrion.get("_radio_arena")),
			)
		)
		if arquetipo.is_empty():
			rival.rotation.y = float(paso["rotacion_y"])
	elif bool(paso["iniciar_ataque"]):
		anfitrion.call("_iniciar_ataque_rival")
