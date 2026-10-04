## Adaptador 3D de arena mixta ENJAMBRE + singular (#2295 / #2067).
##
## JuicioCombateMixtoRuntime2067 es la única autoridad de estado del grupo.
## Esta capa monta cuerpos, proyecta telegraphs/movimiento y devuelve impactos
## al host común; no decide daño, consecuencias ni progreso.
class_name JuicioCombateMixtoHost3D
extends RefCounted

const RUNTIME = preload("res://guion/juicio_combate_mixto_runtime_2067.gd")
const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const ARQUETIPO_HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const ENJAMBRE_HOST = preload("res://guion/juicio_combate_enjambre_host_3d.gd")
const HOSTIGADOR_3D = preload("res://guion/juicio_combate_hostigador_3d.gd")
const BLOQUEADOR_3D = preload("res://guion/juicio_combate_bloqueador_3d.gd")
const RIVAL = preload("res://guion/juicio_combate_rival.gd")
const REGLAS = preload("res://guion/juicio_combate_reglas.gd")

const DETERMINACION_SINGULAR := 1


static func tipo_singular(raiz: int) -> String:
	var tirada := Azar.derivar(raiz, "combate", [2067, 2295])
	return ARQUETIPOS.BLOQUEADOR if tirada % 2 == 0 else ARQUETIPOS.HOSTIGADOR


static func montar(
	anfitrion: Node3D,
	rival: CharacterBody3D,
	acusado: Dictionary,
	mito_id: String,
	raiz: int,
) -> Dictionary:
	if rival == null:
		return {}
	var tipo := tipo_singular(raiz)
	var runtime := RUNTIME.nuevo(raiz, tipo)
	var visual := (
		ENJAMBRE_HOST
		. montar(
			anfitrion,
			rival,
			acusado,
			mito_id,
			raiz,
			RUNTIME.CANTIDAD_ENJAMBRE,
			false,
		)
	)
	visual["unidades"] = runtime.get("enjambre", []).duplicate(true)
	rival.visible = true

	var guardia: MeshInstance3D
	var linea: MeshInstance3D
	if tipo == ARQUETIPOS.BLOQUEADOR:
		guardia = BLOQUEADOR_3D.montar_guardia(rival)
	elif tipo == ARQUETIPOS.HOSTIGADOR:
		linea = HOSTIGADOR_3D.montar_linea(anfitrion)

	return {
		"runtime": runtime,
		"enjambre_visual": visual,
		"tipo_singular": tipo,
		"singular_determinacion": DETERMINACION_SINGULAR,
		"guardia": guardia,
		"linea": linea,
		"ultimo_paso": {},
	}


static func avanzar(anfitrion, estado: Dictionary, delta: float) -> void:
	if estado.is_empty():
		return
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	var rival: CharacterBody3D = anfitrion.get("_rival")
	if jugador == null or rival == null:
		return

	var runtime: Dictionary = estado.get("runtime", {})
	var singular_anterior: Dictionary = runtime.get("singular", {})
	var contexto := _contexto_singular(anfitrion, singular_anterior, rival, jugador)
	if String(singular_anterior.get("tipo", "")) == ARQUETIPOS.BLOQUEADOR:
		anfitrion.set("_guardia_rota", false)

	var paso := RUNTIME.avanzar(runtime, delta, contexto)
	runtime = paso.get("estado", runtime)
	estado["runtime"] = runtime
	estado["ultimo_paso"] = paso

	var visual: Dictionary = estado.get("enjambre_visual", {})
	visual["unidades"] = runtime.get("enjambre", []).duplicate(true)
	estado["enjambre_visual"] = visual
	for distancia in ENJAMBRE_HOST.presentar_paso(
		visual,
		paso.get("enjambre", {}),
		jugador.position,
	):
		anfitrion.set("_rival_inicio_agresion", true)
		anfitrion.call(
			"_aplicar_impacto_rival",
			REGLAS.resultado_ataque_rival(float(distancia), float(anfitrion.get("_esquiva"))),
		)
		if bool(anfitrion.get("_acabado")):
			return

	(
		ENJAMBRE_HOST
		. mover(
			visual,
			jugador.position,
			float(anfitrion.get("_radio_arena")),
			float(anfitrion.get("_velocidad_rival")),
			float(anfitrion.get("_enredo")),
			anfitrion.get("_ritual"),
			delta,
		)
	)

	var singular: Dictionary = runtime.get("singular", {})
	anfitrion.set("_arquetipo", singular)
	if bool(paso.get("singular_vivo", false)):
		rival.visible = true
		_avanzar_singular(anfitrion, estado, singular_anterior, singular, paso.get("singular", {}), delta)
	else:
		_retirar_singular(anfitrion, estado)

	if bool(paso.get("terminado", false)):
		anfitrion.call("_terminar", true)


