## Modelo declarativo del Explorador corporativo del OS98 (#536).
##
## La jerarquía, visibilidad y acceso viven aquí; la UI solo consulta este modelo.
## Las condiciones reciben un contexto de campaña explícito y testeable para no
## convertir nodos visuales en una segunda fuente de verdad narrativa.
class_name ExploradorSigaModelo
extends RefCounted

const RUTA_RAIZ := "equipo"
const RUTA_RECIENTES := "equipo/recientes"
const RUTA_PAPELERA := "equipo/papelera"

var _contexto: Dictionary = {}
var _recientes: Array[String] = []

var _entradas: Array[Dictionary] = [
	{
		"id": "equipo",
		"ruta": RUTA_RAIZ,
		"padre": "",
		"nombre": "Mi equipo",
		"tipo": "carpeta",
		"contenido": "",
		"fecha_narrativa": "",
		"visible_si": {},
		"acceso_si": {},
		"accion": "navegar",
		"persistencia": false,
	},
	{
		"id": "unidad_local",
		"ruta": "equipo/c",
		"padre": RUTA_RAIZ,
		"nombre": "Disco local (C:)",
		"tipo": "carpeta",
		"contenido": "",
		"fecha_narrativa": "",
		"visible_si": {},
		"acceso_si": {},
		"accion": "navegar",
		"persistencia": false,
	},
	{
		"id": "unidad_compartida",
		"ruta": "equipo/red",
		"padre": RUTA_RAIZ,
		"nombre": "Unidad compartida",
		"tipo": "carpeta",
		"contenido": "",
		"fecha_narrativa": "",
		"visible_si": {},
		"acceso_si": {},
		"accion": "navegar",
		"persistencia": false,
	},
	{
		"id": "mis_documentos",
		"ruta": "equipo/documentos",
		"padre": RUTA_RAIZ,
		"nombre": "Mis documentos",
		"tipo": "carpeta",
		"contenido": "",
		"fecha_narrativa": "",
		"visible_si": {},
		"acceso_si": {},
		"accion": "navegar",
		"persistencia": false,
	},
	{
		"id": "recientes",
		"ruta": RUTA_RECIENTES,
		"padre": RUTA_RAIZ,
		"nombre": "Documentos recientes",
		"tipo": "carpeta",
		"contenido": "",
		"fecha_narrativa": "",
		"visible_si": {},
		"acceso_si": {},
		"accion": "navegar",
		"persistencia": false,
	},
	{
		"id": "papelera",
		"ruta": RUTA_PAPELERA,
		"padre": RUTA_RAIZ,
		"nombre": "Papelera",
		"tipo": "carpeta",
		"contenido": "",
		"fecha_narrativa": "",
		"visible_si": {},
		"acceso_si": {},
		"accion": "navegar",
		"persistencia": false,
	},
	{
		"id": "disquete",
		"ruta": "equipo/a",
		"padre": RUTA_RAIZ,
		"nombre": "Disquete (A:)",
		"tipo": "carpeta",
		"contenido": "",
		"fecha_narrativa": "",
		"visible_si": {},
		"acceso_si": {},
		"accion": "navegar",
		"persistencia": false,
	},
	{
		"id": "administracion",
		"ruta": "equipo/c/administracion",
		"padre": "equipo/c",
		"nombre": "Administración",
		"tipo": "carpeta",
		"contenido": "",
		"fecha_narrativa": "",
		"visible_si": {},
		"acceso_si": {},
		"accion": "navegar",
		"persistencia": false,
	},
	{
		"id": "leeme",
		"ruta": "equipo/c/administracion/leeme.txt",
		"padre": "equipo/c/administracion",
		"nombre": "LEEME.TXT",
		"tipo": "texto",
		"contenido": "Carpeta de trabajo administrativa. Los documentos con consecuencias de campaña deben proceder de una regla de diseño explícita.",
		"fecha_narrativa": "1998",
		"visible_si": {},
		"acceso_si": {},
		"accion": "mostrar_contenido",
		"persistencia": false,
	},
	{
		"id": "circular_archivo",
		"ruta": "equipo/red/circular_archivo.cir",
		"padre": "equipo/red",
		"nombre": "Circular de archivo",
		"tipo": "circular",
		"contenido": "CIRCULAR INTERNA\n\nMantenga la documentación de cada jornada en su ubicación asignada y utilice las unidades compartidas solo para material de trabajo.",
		"fecha_narrativa": "1998",
		"visible_si": {},
		"acceso_si": {},
		"accion": "mostrar_contenido",
		"persistencia": false,
	},
	{
		"id": "formulario_incidencia",
		"ruta": "equipo/documentos/formulario_incidencia.frm",
		"padre": "equipo/documentos",
		"nombre": "Formulario de incidencia",
		"tipo": "formulario",
		"contenido": "FORMULARIO DE INCIDENCIA\n\nFecha: __________\nReferencia: __________\nDescripción: ______________________________\nFirma: __________",
		"fecha_narrativa": "1998",
		"visible_si": {},
		"acceso_si": {},
		"accion": "mostrar_contenido",
		"persistencia": false,
	},
	{
		"id": "registro_jornada_anterior",
		"ruta": "equipo/documentos/registro_jornada_anterior.txt",
		"padre": "equipo/documentos",
		"nombre": "Registro de jornada anterior.txt",
		"tipo": "texto",
		"contenido": "El sistema conserva un registro local de que existe una jornada anterior. No contiene pistas ni altera la progresión.",
		"fecha_narrativa": "dinámica",
		"visible_si": {"clave": "jornada", "op": ">=", "valor": 2},
		"acceso_si": {},
		"accion": "mostrar_contenido",
		"persistencia": false,
	},
	{
		"id": "enlace13_reservado",
		"ruta": "equipo/red/acreditaciones",
		"padre": "equipo/red",
		"nombre": "Acreditaciones",
		"tipo": "carpeta",
		"contenido": "",
		"fecha_narrativa": "",
		"visible_si": {"clave": "habilitar_enlace13", "op": "igual", "valor": true},
		"acceso_si": {"clave": "credenciales", "op": "incluye", "valor": "enlace13"},
		"accion": "navegar",
		"persistencia": false,
	},
]


