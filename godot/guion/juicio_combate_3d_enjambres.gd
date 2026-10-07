class_name JuicioCombate3DEnjambres
extends RefCounted

const ENJAMBRE_HOST_3D = preload("res://guion/juicio_combate_enjambre_host_3d.gd")
const MIXTO_HOST_3D = preload("res://guion/juicio_combate_mixto_host_3d.gd")
const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const HOSTIGADOR_3D = preload("res://guion/juicio_combate_hostigador_3d.gd")
const ARQUETIPO_HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")


static func montar(
	anfitrion: Node3D,
	rival: CharacterBody3D,
	acusado: Dictionary,
	mito_id: String,
	raiz: int,
	arquetipo: String
) -> Dictionary:
	if arquetipo == "mixto":
		var estado := MIXTO_HOST_3D.montar(anfitrion, rival, acusado, mito_id, raiz)
		if not estado.is_empty():
			estado["_modo"] = "mixto"
		return estado
	elif arquetipo == ARQUETIPOS.ENJAMBRE:
		var estado := ENJAMBRE_HOST_3D.montar(anfitrion, rival, acusado, mito_id, raiz)
		if not estado.is_empty():
			estado["_modo"] = "puro"
		return estado
	return {}


static func arquetipo_singular(estado: Dictionary) -> Dictionary:
	if estado.get("_modo") == "mixto":
		return estado.get("runtime", {}).get("singular", {})
	return {}


static func objetivo(estado: Dictionary, posicion: Vector3) -> Dictionary:
	if estado.get("_modo") == "puro":
		return ENJAMBRE_HOST_3D.objetivo(estado, posicion)
	elif estado.get("_modo") == "mixto":
		var vivos := MIXTO_HOST_3D.objetivos_vivos(estado, posicion, null)
		if vivos.is_empty():
			return {}
		return vivos[0]
	return {}


static func vivos(estado: Dictionary) -> int:
	if estado.get("_modo") == "puro":
		return ENJAMBRE_HOST_3D.vivos(estado)
	elif estado.get("_modo") == "mixto":
		if MIXTO_HOST_3D.terminado(estado):
			return 0
		var visual: Dictionary = estado.get("enjambre_visual", {})
		var v_enjambre := ENJAMBRE_HOST_3D.vivos(visual)
		var det_singular := maxi(0, int(estado.get("determinacion_singular", 0)))
		return maxi(1, v_enjambre + det_singular)
	return 0


static func aplicar_dano(estado: Dictionary, objetivo_dict: Dictionary, dano: int) -> int:
	if estado.get("_modo") == "puro":
		ENJAMBRE_HOST_3D.aplicar_dano(estado, int(objetivo_dict.get("indice", -1)), dano)
	elif estado.get("_modo") == "mixto":
		MIXTO_HOST_3D.aplicar_dano(estado, objetivo_dict, dano)
	return vivos(estado)


static func centro(estado: Dictionary, fallback: Vector3) -> Vector3:
	if estado.get("_modo") == "puro":
		return ENJAMBRE_HOST_3D.centro(estado, fallback)
	elif estado.get("_modo") == "mixto":
		var visual: Dictionary = estado.get("enjambre_visual", {})
		return ENJAMBRE_HOST_3D.centro(visual, fallback)
	return fallback


static func avanzar(
	estado: Dictionary,
	delta: float,
	pos_jugador: Vector3,
	pos_rival: Vector3,
	rot_y_rival: float,
	guardia_rota: bool,
	esquiva: float
) -> Array:
	var impactos: Array = []
	if estado.get("_modo") == "puro":
		var distancias := ENJAMBRE_HOST_3D.avanzar(estado, delta, pos_jugador)
		for d in distancias:
			impactos.append(REGLAS.resultado_ataque_rival(float(d), esquiva))
	elif estado.get("_modo") == "mixto":
		var res := MIXTO_HOST_3D.avanzar(
			estado, delta, pos_jugador, pos_rival, rot_y_rival, guardia_rota
		)
		for ataque in res.get("ataques_enjambre", []):
			impactos.append(
				REGLAS.resultado_ataque_rival(float(ataque.get("distancia", INF)), esquiva)
			)
		for ataque in res.get("ataques_singular", []):
			if String(ataque.get("tipo", "")) == "linea":
				var dict_unidad := {"rumbo_bloqueado": float(ataque.get("rumbo", 0.0))}
				var resultado := HOSTIGADOR_3D.resultado_disparo(
					ataque.get("origen", pos_rival), dict_unidad, pos_jugador, esquiva
				)
				impactos.append(resultado)
	return impactos


static func ocultar_avisos(estado: Dictionary) -> void:
	if estado.get("_modo") == "puro":
		ENJAMBRE_HOST_3D.ocultar_avisos(estado)
	elif estado.get("_modo") == "mixto":
		var visual: Dictionary = estado.get("enjambre_visual", {})
		if not visual.is_empty():
			ENJAMBRE_HOST_3D.ocultar_avisos(visual)


static func figura_final(estado: Dictionary, fallback: Node3D) -> Node3D:
	if estado.get("_modo") == "puro":
		return ENJAMBRE_HOST_3D.figura_final(estado, fallback)
	elif estado.get("_modo") == "mixto":
		# Solo devolvemos la figura del enjambre si el singular no está vivo
		if not bool(estado.get("runtime", {}).get("singular_vivo", false)):
			var visual: Dictionary = estado.get("enjambre_visual", {})
			return ENJAMBRE_HOST_3D.figura_final(visual, fallback)
	return fallback


static func limpiar(estado: Dictionary) -> void:
	if estado.get("_modo") == "puro":
		ENJAMBRE_HOST_3D.limpiar(estado)
	elif estado.get("_modo") == "mixto":
		MIXTO_HOST_3D.limpiar(estado)
