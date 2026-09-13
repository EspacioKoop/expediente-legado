## Capa de #85 y #84 sobre el día completo.
##
## La economía del alquiler vive en Jornada. Esta capa hace visible el trámite
## en el trayecto y traduce su impago a espacio: mientras el alquiler siga
## pendiente en vencimiento —o ya haya un impago en esta vida laboral— la fase
## `casa` se representa como la oficina de noche. No duplica importes ni deuda.
extends "res://guion/dia_ascensor_app.gd"

const DESTINO_ALQUILER := "alquiler"


## Dormir sin vivienda conserva el mapa de esta vida laboral, pero no lo hace
## crecer: una sola escena repetida expresa el sueño degradado de #84.
func _opciones_sueno() -> Dictionary:
	if _vivienda() == "oficina":
		return {"cantidad": 1, "priorizar_vistas": true, "recordar_mapa": false}
	return super._opciones_sueno()


## La vivienda no necesita otro contador persistido: la consecuencia sale del
## mismo estado de alquiler que ya se guarda. Al reasignar, Jornada crea otra
## vida laboral con alquiler limpio y esta función vuelve automáticamente a
## `casa`; el gato, en cambio, conserva su ausencia.
func _vivienda() -> String:
	if int(jornada.get("alquiler", {}).get("impagos", 0)) > 0:
		return "oficina"
	if _impago_inminente():
		return "oficina"
	return "casa"


## El vencimiento pendiente se convierte en pérdida de vivienda al terminar el
## trayecto. Hasta entonces aún se puede desviarse a la ventanilla y pagarlo.
func _impago_inminente() -> bool:
	var dia := int(jornada.get("dia", 1))
	return dia == Jornada.alquiler_vencimiento(dia) and Jornada.alquiler_pendiente(jornada)


## La ventanilla existe físicamente solo cuando hoy toca pagar y el vencimiento
## sigue pendiente. En los demás días la calle conserva exactamente su planta.
## Si ya no hay casa, la fase doméstica reutiliza la misma oficina sin reparto,
## con un camastro provisional y una única salida para dormir.
func _espacio_de(fase: String) -> Dictionary:
	if fase == "casa" and _vivienda() == "oficina":
		var refugio := EspaciosCatalogo.de_fase("archivo").duplicate(true)
		refugio["figuras"] = []
		refugio["bultos"].append(
			{
				"pos": Vector3(-4.0, 0.16, 2.5),
				"tam": Vector3(1.2, 0.32, 2.0),
				"color": Color(0.28, 0.28, 0.30)
			}
		)
		refugio["salidas"] = [
			{
				"pos": Vector3(-4.0, 1.1, 2.5),
				"destino": "sueño",
				"rotulo": "SALIDA_DORMIR",
				"tam": Vector3(2.0, 2.2, 2.4)
			}
		]
		return refugio

	var sitio: Dictionary = super._espacio_de(fase)
	if fase != "trayecto" or not _alquiler_disponible_hoy():
		return sitio

	# Un mostrador pequeño metido en el lateral de la calle. Son cajas a
	# propósito: #85 prueba el trámite, no estrena un pack de mobiliario.
	sitio["bultos"].append(
		{
			"pos": Vector3(3.55, 1.1, 9.0),
			"tam": Vector3(1.35, 2.2, 2.4),
			"color": Color(0.31, 0.30, 0.29)
		}
	)
	sitio["bultos"].append(
		{
			"pos": Vector3(2.85, 0.65, 9.0),
				"tam": Vector3(0.55, 1.3, 1.8),
				"color": Color(0.47, 0.45, 0.41)
			}
	)
	(
		sitio["salidas"]
		. append(
			{
				"pos": Vector3(2.45, 1.1, 9.0),
				"destino": DESTINO_ALQUILER,
				# Es la MISMA ventanilla de #58: el rótulo común deja esa decisión
				# visible sin crear una segunda institución en la calle.
				"rotulo": "VENTANILLA_TITULO",
				"tam": Vector3(1.8, 2.2, 2.2)
			}
		)
	)
	return sitio


func _alquiler_disponible_hoy() -> bool:
	var dia := int(jornada.get("dia", 1))
	return dia == Jornada.alquiler_vencimiento(dia) and Jornada.alquiler_pendiente(jornada)


## La salida especial no cambia de fase. Pisar el mostrador equivale a hacer
## cola y ser atendido: Jornada valida fase, vencimiento, acción y dinero.
##
## Si se abandona el trayecto con el vencimiento aún pendiente, se materializa
## la pérdida de vivienda ANTES de montar el refugio. No hay cinemática ni
## aviso: al llegar a la oficina nocturna el gato ya no está y cualquier objeto
## que se hubiera dejado en casa deja de estar disponible.
func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	if (
		cuerpo == _caminante
		and _pantalla == null
		and not partida.guardado_pendiente
		and String(salida.get_meta("destino", "")) == DESTINO_ALQUILER
	):
		_pagar_alquiler()
		return

	if (
		cuerpo == _caminante
		and _pantalla == null
		and not partida.guardado_pendiente
		and jornada.get("fase", "") == "trayecto"
		and String(salida.get_meta("destino", "")) == "casa"
		and _impago_inminente()
	):
		_perder_vivienda()

	super._al_pisar_salida(cuerpo, salida)


## #97 separa lo que llevas encima de lo almacenado en casa. #84 consume ese
## contrato sin decidir dónde ni cuándo se crea el inventario persistente: si
## la partida ya lo trae, perder la vivienda elimina solo `home_storage`.
## `carried` no se toca porque son precisamente las cosas que llevabas contigo.
func _perder_vivienda() -> void:
	jornada["gato"]["presente"] = false
	var inventario = partida.estado.get("inventario", null)
	if typeof(inventario) == TYPE_DICTIONARY:
		Inventario.perder_casa(inventario)


func _pagar_alquiler() -> void:
	var resultado := Jornada.pagar_alquiler(jornada)
	_hablando = false
	if resultado.is_empty():
		_sonar("error")
		# El HUD ya expone día y dinero; repetir el trámite o llegar sin saldo
		# no inventa un cobro ni una explicación nueva. El sonido marca que la
		# operación no se produjo y Jornada conserva el estado intacto.
		_nomina.text = (
			tr("DIA_ROTULO") % [jornada["dia"], tr("VENTANILLA_TITULO"), jornada["dinero"], ""]
		)
		return

	_sonar("nomina")
	# Reutiliza el resumen económico existente: el alquiler forma parte del
	# coste de vivir y evita meter una segunda redacción provisional en el CSV.
	_nomina.text = tr("DIA_VIVIR") % [resultado["importe"], resultado["dinero"], ""]
	# El pago ya está aplicado en memoria. Si falla el disco, el mecanismo común
	# bloquea nuevas acciones y convierte la siguiente interacción en reintento.
	_guardar_o_avisar("")
