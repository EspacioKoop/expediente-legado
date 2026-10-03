## Costura 3D de la Gárgola de Umbral para JuicioCombate3D (#2219).
##
## El runtime compuesto conserva transiciones/timers. Este adaptador solo aporta
## contexto físico, mueve el cuerpo y devuelve los impactos al punto común del host.
class_name JuicioCombateGargolaHost3D
extends RefCounted

const VARIANTE := JuicioCombateVarianteOnirica.GARGOLA_UMBRAL


static func es_estado(estado: Dictionary) -> bool:
	return String(estado.get("_variante_onirica", "")) == VARIANTE


static func montar(anfitrion, rival: CharacterBody3D, raiz: int) -> Dictionary:
	if rival == null:
		return {}
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	if jugador == null:
		return {}

	var runtime := JuicioCombateGargolaRuntime2092.nuevo(raiz)
	var hacia := jugador.position - rival.position
	hacia.y = 0.0
	var rumbo := atan2(hacia.x, hacia.z) if hacia.length() > 0.01 else rival.rotation.y
	var salida := (
		JuicioCombateGargolaRuntime2092
		. avanzar(
			runtime,
			0.0,
			hacia.length(),
			rumbo,
			false,
			false,
			true,
			false,
		)
	)
	var presentacion := JuicioCombateGargola3D.montar(rival)
	if presentacion.is_empty():
		return {}

	var figura_base: Node3D = anfitrion.get("_figura_rival")
	if figura_base != null and is_instance_valid(figura_base):
		figura_base.visible = false
	var figura := presentacion.get("raiz") as Node3D
	if figura != null:
		anfitrion.set("_figura_rival", figura)

	var estado := {
		"_variante_onirica": VARIANTE,
		"tipo": JuicioCombateArquetipos.BLOQUEADOR,
		"estado": JuicioCombateArquetipos.GUARDIA,
		"runtime": salida.get("estado", runtime),
		"salida": salida,
		"presentacion": presentacion,
		"impacto_carga_emitido": false,
	}
	(
		JuicioCombateGargola3D
		. pintar(
			presentacion,
			salida,
			bool(anfitrion.get("reduccion_movimiento")),
		)
	)
	return estado


static func avanzar(anfitrion, estado: Dictionary, delta: float) -> void:
	if not es_estado(estado):
		return
	var rival: CharacterBody3D = anfitrion.get("_rival")
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	if rival == null or jugador == null:
		return

	var runtime: Dictionary = estado.get("runtime", {})
	var embestidor: Dictionary = runtime.get("embestidor", {})
	var modo_anterior := String(runtime.get("modo", ""))
	var estado_embestidor := String(embestidor.get("estado", ""))
	var cargando_antes := (
		modo_anterior == JuicioCombateGargolaRuntime2092.MODO_EMBESTIDOR
		and estado_embestidor == JuicioCombateArquetipos.CARGAR
	)
	var hacia := jugador.position - rival.position
	hacia.y = 0.0
	var distancia := hacia.length()
	var rumbo := atan2(hacia.x, hacia.z) if distancia > 0.01 else rival.rotation.y
	var flanqueado := (
		JuicioCombateArquetipoHost
		. flanqueado(
			rival.position,
			rival.rotation.y,
			jugador.position,
		)
	)
	var guardia_rota := bool(anfitrion.get("_guardia_rota"))
	anfitrion.set("_guardia_rota", false)

	var radio := float(anfitrion.get("_radio_arena"))
	var choque_jugador := cargando_antes and distancia <= JuicioCombateReglas.ALCANCE_RIVAL
	var choque_borde := false
	if cargando_antes and delta > 0.0:
		var rumbo_carga := float(embestidor.get("rumbo_bloqueado", rival.rotation.y))
		var esperado := (
			rival.position
			+ (
				JuicioCombateArquetipoHost.direccion_linea(rumbo_carga)
				* JuicioCombateEmbestidor3D.VELOCIDAD_CARGA
				* delta
			)
		)
		var limitado := JuicioCombateReglas.limitar_a_arena(esperado, radio)
		choque_borde = not esperado.is_equal_approx(limitado)
	var salida := (
		JuicioCombateGargolaRuntime2092
		. avanzar(
			runtime,
			delta,
			distancia,
			rumbo,
			flanqueado,
			guardia_rota,
			true,
			choque_jugador or choque_borde,
		)
	)
	estado["runtime"] = salida.get("estado", runtime)
	estado["salida"] = salida
	estado["estado"] = (
		JuicioCombateArquetipos.GUARDIA
		if bool(salida.get("guardia_frontal", false))
		else JuicioCombateArquetipos.APERTURA
	)

	if String(salida.get("telegraph", "")) == "carga_lineal":
		anfitrion.set("_rival_inicio_agresion", true)
	if bool(salida.get("inicio_carga", false)):
		estado["impacto_carga_emitido"] = false
		Sonido.sonar(anfitrion, "marcar")

	if choque_jugador and not bool(estado.get("impacto_carga_emitido", false)):
		estado["impacto_carga_emitido"] = true
		var resultado := (
			JuicioCombateReglas
			. resultado_ataque_rival(
				distancia,
				float(anfitrion.get("_esquiva")),
			)
		)
		anfitrion.call("_aplicar_impacto_rival", resultado)

	_mover(anfitrion, estado, delta)
	(
		JuicioCombateGargola3D
		. pintar(
			estado.get("presentacion", {}),
			salida,
			bool(anfitrion.get("reduccion_movimiento")),
		)
	)
	if bool(salida.get("abrir_ventana", false)):
		var figura: Node3D = anfitrion.get("_figura_rival")
		if figura != null and is_instance_valid(figura):
			JuicioCombateEscenografia3D.gesto(figura, "encajar")


static func _mover(anfitrion, estado: Dictionary, delta: float) -> void:
	var rival: CharacterBody3D = anfitrion.get("_rival")
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	var runtime: Dictionary = estado.get("runtime", {})
	if rival == null or jugador == null or runtime.is_empty():
		return

	if String(runtime.get("modo", "")) == JuicioCombateGargolaRuntime2092.MODO_EMBESTIDOR:
		var embestidor: Dictionary = runtime.get("embestidor", {})
		var plan := (
			JuicioCombateEmbestidor3D
			. mover(
				jugador.position,
				rival.position,
				rival.rotation.y,
				embestidor,
				float(anfitrion.get("_radio_arena")),
				delta,
			)
		)
		rival.position = plan["posicion"]
		rival.rotation.y = float(plan["rotacion_y"])
		return

	var bloqueador: Dictionary = runtime.get("bloqueador", {})
	rival.rotation.y = (
		JuicioCombateArquetipoHost
		. girar(
			bloqueador,
			rival.rotation.y,
			rival.position,
			jugador.position,
			delta,
		)
	)
