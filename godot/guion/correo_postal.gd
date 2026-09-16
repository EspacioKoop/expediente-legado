## Correo postal físico del portal (#672).
##
## Este módulo no crea otra bandeja de tareas ni otra economía. Deriva qué piezas
## existen a partir de la jornada y solo persiste qué sobres ya se recogieron.
## Las piezas puramente narrativas desaparecen del buzón al recogerlas; un paquete
## con objeto delega siempre en Inventario (#97).
class_name CorreoPostal
extends RefCounted

const CLAVE := "correo_postal"
const RECOGIDOS := "recogidos"

const CATALOGO := [
	{
		"id": "publicidad_ultramarinos",
		"categoria": "publicidad",
		"remitente": "Ultramarinos La Esquina",
		"asunto": "Ofertas de la semana",
		"contenido": "Un folleto doblado con conservas, detergente y café en oferta.",
		"desde": 1,
		"cada": 3,
		"resto": 1,
	},
	{
		"id": "factura_agua",
		"categoria": "factura",
		"remitente": "Aguas Municipales",
		"asunto": "Lectura bimestral",
		"contenido": "Recibo doméstico. Recogerlo no cobra nada: cualquier efecto económico pertenece a #93/#83.",
		"desde": 2,
		"cada": 5,
		"resto": 2,
		"economia": "delegada",
	},
	{
		"id": "catalogo_electronica",
		"categoria": "catalogo",
		"remitente": "Electro Hogar 98",
		"asunto": "Catálogo otoño/invierno",
		"contenido": "Televisores, radiocasetes, aspiradores y pequeños electrodomésticos impresos a dos tintas.",
		"desde": 3,
		"cada": 4,
		"resto": 3,
	},
	{
		"id": "circular_comunidad",
		"categoria": "comunidad",
		"remitente": "Comunidad de propietarios",
		"asunto": "Aviso del portal",
		"contenido": "La puerta vuelve a quedarse mal cerrada. Se ruega comprobar el pestillo al entrar.",
		"desde": 4,
		"cada": 6,
		"resto": 4,
	},
	{
		"id": "carta_manuela",
		"categoria": "personal",
		"remitente": "Manuela, 3.º B",
		"asunto": "Sobre sin sello",
		"contenido": "Una nota breve agradece que no se deje comida en el rellano y pregunta por el gato.",
		"desde": 2,
		"cada": 7,
		"resto": 2,
		"requiere_gato": true,
	},
	{
		"id": "aviso_alquiler",
		"categoria": "notificacion",
		"remitente": "Administración de fincas",
		"asunto": "Vencimiento de alquiler",
		"contenido": "Recordatorio del vencimiento. El pago sigue resolviéndose exclusivamente mediante la economía existente.",
		"desde": 10,
		"requiere_alquiler_pendiente": true,
		"economia": "delegada",
	},
	{
		"id": "paquete_calendario_magnetico",
		"categoria": "paquete",
		"remitente": "Galerías Avenida",
		"asunto": "Muestra promocional",
		"contenido": "Un sobre acolchado contiene un pequeño calendario magnético para la nevera.",
		"dias": [4],
		"objeto": {
			"id": "postal_iman_calendario",
			"nombre": "Calendario magnético 1998",
			"categoria": "hogar",
			"origen": "correo_postal",
			"vendible": false,
			"precio": 0,
		},
	},
	{
		"id": "certificado_siga",
		"categoria": "certificado",
		"remitente": "SIGA · Personal",
		"asunto": "Comunicación certificada",
		"contenido": "El sobre confirma únicamente que existe una comunicación administrativa; no revela expedientes no conocidos.",
		"desde": 3,
		"min_cerrados_hoy": 1,
	},
]


static func estado(jornada: Dictionary) -> Dictionary:
	if typeof(jornada.get(CLAVE)) != TYPE_DICTIONARY:
		jornada[CLAVE] = {RECOGIDOS: []}
	var actual: Dictionary = jornada[CLAVE]
	if typeof(actual.get(RECOGIDOS)) != TYPE_ARRAY:
		actual[RECOGIDOS] = []
	return actual


