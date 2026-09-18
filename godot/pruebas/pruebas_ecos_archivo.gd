extends SceneTree

const Ecos := preload("res://guion/ecos_archivo.gd")
const Puzzle := preload("res://guion/puzzle_onirico.gd")
const Presentacion := preload("res://guion/ecos_archivo_presentacion.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_fuentes_y_fragmentos()
	_probar_determinismo()
	_probar_resolucion_y_fallo()
	_probar_deshacer_antes_de_comprometer()
	_probar_salida_y_foco()
	_probar_reentrada()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_fuentes_y_fragmentos() -> void:
	var frase := "el archivo devuelve cada nombre convertido en otra cosa"
	var no_leido = Ecos.crear("F-9", frase, ["F-1"], 17)
	_comprobar(no_leido == null, "rechaza un folio que no se leyó hoy")

	var demasiado_corta = Ecos.crear("F-1", "dos palabras", ["F-1"], 17)
	_comprobar(demasiado_corta == null, "rechaza frases que no pueden formar tres ecos")

	var ecos = Ecos.crear("F-1", frase, ["F-1"], 17, "P-1")
	_comprobar(ecos != null, "crea ecos desde una frase de un folio leído")
	_comprobar(ecos.nucleo.reward_id == "P-1", "transporta la recompensa catalogada del puzzle")
	_comprobar(ecos.fragmentos.size() == 3, "genera exactamente tres fragmentos")
	_comprobar(
		" ".join(ecos.fragmentos) == frase,
		"los tres fragmentos recompuestos conservan exactamente la frase original"
	)
	_comprobar(ecos.ecos_presentados().size() == 3, "presenta exactamente tres ecos")


func _probar_determinismo() -> void:
	var frase := "nadie recuerda por qué la puerta estaba abierta ayer"
	var a = Ecos.crear("F-2", frase, ["F-2"], 4431)
	var b = Ecos.crear("F-2", frase, ["F-2"], 4431)
	_comprobar(a.fragmentos == b.fragmentos, "misma frase produce los mismos fragmentos")
	_comprobar(a.presentacion == b.presentacion, "misma raíz conserva el orden deformado")
	_comprobar(a.presentacion != [0, 1, 2], "el puzzle nunca aparece ya resuelto")
	_comprobar(a.nucleo.seed == b.nucleo.seed, "la semilla del núcleo también es estable")


func _probar_resolucion_y_fallo() -> void:
	var frase := "tres sellos cambian de sitio cuando nadie los mira"
	var ecos = Ecos.crear("F-3", frase, ["F-3"], 91)
	_comprobar(ecos.probar([0, 1]) == "invalido", "una secuencia incompleta no consume intento")
	_comprobar(ecos.intentos == 0, "la entrada inválida deja los intentos intactos")
	_comprobar(ecos.probar([0, 1, 2]) == "completado", "el orden original completa el puzzle")
	_comprobar(ecos.nucleo.state == Puzzle.ESTADO_COMPLETADO, "completar deja el núcleo terminal")
	_comprobar(ecos.probar([0, 1, 2]) == "cerrado", "un puzzle completado no vuelve a resolverse")

	var fallido = Ecos.crear("F-4", frase, ["F-4"], 92)
	_comprobar(
		fallido.probar([2, 1, 0]) == "dispersado",
		"el primer orden completo incorrecto dispersa los ecos",
	)
	_comprobar(fallido.intentos == 1, "solo existe una secuencia completa comprometida")
	_comprobar(
		fallido.intentos == Ecos.MAX_INTENTOS,
		"la dispersión ocurre en el único intento declarado",
	)
	_comprobar(fallido.nucleo.state == Puzzle.ESTADO_FALLADO, "dispersarse registra fallo terminal")
	_comprobar(
		fallido.probar([0, 1, 2]) == "cerrado",
		"tras fallar no puede probar la permutación correcta",
	)
	_comprobar(fallido.salir(), "tras dispersarse sigue existiendo salida segura")


func _probar_deshacer_antes_de_comprometer() -> void:
	var frase := "una nota rota conserva todavía el orden de sus palabras"
	var ecos = Ecos.crear("F-UNDO", frase, ["F-UNDO"], 123)
	var presentacion = Presentacion.crear(ecos)
	_comprobar(presentacion != null, "crea presentación para una respuesta reversible")
	presentacion.foco = 0
	_comprobar(
		presentacion.seleccionar() == Presentacion.EVENTO_SELECCIONADO,
		"el primer eco queda seleccionado sin comprometer respuesta",
	)
	_comprobar(presentacion.seleccion.size() == 1, "la selección parcial queda visible")
	_comprobar(
		presentacion.seleccionar() == Presentacion.EVENTO_DESHECHO,
		"volver a activar el último eco lo retira",
	)
	_comprobar(presentacion.seleccion.is_empty(), "deshacer limpia la selección parcial")
	_comprobar(ecos.intentos == 0, "deshacer antes del tercero no consume el intento")
	_comprobar(
		ecos.nucleo.state == Puzzle.ESTADO_PENDIENTE, "deshacer mantiene el núcleo pendiente"
	)


func _probar_salida_y_foco() -> void:
	var ecos = Ecos.crear("F-5", "la voz llega desde una habitación que no existe", ["F-5"], 111)
	_comprobar(ecos.salir(), "se puede abandonar un puzzle pendiente")
	_comprobar(ecos.nucleo.state == Puzzle.ESTADO_ABANDONADO, "salir registra abandono")
	_comprobar(ecos.salir(), "salir de nuevo de un terminal sigue siendo seguro")
	_comprobar(ecos.mover_foco(0, -1) == 2, "el foco envuelve hacia la izquierda")
	_comprobar(ecos.mover_foco(2, 1) == 0, "el foco envuelve hacia la derecha")
	_comprobar(ecos.mover_foco(1, 0) == 1, "sin dirección el foco permanece")
	_comprobar(
		ecos.politica_presentacion(true) == {"animar": false, "duracion": 0.0},
		"reducir movimiento elimina animación y transición"
	)
	_comprobar(
		ecos.politica_presentacion(false)["animar"],
		"sin reducción de movimiento la presentación puede animarse"
	)


func _probar_reentrada() -> void:
	var frase := "el rótulo conserva una palabra incluso después de romperse"
	var ecos = Ecos.crear("F-6", frase, ["F-6"], 555, "P-6")
	var antes: Array = ecos.presentacion.duplicate()
	var texto := JSON.stringify(ecos.serializar())
	var datos: Dictionary = JSON.parse_string(texto)
	var restaurado = Ecos.restaurar(datos, frase, ["F-6"])
	_comprobar(restaurado != null, "reentra después de serializar por JSON")
	_comprobar(restaurado.intentos == 0, "un pendiente restaurado conserva el intento intacto")
	_comprobar(restaurado.presentacion == antes, "reentrar conserva el orden deformado")
	_comprobar(restaurado.nucleo.reward_id == "P-6", "reentrar conserva la recompensa dirigida")
	_comprobar(restaurado.probar([0, 1, 2]) == "completado", "se puede completar tras reentrar")

	var sin_folio = Ecos.restaurar(datos, frase, [])
	_comprobar(sin_folio == null, "reentrar vuelve a exigir que el folio se leyera hoy")

	var manipulado := datos.duplicate(true)
	manipulado["intentos"] = Ecos.MAX_INTENTOS
	_comprobar(
		Ecos.restaurar(manipulado, frase, ["F-6"]) == null,
		"rechaza un pendiente manipulado que ya consumió su única respuesta",
	)

	var fallido = Ecos.crear("F-7", frase, ["F-7"], 777)
	fallido.probar([2, 1, 0])
	var datos_fallido: Dictionary = JSON.parse_string(JSON.stringify(fallido.serializar()))
	var restaurado_fallido = Ecos.restaurar(datos_fallido, frase, ["F-7"])
	_comprobar(restaurado_fallido != null, "restaura un fallo terminal coherente")
	_comprobar(
		restaurado_fallido.nucleo.state == Puzzle.ESTADO_FALLADO,
		"el fallo sigue siendo terminal tras recargar",
	)
	_comprobar(
		restaurado_fallido.probar([0, 1, 2]) == "cerrado",
		"recargar no abre una segunda permutación",
	)

	var contador_falso := datos_fallido.duplicate(true)
	contador_falso["intentos"] = 0
	_comprobar(
		Ecos.restaurar(contador_falso, frase, ["F-7"]) == null,
		"rechaza un fallo terminal con contador contradictorio",
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Ecos del archivo: " + nombre)
