## Capa de transición casa→sueño en 3D (#395).
##
## Intercepta únicamente la cama. El resto del día sigue bajando por la cadena
## histórica sin cambios. La economía y el cambio de fase continúan viviendo en
## `Jornada.dormir()`: aquí solo se retrasa esa llamada hasta que el reproductor
## común termina o recibe skip, de modo que mientras rueda seguimos realmente
## en `casa` y ningún reloj/controlador onírico se adelanta.
extends "res://guion/dia_onboarding_app.gd"

var _cinematica_sueno: Node3D = null
var _hud_prioridades_previo := true


func _process(delta: float) -> void:
	# Congela el mundo doméstico durante el plano: ni pasos ni gato avanzan
	# mientras la cámara tiene el control. La cinemática procesa por su cuenta.
	if _cinematica_sueno != null:
		return
	super._process(delta)


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	# Los casos especiales y guardados pendientes conservan exactamente el
	# comportamiento base. Esta capa solo posee la cama de casa.
	if partida.guardado_pendiente or cuerpo != _caminante or _pantalla != null:
		super._al_pisar_salida(cuerpo, salida)
		return
	if (
		String(jornada.get("fase", "")) != "casa"
		or String(salida.get_meta("destino", "")) != "sueño"
	):
		super._al_pisar_salida(cuerpo, salida)
		return
	if _cinematica_sueno != null:
		return
	_iniciar_cinematica_sueno()


func _iniciar_cinematica_sueno() -> void:
	# No se llama aún a Jornada.dormir(): conservar `fase == casa` evita que el
	# reloj y los controllers del sueño actúen sobre el mundo doméstico mientras
	# la cámara todavía lo está rodando.
	_caminante.set_physics_process(false)
	_hud.visible = false
	var prioridades := get_node_or_null("HUDPrioridades")
	if prioridades != null:
		_hud_prioridades_previo = bool(prioridades.get("visible"))
		prioridades.set("visible", false)

	_cinematica_sueno = load("res://escenas/cinematica.tscn").instantiate()
	add_child(_cinematica_sueno)
	_cinematica_sueno.terminada.connect(_terminar_cinematica_sueno)
	var vistas := Cinematica.vistas_de(partida.estado, SuenoCinematica.ID)
	_cinematica_sueno.reproducir(
		SuenoCinematica.planos_de(vistas), SuenoCinematica.ID, partida.estado
	)


func _terminar_cinematica_sueno() -> void:
	if _cinematica_sueno == null:
		return
	_cinematica_sueno.queue_free()
	_cinematica_sueno = null

	# A partir de aquí es el mismo contrato que antes vivía directamente en la
	# rama `casa` de Dia: Jornada resuelve coste/gato/fase una sola vez, la
	# política concreta el sueño, se monta el destino y entonces se persiste.
	var noche := Jornada.dormir(jornada)
	_aplicar_politica_sueno()
	_hablando = false
	_nomina.text = (
		tr("DIA_VIVIR")
		% [
			noche["coste"],
			noche["dinero"],
			tr("DIA_SIN_GATO_AVISO") if noche["gato_se_fue"] else ""
		]
	)
	_entrar_en("sueño")
	_guardar_o_avisar("")

	_caminante.set_physics_process(true)
	_hud.visible = true
	var prioridades := get_node_or_null("HUDPrioridades")
	if prioridades != null:
		prioridades.set("visible", _hud_prioridades_previo)
