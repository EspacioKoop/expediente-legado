## Adaptador 3D del ENJAMBRE para JuicioCombate3D (#2158).
##
## Mantiene juntos los cuerpos, telegraphs y selección de objetivo del grupo.
## La política temporal sigue en JuicioCombateEnjambreRuntime y el daño/consecuencias
## siguen perteneciendo al host común.
class_name JuicioCombateEnjambreHost3D
extends RefCounted

const ARENA = preload("res://guion/juicio_combate_arena_3d.gd")
const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const ARQUETIPO_HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const RUNTIME = preload("res://guion/juicio_combate_enjambre_runtime.gd")
const RIVAL = preload("res://guion/juicio_combate_rival.gd")
const REGLAS = preload("res://guion/juicio_combate_reglas.gd")


static func montar(
	anfitrion: Node3D,
	rival_proxy: CharacterBody3D,
	acusado: Dictionary,
	mito_id: String,
	raiz: int,
	cantidad: int = 3,
	ocultar_proxy: bool = true,
) -> Dictionary:
	var unidades := ARQUETIPO_HOST.nuevo_enjambre(raiz, cantidad)
	var clave := String(acusado.get("id", acusado.get("nombre", "enjambre")))
	var montado := (
		ARENA
		. montar_enjambre(
			anfitrion,
			clave,
			JuicioCombateEscenografia3D.color_mito(mito_id),
			unidades.size(),
		)
	)
	if rival_proxy != null and ocultar_proxy:
		rival_proxy.visible = false
	return {
		"unidades": unidades,
		"actores": montado.get("actores", []),
	}


## Avanza solo la política y la lectura visual. Devuelve distancias de los
## ataques que entran este tick; el host común decide esquiva, daño y derrota.
static func avanzar(estado: Dictionary, delta: float, posicion_jugador: Vector3) -> Array:
	var unidades: Array = estado.get("unidades", [])
	if unidades.is_empty():
		return []
	var paso := (
		RUNTIME
		. tick(
			unidades,
			delta,
			ARQUETIPO_HOST.presupuesto_enjambre(),
		)
	)
	estado["unidades"] = paso.get("unidades", unidades)
	return presentar_paso(estado, paso, posicion_jugador)


## Proyecta un paso ya calculado por otra composición. No vuelve a avanzar
## la política: la arena mixta usa esta entrada para conservar un solo tick.
static func presentar_paso(
	estado: Dictionary, paso: Dictionary, posicion_jugador: Vector3
) -> Array:
	var unidades: Array = estado.get("unidades", [])
	var resultados: Array = paso.get("resultados", [])
	for indice in range(unidades.size()):
		var actor := _actor(estado, indice)
		if actor.is_empty():
			continue
		var aviso: MeshInstance3D = actor.get("aviso")
		if aviso == null or not is_instance_valid(aviso):
			continue
		var resultado: Dictionary = resultados[indice] if indice < resultados.size() else {}
		aviso.visible = (
			int(unidades[indice].get("determinacion", 0)) > 0
			and String(resultado.get("telegraph", "")) == "ataque_corto"
		)

	var ataques := []
	for indice_variant in paso.get("inicio_ataque", []):
		var indice := int(indice_variant)
		var actor := _actor(estado, indice)
		if actor.is_empty():
			continue
		var cuerpo: CharacterBody3D = actor.get("cuerpo")
		if cuerpo == null or not is_instance_valid(cuerpo):
			continue
		ataques.append((cuerpo.position - posicion_jugador).length())

	for indice_variant in paso.get("abrir_ventana", []):
		var actor := _actor(estado, int(indice_variant))
		if actor.is_empty():
			continue
		var figura: Node3D = actor.get("figura")
		if figura != null and is_instance_valid(figura):
			JuicioCombateEscenografia3D.gesto(figura, "encajar")
	return ataques


static func mover(
	estado: Dictionary,
	posicion_jugador: Vector3,
	radio_arena: float,
	velocidad_rival: float,
	enredo: float,
	ritual: Dictionary,
	delta: float,
) -> void:
	var unidades: Array = estado.get("unidades", [])
	for indice in range(unidades.size()):
		var unidad: Dictionary = unidades[indice]
		if int(unidad.get("determinacion", 0)) <= 0:
			continue
		var actor := _actor(estado, indice)
		if actor.is_empty():
			continue
		var cuerpo: CharacterBody3D = actor.get("cuerpo")
		var figura: Node3D = actor.get("figura")
		if cuerpo == null or not is_instance_valid(cuerpo):
			continue
		var hacia := posicion_jugador - cuerpo.position
		hacia.y = 0.0
		if hacia.length() > 0.01:
			cuerpo.rotation.y = atan2(hacia.x, hacia.z)
		if String(unidad.get("estado", "")) != ARQUETIPOS.ESPERA:
			if figura != null and is_instance_valid(figura):
				JuicioCombateEscenografia3D.andar(figura, false)
			continue
		var movimiento := (
			RIVAL
			. plan_movimiento(
				posicion_jugador,
				cuerpo.position,
				0.0,
				velocidad_rival,
				enredo,
				ritual,
				delta,
			)
		)
		if figura != null and is_instance_valid(figura):
			JuicioCombateEscenografia3D.andar(figura, bool(movimiento["mover"]))
		if bool(movimiento["mover"]):
			var desplazamiento: Vector3 = movimiento["desplazamiento"]
			cuerpo.position = REGLAS.limitar_a_arena(cuerpo.position + desplazamiento, radio_arena)


