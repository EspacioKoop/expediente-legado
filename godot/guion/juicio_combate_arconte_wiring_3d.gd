## Wiring del Arconte de Umbral al host 3D (#2262 / #2220).
##
## El adaptador cultural/mecánico sigue en JuicioCombateArconteHost3D. Esta
## costura solo aporta contexto físico del host y reinyecta el impacto por la
## autoridad común de JuicioCombate3D.
class_name JuicioCombateArconteWiring3D
extends RefCounted

const ARCONTE = preload("res://guion/juicio_combate_arconte_host_3d.gd")
const REGLAS = preload("res://guion/juicio_combate_reglas.gd")

const VARIANTE := ARCONTE.VARIANTE


static func es_estado(estado: Dictionary) -> bool:
	return ARCONTE.es_estado(estado)


static func montar(anfitrion: Node3D, raiz: int) -> Dictionary:
	var estado := ARCONTE.nuevo(anfitrion, raiz)
	if estado.is_empty():
		return {}
	estado["_impacto_zona_emitido"] = false
	return estado


static func avanzar(anfitrion, estado: Dictionary, delta: float) -> void:
	if not es_estado(estado):
		return
	var rival: CharacterBody3D = anfitrion.get("_rival")
	var jugador: CharacterBody3D = anfitrion.get("_jugador")
	if rival == null or jugador == null:
		return

	# Con una única unidad CONTROLADOR y una sola zona activa, el contrato
	# actual (1.7 m de ancho en arena de radio 5 m) conserva salida lateral.
	var paso := ARCONTE.avanzar(
		estado,
		delta,
		rival.position,
		jugador.position,
		bool(anfitrion.get("reduccion_movimiento")),
		true,
	)
	if paso.is_empty():
		return

	if bool(paso.get("inicio_marca", false)):
		anfitrion.set("_rival_inicio_agresion", true)
		Sonido.sonar(anfitrion, "marcar")

	var activa := bool(paso.get("zona_activa", false))
	if not activa:
		estado["_impacto_zona_emitido"] = false
	elif (
		not bool(estado.get("_impacto_zona_emitido", false))
		and _contiene(paso.get("geometria", {}), jugador.position)
	):
		estado["_impacto_zona_emitido"] = true
		var resultado := REGLAS.resultado_ataque_rival(
			0.0,
			float(anfitrion.get("_esquiva")),
		)
		anfitrion.call("_aplicar_impacto_rival", resultado)

	if bool(paso.get("abrir_ventana", false)):
		var figura: Node3D = anfitrion.get("_figura_rival")
		if figura != null and is_instance_valid(figura):
			JuicioCombateEscenografia3D.gesto(figura, "encajar")


static func _contiene(geometria: Dictionary, posicion: Vector3) -> bool:
	if geometria.is_empty():
		return false
	var origen: Vector3 = geometria.get("origen", Vector3.ZERO)
	var rumbo := float(geometria.get("rumbo", 0.0))
	var largo := maxf(0.0, float(geometria.get("largo", 0.0)))
	var ancho := maxf(0.0, float(geometria.get("ancho", 0.0)))
	if largo <= 0.0 or ancho <= 0.0:
		return false
	var direccion := Vector3(sin(rumbo), 0.0, cos(rumbo))
	var lateral := Vector3(direccion.z, 0.0, -direccion.x)
	var relativo := posicion - origen
	relativo.y = 0.0
	var avance := relativo.dot(direccion)
	var costado := absf(relativo.dot(lateral))
	return avance >= 0.0 and avance <= largo and costado <= ancho * 0.5
