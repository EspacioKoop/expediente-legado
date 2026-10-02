## Runtime del ENJAMBRE onirico (#2120).
##
## El coordinador puro conserva estados y presupuesto. Esta capa mueve cuerpos,
## presenta telegraphs y expone ataques iniciados; no calcula dano al jugador.
class_name JuicioCombateEnjambreRuntime1771
extends RefCounted

const ARENA = preload("res://guion/juicio_combate_arena_3d.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const ESCENA = preload("res://guion/juicio_combate_escenografia_3d.gd")

const VELOCIDAD := 2.25
const DISTANCIA_CERCA := 1.35


static func montar(
	anfitrion: Node3D,
	clave_base: String,
	color: Color,
	raiz: int,
	cantidad: int = 3,
) -> Dictionary:
	var visual := ARENA.montar_enjambre(anfitrion, clave_base, color, cantidad)
	var total := int(visual.get("cantidad", 0))
	var actores: Array = visual.get("actores", [])
	for actor_variant in actores:
		var actor: Dictionary = actor_variant
		actor["vivo"] = true
	return {
		"actores": actores,
		"unidades": HOST.nuevo_enjambre(raiz, total),
	}


static func avanzar(runtime: Dictionary, delta: float) -> Dictionary:
	var actores: Array = runtime.get("actores", [])
	var unidades: Array = runtime.get("unidades", [])
	var vivas: Array = []
	var indices: Array[int] = []
	var anteriores: Array[String] = []
	for indice in range(mini(actores.size(), unidades.size())):
		if not _vivo(actores[indice], unidades[indice]):
			continue
		vivas.append(unidades[indice])
		indices.append(indice)
		anteriores.append(String(unidades[indice].get("estado", "")))
	var paso := HOST.avanzar_enjambre(vivas, delta)
	var nuevas: Array = paso.get("unidades", [])
	var resultados: Array = paso.get("resultados", [])
	var ataques: Array = []
	for local in range(indices.size()):
		var indice := indices[local]
		var nueva: Dictionary = nuevas[local]
		unidades[indice] = nueva
		_pintar_actor(actores[indice], nueva)
		if (
			String(nueva.get("estado", "")) == ARQUETIPOS.ATACAR
			and anteriores[local] != ARQUETIPOS.ATACAR
		):
			var cuerpo := actores[indice].get("cuerpo") as CharacterBody3D
			if cuerpo != null:
				ataques.append({"indice": indice, "posicion": cuerpo.position})
	runtime["unidades"] = unidades
	return {
		"ataques": ataques,
		"resultados": resultados,
		"atacantes_activos": int(paso.get("atacantes_activos", 0)),
	}


static func mover(
	runtime: Dictionary,
	posicion_jugador: Vector3,
	radio_arena: float,
	delta: float,
) -> void:
	var actores: Array = runtime.get("actores", [])
	var unidades: Array = runtime.get("unidades", [])
	for indice in range(mini(actores.size(), unidades.size())):
		if not _vivo(actores[indice], unidades[indice]):
			continue
		var cuerpo := actores[indice].get("cuerpo") as CharacterBody3D
		var figura := actores[indice].get("figura") as Node3D
		if cuerpo == null:
			continue
		var estado := String(unidades[indice].get("estado", ""))
		if estado != ARQUETIPOS.ESPERA:
			ESCENA.andar(figura, false)
			continue
		var hacia := posicion_jugador - cuerpo.position
		hacia.y = 0.0
		if hacia.length() < 0.01:
			ESCENA.andar(figura, false)
			continue
		var normal := hacia.normalized()
		var direccion := normal
		if hacia.length() <= DISTANCIA_CERCA:
			var lado := -1.0 if indice % 2 == 0 else 1.0
			direccion = Vector3(normal.z, 0.0, -normal.x) * lado
		cuerpo.position = REGLAS.limitar_a_arena(
			cuerpo.position + direccion * VELOCIDAD * delta, radio_arena
		)
		cuerpo.rotation.y = atan2(hacia.x, hacia.z)
		ESCENA.andar(figura, true)


static func objetivo(
	runtime: Dictionary, posicion_jugador: Vector3, alcance: float
) -> Dictionary:
	var actores: Array = runtime.get("actores", [])
	var unidades: Array = runtime.get("unidades", [])
	var mejor := {}
	var mejor_distancia := INF
	for indice in range(mini(actores.size(), unidades.size())):
		if not _vivo(actores[indice], unidades[indice]):
			continue
		var cuerpo := actores[indice].get("cuerpo") as CharacterBody3D
		if cuerpo == null:
			continue
		var distancia := cuerpo.position.distance_to(posicion_jugador)
		if distancia <= alcance and distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor = {
				"indice": indice,
				"cuerpo": cuerpo,
				"figura": actores[indice].get("figura"),
			}
	return mejor


static func aplicar_dano(runtime: Dictionary, indice: int, dano: int) -> bool:
	var actores: Array = runtime.get("actores", [])
	var unidades: Array = runtime.get("unidades", [])
	if indice < 0 or indice >= actores.size() or indice >= unidades.size() or dano <= 0:
		return false
	if not _vivo(actores[indice], unidades[indice]):
		return false
	var unidad: Dictionary = unidades[indice]
	unidad["determinacion"] = maxi(0, int(unidad.get("determinacion", 1)) - dano)
	unidades[indice] = unidad
	runtime["unidades"] = unidades
	if int(unidad["determinacion"]) > 0:
		return false
	var actor: Dictionary = actores[indice]
	actor["vivo"] = false
	var cuerpo := actor.get("cuerpo") as CharacterBody3D
	var aviso := actor.get("aviso") as MeshInstance3D
	if aviso != null:
		aviso.visible = false
	if cuerpo != null:
		cuerpo.visible = false
		cuerpo.process_mode = Node.PROCESS_MODE_DISABLED
	return true


static func aplicar_dano_repartido(runtime: Dictionary, dano: int) -> int:
	var restante := maxi(0, dano)
	var indice := 0
	while restante > 0 and indice < runtime.get("actores", []).size():
		if aplicar_dano(runtime, indice, 1):
			restante -= 1
		indice += 1
	return dano - restante


static func restantes(runtime: Dictionary) -> int:
	var actores: Array = runtime.get("actores", [])
	var unidades: Array = runtime.get("unidades", [])
	var total := 0
	for indice in range(mini(actores.size(), unidades.size())):
		if _vivo(actores[indice], unidades[indice]):
			total += 1
	return total


static func centro(runtime: Dictionary, fallback: Vector3) -> Vector3:
	var actores: Array = runtime.get("actores", [])
	var unidades: Array = runtime.get("unidades", [])
	var suma := Vector3.ZERO
	var total := 0
	for indice in range(mini(actores.size(), unidades.size())):
		if not _vivo(actores[indice], unidades[indice]):
			continue
		var cuerpo := actores[indice].get("cuerpo") as CharacterBody3D
		if cuerpo != null:
			suma += cuerpo.position
			total += 1
	return fallback if total == 0 else suma / float(total)


static func ocultar(runtime: Dictionary) -> void:
	for actor_variant in runtime.get("actores", []):
		var actor: Dictionary = actor_variant
		var aviso := actor.get("aviso") as MeshInstance3D
		if aviso != null:
			aviso.visible = false


static func _vivo(actor: Dictionary, unidad: Dictionary) -> bool:
	return bool(actor.get("vivo", false)) and int(unidad.get("determinacion", 0)) > 0


static func _pintar_actor(actor: Dictionary, unidad: Dictionary) -> void:
	var aviso := actor.get("aviso") as MeshInstance3D
	if aviso == null:
		return
	var estado := String(unidad.get("estado", ""))
	aviso.visible = estado in [ARQUETIPOS.TELEGRAFIAR, ARQUETIPOS.ATACAR]
