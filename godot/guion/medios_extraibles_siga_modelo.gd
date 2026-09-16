## Modelo de medios extraíbles simulados del OS98 (#664).
##
## Los medios son datos puros: nunca enumeran dispositivos ni rutas del host. El
## Explorador decide qué unidad está montada consultando exclusivamente este modelo.
class_name MediosExtraiblesSigaModelo
extends RefCounted

const RUTA_RAIZ := "equipo"

const MEDIOS := [
	{
		"id": "disquete_trabajo_97",
		"etiqueta": "TURNOS_97",
		"tipo": "Disquete 3½",
		"capacidad": "1,44 MB",
		"unidad": "a",
		"unidad_persistente": true,
		"solo_lectura": false,
		"icono": "disquete_trabajo",
		"procedencia": "Archivador del puesto · material administrativo heredado",
		"obtener_si": {},
		"entradas": [
			{
				"id": "turnos_97_formularios",
				"ruta_relativa": "formularios",
				"padre_relativo": "",
				"nombre": "FORMULARIOS",
				"tipo": "carpeta",
				"contenido": "",
				"fecha_narrativa": "1997",
				"visible_si": {},
				"acceso_si": {},
				"accion": "navegar",
				"persistencia": false,
			},
			{
				"id": "turnos_97_parte",
				"ruta_relativa": "formularios/parte_turno.frm",
				"padre_relativo": "formularios",
				"nombre": "PARTE_TUR.FRM",
				"tipo": "formulario",
				"contenido":
				(
					"PARTE DE TURNO\n\nFecha: ________\nIncidencias: ____________________"
					+ "\nEntrega: ________\nRecibe: ________"
				),
				"fecha_narrativa": "1997",
				"visible_si": {},
				"acceso_si": {},
				"accion": "mostrar_contenido",
				"persistencia": false,
			},
			{
				"id": "turnos_97_cierre",
				"ruta_relativa": "cierre_97.txt",
				"padre_relativo": "",
				"nombre": "CIERRE97.TXT",
				"tipo": "texto",
				"contenido":
				(
					"Copia de cierre administrativo del soporte anterior. "
					+ "No contiene información necesaria para la campaña."
				),
				"fecha_narrativa": "1997",
				"visible_si": {"clave": "jornada", "op": ">=", "valor": 3},
				"acceso_si": {},
				"accion": "mostrar_contenido",
				"persistencia": false,
			},
		],
	},
	{
		"id": "disquete_personal",
		"etiqueta": "COSAS",
		"tipo": "Disquete 3½",
		"capacidad": "1,44 MB",
		"unidad": "a",
		"unidad_persistente": true,
		"solo_lectura": true,
		"icono": "disquete_personal",
		"procedencia": "Cajón compartido · etiqueta manuscrita",
		"obtener_si": {"clave": "jornada", "op": ">=", "valor": 2},
		"entradas": [
			{
				"id": "cosas_notas",
				"ruta_relativa": "notas.txt",
				"padre_relativo": "",
				"nombre": "NOTAS.TXT",
				"tipo": "texto",
				"contenido":
				(
					"Recordatorio personal: devolver el disquete al cajón y no guardar aquí "
					+ "la única copia de ningún documento."
				),
				"fecha_narrativa": "1998",
				"visible_si": {},
				"acceso_si": {},
				"accion": "mostrar_contenido",
				"persistencia": false,
			},
			{
				"id": "cosas_nebulosa",
				"ruta_relativa": "nebulosa.scr",
				"padre_relativo": "",
				"nombre": "NEBULOSA.SCR",
				"tipo": "paquete",
				"contenido": "",
				"fecha_narrativa": "1998",
				"visible_si": {},
				"acceso_si": {},
				"accion": "mostrar_paquete_software",
				"persistencia": false,
				"paquete_id": "nebulosa-scr",
			},
		],
	},
	{
		"id": "cd_byte_lunar_06",
		"etiqueta": "BYTE_LUNAR_06",
		"tipo": "CD-ROM",
		"capacidad": "650 MB",
		"unidad": "d",
		"unidad_persistente": false,
		"solo_lectura": true,
		"icono": "cd_revista",
		"procedencia": "Revista informática ficticia · número 6",
		"obtener_si": {},
		"entradas": [
			{
				"id": "byte_lunar_demos",
				"ruta_relativa": "demos",
				"padre_relativo": "",
				"nombre": "DEMOS",
				"tipo": "carpeta",
				"contenido": "",
				"fecha_narrativa": "1998",
				"visible_si": {},
				"acceso_si": {},
				"accion": "navegar",
				"persistencia": false,
			},
			{
				"id": "byte_lunar_utilidades",
				"ruta_relativa": "utilidades",
				"padre_relativo": "",
				"nombre": "UTILIDADES",
				"tipo": "carpeta",
				"contenido": "",
				"fecha_narrativa": "1998",
				"visible_si": {},
				"acceso_si": {},
				"accion": "navegar",
				"persistencia": false,
			},
			{
				"id": "byte_lunar_astro_topo",
				"ruta_relativa": "demos/astrotop.exe",
				"padre_relativo": "demos",
				"nombre": "ASTROTOP.EXE",
				"tipo": "paquete",
				"contenido": "",
				"fecha_narrativa": "1998",
				"visible_si": {},
				"acceso_si": {},
				"accion": "mostrar_paquete_software",
				"persistencia": false,
				"paquete_id": "astro-topo-demo",
			},
			{
				"id": "byte_lunar_pixelvista",
				"ruta_relativa": "utilidades/pixelv14.exe",
				"padre_relativo": "utilidades",
				"nombre": "PIXELV14.EXE",
				"tipo": "paquete",
				"contenido": "",
				"fecha_narrativa": "1998",
				"visible_si": {},
				"acceso_si": {},
				"accion": "mostrar_paquete_software",
				"persistencia": false,
				"paquete_id": "pixelvista-14",
			},
			{
				"id": "byte_lunar_leeme",
				"ruta_relativa": "leeme.htm",
				"padre_relativo": "",
				"nombre": "LEEME.HTM",
				"tipo": "texto",
				"contenido":
				(
					"BYTE LUNAR 06 · índice offline. Todo el contenido de este CD es ficticio "
					+ "y se abre dentro del OS simulado."
				),
				"fecha_narrativa": "1998",
				"visible_si": {},
				"acceso_si": {},
				"accion": "mostrar_contenido",
				"persistencia": false,
			},
		],
	},
]

