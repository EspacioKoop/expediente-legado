## Prueba headless aislada de BBS y tablones archivados del OS98 (#662).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var bbs := Bbs98Modelo.new()
	var contexto := {
		"dia": 1,
		"conocimiento": [],
		"companeros": ["becario", "cunado"],
	}
	bbs.configurar_contexto(contexto)

	var recursos_catalogo := bbs.recursos_web_catalogo()
	_comprobar(recursos_catalogo.size() == 3, "Web98 puede registrar todos los BBS por adelantado")
	var recurso_byte := _por_id(recursos_catalogo, "byte-local-bbs")
	_comprobar(
		String(recurso_byte.get("paquete_software", "")) == "archivazo-21",
		"Byte Local BBS exporta el paquete ficticio sin ejecutarlo",
	)

	var tablones_dia1 := _ids(bbs.tablones_visibles())
	_comprobar(tablones_dia1.size() == 2, "el primer día solo muestra dos tablones")
	_comprobar(tablones_dia1.has("byte-local-bbs"), "Byte Local está visible desde el inicio")
	_comprobar(tablones_dia1.has("nodo-4b"), "el archivo de radio está visible desde el inicio")
	_comprobar(not tablones_dia1.has("tablon-norte"), "el tablón local respeta su jornada")

	var byte_hilos := _ids(bbs.hilos_de("byte-local-bbs"))
	_comprobar(byte_hilos.has("byte-modem-ocupado"), "el hilo normal aparece")
	_comprobar(
		not byte_hilos.has("byte-quake-sonido"),
		"la huella del compañero no aparece cuando no está en la plantilla",
	)

	contexto["companeros"] = ["telefono", "becario", "cunado"]
	bbs.configurar_contexto(contexto)
	byte_hilos = _ids(bbs.hilos_de("byte-local-bbs"))
	_comprobar(
		byte_hilos.has("byte-quake-sonido"),
		"la misma huella aparece cuando el compañero pertenece a esta vida laboral",
	)
	var perfil := bbs.perfil_usuario("linea-ocupada")
	_comprobar(String(perfil.get("companero_id", "")) == "telefono", "el nick enlaza con #125")
	_comprobar(String(perfil.get("nick", "")) == "lineaocupada", "el nick es estable")

	var modem := _ids(bbs.buscar("modem"))
	_comprobar(modem.has("byte-modem-ocupado"), "el buscador encuentra términos indexados")
	_comprobar(not modem.has("norte-monitor"), "buscar no atraviesa un tablón aún invisible")
	_comprobar(
		bbs.buscar("expediente-secreto").is_empty(),
		"un término no indexado no convierte el BBS en búsqueda de texto libre",
	)

	var mensajes := bbs.mensajes_de("radio-packet")
	_comprobar(mensajes.size() == 3, "el hilo conserva mensajes visibles y lápidas")
	var referencia := bbs.referencia_de_mensaje("radio-p2")
	_comprobar(String(referencia.get("id", "")) == "radio-p0", "una cita conserva su objetivo")
	_comprobar(
		String(referencia.get("estado", "")) == "eliminado",
		"la cita a un mensaje borrado devuelve una lápida, no inventa contenido",
	)

	contexto["dia"] = 2
	bbs.configurar_contexto(contexto)
	var tablones_dia2 := _ids(bbs.tablones_visibles())
	_comprobar(tablones_dia2.size() == 3, "el segundo día incorpora el tercer tablón")
	_comprobar(tablones_dia2.has("tablon-norte"), "el tablón local aparece en su jornada")
	_comprobar(
		_ids(bbs.buscar("monitor")).has("norte-monitor"), "su índice ya participa en búsqueda"
	)
	_comprobar(bbs.recursos_web().size() == 3, "el modelo expone destinos para Web98")

	var movido := bbs.mensajes_de("radio-movido-soldador")
	_comprobar(movido.size() == 1, "el hilo movido mantiene su aviso de sistema")
	_comprobar(
		String(movido[0].get("estado", "")) == "movido",
		"el estado movido se conserva de forma declarativa",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _por_id(elementos: Array[Dictionary], id: String) -> Dictionary:
	for elemento in elementos:
		if String(elemento.get("id", "")) == id:
			return elemento
	return {}


func _ids(elementos: Array[Dictionary]) -> Array[String]:
	var resultado: Array[String] = []
	for elemento in elementos:
		resultado.append(String(elemento.get("id", "")))
	return resultado


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
