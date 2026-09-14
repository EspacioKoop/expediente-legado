## Costura de #70, #72, #73 y #81 sobre el visor existente.
##
## El visor base conserva toda la lógica de lectura, firma y persistencia. Esta
## capa inserta las cinemáticas de sello, remate y reasignación sin dejar que
## ninguna de ellas decida el veredicto ni aplique consecuencias.
extends "res://guion/visor_expediente.gd"

const ESCENA_CINEMATICA := preload("res://escenas/cinematica.tscn")

var _duelo_resuelto := false


func _al_firmar(resultado: Dictionary, formulario: Control) -> void:
	formulario.queue_free()
	if not _guardar_o_avisar():
		return
	_reproducir_sello(resultado)


func _reproducir_sello(resultado: Dictionary) -> void:
	_imputar.disabled = true
	var reproductor: Node = ESCENA_CINEMATICA.instantiate()
	add_child(reproductor)
	reproductor.terminada.connect(_al_terminar_sello.bind(reproductor, resultado))
	reproductor.reproducir(
		SelloCinematica.planos_de(
			bool(resultado.get("precipitada", false)),
			Cinematica.vistas_de(partida.estado, SelloCinematica.ID)
		),
		SelloCinematica.ID,
		partida.estado
	)


## Terminar y saltar comparten exactamente esta salida. La animación no decide
## nada: la firma ya estaba guardada antes de entrar aquí.
func _al_terminar_sello(reproductor: Node, resultado: Dictionary) -> void:
	reproductor.queue_free()
	# Una acusación precipitada puede gastar la última vida. La reasignación ya
	# está aplicada en la lógica, así que no se abre un careo perteneciente a la
	# vida laboral anterior: primero se representa el despido.
	if bool(resultado.get("despido", false)):
		_reproducir_despido(resultado)
		return
	if not resultado.get("duelo", {}).is_empty():
		_abrir_careo_firmado(resultado)
		return
	_mostrar_cierre(resultado)


func _abrir_careo_firmado(resultado: Dictionary) -> void:
	_duelo_resuelto = false
	var careo: Node3D = load("res://escenas/careo.tscn").instantiate()
	careo.acusado = resultado["duelo"]
	careo.folio = registro_actual.get("folio", caso.get("titulo", ""))
	careo.cargas = historias.cargas(partida.estado)
	careo.estado = partida.estado
	careo.semilla_tiradas = _raiz()
	careo.terminado.connect(_al_terminar_careo.bind(careo, resultado))
	add_child(careo)


## El duelo se resuelve una sola vez aunque una señal se emita dos veces. La
## consecuencia se aplica y se guarda ANTES del remate: la cinemática solo la
## representa, por lo que verla entera o saltarla deja exactamente el mismo
## estado.
func _al_terminar_careo(gano: bool, careo: Node3D, acusacion: Dictionary) -> void:
	if _duelo_resuelto:
		return
	_duelo_resuelto = true
	careo.queue_free()
	var duelo := Acusacion.resolver_duelo(partida.estado, jornada, gano)
	if not _guardar_o_avisar():
		return
	_reproducir_remate(gano, acusacion, duelo)


func _reproducir_remate(gano: bool, acusacion: Dictionary, duelo: Dictionary) -> void:
	var id := DueloRemateCinematica.id_de(gano)
	var reproductor: Node = ESCENA_CINEMATICA.instantiate()
	add_child(reproductor)
	reproductor.terminada.connect(_al_terminar_remate.bind(reproductor, acusacion, duelo))
	reproductor.reproducir(
		DueloRemateCinematica.planos_de(gano, Cinematica.vistas_de(partida.estado, id)),
		id,
		partida.estado
	)


func _al_terminar_remate(reproductor: Node, acusacion: Dictionary, duelo: Dictionary) -> void:
	reproductor.queue_free()
	if bool(duelo.get("despido", false)):
		_reproducir_despido(acusacion, duelo)
		return
	_mostrar_cierre(acusacion, duelo)


## La lógica ya ha empezado otra vuelta antes de llegar aquí. Este método solo
## fotografía ese hecho: expediente en el puesto, salida acompañada y nueva
## credencial. El gato se consulta del estado ya reiniciado porque Jornada lo
## conserva exactamente como estaba.
func _reproducir_despido(acusacion: Dictionary, duelo: Dictionary = {}) -> void:
	# El cierre textual se fija antes de la escena para que el estado sea legible
	# incluso si el reproductor se interrumpe. La cinemática se superpone, pero
	# no es la autoridad de la reasignación ni del mensaje.
	_mostrar_cierre(acusacion, duelo)
	var reproductor: Node = ESCENA_CINEMATICA.instantiate()
	add_child(reproductor)
	reproductor.terminada.connect(_al_terminar_despido.bind(reproductor, acusacion, duelo))
	var gato_presente := bool(jornada.get("gato", {}).get("presente", false))
	# `vuelta` ya pertenece a la nueva vida laboral, pero es persistente: si se
	# recarga esta transición, el cuñado conserva exactamente la misma frase.
	var voz_cunado := Cunado.clave_despido(int(jornada.get("vuelta", 1)))
	reproductor.reproducir(
		DespidoCinematica.planos_de(
			gato_presente, Cinematica.vistas_de(partida.estado, DespidoCinematica.ID), voz_cunado
		),
		DespidoCinematica.ID,
		partida.estado
	)


func _al_terminar_despido(reproductor: Node, acusacion: Dictionary, duelo: Dictionary = {}) -> void:
	reproductor.queue_free()
	_mostrar_cierre(acusacion, duelo)
