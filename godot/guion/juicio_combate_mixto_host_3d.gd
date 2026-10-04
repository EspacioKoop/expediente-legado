## Adaptador 3D autónomo de arena mixta ENJAMBRE + singular (#2295/#2342).
##
## JuicioCombateMixtoRuntime2067 conserva toda la autoridad de estado. Esta
## capa monta/pinta cuerpos y devuelve intención al host común; no aplica daño,
## no emite desenlace y no conoce Partida/Jornada.
class_name JuicioCombateMixtoHost3D
extends RefCounted

const RUNTIME = preload("res://guion/juicio_combate_mixto_runtime_2067.gd")
const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const ARQUETIPO_HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const ENJAMBRE_HOST = preload("res://guion/juicio_combate_enjambre_host_3d.gd")
const HOSTIGADOR_3D = preload("res://guion/juicio_combate_hostigador_3d.gd")
const BLOQUEADOR_3D = preload("res://guion/juicio_combate_bloqueador_3d.gd")


static func tipo_singular(raiz: int) -> String:
	var tirada := Azar.derivar(raiz, "combate", [2067, 2295])
	return ARQUETIPOS.BLOQUEADOR if tirada % 2 == 0 else ARQUETIPOS.HOSTIGADOR


static func montar(
	anfitrion: Node3D,
	rival_proxy: CharacterBody3D,
	acusado: Dictionary,
	mito_id: String,
	raiz: int,
	tipo_singular_forzado: String = "",
) -> Dictionary:
	if anfitrion == null or rival_proxy == null:
		return {}

	var tipo := tipo_singular_forzado
	if tipo not in [ARQUETIPOS.BLOQUEADOR, ARQUETIPOS.HOSTIGADOR]:
		tipo = tipo_singular(raiz)

	var runtime := RUNTIME.nuevo(raiz, tipo)
	var enjambre_visual := (
		ENJAMBRE_HOST
		. montar(
			anfitrion,
			rival_proxy,
			acusado,
			mito_id,
			raiz,
			RUNTIME.CANTIDAD_ENJAMBRE,
		)
	)
	if enjambre_visual.is_empty():
		return {}

	enjambre_visual["unidades"] = runtime.get("enjambre", []).duplicate(true)
	rival_proxy.visible = true

	var guardia: MeshInstance3D
	var linea: MeshInstance3D
	if tipo == ARQUETIPOS.BLOQUEADOR:
		guardia = BLOQUEADOR_3D.montar_guardia(rival_proxy)
	elif tipo == ARQUETIPOS.HOSTIGADOR:
		linea = HOSTIGADOR_3D.montar_linea(anfitrion)

	return {
		"runtime": runtime,
		"enjambre_visual": enjambre_visual,
		"tipo_singular": tipo,
		"rival_proxy": rival_proxy,
		"guardia": guardia,
		"linea": linea,
		"ultimo_paso": {},
	}


