## Modelo declarativo del chat corporativo simulado del OS98 (#666).
##
## Todo depende de estado narrativo explícito: fase, día, acciones restantes,
## plantilla, conocimiento y eventos. No usa reloj real, sockets ni procesos del
## host. La futura UI de #534/#538 puede consumir este contrato sin crear un
## protocolo IRC ni un segundo sistema de progreso.
class_name ChatCorporativoModelo
extends RefCounted

const RUTA_CATALOGO := "res://datos/chat_corporativo.json"

var _canales: Array[Dictionary] = []
var _usuarios: Array[Dictionary] = []
var _mensajes: Array[Dictionary] = []
var _canal_por_id: Dictionary = {}
var _usuario_por_id: Dictionary = {}
var _mensaje_por_id: Dictionary = {}
var _contexto: Dictionary = {}
var _historial_max := 12


func _init(ruta: String = RUTA_CATALOGO) -> void:
	_cargar_catalogo(ruta)


func configurar_contexto(contexto: Dictionary) -> void:
	_contexto = contexto.duplicate(true)


func canales_visibles() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	if not _en_archivo():
		return resultado
	for canal in _canales:
		if _cumple_condiciones(canal):
			resultado.append(canal.duplicate(true))
	resultado.sort_custom(_orden_canales)
	return resultado


func perfil_usuario(usuario_id: String) -> Dictionary:
	var usuario: Variant = _usuario_por_id.get(usuario_id, {})
	if not usuario is Dictionary or (usuario as Dictionary).is_empty():
		return {}
	var copia := (usuario as Dictionary).duplicate(true)
	copia["estado"] = estado_usuario(usuario_id)
	return copia


func presencias(canal_id: String = "") -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	if not _en_archivo():
		return resultado
	if not canal_id.is_empty() and not _canal_visible(canal_id):
		return resultado
	for usuario in _usuarios:
		if not canal_id.is_empty() and not _usuario_en_canal(usuario, canal_id):
			continue
		var copia := usuario.duplicate(true)
		copia["estado"] = estado_usuario(String(usuario.get("id", "")))
		resultado.append(copia)
	resultado.sort_custom(_orden_usuarios)
	return resultado


func estado_usuario(usuario_id: String) -> String:
	var usuario: Variant = _usuario_por_id.get(usuario_id, {})
	if not usuario is Dictionary or not _en_archivo():
		return "desconectado"
	if String((usuario as Dictionary).get("tipo", "")) == "sistema":
		return "conectado"
	if not _usuario_disponible(usuario as Dictionary):
		return "desconectado"
	var dia := maxi(1, int(_contexto.get("dia", 1)))
	var minuto := _minutos(hora_narrativa())
	var estado := "desconectado"
	for valor in (usuario as Dictionary).get("presencia", []):
		if not valor is Dictionary:
			continue
		var regla := valor as Dictionary
		if _regla_presencia_aplica(regla, dia, minuto):
			estado = String(regla.get("estado", "desconectado"))
	return estado


## La hora narrativa usa la misma escala que correo_siga_modelo.gd: cuatro
## acciones recorren aproximadamente una jornada laboral. Así chat y correo
## pueden coincidir sin consultar el reloj real del equipo.
func hora_narrativa() -> String:
	var acciones := clampi(
		int(_contexto.get("acciones", Jornada.ACCIONES_POR_DIA)), 0, Jornada.ACCIONES_POR_DIA
	)
	var consumidas := Jornada.ACCIONES_POR_DIA - acciones
	var pasos := maxi(1, Jornada.ACCIONES_POR_DIA)
	var minutos := 8 * 60 + 16 + int(round(float(consumidas) * 480.0 / float(pasos)))
	return "%02d:%02d" % [int(minutos / 60), minutos % 60]


