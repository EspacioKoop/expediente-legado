extends SceneTree

const CorreoModelo := preload("res://guion/correo_siga_modelo.gd")

var _fallos := 0
var _pasadas := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var modelo := CorreoModelo.new()
	var presentes: Array[String] = ["cunado", "becario", "telefono"]

	_configurar(modelo, 1, 3, presentes)
	_comprobar(_ids(modelo) == ["sistema-buzon-alta"], "al entrar solo está el alta")

	_configurar(modelo, 1, 2, presentes)
	var media_manana := _ids(modelo)
	_comprobar(media_manana.has("cunado-asuntos-mayusculas"), "llega el cuñado")
	_comprobar(media_manana.has("telefono-centralita"), "llega el del teléfono")
	_comprobar(not media_manana.has("correspondencia-sobres"), "ausente no escribe")
	_comprobar(not media_manana.has("becario-listado"), "el becario aún no escribe")

	_configurar(modelo, 1, 1, presentes)
	var tarde := _ids(modelo)
	_comprobar(tarde.has("becario-listado"), "el becario llega más tarde")
	_comprobar(tarde.has("spam-modem-56k"), "entra spam de época")
	_comprobar(not tarde.has("sistema-cierre-dia1"), "mantenimiento espera al cierre")

	_configurar(modelo, 1, 0, presentes)
	var cierre := _ids(modelo)
	_comprobar(cierre.has("sistema-cierre-dia1"), "el aviso llega al agotar acciones")

	_configurar(modelo, 2, 3, presentes)
	var dia_dos := _ids(modelo)
	_comprobar(dia_dos.has("sistema-cierre-dia1"), "lo ya entregado no desaparece")
	_comprobar(dia_dos.has("rrhh-formacion"), "el día dos incorpora RRHH")
	_comprobar(not dia_dos.has("emperador-orden-carpetas"), "un compañero ausente no escribe")

	var leidos: Array[String] = ["sistema-buzon-alta"]
	_comprobar(
		modelo.contar_no_leidos(leidos) == dia_dos.size() - 1,
		"leer solo cambia el contador y no la bandeja"
	)

	_comprobar(
		modelo.opciones_respuesta("cunado-asuntos-mayusculas").size() == 3,
		"el cuñado ofrece tres respuestas declarativas"
	)
	_comprobar(
		modelo.opciones_respuesta("sistema-buzon-alta").is_empty(),
		"los mensajes de sistema no se pueden responder"
	)

	var respuestas := {
		"cunado-asuntos-mayusculas": {
			"opcion_id": "quien-lo-dijo",
			"dia": 1,
			"acciones": 2,
		}
	}
	modelo.configurar_respuestas_enviadas(respuestas)
	_configurar(modelo, 1, 2, presentes)
	_comprobar(
		not _ids(modelo).has("contestacion-cunado-asuntos-mayusculas-quien-lo-dijo"),
		"la réplica no llega en el mismo instante del envío"
	)

	_configurar(modelo, 1, 1, presentes)
	var id_cunado := "contestacion-cunado-asuntos-mayusculas-quien-lo-dijo"
	var tras_otra_accion := _ids(modelo)
	_comprobar(tras_otra_accion.has(id_cunado), "el cuñado contesta tras avanzar la jornada")
	var contestacion_cunado := _mensaje(modelo, id_cunado)
	_comprobar(
		String(contestacion_cunado.get("asunto", "")).begins_with("RE:"),
		"la contestación mantiene forma de hilo"
	)
	_comprobar(
		String(contestacion_cunado.get("respuesta_a", "")) == "cunado-asuntos-mayusculas",
		"la contestación conserva referencia al correo original"
	)
	_comprobar(
		contestacion_cunado.get("importancia_narrativa", true) == false,
		"contestar no convierte el correo en una pista sistémica"
	)
	_comprobar(
		String(contestacion_cunado.get("cuerpo", "")).contains("me haces dudar"),
		"la réplica conserva la voz insegura del cuñado"
	)

	respuestas["telefono-centralita"] = {
		"opcion_id": "como-te-pasas",
		"dia": 1,
		"acciones": 0,
	}
	respuestas["correspondencia-sobres"] = {
		"opcion_id": "de-donde-vienen",
		"dia": 1,
		"acciones": 0,
	}
	modelo.configurar_respuestas_enviadas(respuestas)
	_configurar(modelo, 1, 0, presentes)
	var id_telefono := "contestacion-telefono-centralita-como-te-pasas"
	_comprobar(not _ids(modelo).has(id_telefono), "una respuesta al cierre espera al día siguiente")

	_configurar(modelo, 2, Jornada.ACCIONES_POR_DIA, presentes)
	var siguiente_manana := _ids(modelo)
	_comprobar(siguiente_manana.has(id_telefono), "el del teléfono responde al abrir el día siguiente")
	_comprobar(siguiente_manana.has(id_cunado), "las conversaciones anteriores permanecen visibles")
	_comprobar(
		not siguiente_manana.has("contestacion-correspondencia-sobres-de-donde-vienen"),
		"no aparece una réplica de un compañero ausente"
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _configurar(modelo: Variant, dia: int, acciones: int, presentes: Array[String]) -> void:
	(
		modelo
		. configurar_contexto(
			{
				"dia": dia,
				"acciones": acciones,
				"fase": "archivo",
				"companeros": presentes,
			}
		)
	)


func _ids(modelo: Variant) -> Array[String]:
	var resultado: Array[String] = []
	for mensaje in modelo.mensajes_disponibles():
		resultado.append(String(mensaje.get("id", "")))
	return resultado


func _mensaje(modelo: Variant, mensaje_id: String) -> Dictionary:
	for mensaje in modelo.mensajes_disponibles():
		if String(mensaje.get("id", "")) == mensaje_id:
			return (mensaje as Dictionary).duplicate(true)
	return {}


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