var _contexto: Dictionary = {}
var _montados: Array[String] = []


func configurar_contexto(contexto: Dictionary) -> void:
	_contexto = contexto.duplicate(true)
	for id in _montados.duplicate():
		var medio := _buscar_medio(String(id))
		if medio.is_empty() or not _cumple_condicion(medio.get("obtener_si", {}) as Dictionary):
			_montados.erase(String(id))


func catalogo() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for valor in MEDIOS:
		var medio := (valor as Dictionary).duplicate(true)
		medio["disponible"] = _cumple_condicion(medio.get("obtener_si", {}) as Dictionary)
		medio["montado"] = _montados.has(String(medio.get("id", "")))
		medio.erase("entradas")
		salida.append(medio)
	return salida


func medios_disponibles() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for medio in catalogo():
		if bool(medio.get("disponible", false)):
			salida.append(medio)
	return salida


func esta_montado(id: String) -> bool:
	return _montados.has(id)


func montar(id: String) -> bool:
	var medio := _buscar_medio(id)
	if medio.is_empty():
		return false
	if not _cumple_condicion(medio.get("obtener_si", {}) as Dictionary):
		return false
	var unidad := String(medio.get("unidad", ""))
	for otro_id in _montados.duplicate():
		var otro := _buscar_medio(String(otro_id))
		if String(otro.get("unidad", "")) == unidad:
			_montados.erase(String(otro_id))
	if not _montados.has(id):
		_montados.append(id)
	return true


func desmontar(id: String) -> bool:
	if not _montados.has(id):
		return false
	_montados.erase(id)
	return true


func ruta_de_medio(id: String) -> String:
	var medio := _buscar_medio(id)
	if medio.is_empty():
		return ""
	return "%s/%s" % [RUTA_RAIZ, String(medio.get("unidad", "")).to_lower()]


func unidad_persistente(id: String) -> bool:
	var medio := _buscar_medio(id)
	return not medio.is_empty() and bool(medio.get("unidad_persistente", false))


func ruta_pertenece_a_medio(ruta: String, id: String) -> bool:
	var base := ruta_de_medio(id)
	if base.is_empty():
		return false
	var normalizada := _normalizar_ruta(ruta)
	return normalizada == base or normalizada.begins_with(base + "/")


func resolver_ruta(ruta: String) -> Dictionary:
	var normalizada := _normalizar_ruta(ruta)
	for valor in MEDIOS:
		var medio := valor as Dictionary
		var id := String(medio.get("id", ""))
		if not _montados.has(id):
			continue
		var raiz := _entrada_raiz(medio)
		if String(raiz.get("ruta", "")) == normalizada:
			return raiz
		for entrada_valor in medio.get("entradas", []) as Array:
			var entrada := _entrada_completa(medio, entrada_valor as Dictionary)
			if String(entrada.get("ruta", "")) != normalizada:
				continue
			if _cumple_condicion(entrada.get("visible_si", {}) as Dictionary):
				return entrada
	return {}


