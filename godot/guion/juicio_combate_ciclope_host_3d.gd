## Wiring del Cíclope de Cantera al host 3D (#2280 / #2091).
##
## Reutiliza íntegramente EMBESTIDOR y la presentación cultural existente.
## Esta capa aporta contexto físico, movimiento y reinyecta el impacto por la
## autoridad común de JuicioCombate3D.
class_name JuicioCombateCiclopeHost3D
extends RefCounted

const RUNTIME = preload("res://guion/juicio_combate_embestidor_3d.gd")
const PRESENTACION = preload("res://guion/juicio_combate_ciclope_3d.gd")
const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")

const VARIANTE := "ciclope_cantera"


static func es_estado(estado: Dictionary) -> bool:
	return String(estado.get("_variante_onirica", "")) == VARIANTE


static func montar(anfitrion, rival: CharacterBody3D, raiz: int) -> Dictionary:
	if rival == null:
		return {}
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	if jugador == null:
		return {}

	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.EMBESTIDOR, raiz)
	var salida := RUNTIME.avanzar(unidad, 0.0, rival.position, jugador.position, true, false)
	unidad = salida.get("unidad", unidad)
	var presentacion := PRESENTACION.montar(rival)
	if presentacion.is_empty():
		return {}
	var linea := RUNTIME.montar_linea(anfitrion)

	var figura_base: Node3D = anfitrion.get("_figura_rival")
	if figura_base != null and is_instance_valid(figura_base):
		figura_base.visible = false
	var figura := presentacion.get("raiz") as Node3D
	if figura != null:
		anfitrion.set("_figura_rival", figura)

	(
		PRESENTACION
		. pintar(
			presentacion,
			String(unidad.get("estado", "")),
			bool(anfitrion.get("reduccion_movimiento")),
		)
	)
	RUNTIME.pintar_linea(linea, rival.position, unidad, String(salida.get("telegraph", "")))
	return {
		"_variante_onirica": VARIANTE,
		"tipo": ARQUETIPOS.EMBESTIDOR,
		"estado": String(unidad.get("estado", "")),
		"unidad": unidad,
		"salida": salida,
		"presentacion": presentacion,
		"linea": linea,
		"impacto_carga_emitido": false,
	}


static func avanzar(anfitrion, estado: Dictionary, delta: float) -> void:
	if not es_estado(estado):
		return
	var rival: CharacterBody3D = anfitrion.get("_rival")
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	if rival == null or jugador == null:
		return

	var unidad: Dictionary = estado.get("unidad", {})
	if unidad.is_empty():
		return
	var fase_anterior := String(unidad.get("estado", ""))
	var cargando_antes := fase_anterior == ARQUETIPOS.CARGAR
	var distancia := rival.position.distance_to(jugador.position)
	var choque_jugador := cargando_antes and distancia <= REGLAS.ALCANCE_RIVAL
	var choque_borde := (
		_chocaria_borde(
			rival.position,
			float(unidad.get("rumbo_bloqueado", rival.rotation.y)),
			float(anfitrion.get("_radio_arena")),
			delta,
		)
		if cargando_antes
		else false
	)

	var salida := (
		RUNTIME
		. avanzar(
			unidad,
			delta,
			rival.position,
			jugador.position,
			true,
			choque_jugador or choque_borde,
		)
	)
	unidad = salida.get("unidad", unidad)
	estado["unidad"] = unidad
	estado["salida"] = salida
	estado["estado"] = String(unidad.get("estado", ""))

	if bool(salida.get("inicio_agresion", false)):
		anfitrion.set("_rival_inicio_agresion", true)
	if bool(salida.get("inicio_carga", false)):
		estado["impacto_carga_emitido"] = false
		Sonido.sonar(anfitrion, "marcar")

	if choque_jugador and not bool(estado.get("impacto_carga_emitido", false)):
		estado["impacto_carga_emitido"] = true
		var resultado := (
			REGLAS
			. resultado_ataque_rival(
				distancia,
				float(anfitrion.get("_esquiva")),
			)
		)
		anfitrion.call("_aplicar_impacto_rival", resultado)

	var plan := (
		RUNTIME
		. mover(
			jugador.position,
			rival.position,
			rival.rotation.y,
			unidad,
			float(anfitrion.get("_radio_arena")),
			delta,
		)
	)
	rival.position = plan.get("posicion", rival.position)
	rival.rotation.y = float(plan.get("rotacion_y", rival.rotation.y))

	var linea := estado.get("linea") as MeshInstance3D
	(
		RUNTIME
		. pintar_linea(
			linea,
			rival.position,
			unidad,
			String(salida.get("telegraph", "")),
		)
	)
	(
		PRESENTACION
		. pintar(
			estado.get("presentacion", {}),
			String(unidad.get("estado", "")),
			bool(anfitrion.get("reduccion_movimiento")),
		)
	)
	if bool(salida.get("abrir_ventana", false)):
		var figura: Node3D = anfitrion.get("_figura_rival")
		if figura != null and is_instance_valid(figura):
			JuicioCombateEscenografia3D.gesto(figura, "encajar")


static func _chocaria_borde(
	posicion: Vector3,
	rumbo: float,
	radio_arena: float,
	delta: float,
) -> bool:
	if delta <= 0.0:
		return false
	var esperado := (
		posicion
		+ JuicioCombateArquetipoHost.direccion_linea(rumbo) * RUNTIME.VELOCIDAD_CARGA * delta
	)
	var limitado := REGLAS.limitar_a_arena(esperado, radio_arena)
	return not esperado.is_equal_approx(limitado)