func configurar_contexto(contexto: Dictionary) -> void:
	_contexto = contexto.duplicate(true)


func contexto() -> Dictionary:
	return _contexto.duplicate(true)


func resolver_ruta(ruta: String) -> Dictionary:
	var normalizada := normalizar_ruta(ruta)
	for entrada in _entradas:
		if String(entrada.get("ruta", "")) == normalizada:
			return entrada.duplicate(true)
	return {}


func listar_ruta(ruta: String) -> Array[Dictionary]:
	var normalizada := normalizar_ruta(ruta)
	if normalizada == RUTA_RECIENTES:
		return _listar_recientes()
	var resultado: Array[Dictionary] = []
	for entrada in _entradas:
		if String(entrada.get("padre", "")) != normalizada:
			continue
		if es_visible(entrada):
			resultado.append(entrada.duplicate(true))
	return resultado


func es_visible(entrada: Dictionary) -> bool:
	return _cumple_condicion(entrada.get("visible_si", {}) as Dictionary)


func puede_acceder(entrada: Dictionary) -> bool:
	return _cumple_condicion(entrada.get("acceso_si", {}) as Dictionary)


func registrar_apertura(id: String) -> void:
	if id.is_empty():
		return
	var entrada := _buscar_id(id)
	if entrada.is_empty() or String(entrada.get("tipo", "")) == "carpeta":
		return
	_recientes.erase(id)
	_recientes.push_front(id)
	if _recientes.size() > 8:
		_recientes.resize(8)


func documentos_recientes() -> Array[String]:
	return _recientes.duplicate()


func ruta_padre(ruta: String) -> String:
	var normalizada := normalizar_ruta(ruta)
	if normalizada == RUTA_RAIZ:
		return RUTA_RAIZ
	var partes := normalizada.split("/", false)
	if partes.size() <= 1:
		return RUTA_RAIZ
	partes.remove_at(partes.size() - 1)
	return "/".join(partes)


func normalizar_ruta(ruta: String) -> String:
	var limpia := ruta.strip_edges().replace("\\", "/").trim_prefix("/").trim_suffix("/")
	if limpia.is_empty() or limpia == ".":
		return RUTA_RAIZ
	return limpia.to_lower()


func _listar_recientes() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for id in _recientes:
		var entrada := _buscar_id(id)
		if not entrada.is_empty() and es_visible(entrada):
			resultado.append(entrada.duplicate(true))
	return resultado


func _buscar_id(id: String) -> Dictionary:
	for entrada in _entradas:
		if String(entrada.get("id", "")) == id:
			return entrada
	return {}


func _cumple_condicion(condicion: Dictionary) -> bool:
	if condicion.is_empty():
		return true
	var clave := String(condicion.get("clave", ""))
	if clave.is_empty() or not _contexto.has(clave):
		return false
	var actual: Variant = _contexto[clave]
	var esperado: Variant = condicion.get("valor")
	match String(condicion.get("op", "igual")):
		"igual":
			return actual == esperado
		">=":
			if not (actual is int or actual is float):
				return false
			if not (esperado is int or esperado is float):
				return false
			return float(actual) >= float(esperado)
		"incluye":
			if actual is Array:
				return (actual as Array).has(esperado)
			if actual is PackedStringArray:
				return (actual as PackedStringArray).has(String(esperado))
			return false
	return false