func mensajes_de_canal(canal_id: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	if not _canal_visible(canal_id):
		return resultado
	for mensaje in _mensajes:
		if String(mensaje.get("canal", "")) != canal_id:
			continue
		if _mensaje_visible(mensaje):
			resultado.append(mensaje.duplicate(true))
	resultado.sort_custom(_orden_mensajes)
	var canal: Dictionary = _canal_por_id.get(canal_id, {})
	var limite := maxi(1, int(canal.get("historial_max", _historial_max)))
	while resultado.size() > limite:
		resultado.pop_front()
	return resultado


func opciones_respuesta(mensaje_id: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var mensaje := _mensaje_visible_por_id(mensaje_id)
	if mensaje.is_empty():
		return resultado
	for valor in mensaje.get("opciones", []):
		if not valor is Dictionary:
			continue
		var opcion := valor as Dictionary
		if _cumple_condiciones(opcion):
			resultado.append(opcion.duplicate(true))
	return resultado


func resolver_respuesta(mensaje_id: String, opcion_id: String) -> Dictionary:
	for opcion in opciones_respuesta(mensaje_id):
		if String(opcion.get("id", "")) != opcion_id:
			continue
		return {
			"mensaje_id": mensaje_id,
			"opcion_id": opcion_id,
			"texto": String(opcion.get("texto", "")),
			"contestacion": String(opcion.get("contestacion", "")),
			"efecto": String(opcion.get("efecto", "")),
		}
	return {}


func enlace_de_mensaje(mensaje_id: String) -> Dictionary:
	var mensaje := _mensaje_visible_por_id(mensaje_id)
	if mensaje.is_empty():
		return {}
	var enlace: Variant = mensaje.get("enlace", null)
	if not enlace is Dictionary or not _cumple_condiciones(enlace as Dictionary):
		return {}
	return (enlace as Dictionary).duplicate(true)


func _mensaje_visible_por_id(mensaje_id: String) -> Dictionary:
	var mensaje: Variant = _mensaje_por_id.get(mensaje_id, {})
	if not mensaje is Dictionary or not _mensaje_visible(mensaje as Dictionary):
		return {}
	var canal_id := String((mensaje as Dictionary).get("canal", ""))
	if not _canal_visible(canal_id):
		return {}
	return (mensaje as Dictionary).duplicate(true)


func _mensaje_visible(mensaje: Dictionary) -> bool:
	if not _cumple_condiciones(mensaje) or not _momento_alcanzado(mensaje):
		return false
	var autor_id := String(mensaje.get("autor", ""))
	var autor: Variant = _usuario_por_id.get(autor_id, {})
	if not autor is Dictionary:
		return false
	return _usuario_disponible(autor as Dictionary)


func _momento_alcanzado(mensaje: Dictionary) -> bool:
	var dia_actual := maxi(1, int(_contexto.get("dia", 1)))
	var dia_mensaje := maxi(1, int(mensaje.get("dia", 1)))
	if dia_actual > dia_mensaje:
		return true
	if dia_actual < dia_mensaje:
		return false
	return _minutos(hora_narrativa()) >= _minutos(String(mensaje.get("hora", "00:00")))


func _usuario_disponible(usuario: Dictionary) -> bool:
	if String(usuario.get("tipo", "")) == "sistema":
		return true
	var companero_id := String(usuario.get("companero_id", ""))
	if companero_id.is_empty():
		return true
	var presentes: Variant = _contexto.get("companeros", [])
	return presentes is Array and (presentes as Array).has(companero_id)


func _canal_visible(canal_id: String) -> bool:
	if not _en_archivo():
		return false
	var canal: Variant = _canal_por_id.get(canal_id, {})
	return canal is Dictionary and _cumple_condiciones(canal as Dictionary)


func _usuario_en_canal(usuario: Dictionary, canal_id: String) -> bool:
	var canales: Variant = usuario.get("canales", [])
	return canales is Array and (canales as Array).has(canal_id)


func _cumple_condiciones(elemento: Dictionary) -> bool:
	return (
		_contiene_todos(
			_contexto.get("conocimiento", []), elemento.get("requiere_conocimiento", [])
		)
		and _contiene_todos(_contexto.get("eventos", []), elemento.get("requiere_eventos", []))
	)


func _contiene_todos(disponibles: Variant, requeridos: Variant) -> bool:
	if not requeridos is Array:
		return true
	if not disponibles is Array:
		disponibles = []
	for valor in requeridos as Array:
		if not (disponibles as Array).has(String(valor)):
			return false
	return true


func _en_archivo() -> bool:
	return String(_contexto.get("fase", "archivo")) == "archivo"


func _regla_presencia_aplica(regla: Dictionary, dia: int, minuto: int) -> bool:
	var dia_regla := int(regla.get("dia", 0))
	if dia_regla != 0 and dia_regla != dia:
		return false
	var desde := _minutos(String(regla.get("desde", "00:00")))
	var hasta := _minutos(String(regla.get("hasta", "23:59")))
	return desde >= 0 and hasta >= desde and minuto >= desde and minuto <= hasta


func _minutos(hora: String) -> int:
	var partes := hora.split(":", false)
	if partes.size() != 2:
		return -1
	var horas := int(partes[0])
	var minutos := int(partes[1])
	if horas < 0 or horas > 23 or minutos < 0 or minutos > 59:
		return -1
	return horas * 60 + minutos


func _orden_canales(a: Dictionary, b: Dictionary) -> bool:
	var orden_a := int(a.get("orden", 999))
	var orden_b := int(b.get("orden", 999))
	if orden_a != orden_b:
		return orden_a < orden_b
	return String(a.get("id", "")) < String(b.get("id", ""))


func _orden_usuarios(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("nick", "")) < String(b.get("nick", ""))


func _orden_mensajes(a: Dictionary, b: Dictionary) -> bool:
	var dia_a := int(a.get("dia", 1))
	var dia_b := int(b.get("dia", 1))
	if dia_a != dia_b:
		return dia_a < dia_b
	var minuto_a := _minutos(String(a.get("hora", "00:00")))
	var minuto_b := _minutos(String(b.get("hora", "00:00")))
	if minuto_a != minuto_b:
		return minuto_a < minuto_b
	return String(a.get("id", "")) < String(b.get("id", ""))


func _cargar_catalogo(ruta: String) -> void:
	if not FileAccess.file_exists(ruta):
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not datos is Dictionary:
		return
	_historial_max = maxi(1, int((datos as Dictionary).get("historial_max", 12)))
	for valor in (datos as Dictionary).get("canales", []):
		if not valor is Dictionary:
			continue
		var canal := (valor as Dictionary).duplicate(true)
		var canal_id := String(canal.get("id", ""))
		if canal_id.is_empty() or _canal_por_id.has(canal_id):
			continue
		_canales.append(canal)
		_canal_por_id[canal_id] = canal
	for valor in (datos as Dictionary).get("usuarios", []):
		if not valor is Dictionary:
			continue
		var usuario := (valor as Dictionary).duplicate(true)
		var usuario_id := String(usuario.get("id", ""))
		if usuario_id.is_empty() or _usuario_por_id.has(usuario_id):
			continue
		_usuarios.append(usuario)
		_usuario_por_id[usuario_id] = usuario
	for valor in (datos as Dictionary).get("mensajes", []):
		if not valor is Dictionary:
			continue
		var mensaje := (valor as Dictionary).duplicate(true)
		var mensaje_id := String(mensaje.get("id", ""))
		if mensaje_id.is_empty() or _mensaje_por_id.has(mensaje_id):
			continue
		if not _canal_por_id.has(String(mensaje.get("canal", ""))):
			continue
		if not _usuario_por_id.has(String(mensaje.get("autor", ""))):
			continue
		_mensajes.append(mensaje)
		_mensaje_por_id[mensaje_id] = mensaje