static func avanzar(
	estado: Dictionary,
	delta: float,
	posicion_jugador: Vector3,
	posicion_singular: Vector3,
	rotacion_y_singular: float = 0.0,
	guardia_rota: bool = false,
	derrotados_enjambre: Array = [],
	singular_derrotado: bool = false,
) -> Dictionary:
	if estado.is_empty():
		return _salida_vacia()

	var runtime: Dictionary = estado.get("runtime", {})
	if runtime.is_empty():
		return _salida_vacia()

	var singular_anterior: Dictionary = runtime.get("singular", {}).duplicate(true)
	var contexto := _contexto_singular(
		singular_anterior,
		posicion_singular,
		rotacion_y_singular,
		posicion_jugador,
		guardia_rota,
	)
	var paso := (
		RUNTIME
		. avanzar(
			runtime,
			maxf(0.0, delta),
			contexto,
			derrotados_enjambre,
			singular_derrotado,
		)
	)
	runtime = paso.get("estado", runtime)
	estado["runtime"] = runtime
	estado["ultimo_paso"] = paso

	var visual: Dictionary = estado.get("enjambre_visual", {})
	visual["unidades"] = runtime.get("enjambre", []).duplicate(true)
	estado["enjambre_visual"] = visual
	var ataques_enjambre := _presentar_enjambre(
		visual,
		paso.get("enjambre", {}),
		posicion_jugador,
	)

	var singular_actual: Dictionary = runtime.get("singular", {})
	var singular_vivo := bool(paso.get("singular_vivo", false))
	_presentar_singular(
		estado,
		singular_actual,
		paso.get("singular", {}),
		posicion_singular,
		singular_vivo,
	)
	var ataques_singular := _ataques_singular(
		singular_anterior,
		singular_actual,
		singular_vivo,
		posicion_singular,
	)

	return {
		"estado": estado,
		"ataques_enjambre": ataques_enjambre,
		"ataques_singular": ataques_singular,
		"ventana_respuesta": bool(paso.get("ventana_respuesta", false)),
		"vivos_enjambre": int(paso.get("vivos_enjambre", 0)),
		"singular_vivo": singular_vivo,
		"terminado": bool(paso.get("terminado", false)),
	}


static func objetivos_vivos(
	estado: Dictionary,
	posicion_jugador: Vector3,
	figura_singular: Node3D = null,
) -> Array:
	var objetivos: Array = []
	var visual: Dictionary = estado.get("enjambre_visual", {})
	var unidades: Array = visual.get("unidades", [])
	var actores: Array = visual.get("actores", [])
	for indice in range(unidades.size()):
		var unidad = unidades[indice]
		if not unidad is Dictionary or int(unidad.get("determinacion", 0)) <= 0:
			continue
		if indice >= actores.size() or not actores[indice] is Dictionary:
			continue
		var actor: Dictionary = actores[indice]
		var cuerpo := actor.get("cuerpo") as CharacterBody3D
		if cuerpo == null or not is_instance_valid(cuerpo):
			continue
		(
			objetivos
			. append(
				{
					"grupo": "enjambre",
					"indice": indice,
					"cuerpo": cuerpo,
					"figura": actor.get("figura"),
					"distancia2": cuerpo.position.distance_squared_to(posicion_jugador),
				}
			)
		)

	var runtime: Dictionary = estado.get("runtime", {})
	var rival := estado.get("rival_proxy") as CharacterBody3D
	if bool(runtime.get("singular_vivo", false)) and rival != null and is_instance_valid(rival):
		(
			objetivos
			. append(
				{
					"grupo": "singular",
					"indice": -1,
					"cuerpo": rival,
					"figura": figura_singular,
					"distancia2": rival.position.distance_squared_to(posicion_jugador),
				}
			)
		)

	objetivos.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("distancia2", INF)) < float(b.get("distancia2", INF))
	)
	return objetivos


static func terminado(estado: Dictionary) -> bool:
	return bool(estado.get("ultimo_paso", {}).get("terminado", false))


static func limpiar(estado: Dictionary) -> void:
	if estado.is_empty():
		return
	ENJAMBRE_HOST.limpiar(estado.get("enjambre_visual", {}))
	for clave in ["guardia", "linea"]:
		var nodo := estado.get(clave) as Node
		if nodo != null and is_instance_valid(nodo):
			nodo.queue_free()
	var rival := estado.get("rival_proxy") as CharacterBody3D
	if rival != null and is_instance_valid(rival):
		rival.visible = true
	estado.clear()


static func _contexto_singular(
	singular: Dictionary,
	posicion_singular: Vector3,
	rotacion_y_singular: float,
	posicion_jugador: Vector3,
	guardia_rota: bool,
) -> Dictionary:
	match String(singular.get("tipo", "")):
		ARQUETIPOS.HOSTIGADOR:
			return ARQUETIPO_HOST.contexto_hostigador(posicion_singular, posicion_jugador)
		ARQUETIPOS.BLOQUEADOR:
			return (
				ARQUETIPO_HOST
				. contexto(
					posicion_singular,
					rotacion_y_singular,
					posicion_jugador,
					guardia_rota,
				)
			)
		_:
			return {}


