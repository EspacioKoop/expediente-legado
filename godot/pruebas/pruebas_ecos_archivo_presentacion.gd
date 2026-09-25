extends SceneTree

const Ecos := preload("res://guion/ecos_archivo.gd")
const Presentacion := preload("res://guion/ecos_archivo_presentacion.gd")
const Puzzle := preload("res://guion/puzzle_onirico.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_vista_y_foco()
	_probar_seleccion_y_correccion()
	_probar_completar()
	_probar_fallo_y_salida()
	_probar_manifestaciones_documentales()
	_probar_reduccion_movimiento()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _nuevo(folio: String, semilla: int = 161, tipo_documental: String = ""):
	var frase := "la puerta recuerda el nombre que el archivo intentó borrar"
	var ecos = Ecos.crear(folio, frase, [folio], semilla)
	return Presentacion.crear(ecos, tipo_documental)


func _probar_vista_y_foco() -> void:
	var presentacion = _nuevo("F-P1")
	_comprobar(presentacion != null, "crea presentación sobre un EcosArchivo válido")
	var vista: Dictionary = presentacion.vista(false)
	_comprobar(vista["elementos"].size() == 3, "expone tres elementos focusables")
	_comprobar(vista["foco"] == 0, "el foco inicial es determinista")
	_comprobar(vista["elementos"][0]["foco"], "el primer elemento refleja el foco")
	_comprobar(vista["salida_disponible"], "la salida siempre figura disponible")
	_comprobar(not str(vista["regla"]).is_empty(), "expone una regla antes de actuar")
	_comprobar(presentacion.mover(-1) == 2, "el foco envuelve hacia la izquierda")
	_comprobar(presentacion.mover(1) == 0, "el foco envuelve hacia la derecha")


func _probar_seleccion_y_correccion() -> void:
	var presentacion = _nuevo("F-P2", 202)
	var primer_id := int(presentacion.vista(false)["elementos"][0]["id"])
	_comprobar(
		presentacion.seleccionar() == Presentacion.EVENTO_SELECCIONADO,
		"seleccionar añade el eco bajo foco"
	)
	_comprobar(presentacion.seleccion == [primer_id], "la selección guarda ids canónicos")
	_comprobar(
		presentacion.ecos.seleccion == [primer_id],
		"la selección visual muta el estado serializable del puzzle",
	)
	_comprobar(
		presentacion.seleccionar() == Presentacion.EVENTO_DESHECHO,
		"reactivar el último eco deshace la elección"
	)
	_comprobar(presentacion.seleccion.is_empty(), "reactivar limpia la última elección")
	_comprobar(
		presentacion.seleccionar() == Presentacion.EVENTO_SELECCIONADO,
		"se puede volver a seleccionar después de corregir"
	)
	_comprobar(presentacion.deshacer(), "la operación semántica deshacer sigue disponible")
	_comprobar(presentacion.seleccion.is_empty(), "deshacer elimina la última elección")
	_comprobar(not presentacion.deshacer(), "deshacer vacío es inocuo")
	_comprobar(
		presentacion.confirmar() == Presentacion.EVENTO_INCOMPLETO,
		"confirmar una secuencia incompleta no consume respuesta",
	)
	_comprobar(presentacion.ecos.intentos == 0, "confirmar incompleto no gasta intento")


func _probar_completar() -> void:
	var presentacion = _nuevo("F-P3", 303)
	_seleccionar_id(presentacion, 0)
	_seleccionar_id(presentacion, 1)
	var resultado := _seleccionar_id(presentacion, 2)
	_comprobar(resultado == Presentacion.EVENTO_LISTO, "el tercer eco solo deja la secuencia lista")
	_comprobar(
		presentacion.ecos.nucleo.state == Puzzle.ESTADO_PENDIENTE,
		"la secuencia completa sigue pendiente antes de confirmar",
	)
	_comprobar(
		presentacion.confirmar() == Presentacion.EVENTO_COMPLETADO,
		"confirmar el orden canónico completa el puzzle",
	)
	_comprobar(
		presentacion.ecos.nucleo.state == Puzzle.ESTADO_COMPLETADO,
		"la confirmación delega el cierre al núcleo reusable"
	)
	_comprobar(
		presentacion.seleccionar() == Presentacion.EVENTO_CERRADO,
		"un puzzle terminal no acepta nuevas selecciones"
	)
	_comprobar(presentacion.vista(false)["salida_disponible"], "completar conserva salida segura")


func _probar_fallo_y_salida() -> void:
	var presentacion = _nuevo("F-P4", 404)
	var listo := _seleccionar_orden(presentacion, [2, 1, 0])
	_comprobar(
		listo == Presentacion.EVENTO_LISTO,
		"un orden completo incorrecto todavía puede corregirse antes de confirmar",
	)
	_comprobar(
		presentacion.ecos.nucleo.state == Puzzle.ESTADO_PENDIENTE,
		"preparar una secuencia incorrecta no consume el intento",
	)
	var final: String = str(presentacion.confirmar())
	_comprobar(
		final == Presentacion.EVENTO_DISPERSADO,
		"confirmar el primer orden completo incorrecto dispersa los ecos"
	)
	_comprobar(
		presentacion.seleccion == [2, 1, 0],
		"la secuencia fallida permanece visible como feedback terminal"
	)
	_comprobar(presentacion.ecos.intentos == 1, "el fallo consume la única respuesta")
	_comprobar(
		presentacion.ecos.nucleo.state == Puzzle.ESTADO_FALLADO,
		"la dispersión queda como fallo terminal"
	)
	_comprobar(
		presentacion.seleccionar() == Presentacion.EVENTO_CERRADO,
		"un fallo no permite probar otra permutación"
	)
	_comprobar(presentacion.abandonar(), "un terminal sigue devolviendo control a la sala")

	var abandonada = _nuevo("F-P5", 505)
	_comprobar(abandonada.abandonar(), "se puede abandonar antes de intentar resolver")
	_comprobar(
		abandonada.ecos.nucleo.state == Puzzle.ESTADO_ABANDONADO,
		"abandonar registra el estado diferenciado"
	)
	_comprobar(
		abandonada.vista(false)["estado"] == Presentacion.EVENTO_ABANDONADO,
		"la vista refleja abandono sin inventar recompensa"
	)


func _probar_manifestaciones_documentales() -> void:
	var factura = _nuevo("F-M1", 707, "factura")
	var empleado = _nuevo("F-M2", 808, "EMPLEADO")
	var acta = _nuevo("F-M3", 909, "ACTA")
	var memo = _nuevo("F-M4", 1001, "MEMORANDO")
	_comprobar(
		factura.vista(false)["manifestacion"] == Presentacion.MANIFESTACION_REPETICION,
		"factura usa repetición visual",
	)
	_comprobar(
		empleado.vista(false)["manifestacion"] == Presentacion.MANIFESTACION_PALABRA_AUSENTE,
		"ficha de empleado usa palabra ausente",
	)
	_comprobar(
		acta.vista(false)["manifestacion"] == Presentacion.MANIFESTACION_ROTULO_DESHECHO,
		"acta usa rótulo deshecho",
	)
	_comprobar(
		memo.vista(false)["manifestacion"] == Presentacion.MANIFESTACION_ECO_LEJANO,
		"memorando usa eco lejano",
	)
	var vista_empleado: Dictionary = empleado.vista(false)
	var deformado := false
	var original_intacto := true
	for elemento in vista_empleado["elementos"]:
		if int(elemento["id"]) != 1:
			continue
		deformado = str(elemento["texto_visible"]).contains("····")
		original_intacto = not str(elemento["texto"]).contains("····")
	_comprobar(deformado, "palabra ausente deforma solo la copia visible")
	_comprobar(original_intacto, "la frase canónica permanece intacta")
	var misma_familia = _nuevo("F-M5", 2026, "FACTURA")
	_comprobar(
		misma_familia.vista(false)["manifestacion"] == factura.vista(false)["manifestacion"],
		"la manifestación depende del tipo y no de una tirada aleatoria",
	)


func _probar_reduccion_movimiento() -> void:
	var presentacion = _nuevo("F-P6", 606)
	var reducida: Dictionary = presentacion.vista(true)["movimiento"]
	var normal: Dictionary = presentacion.vista(false)["movimiento"]
	_comprobar(not reducida["animar"], "reducción de movimiento desactiva animación")
	_comprobar(reducida["duracion"] == 0.0, "reducción de movimiento elimina transición")
	_comprobar(normal["animar"], "modo normal permite animación")
	_comprobar(normal["duracion"] > 0.0, "modo normal conserva duración de transición")


func _seleccionar_id(presentacion, id: int) -> String:
	var elementos: Array = presentacion.vista(false)["elementos"]
	for indice in range(elementos.size()):
		if int(elementos[indice]["id"]) == id:
			presentacion.foco = indice
			return presentacion.seleccionar()
	return "no_encontrado"


func _seleccionar_orden(presentacion, orden: Array) -> String:
	var resultado := ""
	for id in orden:
		resultado = _seleccionar_id(presentacion, int(id))
	return resultado


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO presentación Ecos del archivo: " + nombre)