static func objetivo(
	estado: Dictionary,
	posicion_jugador: Vector3,
	rival: CharacterBody3D,
	figura_rival: Node3D,
) -> Dictionary:
	var mejor := {}
	var visual: Dictionary = estado.get("enjambre_visual", {})
	var enjambre := ENJAMBRE_HOST.objetivo(visual, posicion_jugador)
	if not enjambre.is_empty():
		mejor = enjambre.duplicate()
		mejor["grupo"] = "enjambre"

	var runtime: Dictionary = estado.get("runtime", {})
	if (
		bool(runtime.get("singular_vivo", false))
		and int(estado.get("singular_determinacion", 0)) > 0
		and rival != null
		and is_instance_valid(rival)
	):
		var distancia_singular := rival.position.distance_squared_to(posicion_jugador)
		var distancia_actual := INF
		if not mejor.is_empty():
			var cuerpo_actual: CharacterBody3D = mejor.get("cuerpo")
			if cuerpo_actual != null and is_instance_valid(cuerpo_actual):
				distancia_actual = cuerpo_actual.position.distance_squared_to(posicion_jugador)
		if distancia_singular <= distancia_actual:
			mejor = {
				"grupo": "singular",
				"indice": -1,
				"cuerpo": rival,
				"figura": figura_rival,
			}
	return mejor


static func aplicar_dano(estado: Dictionary, objetivo: Dictionary, dano: int) -> Dictionary:
	if estado.is_empty() or dano <= 0:
		return _resultado_dano(estado, false)

	var runtime: Dictionary = estado.get("runtime", {})
	var grupo := String(objetivo.get("grupo", ""))
	if grupo == "enjambre":
		var visual: Dictionary = estado.get("enjambre_visual", {})
		ENJAMBRE_HOST.aplicar_dano(visual, int(objetivo.get("indice", -1)), dano)
		runtime["enjambre"] = visual.get("unidades", []).duplicate(true)
		estado["enjambre_visual"] = visual
	elif grupo == "singular" and bool(runtime.get("singular_vivo", false)):
		var restante := maxi(0, int(estado.get("singular_determinacion", 0)) - dano)
		estado["singular_determinacion"] = restante
		if restante <= 0:
			runtime["singular_vivo"] = false

	var paso := RUNTIME.avanzar(runtime, 0.0)
	estado["runtime"] = paso.get("estado", runtime)
	estado["ultimo_paso"] = paso
	var visual_actual: Dictionary = estado.get("enjambre_visual", {})
	visual_actual["unidades"] = estado["runtime"].get("enjambre", []).duplicate(true)
	estado["enjambre_visual"] = visual_actual
	return _resultado_dano(estado, bool(paso.get("terminado", false)))


static func determinacion_total(estado: Dictionary) -> int:
	if estado.is_empty():
		return 0
	var runtime: Dictionary = estado.get("runtime", {})
	var visual: Dictionary = estado.get("enjambre_visual", {})
	var total := ENJAMBRE_HOST.vivos(visual)
	if bool(runtime.get("singular_vivo", false)):
		total += maxi(0, int(estado.get("singular_determinacion", 0)))
	return total


static func singular(estado: Dictionary) -> Dictionary:
	var runtime: Dictionary = estado.get("runtime", {})
	if not bool(runtime.get("singular_vivo", false)):
		return {}
	var valor = runtime.get("singular", {})
	return valor.duplicate(true) if valor is Dictionary else {}


static func terminado(estado: Dictionary) -> bool:
	return bool(estado.get("ultimo_paso", {}).get("terminado", false))


static func figura_final(estado: Dictionary, fallback: Node3D) -> Node3D:
	var runtime: Dictionary = estado.get("runtime", {})
	if bool(runtime.get("singular_vivo", false)) and fallback != null:
		return fallback
	return ENJAMBRE_HOST.figura_final(estado.get("enjambre_visual", {}), fallback)


static func limpiar(estado: Dictionary) -> void:
	if estado.is_empty():
		return
	ENJAMBRE_HOST.limpiar(estado.get("enjambre_visual", {}))
	var linea := estado.get("linea") as MeshInstance3D
	if linea != null and is_instance_valid(linea):
		linea.queue_free()
	estado.clear()


