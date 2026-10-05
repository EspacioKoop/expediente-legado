## Regresión headless de buffer de input y cancelaciones (#2435).
extends SceneTree

const BUFFER = preload("res://guion/juicio_combate_input_buffer.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_entrada_temprana()
	_probar_caducidad()
	_probar_prioridad_esquiva()
	_probar_ventanas()
	_probar_finisher_comprometido()
	_probar_estado_desconocido()
	_probar_determinismo()
	print("combate_input_buffer_2435: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_entrada_temprana() -> void:
	var estado := BUFFER.encolar(BUFFER.nuevo(), BUFFER.LIGERO)
	var temprano := BUFFER.consumir(estado, BUFFER.LIGERO, 0.30)
	_comprobar(String(temprano["ejecutar"]).is_empty(), "ligero temprano queda pendiente")
	_comprobar(String(temprano["estado"]["accion"]) == BUFFER.LIGERO, "buffer conserva ligero")

	var abierto := BUFFER.consumir(temprano["estado"], BUFFER.LIGERO, 0.50)
	_comprobar(String(abierto["ejecutar"]) == BUFFER.LIGERO, "ligero se ejecuta al abrir ventana")
	_comprobar(String(abierto["estado"]["accion"]).is_empty(), "consumir vacía el buffer")


func _probar_caducidad() -> void:
	var estado := BUFFER.encolar(BUFFER.nuevo(), BUFFER.FUERTE)
	estado = BUFFER.avanzar(estado, BUFFER.BUFFER_SEGUNDOS + 0.01)
	_comprobar(String(estado["accion"]).is_empty(), "entrada caducada se descarta")
	var resultado := BUFFER.consumir(estado, BUFFER.LIGERO, 1.0)
	_comprobar(String(resultado["ejecutar"]).is_empty(), "entrada caducada nunca ejecuta tarde")


func _probar_prioridad_esquiva() -> void:
	var estado := BUFFER.encolar(BUFFER.nuevo(), BUFFER.FUERTE)
	estado = BUFFER.encolar(estado, BUFFER.ESQUIVA)
	_comprobar(String(estado["accion"]) == BUFFER.ESQUIVA, "esquiva reemplaza ataque pendiente")

	estado = BUFFER.encolar(estado, BUFFER.LIGERO)
	_comprobar(String(estado["accion"]) == BUFFER.ESQUIVA, "ataque no desplaza esquiva pendiente")

	var resultado := BUFFER.consumir(estado, BUFFER.FUERTE, 0.36)
	_comprobar(String(resultado["ejecutar"]) == BUFFER.ESQUIVA, "esquiva gana al abrir su ventana")


func _probar_ventanas() -> void:
	_comprobar(
		not BUFFER.puede_cancelar(BUFFER.LIGERO, BUFFER.LIGERO, BUFFER.LIGERO_A_LIGERO - 0.01),
		"ligero→ligero no abre antes del umbral",
	)
	_comprobar(
		BUFFER.puede_cancelar(BUFFER.LIGERO, BUFFER.LIGERO, BUFFER.LIGERO_A_LIGERO),
		"ligero→ligero abre en el umbral",
	)
	_comprobar(
		not BUFFER.puede_cancelar(BUFFER.LIGERO, BUFFER.FUERTE, BUFFER.LIGERO_A_FUERTE - 0.01),
		"ligero→fuerte espera su ventana",
	)
	_comprobar(
		BUFFER.puede_cancelar(BUFFER.LIGERO, BUFFER.FUERTE, BUFFER.LIGERO_A_FUERTE),
		"ligero→fuerte abre en el umbral",
	)
	_comprobar(
		BUFFER.puede_cancelar(BUFFER.FUERTE, BUFFER.ESQUIVA, BUFFER.ATAQUE_A_ESQUIVA),
		"fuerte permite esquiva defensiva",
	)
	_comprobar(
		not BUFFER.puede_cancelar(BUFFER.FUERTE, BUFFER.LIGERO, BUFFER.FUERTE_A_LIGERO - 0.01),
		"fuerte→ligero exige recovery tardío",
	)
	_comprobar(
		BUFFER.puede_cancelar(BUFFER.FUERTE, BUFFER.LIGERO, BUFFER.FUERTE_A_LIGERO),
		"fuerte→ligero abre al final del recovery",
	)
	_comprobar(
		not BUFFER.puede_cancelar(BUFFER.FUERTE, BUFFER.FUERTE, 1.0),
		"fuerte→fuerte no existe implícitamente",
	)
	_comprobar(
		BUFFER.puede_cancelar(BUFFER.NINGUNA, BUFFER.FUERTE, 0.0),
		"reposo consume acción válida inmediatamente",
	)


func _probar_finisher_comprometido() -> void:
	for accion in [BUFFER.LIGERO, BUFFER.FUERTE, BUFFER.ESQUIVA]:
		_comprobar(
			not BUFFER.puede_cancelar(BUFFER.FINISHER, accion, 1.0),
			"finisher no cancela hacia %s" % accion,
		)


func _probar_estado_desconocido() -> void:
	_comprobar(
		not BUFFER.puede_cancelar("animacion_desconocida", BUFFER.ESQUIVA, 1.0),
		"estado desconocido no obtiene cancelación gratis",
	)
	var invalido := BUFFER.encolar(BUFFER.nuevo(), "parry")
	_comprobar(
		String(invalido["accion"]).is_empty(), "acción fuera del contrato no entra al buffer"
	)


func _probar_determinismo() -> void:
	var a := BUFFER.encolar(BUFFER.nuevo(), BUFFER.LIGERO)
	var b := BUFFER.encolar(BUFFER.nuevo(), BUFFER.LIGERO)
	a = BUFFER.avanzar(a, 0.05)
	b = BUFFER.avanzar(b, 0.05)
	var salida_a := BUFFER.consumir(a, BUFFER.LIGERO, 0.49)
	var salida_b := BUFFER.consumir(b, BUFFER.LIGERO, 0.49)
	_comprobar(salida_a == salida_b, "mismos eventos producen misma salida")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2435 input buffer: " + mensaje)