static func objetivo(estado: Dictionary, posicion_jugador: Vector3) -> Dictionary:
	var unidades: Array = estado.get("unidades", [])
	var mejor := {}
	var mejor_distancia := INF
	for indice in range(unidades.size()):
		if int(unidades[indice].get("determinacion", 0)) <= 0:
			continue
		var actor := _actor(estado, indice)
		if actor.is_empty():
			continue
		var cuerpo: CharacterBody3D = actor.get("cuerpo")
		if cuerpo == null or not is_instance_valid(cuerpo):
			continue
		var distancia := (cuerpo.position - posicion_jugador).length_squared()
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor = {
				"indice": indice,
				"cuerpo": cuerpo,
				"figura": actor.get("figura"),
			}
	return mejor


static func aplicar_dano(estado: Dictionary, indice: int, dano: int) -> int:
	var unidades: Array = estado.get("unidades", [])
	if indice < 0 or indice >= unidades.size():
		return vivos(estado)
	var unidad: Dictionary = unidades[indice].duplicate(true)
	unidad["determinacion"] = maxi(0, int(unidad.get("determinacion", 0)) - maxi(0, dano))
	unidades[indice] = unidad
	estado["unidades"] = unidades
	if int(unidad["determinacion"]) <= 0:
		_retirar_actor(estado, indice)
	return vivos(estado)


static func vivos(estado: Dictionary) -> int:
	var total := 0
	for unidad in estado.get("unidades", []):
		if unidad is Dictionary and int(unidad.get("determinacion", 0)) > 0:
			total += 1
	return total


static func centro(estado: Dictionary, fallback: Vector3) -> Vector3:
	var unidades: Array = estado.get("unidades", [])
	var acumulado := Vector3.ZERO
	var cuerpos := 0
	for indice in range(unidades.size()):
		if int(unidades[indice].get("determinacion", 0)) <= 0:
			continue
		var actor := _actor(estado, indice)
		var cuerpo: CharacterBody3D = actor.get("cuerpo") if not actor.is_empty() else null
		if cuerpo == null or not is_instance_valid(cuerpo):
			continue
		acumulado += cuerpo.position
		cuerpos += 1
	return acumulado / float(cuerpos) if cuerpos > 0 else fallback


static func ocultar_avisos(estado: Dictionary) -> void:
	for actor_variant in estado.get("actores", []):
		if actor_variant is Dictionary:
			var aviso: MeshInstance3D = actor_variant.get("aviso")
			if aviso != null and is_instance_valid(aviso):
				aviso.visible = false


static func figura_final(estado: Dictionary, fallback: Node3D) -> Node3D:
	var unidades: Array = estado.get("unidades", [])
	for indice in range(unidades.size()):
		if int(unidades[indice].get("determinacion", 0)) <= 0:
			continue
		var actor := _actor(estado, indice)
		var figura: Node3D = actor.get("figura") if not actor.is_empty() else null
		if figura != null and is_instance_valid(figura):
			return figura
	return fallback


static func limpiar(estado: Dictionary) -> void:
	for actor_variant in estado.get("actores", []):
		if not (actor_variant is Dictionary):
			continue
		var cuerpo: CharacterBody3D = actor_variant.get("cuerpo")
		if cuerpo != null and is_instance_valid(cuerpo):
			cuerpo.queue_free()
	estado.clear()


static func _actor(estado: Dictionary, indice: int) -> Dictionary:
	var actores: Array = estado.get("actores", [])
	if indice < 0 or indice >= actores.size():
		return {}
	var actor = actores[indice]
	return actor if actor is Dictionary else {}


static func _retirar_actor(estado: Dictionary, indice: int) -> void:
	var actores: Array = estado.get("actores", [])
	if indice < 0 or indice >= actores.size():
		return
	var actor := _actor(estado, indice)
	if actor.is_empty():
		return
	var aviso: MeshInstance3D = actor.get("aviso")
	if aviso != null and is_instance_valid(aviso):
		aviso.visible = false
	var cuerpo: CharacterBody3D = actor.get("cuerpo")
	if cuerpo != null and is_instance_valid(cuerpo):
		cuerpo.queue_free()
	actor["cuerpo"] = null
	actor["figura"] = null
	actor["aviso"] = null
	actores[indice] = actor
	estado["actores"] = actores
