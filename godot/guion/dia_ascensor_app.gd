## Capa de #238/#135 sobre el día completo.
##
## Intercepta únicamente archivo -> trayecto. La jornada ficha, monta la calle y
## se guarda antes de abrir la presentación; ascensor y escaleras no pueden
## cobrar una nómina, avanzar el calendario ni dejar al jugador entre fases.
extends "res://guion/dia_salidas_confirmadas_app.gd"

const ESCENA_ASCENSOR := preload("res://escenas/ascensor_3d.tscn")
const ESCENA_ESCALERAS := preload("res://escenas/escaleras_3d.tscn")

var _ascensor: Node3D = null
var _escaleras: Node3D = null
var _selector_ruta: ConfirmationDialog = null


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	if (
		cuerpo == _caminante
		and _pantalla == null
		and _ascensor == null
		and _escaleras == null
		and _selector_ruta == null
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
## regla, y solo después permite elegir presentación. Entrar en `trayecto` antes
## de cualquiera de las dos rutas hace que cerrar el juego durante el tránsito
## reabra ya en la calle.
func _salir_por_ascensor() -> void:
	_registrar_firma_sin_prisa()
	Auditorias.resolver_fin_archivo(partida.estado)
	PronosticosAuditoria.resolver_fin_jornada(partida.estado)
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

	_mostrar_selector_ruta()


func _mostrar_selector_ruta() -> void:
	_caminante.set_physics_process(false)
	_hud.visible = false

	_selector_ruta = ConfirmationDialog.new()
	_selector_ruta.name = "SelectorRutaPlanta4"
	_selector_ruta.title = "Bajar a la calle"
	_selector_ruta.dialog_text = "Planta 4 · Elige cómo bajar al portal."
	_selector_ruta.ok_button_text = "Ascensor"
	_selector_ruta.add_button("Escaleras", true, "escaleras")
	_selector_ruta.confirmed.connect(_iniciar_ascensor)
	# Cerrar el selector conserva la ruta histórica como opción segura.
	_selector_ruta.canceled.connect(_iniciar_ascensor)
	_selector_ruta.custom_action.connect(_al_elegir_ruta)
	add_child(_selector_ruta)
	_selector_ruta.popup_centered(Vector2i(420, 180))


func _al_elegir_ruta(accion: StringName) -> void:
	if accion == &"escaleras":
		_iniciar_escaleras()


func _quitar_selector_ruta() -> void:
	if _selector_ruta == null:
		return
	_selector_ruta.queue_free()
	_selector_ruta = null


func _iniciar_ascensor() -> void:
	_quitar_selector_ruta()
	if _ascensor != null or _escaleras != null:
		return
	_ascensor = ESCENA_ASCENSOR.instantiate()
	add_child(_ascensor)
	_ascensor.terminada.connect(_cerrar_ascensor)
	_ascensor.reproducir(
		AscensorCinematica.planos_de(Cinematica.vistas_de(partida.estado, AscensorCinematica.ID)),
		AscensorCinematica.ID,
		partida.estado
	)


func _iniciar_escaleras() -> void:
	_quitar_selector_ruta()
	if _ascensor != null or _escaleras != null:
		return
	_escaleras = ESCENA_ESCALERAS.instantiate()
	add_child(_escaleras)
	_escaleras.terminada.connect(_cerrar_escaleras)


func _cerrar_ascensor() -> void:
	if _ascensor == null:
		return
	_ascensor.queue_free()
	_ascensor = null
	_restaurar_dia_tras_transito()
	# Solo persiste la cuenta de vistas. La nómina y el destino ya estaban en
	# disco antes de que empezara la presentación.
	_guardar_o_avisar("")


func _cerrar_escaleras() -> void:
	if _escaleras == null:
		return
	_escaleras.queue_free()
	_escaleras = null
	# La ruta jugable no escribe estado: termina exactamente en el mismo
	# `trayecto` que ya se guardó antes de abrir el selector.
	_restaurar_dia_tras_transito()


func _restaurar_dia_tras_transito() -> void:
	_caminante.set_physics_process(true)
	_hud.visible = true
