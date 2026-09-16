## Costura de #74 sobre el día existente.
##
## `dia_app.gd` sigue siendo la autoridad del ciclo diario. Esta capa solo
## intercepta el tránsito casa -> sueño para poner una continuidad visual una
## vez que Jornada ya ha calculado la noche y la primera sala ya está montada.
extends "res://guion/dia_app.gd"

const ESCENA_CINEMATICA := preload("res://escenas/cinematica.tscn")

var _entrada_sueno: Node3D = null


## Las presentaciones específicas se montan DESPUÉS del espacio jugable. Así la
## familia poligonal sigue siendo la única autoridad de navegación/colisión y el
## arte puede vestirla sin duplicar reglas ni conocer el id de la sala aquí.
func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	if fase != "sueño" or _mundo == null:
		return
	SuenoCastillo3D.montar(_mundo, _espacio_actual)


## Mientras se ve la bisagra no corre el reloj onírico. La noche ya existe,
## pero no empieza a gastarse hasta que el jugador recupera el control.
func _process(delta: float) -> void:
	if _entrada_sueno != null:
		return
	super._process(delta)


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	var destino := String(salida.get_meta("destino", ""))
	var frase := String(salida.get_meta("frase", ""))
	if (
		jornada.get("fase", "") == "casa"
		and cuerpo == _caminante
		and _pantalla == null
		and not partida.guardado_pendiente
		and frase.is_empty()
		and destino == "sueño"
	):
		_dormir_con_entrada()
		return
	super._al_pisar_salida(cuerpo, salida)


## La regla ocurre primero: pagar el día, actualizar el gato, seleccionar la
## noche, montar la primera sala y recordar su mapa. Solo después se reproduce
## la transición, de modo que saltarla o cerrarla no decide nada.
func _dormir_con_entrada() -> void:
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

	# El sueño queda detrás de la cinemática ya construido. Así no existe un
	# fotograma negro entre ambas capas y el mapa está actualizado antes de que
	# empiece la presentación.
	_entrar_en("sueño")
	_guardar_o_avisar("")

	_caminante.set_physics_process(false)
	# La secuencia rueda dentro de la sala: sin HUD encima, igual que la cama.
	_hud.visible = false
	_mostrar_prioridades(false)
	_mundo.process_mode = Node.PROCESS_MODE_DISABLED
	_entrada_sueno = ESCENA_CINEMATICA.instantiate()
	add_child(_entrada_sueno)
	_entrada_sueno.terminada.connect(_cerrar_entrada_sueno)
	_entrada_sueno.reproducir(
		EntradaSuenoCinematica.planos_de(
			jornada["leido_hoy"],
			Cinematica.vistas_de(partida.estado, EntradaSuenoCinematica.ID),
			_espacio_actual
		),
		EntradaSuenoCinematica.ID,
		partida.estado
	)


func _cerrar_entrada_sueno() -> void:
	if _entrada_sueno == null:
		return
	_entrada_sueno.queue_free()
	_entrada_sueno = null
	_mundo.process_mode = Node.PROCESS_MODE_INHERIT
	_caminante.set_physics_process(true)
	_hud.visible = true
	_mostrar_prioridades(true)
	# Conserva también la cuenta de vistas de la cinemática. El resto del sueño
	# ya se había guardado antes de empezar a verla.
	_guardar_o_avisar("")


func _mostrar_prioridades(mostrar: bool) -> void:
	var prioridades := get_node_or_null("HUDPrioridades")
	if prioridades != null:
		prioridades.set("visible", mostrar)