func listar_ruta(ruta: String) -> Array[Dictionary]:
	var normalizada := _normalizar_ruta(ruta)
	var salida: Array[Dictionary] = []
	for valor in MEDIOS:
		var medio := valor as Dictionary
		var id := String(medio.get("id", ""))
		if not _montados.has(id):
			continue
		var raiz := _entrada_raiz(medio)
		if normalizada == RUTA_RAIZ:
			if not bool(medio.get("unidad_persistente", false)):
				salida.append(raiz)
			continue
		for entrada_valor in medio.get("entradas", []) as Array:
			var entrada := _entrada_completa(medio, entrada_valor as Dictionary)
			if String(entrada.get("padre", "")) != normalizada:
				continue
			if _cumple_condicion(entrada.get("visible_si", {}) as Dictionary):
				salida.append(entrada)
	return salida


func buscar_id(id: String) -> Dictionary:
	for valor in MEDIOS:
		var medio := valor as Dictionary
		var medio_id := String(medio.get("id", ""))
		if not _montados.has(medio_id):
			continue
		var raiz := _entrada_raiz(medio)
		if String(raiz.get("id", "")) == id:
			return raiz
		for entrada_valor in medio.get("entradas", []) as Array:
			var entrada := _entrada_completa(medio, entrada_valor as Dictionary)
			if String(entrada.get("id", "")) == id:
				if _cumple_condicion(entrada.get("visible_si", {}) as Dictionary):
					return entrada
	return {}


func puede_acceder(entrada: Dictionary) -> bool:
	return _cumple_condicion(entrada.get("acceso_si", {}) as Dictionary)


func _buscar_medio(id: String) -> Dictionary:
	for valor in MEDIOS:
		var medio := valor as Dictionary
		if String(medio.get("id", "")) == id:
			return medio
	return {}


func _entrada_raiz(medio: Dictionary) -> Dictionary:
	var id := String(medio.get("id", ""))
	var unidad := String(medio.get("unidad", "")).to_lower()
	return {
		"id": "medio_%s" % id,
		"ruta": "%s/%s" % [RUTA_RAIZ, unidad],
		"padre": RUTA_RAIZ,
		"nombre": "%s (%s:)" % [String(medio.get("etiqueta", id)), unidad.to_upper()],
		"tipo": "carpeta",
		"contenido": "",
		"fecha_narrativa": "1998",
		"visible_si": {},
		"acceso_si": {},
		"accion": "navegar",
		"persistencia": false,
		"medio_id": id,
		"solo_lectura": bool(medio.get("solo_lectura", true)),
		"icono_medio": String(medio.get("icono", "")),
		"procedencia_medio": String(medio.get("procedencia", "")),
		"capacidad_medio": String(medio.get("capacidad", "")),
	}


func _entrada_completa(medio: Dictionary, entrada: Dictionary) -> Dictionary:
	var salida := entrada.duplicate(true)
	var base := ruta_de_medio(String(medio.get("id", "")))
	var relativa := String(entrada.get("ruta_relativa", "")).strip_edges().trim_prefix("/")
	var padre_relativo := String(entrada.get("padre_relativo", "")).strip_edges().trim_prefix("/")
	salida["ruta"] = base if relativa.is_empty() else base + "/" + relativa.to_lower()
	salida["padre"] = base if padre_relativo.is_empty() else base + "/" + padre_relativo.to_lower()
	salida.erase("ruta_relativa")
	salida.erase("padre_relativo")
	salida["medio_id"] = String(medio.get("id", ""))
	salida["solo_lectura"] = bool(medio.get("solo_lectura", true))
	salida["icono_medio"] = String(medio.get("icono", ""))
	salida["procedencia_medio"] = String(medio.get("procedencia", ""))
	salida["capacidad_medio"] = String(medio.get("capacidad", ""))
	return salida


func _normalizar_ruta(ruta: String) -> String:
	var limpia := ruta.strip_edges().replace("\\", "/").trim_prefix("/").trim_suffix("/")
	if limpia.is_empty() or limpia == ".":
		return RUTA_RAIZ
	return limpia.to_lower()


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
			var actual_numerico := actual is int or actual is float
			var esperado_numerico := esperado is int or esperado is float
			return actual_numerico and esperado_numerico and float(actual) >= float(esperado)
		"incluye":
			if actual is Array:
				return (actual as Array).has(esperado)
			if actual is PackedStringArray:
				return (actual as PackedStringArray).has(String(esperado))
	return false