static func _presentar_enjambre(
	visual: Dictionary,
	paso_enjambre: Dictionary,
	posicion_jugador: Vector3,
) -> Array:
	var ataques: Array = []
	var unidades: Array = visual.get("unidades", [])
	var actores: Array = visual.get("actores", [])
	var resultados: Array = paso_enjambre.get("resultados", [])

	for indice in range(unidades.size()):
		if indice >= actores.size() or not actores[indice] is Dictionary:
			continue
		var actor: Dictionary = actores[indice]
		var aviso := actor.get("aviso") as MeshInstance3D
		var resultado: Dictionary = resultados[indice] if indice < resultados.size() else {}
		if aviso != null and is_instance_valid(aviso):
			aviso.visible = (
				int(unidades[indice].get("determinacion", 0)) > 0
				and String(resultado.get("telegraph", "")) == "ataque_corto"
			)

	for indice_variant in paso_enjambre.get("inicio_ataque", []):
		var indice := int(indice_variant)
		if indice < 0 or indice >= actores.size() or not actores[indice] is Dictionary:
			continue
		var cuerpo := (actores[indice] as Dictionary).get("cuerpo") as CharacterBody3D
		if cuerpo == null or not is_instance_valid(cuerpo):
			continue
		(
			ataques
			. append(
				{
					"grupo": "enjambre",
					"indice": indice,
					"distancia": cuerpo.position.distance_to(posicion_jugador),
				}
			)
		)

	for indice_variant in paso_enjambre.get("abrir_ventana", []):
		var indice := int(indice_variant)
		if indice < 0 or indice >= actores.size() or not actores[indice] is Dictionary:
			continue
		var figura := (actores[indice] as Dictionary).get("figura") as Node3D
		if figura != null and is_instance_valid(figura):
			JuicioCombateEscenografia3D.gesto(figura, "encajar")
	return ataques


static func _presentar_singular(
	estado: Dictionary,
	singular: Dictionary,
	paso_singular: Dictionary,
	posicion_singular: Vector3,
	vivo: bool,
) -> void:
	var rival := estado.get("rival_proxy") as CharacterBody3D
	if rival != null and is_instance_valid(rival):
		rival.visible = vivo

	var guardia := estado.get("guardia") as MeshInstance3D
	if guardia != null and is_instance_valid(guardia):
		guardia.visible = (vivo and String(singular.get("estado", "")) == ARQUETIPOS.GUARDIA)

	var linea := estado.get("linea") as MeshInstance3D
	if linea != null and is_instance_valid(linea):
		if not vivo:
			linea.visible = false
		else:
			(
				HOSTIGADOR_3D
				. pintar_linea(
					linea,
					posicion_singular,
					singular,
					String(paso_singular.get("telegraph", "")),
				)
			)


static func _ataques_singular(
	anterior: Dictionary,
	actual: Dictionary,
	vivo: bool,
	posicion_singular: Vector3,
) -> Array:
	if not vivo or String(actual.get("tipo", "")) != ARQUETIPOS.HOSTIGADOR:
		return []
	if (
		String(actual.get("estado", "")) != ARQUETIPOS.DISPARAR_LINEA
		or String(anterior.get("estado", "")) == ARQUETIPOS.DISPARAR_LINEA
	):
		return []
	return [
		{
			"grupo": "singular",
			"tipo": "linea",
			"origen": posicion_singular,
			"rumbo": float(actual.get("rumbo_bloqueado", 0.0)),
			"alcance": HOSTIGADOR_3D.LINEA_ALCANCE,
			"radio": HOSTIGADOR_3D.LINEA_RADIO,
		}
	]


static func _salida_vacia() -> Dictionary:
	return {
		"estado": {},
		"ataques_enjambre": [],
		"ataques_singular": [],
		"ventana_respuesta": false,
		"vivos_enjambre": 0,
		"singular_vivo": false,
		"terminado": false,
	}
