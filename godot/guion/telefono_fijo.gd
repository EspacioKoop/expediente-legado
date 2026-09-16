## Teléfono fijo doméstico y contestador de la casa (#671).
##
## El tiempo es narrativo: cada llamada declara día/condiciones y una hora de
## ficción. No consulta reloj real ni abre una segunda agenda de misiones.
## El contestador evita perder contenido opcional cuando el jugador no descuelga.
class_name TelefonoFijo
extends RefCounted

const CLAVE := "telefono_fijo"
const PROCESADAS := "procesadas"
const MENSAJES := "mensajes"
const HISTORIAL := "historial"
const LLAMADA_ACTIVA := "llamada_activa"
const DIA_PREPARADO := "dia_preparado"
const DESCOLGADO := "descolgado"

const LLAMADAS := [
	{
		"id": "companero_fin_jornada",
		"remitente": "Compañero del archivo",
		"hora": "18:42",
		"dias": [1],
		"texto": "He dejado la carpeta gris donde siempre. Mañana te cuento el resto.",
		"mensaje": "He dejado la carpeta gris donde siempre. Mañana te cuento.",
	},
	{
		"id": "numero_equivocado",
		"remitente": "Número desconocido",
		"hora": "19:07",
		"desde": 2,
		"cada": 5,
		"resto": 2,
		"texto": "¿Está Julián? ... Perdón, me he equivocado de número.",
		"mensaje": "¿Julián? ... Ah. Perdón, número equivocado.",
	},
	{
		"id": "administracion_alquiler",
		"remitente": "Administración de fincas",
		"hora": "19:26",
		"desde": 9,
		"cada": 10,
		"resto": 9,
		"requiere_alquiler_pendiente": true,
		"texto": "Le recordamos que mañana vence el alquiler. Este aviso no realiza ningún cobro.",
		"mensaje": "Recordatorio: mañana vence el alquiler. Use la vía de pago habitual.",
	},
	{
		"id": "comercial_enciclopedia",
		"remitente": "Encuestas Editorial Horizonte",
		"hora": "20:11",
		"desde": 3,
		"cada": 6,
		"resto": 3,
		"texto": "Buenas tardes. Hacemos una encuesta sobre lectura en el hogar. No le robo más tiempo.",
		"mensaje": "Encuestas Editorial Horizonte. Volveremos a intentarlo otro día.",
	},
	{
		"id": "companera_cierre",
		"remitente": "Compañera del archivo",
		"hora": "20:34",
		"desde": 2,
		"cada": 4,
		"resto": 0,
		"min_cerrados_hoy": 1,
		"texto": "Vi que hoy cerraste expedientes. Te llamaba por una tontería; nada urgente.",
		"mensaje": "Te llamaba por una tontería del turno. Mañana te lo digo en persona.",
	},
	{
		"id": "centralita_interna",
		"remitente": "Centralita SIGA",
		"hora": "18:55",
		"desde": 4,
		"cada": 7,
		"resto": 4,
		"min_cerrados_hoy": 2,
		"texto": "Prueba de línea interna. No se requiere ninguna acción.",
		"mensaje": "Prueba de línea interna completada. No hace falta devolver la llamada.",
	},
]

const CONTACTOS := [
	{
		"id": "centralita_siga",
		"nombre": "Centralita SIGA",
		"numero": "555-0198",
		"texto": "Centralita SIGA. El edificio está cerrado; vuelva a llamar durante la jornada.",
	},
	{
		"id": "ultramarinos_esquina",
		"nombre": "Ultramarinos La Esquina",
		"numero": "555-0142",
		"texto": "Ultramarinos La Esquina. Han cerrado por hoy; mañana abren con normalidad.",
	},
	{
		"id": "videoclub_mirador",
		"nombre": "Videoclub Mirador",
		"numero": "555-0177",
		"texto": "Videoclub Mirador. Mensaje grabado: recuerde devolver las cintas rebobinadas.",
	},
]


