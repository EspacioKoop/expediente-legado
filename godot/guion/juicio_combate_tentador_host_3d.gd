## Wiring del Tentador miniado al host 3D (#2273 / #2088).
##
## Consume el runtime MIMETICO y su presentación ya integrados. Esta capa solo
## observa un patrón del jugador, congela la geometría mínima necesaria para
## repetirlo y devuelve el impacto al punto común de JuicioCombate3D.
class_name JuicioCombateTentadorHost3D
extends RefCounted

const RUNTIME = preload("res://guion/juicio_combate_tentador_runtime_2088.gd")
const PRESENTACION = preload("res://guion/juicio_combate_tentador_3d.gd")
const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const ARQUETIPO_HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")

const VARIANTE := "tentador_miniado"
const PATRON_CORTO := "ataque_corto"
const ALCANCE_LINEA := 5.2
const RADIO_LINEA := 0.32
const RADIO_CARGA := 0.72
const RADIO_ZONA := 2.20


static func es_estado(estado: Dictionary) -> bool:
	return String(estado.get("_variante_onirica", "")) == VARIANTE


static func montar(anfitrion, rival: CharacterBody3D, raiz: int) -> Dictionary:
	if rival == null:
		return {}
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	if jugador == null:
		return {}

	var runtime := RUNTIME.nuevo(raiz)
	var salida := RUNTIME.avanzar(runtime, 0.0, "")
	var presentacion := PRESENTACION.montar(rival)
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
		"tipo": ARQUETIPOS.MIMETICO,
		"estado": ARQUETIPOS.OBSERVAR,
		"runtime": salida.get("estado", runtime),
		"salida": salida,
		"presentacion": presentacion,
		"_rumbo_eco": rival.rotation.y,
		"_repeticion_emitida": false,
	}
	PRESENTACION.pintar(
		presentacion,
		salida,
		bool(anfitrion.get("reduccion_movimiento")),
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
	var unidad_anterior: Dictionary = runtime.get("unidad", {})
	var fase_anterior := String(unidad_anterior.get("estado", ""))
	var patron_observado := _patron_observado(anfitrion)
	var salida := RUNTIME.avanzar(runtime, delta, patron_observado)
	runtime = salida.get("estado", runtime)
	estado["runtime"] = runtime
	estado["salida"] = salida

	var unidad: Dictionary = runtime.get("unidad", {})
	var fase := String(unidad.get("estado", ""))
	var patron := String(salida.get("patron_eco", ""))
	estado["estado"] = fase

	if fase_anterior == ARQUETIPOS.OBSERVAR and fase == ARQUETIPOS.TELEGRAFIAR_ECO:
		estado["_rumbo_eco"] = _rumbo_hacia(rival.position, jugador.position, rival.rotation.y)
		estado["_repeticion_emitida"] = false
		anfitrion.set("_rival_inicio_agresion", true)
		Sonido.sonar(anfitrion, "marcar")

	if fase in [ARQUETIPOS.TELEGRAFIAR_ECO, ARQUETIPOS.REPETIR]:
		rival.rotation.y = float(estado.get("_rumbo_eco", rival.rotation.y))

	if fase != ARQUETIPOS.REPETIR:
		estado["_repeticion_emitida"] = false
	elif fase_anterior != ARQUETIPOS.REPETIR and not bool(
		estado.get("_repeticion_emitida", false)
	):
		# Un patrón repetido produce como máximo una resolución lógica. Permanecer
		# varios frames en REPETIR no vuelve a aplicar daño.
		estado["_repeticion_emitida"] = true
		anfitrion.call(
			"_aplicar_impacto_rival",
			_resultado_patron(
				patron,
				rival.position,
				float(estado.get("_rumbo_eco", rival.rotation.y)),
				jugador.position,
				float(anfitrion.get("_esquiva")),
			),
		)

	PRESENTACION.pintar(
		estado.get("presentacion", {}),
		salida,
		bool(anfitrion.get("reduccion_movimiento")),
	)
	if bool(salida.get("ventana_respuesta", false)):
		var figura: Node3D = anfitrion.get("_figura_rival")
		if figura != null and is_instance_valid(figura):
			JuicioCombateEscenografia3D.gesto(figura, "encajar")


## El host actual solo expone ataques cuerpo a cuerpo del jugador. Se traducen
## al patrón permitido ataque_corto; futuros verbos pueden ampliar esta función
## sin alterar la máquina MIMETICO ni su presentación.
static func _patron_observado(anfitrion) -> String:
	return PATRON_CORTO if float(anfitrion.get("_recarga_jugador")) > 0.0 else ""


static func _resultado_patron(
	patron: String,
	origen: Vector3,
	rumbo: float,
	objetivo: Vector3,
	esquiva: float,
) -> String:
	var distancia := origen.distance_to(objetivo)
	var distancia_logica := REGLAS.ALCANCE_RIVAL + 1.0
	match patron:
		"ataque_corto":
			distancia_logica = distancia
		"linea":
			if ARQUETIPO_HOST.impacto_linea(
				origen, rumbo, objetivo, ALCANCE_LINEA, RADIO_LINEA
			):
				distancia_logica = 0.0
		"carga_lineal":
			if ARQUETIPO_HOST.impacto_linea(
				origen, rumbo, objetivo, ALCANCE_LINEA, RADIO_CARGA
			):
				distancia_logica = 0.0
		"zona":
			if distancia <= RADIO_ZONA:
				distancia_logica = 0.0
	return REGLAS.resultado_ataque_rival(distancia_logica, esquiva)


static func _rumbo_hacia(origen: Vector3, objetivo: Vector3, fallback: float) -> float:
	var hacia := objetivo - origen
	hacia.y = 0.0
	return atan2(hacia.x, hacia.z) if hacia.length() > 0.01 else fallback