static func _contexto_singular(
	anfitrion,
	singular: Dictionary,
	rival: CharacterBody3D,
	jugador: CharacterBody3D,
) -> Dictionary:
	match String(singular.get("tipo", "")):
		ARQUETIPOS.HOSTIGADOR:
			return ARQUETIPO_HOST.contexto_hostigador(rival.position, jugador.position)
		ARQUETIPOS.BLOQUEADOR:
			return (
				ARQUETIPO_HOST
				. contexto(
					rival.position,
					rival.rotation.y,
					jugador.position,
					bool(anfitrion.get("_guardia_rota")),
				)
			)
		_:
			return {}


static func _avanzar_singular(
	anfitrion,
	estado: Dictionary,
	anterior: Dictionary,
	singular: Dictionary,
	paso_singular: Dictionary,
	delta: float,
) -> void:
	var rival: CharacterBody3D = anfitrion.get("_rival")
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	var figura: Node3D = anfitrion.get("_figura_rival")
	var tipo := String(singular.get("tipo", ""))
	if tipo == ARQUETIPOS.HOSTIGADOR:
		var estado_anterior := String(anterior.get("estado", ""))
		var estado_actual := String(singular.get("estado", ""))
		if estado_actual == ARQUETIPOS.TELEGRAFIAR and estado_anterior != ARQUETIPOS.TELEGRAFIAR:
			anfitrion.set("_rival_inicio_agresion", true)
			Sonido.sonar(anfitrion, "marcar")
		if (
			estado_actual == ARQUETIPOS.DISPARAR_LINEA
			and estado_anterior != ARQUETIPOS.DISPARAR_LINEA
		):
			anfitrion.call(
				"_aplicar_impacto_rival",
				HOSTIGADOR_3D.resultado_disparo(
					rival.position,
					singular,
					jugador.position,
					float(anfitrion.get("_esquiva")),
				),
			)
		var linea := estado.get("linea") as MeshInstance3D
		HOSTIGADOR_3D.pintar_linea(
			linea,
			rival.position,
			singular,
			String(paso_singular.get("telegraph", "")),
		)
		var movimiento := (
			HOSTIGADOR_3D
			. mover(
				jugador.position,
				rival.position,
				rival.rotation.y,
				singular,
				float(anfitrion.get("_radio_arena")),
				delta,
			)
		)
		rival.position = movimiento.get("posicion", rival.position)
		rival.rotation.y = float(movimiento.get("rotacion_y", rival.rotation.y))
		JuicioCombateEscenografia3D.andar(figura, bool(movimiento.get("andando", false)))
		if bool(paso_singular.get("ventana_respuesta", false)):
			JuicioCombateEscenografia3D.gesto(figura, "encajar")
		return

	var guardia := estado.get("guardia") as MeshInstance3D
	if guardia != null and is_instance_valid(guardia):
		guardia.visible = String(singular.get("estado", "")) == ARQUETIPOS.GUARDIA
	rival.rotation.y = (
		ARQUETIPO_HOST
		. girar(
			singular,
			rival.rotation.y,
			rival.position,
			jugador.position,
			delta,
		)
	)
	if bool(anfitrion.get("_ataque_rival_pendiente")):
		anfitrion.call("_actualizar_telegrafo_rival", delta)
		return
	if not ARQUETIPO_HOST.permite_iniciar_ataque(singular):
		JuicioCombateEscenografia3D.andar(figura, false)
		return
	var estado_temporal = anfitrion.get("_estado_temporal")
	var movimiento := (
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
	JuicioCombateEscenografia3D.andar(figura, bool(movimiento.get("mover", false)))
	if bool(movimiento.get("mover", false)):
		var desplazamiento: Vector3 = movimiento.get("desplazamiento", Vector3.ZERO)
		rival.position = (
			REGLAS
			. limitar_a_arena(
				rival.position + desplazamiento,
				float(anfitrion.get("_radio_arena")),
			)
		)
		if desplazamiento.length() > 0.01:
			rival.rotation.y = atan2(desplazamiento.x, desplazamiento.z)
	elif bool(movimiento.get("iniciar_ataque", false)):
		anfitrion.call("_iniciar_ataque_rival")


static func _retirar_singular(anfitrion, estado: Dictionary) -> void:
	var rival: CharacterBody3D = anfitrion.get("_rival")
	if rival != null and is_instance_valid(rival):
		rival.visible = false
	var guardia := estado.get("guardia") as MeshInstance3D
	if guardia != null and is_instance_valid(guardia):
		guardia.visible = false
	var linea := estado.get("linea") as MeshInstance3D
	if linea != null and is_instance_valid(linea):
		linea.visible = false
	if bool(anfitrion.get("_ataque_rival_pendiente")):
		anfitrion.call("_cancelar_ataque_rival")


static func _resultado_dano(estado: Dictionary, fin: bool) -> Dictionary:
	return {
		"determinacion_total": determinacion_total(estado),
		"terminado": fin,
	}
