## Regresión ejecutable de verificación falsa -> El Diablo (#1029).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_probabilidad()
	_probar_tarot_por_evento()
	await _probar_ui()
	print("tarot_diablo_1029: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_probabilidad() -> void:
	_comprobar(VerificacionFalsa.debe_mostrar(0.0), "cero entra en el 30 %")
	_comprobar(VerificacionFalsa.debe_mostrar(0.2999), "un valor bajo 0.3 entra")
	_comprobar(not VerificacionFalsa.debe_mostrar(0.3), "0.3 queda fuera")
	_comprobar(not VerificacionFalsa.debe_mostrar(1.0), "uno queda fuera")


func _probar_tarot_por_evento() -> void:
	var estado := Partida.nueva()
	_comprobar(not _carta(estado, "el-diablo").get("recogida", false), "Diablo empieza sellado")
	_comprobar(VerificacionFalsa.registrar(estado), "la aparición adquiere Diablo")
	_comprobar(_carta(estado, "el-diablo").get("recogida", false), "Diablo queda recogido")
	_comprobar(estado.get("cartas_conocidas", []).has("el-diablo"), "la memoria fantasma recuerda Diablo")
	_comprobar(not VerificacionFalsa.registrar(estado), "repetir la misma vuelta es idempotente")

	Prometeo.reiniciar_vuelta(estado, 3)
	_comprobar(not _carta(estado, "el-diablo").get("recogida", false), "nueva vuelta retira posesión")
	_comprobar(estado.get("cartas_conocidas", []).has("el-diablo"), "nueva vuelta conserva memoria")
	_comprobar(VerificacionFalsa.registrar(estado), "otra vuelta puede volver a ganar Diablo")


func _probar_ui() -> void:
	var verificacion := VerificacionFalsa.new()
	root.add_child(verificacion)
	await process_frame
	_comprobar(not verificacion.visible, "la verificación nace oculta")
	verificacion.mostrar(0)
	_comprobar(verificacion.visible, "mostrar hace visible la verificación")
	var pregunta := verificacion.find_child("Pregunta", true, false) as Label
	_comprobar(pregunta != null and not pregunta.text.is_empty(), "la pregunta visible no queda vacía")
	var confirmar := verificacion.find_child("Confirmar", true, false) as Button
	_comprobar(confirmar != null, "la verificación conserva una acción enfocables")
	verificacion.ocultar()
	_comprobar(not verificacion.visible, "cancelar/cerrar la oculta")
	verificacion.queue_free()


func _carta(estado: Dictionary, id: String) -> Dictionary:
	for carta in estado.get("tarot", []):
		if String(carta.get("id", "")) == id:
			return carta
	return {}


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
