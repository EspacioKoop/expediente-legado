## Capa de #238/#135 sobre el día completo.
##
## Intercepta únicamente archivo -> trayecto. La jornada ficha, monta la calle y
## se guarda antes de abrir la presentación; el ascensor no puede cobrar una
## nómina, avanzar el calendario ni dejar al jugador atrapado entre fases.
extends "res://guion/dia_jornada_app.gd"

const ESCENA_ASCENSOR := preload("res://escenas/ascensor_3d.tscn")

var _ascensor: Node3D = null


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	if (
		cuerpo == _caminante
		and _pantalla == null
		and _ascensor == null
		and not partida.guardado_pendiente
		and jornada.get("fase", "") == "archivo"
		and String(salida.get_meta("destino", "")) == "trayecto"
		and String(salida.get_meta("frase", "")).is_empty()
		and String(salida.get_meta("duelo", "")).is_empty()
	):
		_salir_por_ascensor()
		return
	super._al_pisar_salida(cuerpo, salida)


## Reproduce exactamente la parte de la salida de oficina que pertenece a la
## regla, y solo después añade presentación. Entrar en `trayecto` antes de la
## escena hace que cerrar el juego dentro del ascensor reabra ya en la calle.
func _salir_por_ascensor() -> void:
	var paga := Jornada.fichar_salida(jornada)
	_sonar("nomina")
	_hablando = false
	_nomina.text = (
		tr("DIA_NOMINA")
		% [
			jornada["dia"],
			paga["bruto"],
			paga["base"],
			paga["por_expedientes"],
			paga["expedientes"],
			paga["dinero"]
		]
	)

	_sonar("puerta_abre")
	_entrar_en("trayecto")
	if not _guardar_o_avisar(""):
		return

	_caminante.set_physics_process(false)
	_hud.visible = false
	_ascensor = ESCENA_ASCENSOR.instantiate()
	add_child(_ascensor)
	_ascensor.terminada.connect(_cerrar_ascensor)
	_ascensor.reproducir(
		AscensorCinematica.planos_de(Cinematica.vistas_de(partida.estado, AscensorCinematica.ID)),
		AscensorCinematica.ID,
		partida.estado
	)


func _cerrar_ascensor() -> void:
	if _ascensor == null:
		return
	_ascensor.queue_free()
	_ascensor = null
	_caminante.set_physics_process(true)
	_hud.visible = true
	# Solo persiste la cuenta de vistas. La nómina y el destino ya estaban en
	# disco antes de que empezara la presentación.
	_guardar_o_avisar("")
