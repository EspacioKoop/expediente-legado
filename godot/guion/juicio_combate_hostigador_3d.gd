## Runtime 3D del hostigador onírico (#1771).
## No aplica daño ni consecuencias; devuelve intención, geometría y resultado de línea.
class_name JuicioCombateHostigador3D
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const ARQUETIPO_HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")
const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const LINEA_ALCANCE := 10.0
const LINEA_RADIO := 0.55
const VELOCIDAD := 2.8


static func montar_linea(anfitrion: Node3D) -> MeshInstance3D:
	var linea := MeshInstance3D.new()
	linea.name = "LineaHostigador"
	var malla := BoxMesh.new()
	malla.size = Vector3(0.10, 0.035, LINEA_ALCANCE)
	linea.mesh = malla
	var material := FEEDBACK.material(Color(1.0, 0.42, 0.18, 0.52), true)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	linea.material_override = material
	linea.visible = false
	anfitrion.add_child(linea)
	return linea


static func avanzar(
	unidad: Dictionary, delta: float, posicion_rival: Vector3, posicion_jugador: Vector3
) -> Dictionary:
	var estado_anterior := String(unidad.get("estado", ""))
	var contexto := ARQUETIPO_HOST.contexto_hostigador(posicion_rival, posicion_jugador)
	var paso := ARQUETIPOS.avanzar(unidad, delta, contexto)
	var nueva: Dictionary = paso["unidad"]
	nueva["_intencion_runtime"] = String(paso.get("intencion", ""))
	var estado := String(nueva.get("estado", ""))
	return {
		"unidad": nueva,
		"telegraph": String(paso.get("telegraph", "")),
		"fijar_rumbo": estado in [ARQUETIPOS.TELEGRAFIAR, ARQUETIPOS.DISPARAR_LINEA],
		"inicio_agresion":
		estado == ARQUETIPOS.TELEGRAFIAR and estado_anterior != ARQUETIPOS.TELEGRAFIAR,
		"disparar":
		estado == ARQUETIPOS.DISPARAR_LINEA and estado_anterior != ARQUETIPOS.DISPARAR_LINEA,
		"abrir_ventana":
		estado == ARQUETIPOS.VULNERABLE and estado_anterior != ARQUETIPOS.VULNERABLE,
	}


static func mover(
	posicion_jugador: Vector3,
	posicion_rival: Vector3,
	rotacion_y_rival: float,
	unidad: Dictionary,
	radio_arena: float,
	delta: float,
) -> Dictionary:
	var hacia := posicion_jugador - posicion_rival
	hacia.y = 0.0
	var direccion := Vector3.ZERO
	var rotacion := rotacion_y_rival
	var estado := String(unidad.get("estado", ""))
	if hacia.length() > 0.01:
		var normal := hacia.normalized()
		match String(unidad.get("_intencion_runtime", "")):
			"acercarse":
				direccion = normal
			"alejarse", "retroceder":
				direccion = -normal
			"mantener_distancia", "reposicionar":
				direccion = (
					Vector3(normal.z, 0.0, -normal.x) * float(unidad.get("sesgo_lateral", 1.0))
				)
		if estado == ARQUETIPOS.VULNERABLE:
			direccion = -normal
		if estado not in [ARQUETIPOS.TELEGRAFIAR, ARQUETIPOS.DISPARAR_LINEA]:
			rotacion = atan2(hacia.x, hacia.z)
	var andando := (
		not direccion.is_zero_approx()
		and estado not in [ARQUETIPOS.TELEGRAFIAR, ARQUETIPOS.DISPARAR_LINEA]
	)
	var posicion := posicion_rival
	if andando:
		posicion = REGLAS.limitar_a_arena(
			posicion_rival + direccion * VELOCIDAD * delta, radio_arena
		)
	return {"posicion": posicion, "rotacion_y": rotacion, "andando": andando}


static func resultado_disparo(
	posicion_rival: Vector3, unidad: Dictionary, posicion_jugador: Vector3, esquiva_restante: float
) -> String:
	var rumbo := float(unidad.get("rumbo_bloqueado", 0.0))
	if not ARQUETIPO_HOST.impacto_linea(
		posicion_rival, rumbo, posicion_jugador, LINEA_ALCANCE, LINEA_RADIO
	):
		return "falla"
	return "esquiva" if esquiva_restante > 0.0 else "impacto"


static func pintar_linea(
	linea: MeshInstance3D, posicion_rival: Vector3, unidad: Dictionary, telegraph: String
) -> void:
	if linea == null:
		return
	linea.visible = telegraph == "linea"
	if not linea.visible:
		return
	var rumbo := float(unidad.get("rumbo_bloqueado", 0.0))
	var direccion := ARQUETIPO_HOST.direccion_linea(rumbo)
	linea.position = posicion_rival + Vector3(0.0, 0.06, 0.0) + direccion * (LINEA_ALCANCE * 0.5)
	linea.rotation = Vector3(0.0, rumbo, 0.0)
