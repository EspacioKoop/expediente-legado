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


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