static func estado(jornada: Dictionary) -> Dictionary:
	if typeof(jornada.get(CLAVE)) != TYPE_DICTIONARY:
		jornada[CLAVE] = {
			PROCESADAS: [],
			MENSAJES: [],
			HISTORIAL: [],
			LLAMADA_ACTIVA: "",
			DIA_PREPARADO: 0,
			DESCOLGADO: false,
		}
	var actual: Dictionary = jornada[CLAVE]
	for clave in [PROCESADAS, MENSAJES, HISTORIAL]:
		if typeof(actual.get(clave)) != TYPE_ARRAY:
			actual[clave] = []
	actual[LLAMADA_ACTIVA] = String(actual.get(LLAMADA_ACTIVA, ""))
	actual[DIA_PREPARADO] = int(actual.get(DIA_PREPARADO, 0))
	actual[DESCOLGADO] = bool(actual.get(DESCOLGADO, false))
	return actual


static func catalogo() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for llamada in LLAMADAS:
		salida.append(llamada.duplicate(true))
	return salida


static func contactos() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for contacto in CONTACTOS:
		salida.append(contacto.duplicate(true))
	return salida


static func preparar_casa(jornada: Dictionary) -> Dictionary:
	if String(jornada.get("fase", "")) != "casa":
		return {}
	var telefono := estado(jornada)
	var dia := maxi(1, int(jornada.get("dia", 1)))
	if int(telefono[DIA_PREPARADO]) == dia:
		return llamada_activa(jornada)
	telefono[DIA_PREPARADO] = dia
	telefono[DESCOLGADO] = false
	telefono[LLAMADA_ACTIVA] = ""
	var procesadas: Array = telefono[PROCESADAS]
	for llamada in LLAMADAS:
		var llamada_id := String(llamada.get("id", ""))
		if llamada_id.is_empty() or procesadas.has(llamada_id) or not _cumple(llamada, jornada):
			continue
		telefono[LLAMADA_ACTIVA] = llamada_id
		return _con_dia(llamada, dia)
	return {}


static func llamada_activa(jornada: Dictionary) -> Dictionary:
	var telefono := estado(jornada)
	var llamada_id := String(telefono[LLAMADA_ACTIVA])
	if llamada_id.is_empty():
		return {}
	var llamada := _buscar_llamada(llamada_id)
	if llamada.is_empty():
		telefono[LLAMADA_ACTIVA] = ""
		return {}
	return _con_dia(llamada, int(jornada.get("dia", 1)))


static func descolgar(jornada: Dictionary) -> Dictionary:
	if String(jornada.get("fase", "")) != "casa":
		return _fallo("fuera_de_casa")
	var telefono := estado(jornada)
	if bool(telefono[DESCOLGADO]):
		return _fallo("ya_descolgado")
	telefono[DESCOLGADO] = true
	var llamada := llamada_activa(jornada)
	if llamada.is_empty():
		return {"ok": true, "tipo": "tono", "texto": "Tono de línea."}

	_marcar_procesada(telefono, String(llamada["id"]))
	telefono[LLAMADA_ACTIVA] = ""
	_agregar_historial(telefono, jornada, "entrante_atendida", llamada)
	return {
		"ok": true,
		"tipo": "entrante",
		"llamada": llamada.duplicate(true),
		"texto": String(llamada.get("texto", "")),
	}


static func colgar(jornada: Dictionary) -> Dictionary:
	var telefono := estado(jornada)
	if not bool(telefono[DESCOLGADO]):
		return _fallo("ya_colgado")
	telefono[DESCOLGADO] = false
	return {"ok": true, "tipo": "colgado"}


static func pasar_a_contestador(jornada: Dictionary) -> Dictionary:
	var telefono := estado(jornada)
	var llamada := llamada_activa(jornada)
	if llamada.is_empty():
		return _fallo("sin_llamada")
	var mensaje := _guardar_mensaje(telefono, jornada, llamada)
	_marcar_procesada(telefono, String(llamada["id"]))
	telefono[LLAMADA_ACTIVA] = ""
	_agregar_historial(telefono, jornada, "entrante_contestador", llamada)
	return {"ok": true, "tipo": "mensaje", "mensaje": mensaje.duplicate(true)}


static func perder_activa(jornada: Dictionary) -> Dictionary:
	# Se llama al abandonar la casa. Si el jugador ignoró el timbre, el contenido
	# queda en la cinta en vez de exigir presencia durante una ventana de segundos.
	if llamada_activa(jornada).is_empty():
		return {}
	return pasar_a_contestador(jornada)


static func mensajes_nuevos(jornada: Dictionary) -> int:
	var total := 0
	for mensaje in estado(jornada)[MENSAJES]:
		if mensaje is Dictionary and not bool(mensaje.get("escuchado", false)):
			total += 1
	return total