static func catalogo() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for pieza in CATALOGO:
		salida.append(pieza.duplicate(true))
	return salida


static func disponibles(jornada: Dictionary) -> Array[Dictionary]:
	var recogidos: Array = estado(jornada)[RECOGIDOS]
	var salida: Array[Dictionary] = []
	for base in CATALOGO:
		var id_pieza := String(base.get("id", ""))
		if id_pieza.is_empty() or recogidos.has(id_pieza) or not _cumple(base, jornada):
			continue
		var pieza: Dictionary = base.duplicate(true)
		pieza["fecha"] = int(jornada.get("dia", 1))
		salida.append(pieza)
	return salida


static func siguiente(jornada: Dictionary) -> Dictionary:
	var pendientes := disponibles(jornada)
	if pendientes.is_empty():
		return {}
	return pendientes[0].duplicate(true)


static func recoger(jornada: Dictionary, inventario: Dictionary, pieza_id: String) -> Dictionary:
	if String(jornada.get("fase", "")) != "trayecto":
		return _fallo(pieza_id, "fuera_del_portal")

	var pieza := _buscar_disponible(jornada, pieza_id)
	if pieza.is_empty():
		return _fallo(pieza_id, "no_disponible")

	var objeto = pieza.get("objeto", {})
	var objeto_agregado := false
	if typeof(objeto) == TYPE_DICTIONARY and not objeto.is_empty():
		Inventario.completar(inventario)
		if not Inventario.recoger(inventario, objeto):
			return _fallo(pieza_id, "inventario_rechazado")
		objeto_agregado = true

	var postal := estado(jornada)
	var recogidos: Array = postal[RECOGIDOS]
	recogidos.append(pieza_id)
	postal[RECOGIDOS] = recogidos
	return {
		"ok": true,
		"pieza": pieza.duplicate(true),
		"objeto_agregado": objeto_agregado,
	}


static func recoger_siguiente(jornada: Dictionary, inventario: Dictionary) -> Dictionary:
	var pieza := siguiente(jornada)
	if pieza.is_empty():
		return _fallo("", "buzon_vacio")
	return recoger(jornada, inventario, String(pieza["id"]))


static func _buscar_disponible(jornada: Dictionary, pieza_id: String) -> Dictionary:
	for pieza in disponibles(jornada):
		if String(pieza.get("id", "")) == pieza_id:
			return pieza
	return {}


static func _cumple(pieza: Dictionary, jornada: Dictionary) -> bool:
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var dias = pieza.get("dias", [])
	if typeof(dias) == TYPE_ARRAY and not dias.is_empty() and not dias.has(dia):
		return false

	var desde := int(pieza.get("desde", 1))
	if dia < desde:
		return false
	var hasta := int(pieza.get("hasta", 0))
	if hasta > 0 and dia > hasta:
		return false

	var cada := int(pieza.get("cada", 0))
	if cada > 0:
		var resto := int(pieza.get("resto", desde % cada))
		if dia % cada != resto % cada:
			return false

	if bool(pieza.get("requiere_gato", false)):
		var gato = jornada.get("gato", {})
		if typeof(gato) != TYPE_DICTIONARY or not bool(gato.get("presente", false)):
			return false

	var min_cerrados := int(pieza.get("min_cerrados_hoy", 0))
	if int(jornada.get("cerrados_hoy", 0)) < min_cerrados:
		return false

	if bool(pieza.get("requiere_alquiler_pendiente", false)):
		if dia % Jornada.DIAS_POR_MES != 0:
			return false
		var alquiler = jornada.get("alquiler", {})
		if typeof(alquiler) != TYPE_DICTIONARY:
			return false
		if int(alquiler.get("ultimo_resuelto", 0)) >= dia:
			return false

	return true


static func _fallo(pieza_id: String, motivo: String) -> Dictionary:
	return {
		"ok": false,
		"id": pieza_id,
		"motivo": motivo,
	}
