## Vertical slice #286: relacionar manualmente dos documentos ya leídos.
##
## La capa no inventa hechos ni decide culpables. Solo permite que el jugador
## proponga una relación entre dos registros y, si el catálogo contiene una
## conclusión exacta para ese par, conserva su id en pistas_descubiertas.
extends "res://guion/visor_proyeccion_app.gd"

var _relacionar: Button
var _origen_relacion := ""


func _columna_documento() -> Control:
	var columna: Control = super._columna_documento()
	_relacionar = Button.new()
	_relacionar.text = tr("VISOR_RELACIONAR")
	_relacionar.disabled = true
	_relacionar.pressed.connect(_al_relacionar)
	columna.add_child(_relacionar)
	return columna


func _al_elegir_documento(indice: int) -> void:
	var esperado: Dictionary = caso["registros"][indice]
	super._al_elegir_documento(indice)
	# Una apertura denegada deja registro_actual apuntando al documento anterior;
	# no debe contar como lectura ni habilitarlo para una combinación.
	if registro_actual.get("id", "") != esperado.get("id", ""):
		_actualizar_boton_relacion()
		return

	var leidos: Array = jornada.get("leidos_total", [])
	if not leidos.has(registro_actual["id"]):
		leidos.append(registro_actual["id"])
		jornada["leidos_total"] = leidos
		# `jornada` se conserva completa en Partida, así que esta memoria sobrevive
		# al cambio de día y a la recarga sin crear un segundo archivo de estado.
		_guardar_o_avisar()
	_actualizar_boton_relacion()


func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_origen_relacion = ""
	_actualizar_boton_relacion()


func _al_relacionar() -> void:
	if (
		_hay_guardado_a_medias()
		or registro_actual.is_empty()
		or Acusacion.esta_cerrado(partida.estado, caso["id"])
	):
		return

	var actual := String(registro_actual["id"])
	if not _esta_leido(actual):
		_estado.text = tr("VISOR_RELACION_LEA_ANTES")
		return

	if _origen_relacion.is_empty():
		_origen_relacion = actual
		_estado.text = tr("VISOR_RELACION_PRIMERO") % registro_actual["folio"]
		_actualizar_boton_relacion()
		return

	if _origen_relacion == actual:
		_estado.text = tr("VISOR_RELACION_DISTINTO")
		return

	if not _esta_leido(_origen_relacion):
		_origen_relacion = ""
		_estado.text = tr("VISOR_RELACION_PRIMERO_INVALIDO")
		_actualizar_boton_relacion()
		return

	var relacion := _buscar_relacion(caso, _origen_relacion, actual)
	var primero := _folio_por_id(_origen_relacion)
	var segundo := String(registro_actual.get("folio", actual))
	_origen_relacion = ""
	_actualizar_boton_relacion()

	if relacion.is_empty():
		# No se afirma que la pareja jamás pueda tener sentido narrativo: solo que
		# con la evidencia catalogada todavía no se ha demostrado una conclusión.
		_estado.text = tr("VISOR_RELACION_NO_DEMOSTRADA") % [primero, segundo]
	else:
		var pista_id := String(relacion["id"])
		if descubiertas.has(pista_id):
			_estado.text = _feedback_relacion(
				primero, segundo, tr("VISOR_RELACION_YA_REGISTRADA") % relacion["descripcion"]
			)
		else:
			descubiertas.append(pista_id)
			_refrescar_archivo()
			_guardar_o_avisar()
			_estado.text = _feedback_relacion(
				primero, segundo, tr("VISOR_RELACION_REGISTRADA") % relacion["descripcion"]
			)


func _esta_leido(registro_id: String) -> bool:
	return jornada.get("leidos_total", []).has(registro_id)


func _folio_por_id(registro_id: String) -> String:
	for registro in caso.get("registros", []):
		if registro.get("id", "") == registro_id:
			return String(registro.get("folio", registro_id))
	return registro_id


func _actualizar_boton_relacion() -> void:
	if _relacionar == null:
		return
	var cerrado := caso.is_empty() or Acusacion.esta_cerrado(partida.estado, caso["id"])
	var actual := String(registro_actual.get("id", ""))
	_relacionar.disabled = actual.is_empty() or cerrado or not _esta_leido(actual)
	if _origen_relacion.is_empty():
		_relacionar.text = tr("VISOR_RELACIONAR")
	else:
		_relacionar.text = tr("VISOR_RELACIONAR_CON") % _folio_por_id(_origen_relacion)


static func _feedback_relacion(primero: String, segundo: String, mensaje: String) -> String:
	return "%s ↔ %s\n%s" % [primero, segundo, mensaje]


## La pareja es conmutativa: A+B y B+A descubren la misma conclusión.
## Solo cuentan pistas explícitamente catalogadas con dos orígenes.
static func _buscar_relacion(ficha: Dictionary, a: String, b: String) -> Dictionary:
	if a.is_empty() or b.is_empty() or a == b:
		return {}
	for pista in ficha.get("pistas", []):
		if not pista.has("registroOrigen2"):
			continue
		var uno := String(pista.get("registroOrigen", ""))
		var dos := String(pista.get("registroOrigen2", ""))
		if (uno == a and dos == b) or (uno == b and dos == a):
			return pista
	return {}