static func escuchar_siguiente(jornada: Dictionary) -> Dictionary:
	var telefono := estado(jornada)
	var mensajes: Array = telefono[MENSAJES]
	for indice in range(mensajes.size()):
		var mensaje = mensajes[indice]
		if not mensaje is Dictionary or bool(mensaje.get("escuchado", false)):
			continue
		mensaje["escuchado"] = true
		mensajes[indice] = mensaje
		telefono[MENSAJES] = mensajes
		return {"ok": true, "mensaje": mensaje.duplicate(true)}
	return _fallo("sin_mensajes_nuevos")


static func llamar(jornada: Dictionary, contacto_id: String) -> Dictionary:
	if String(jornada.get("fase", "")) != "casa":
		return _fallo("fuera_de_casa")
	var telefono := estado(jornada)
	if not bool(telefono[DESCOLGADO]):
		return _fallo("auricular_colgado")
	var contacto := _buscar_contacto(contacto_id)
	if contacto.is_empty():
		return _fallo("numero_no_declarado")
	var entrada := contacto.duplicate(true)
	entrada["hora"] = "21:00"
	_agregar_historial(telefono, jornada, "saliente", entrada)
	return {
		"ok": true,
		"tipo": "saliente",
		"contacto": contacto.duplicate(true),
		"texto": String(contacto.get("texto", "")),
	}


static func _guardar_mensaje(
	telefono: Dictionary, jornada: Dictionary, llamada: Dictionary
) -> Dictionary:
	var mensaje := {
		"id": String(llamada.get("id", "")),
		"remitente": String(llamada.get("remitente", "Número desconocido")),
		"hora": String(llamada.get("hora", "")),
		"dia": int(jornada.get("dia", 1)),
		"texto": String(llamada.get("mensaje", llamada.get("texto", ""))),
		"escuchado": false,
	}
	var mensajes: Array = telefono[MENSAJES]
	mensajes.append(mensaje)
	telefono[MENSAJES] = mensajes
	return mensaje


static func _agregar_historial(
	telefono: Dictionary, jornada: Dictionary, tipo: String, item: Dictionary
) -> void:
	var historial: Array = telefono[HISTORIAL]
	var entrada := {
		"tipo": tipo,
		"id": String(item.get("id", "")),
		"dia": int(jornada.get("dia", 1)),
		"hora": String(item.get("hora", "")),
	}
	historial.append(entrada)
	telefono[HISTORIAL] = historial


static func _marcar_procesada(telefono: Dictionary, llamada_id: String) -> void:
	var procesadas: Array = telefono[PROCESADAS]
	if not procesadas.has(llamada_id):
		procesadas.append(llamada_id)
	telefono[PROCESADAS] = procesadas


static func _cumple(llamada: Dictionary, jornada: Dictionary) -> bool:
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var dias = llamada.get("dias", [])
	if typeof(dias) == TYPE_ARRAY and not dias.is_empty() and not dias.has(dia):
		return false
	var desde := int(llamada.get("desde", 1))
	if dia < desde:
		return false
	var cada := int(llamada.get("cada", 0))
	if cada > 0:
		var resto := int(llamada.get("resto", desde % cada))
		if dia % cada != resto % cada:
			return false
	if int(jornada.get("cerrados_hoy", 0)) < int(llamada.get("min_cerrados_hoy", 0)):
		return false
	if bool(llamada.get("requiere_alquiler_pendiente", false)):
		var alquiler = jornada.get("alquiler", {})
		if typeof(alquiler) != TYPE_DICTIONARY:
			return false
		if int(alquiler.get("ultimo_resuelto", 0)) >= dia + 1:
			return false
	return true


static func _buscar_llamada(llamada_id: String) -> Dictionary:
	for llamada in LLAMADAS:
		if String(llamada.get("id", "")) == llamada_id:
			return llamada.duplicate(true)
	return {}


static func _buscar_contacto(contacto_id: String) -> Dictionary:
	for contacto in CONTACTOS:
		if String(contacto.get("id", "")) == contacto_id:
			return contacto.duplicate(true)
	return {}


static func _con_dia(llamada: Dictionary, dia: int) -> Dictionary:
	var salida := llamada.duplicate(true)
	salida["dia"] = dia
	return salida


static func _fallo(motivo: String) -> Dictionary:
	return {"ok": false, "motivo": motivo}
