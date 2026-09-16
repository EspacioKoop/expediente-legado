## Prueba headless aislada del chat corporativo simulado del OS98 (#666).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var chat := ChatCorporativoModelo.new()
	var companeros := ["becario", "telefono", "cunado", "correspondencia", "jubilacion"]
	var contexto := {
		"fase": "archivo",
		"dia": 1,
		"acciones": Jornada.ACCIONES_POR_DIA,
		"companeros": companeros,
		"conocimiento": [],
		"eventos": [],
	}
	chat.configurar_contexto(contexto)

	var canales := _ids(chat.canales_visibles())
	_comprobar(canales.size() == 4, "sin incidencia hay cuatro canales normales")
	_comprobar(canales.has("planta4"), "existe el canal general")
	_comprobar(canales.has("sistemas"), "existe el canal de sistemas")
	_comprobar(canales.has("cafe"), "existe el canal de café")
	_comprobar(canales.has("despues"), "existe el canal informal")
	_comprobar(not canales.has("inc-impresora"), "el canal temporal no aparece sin evento")
	_comprobar(chat.hora_narrativa() == "08:16", "la jornada empieza en hora narrativa estable")
	_comprobar(chat.estado_usuario("becario") == "conectado", "el becario empieza conectado")
	_comprobar(chat.estado_usuario("telefono") == "conectado", "centralita empieza conectada")

	contexto["acciones"] = 3
	chat.configurar_contexto(contexto)
	_comprobar(chat.hora_narrativa() == "10:16", "consumir una acción avanza la hora narrativa")
	_comprobar(chat.estado_usuario("telefono") == "ausente", "centralita pasa a ausente")
	_comprobar(chat.estado_usuario("becario") == "ausente", "el becario puede marcar AFK")
	var mensajes_cafe := _ids(chat.mensajes_de_canal("cafe"))
	_comprobar(mensajes_cafe.has("cunado-cafe"), "el mensaje de café aparece a su hora")
	var opciones := chat.opciones_respuesta("cunado-cafe")
	_comprobar(opciones.size() == 2, "el chat ofrece respuestas cerradas cuando aportan carácter")
	var respuesta := chat.resolver_respuesta("cunado-cafe", "solo")
	_comprobar(
		String(respuesta.get("contestacion", "")).contains("sin azúcar"),
		"una opción resuelve una contestación guionizada",
	)
	_comprobar(
		chat.resolver_respuesta("cunado-cafe", "inventada").is_empty(),
		"no existe entrada de respuesta arbitraria",
	)

	contexto["acciones"] = 2
	chat.configurar_contexto(contexto)
	_comprobar(chat.hora_narrativa() == "12:16", "dos acciones sitúan la jornada al mediodía")
	_comprobar(chat.estado_usuario("becario") == "conectado", "el becario vuelve de AFK")
	_comprobar(chat.estado_usuario("cunado") == "ausente", "el compañero está fuera por café")
	_comprobar(
		chat.estado_usuario("correspondencia") == "ausente", "correspondencia refleja su reparto"
	)
	var enlace_normal := chat.enlace_de_mensaje("becario-byte-local")
	_comprobar(
		String(enlace_normal.get("recurso_id", "")) == "byte-local",
		"un enlace normal apunta al recurso web conocido",
	)

	contexto["acciones"] = 1
	chat.configurar_contexto(contexto)
	_comprobar(
		chat.estado_usuario("jubilacion") == "desconectado",
		"una persona puede desconectarse antes del cierre de jornada",
	)

	contexto["acciones"] = 2
	contexto["companeros"] = ["becario", "cunado", "correspondencia", "jubilacion"]
	chat.configurar_contexto(contexto)
	_comprobar(
		chat.estado_usuario("telefono") == "desconectado",
		"un compañero ausente de la plantilla no inventa sesión",
	)
	_comprobar(
		not _ids(chat.mensajes_de_canal("planta4")).has("telefono-centralita-chat"),
		"tampoco aparecen mensajes de una persona que no existe en esta vuelta",
	)

	contexto["companeros"] = companeros
	contexto["eventos"] = ["impresora_atascada"]
	chat.configurar_contexto(contexto)
	_comprobar(
		_ids(chat.canales_visibles()).has("inc-impresora"), "el evento abre el canal temporal"
	)
	var incidencia := _ids(chat.mensajes_de_canal("inc-impresora"))
	_comprobar(incidencia.size() == 3, "la incidencia tiene conversación breve y acotada")
	_comprobar(incidencia.has("sistema-incidencia-abierta"), "el sistema diferencia la apertura")

	contexto["dia"] = 2
	contexto["acciones"] = Jornada.ACCIONES_POR_DIA
	contexto["eventos"] = []
	chat.configurar_contexto(contexto)
	_comprobar(
		chat.estado_usuario("becario") == "ausente",
		"una regla específica de jornada prevalece sobre el horario general",
	)

	contexto["dia"] = 3
	contexto["acciones"] = 2
	chat.configurar_contexto(contexto)
	var sistemas_bloqueado := _ids(chat.mensajes_de_canal("sistemas"))
	_comprobar(
		not sistemas_bloqueado.has("sistema-diagnostico-reservado"),
		"el chat no filtra el diagnóstico reservado antes de conocerlo",
	)
	_comprobar(
		not sistemas_bloqueado.has("becario-diagnostico"),
		"un compañero tampoco filtra indirectamente el conocimiento",
	)
	_comprobar(
		chat.enlace_de_mensaje("sistema-diagnostico-reservado").is_empty(),
		"el enlace restringido no se resuelve por acceso directo",
	)

	contexto["conocimiento"] = ["enlace13"]
	chat.configurar_contexto(contexto)
	var sistemas_autorizado := _ids(chat.mensajes_de_canal("sistemas"))
	_comprobar(
		sistemas_autorizado.has("sistema-diagnostico-reservado"),
		"el conocimiento habilita el mensaje reservado",
	)
	_comprobar(
		sistemas_autorizado.has("becario-diagnostico"),
		"el comentario asociado aparece bajo la misma condición",
	)
	var enlace_reservado := chat.enlace_de_mensaje("sistema-diagnostico-reservado")
	_comprobar(
		String(enlace_reservado.get("recurso_id", "")) == "diagnostico-enlace13",
		"el enlace autorizado apunta al recurso restringido correcto",
	)
	_comprobar(
		chat.mensajes_de_canal("sistemas").size() <= 6,
		"el historial respeta el límite declarado del canal",
	)
	var perfil := chat.perfil_usuario("becario")
	_comprobar(String(perfil.get("nick", "")) == "becario4", "el nick del personaje es estable")
	_comprobar(
		not String(perfil.get("estilo", "")).is_empty(), "el perfil conserva una voz declarada"
	)

	contexto["fase"] = "casa"
	contexto["dia"] = 1
	contexto["conocimiento"] = []
	chat.configurar_contexto(contexto)
	_comprobar(
		chat.canales_visibles().is_empty(), "el chat no funciona fuera del puesto de archivo"
	)
	_comprobar(
		chat.estado_usuario("becario") == "desconectado",
		"fuera del puesto no hay presencia digital"
	)
	_comprobar(chat.mensajes_de_canal("no-existe").is_empty(), "un canal inexistente no se inventa")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


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
