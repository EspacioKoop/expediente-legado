## Contrato declarativo de fallos mundanos del OS98 (#668).
##
## Esta capa define reglas normales antes de que #539 pueda romperlas de forma
## narrativa. No toca host, red, procesos reales ni estado de campaña: recibe un
## evento ficticio explícito y devuelve una incidencia cerrable y reproducible.
class_name FallosMundanosOs98
extends RefCounted

const ESTADO_NORMAL := "normal"
const ESTADO_FALLO_MUNDANO := "fallo_mundano"
const ESTADO_FIXTURE_ANOMALO := "fixture_anomalo"
const ESTADO_DESCONOCIDO := "desconocido"

const REGLAS := [
	{
		"id": "acceso_directo_roto",
		"superficie": "shell",
		"evento": "destino_ausente",
		"causa": "El destino declarado por el acceso directo ya no existe en el OS simulado.",
		"resolucion": "Cerrar el aviso y abrir la aplicación desde Archivo de programas.",
		"salida_segura": "cerrar_aviso",
		"regla_normal": "Un acceso directo solo puede abrir un destino instalado y declarado.",
		"fixture_anomalo": "destino_reaparece_sin_instalacion",
		"refs": ["#534"],
	},
	{
		"id": "formato_no_reconocido",
		"superficie": "explorador",
		"evento": "extension_desconocida",
		"causa": "Ninguna aplicación simulada declara compatibilidad con la extensión.",
		"resolucion": "Cerrar el aviso o elegir otra copia del documento en un formato conocido.",
		"salida_segura": "cerrar_aviso",
		"regla_normal": "Solo se abren formatos asociados a una aplicación ficticia conocida.",
		"fixture_anomalo": "formato_imposible_se_abre_solo",
		"refs": ["#536"],
	},
	{
		"id": "shareware_expirado",
		"superficie": "software",
		"evento": "licencia_expirada",
		"causa": "El periodo ficticio de prueba terminó según el propio estado del paquete.",
		"resolucion": "Cerrar el popup de registro o desinstalar el programa.",
		"salida_segura": "cerrar_popup",
		"regla_normal":
		"Un trial expirado permanece expirado hasta que se desinstala o cambia su estado declarado.",
		"fixture_anomalo": "trial_revive_sin_cambio_de_estado",
		"refs": ["#663"],
	},
	{
		"id": "residente_simulado",
		"superficie": "software",
		"evento": "residente_activo",
		"causa": "Una utilidad ficticia sigue residente porque todavía no se cerró correctamente.",
		"resolucion":
		"Cerrar la utilidad desde su menú o desinstalarla desde Archivo de programas.",
		"salida_segura": "cerrar_utilidad",
		"regla_normal": "Cerrar o desinstalar correctamente elimina el residente simulado.",
		"fixture_anomalo": "residente_regresa_tras_desinstalar",
		"refs": ["#663"],
	},
	{
		"id": "medio_solo_lectura",
		"superficie": "medios",
		"evento": "escritura_en_solo_lectura",
		"causa": "El medio extraíble declara modo de solo lectura.",
		"resolucion": "Guardar la copia en una unidad simulada con escritura permitida.",
		"salida_segura": "cancelar_escritura",
		"regla_normal": "Un medio de solo lectura nunca acepta escrituras ficticias.",
		"fixture_anomalo": "medio_solo_lectura_acepta_escritura",
		"refs": ["#664"],
	},
	{
		"id": "medio_retirado",
		"superficie": "medios",
		"evento": "ruta_medio_retirado",
		"causa": "La unidad simulada dejó de estar montada.",
		"resolucion": "Volver a Mi equipo, insertar el medio correcto o cerrar la ventana.",
		"salida_segura": "volver_a_equipo",
		"regla_normal":
		"Retirar un medio hace inaccesibles sus rutas sin cerrar por la fuerza la ventana.",
		"fixture_anomalo": "archivo_accesible_tras_retirada",
		"refs": ["#664"],
	},
	{
		"id": "cache_desactualizada",
		"superficie": "web98",
		"evento": "cache_antigua_consultada",
		"causa": "La copia local declarada es anterior al contenido actual del recurso.",
		"resolucion": "Volver al origen, usar un mirror conocido o aceptar la copia antigua.",
		"salida_segura": "volver_al_origen",
		"regla_normal":
		"La caché solo existe para recursos que la declaran y conserva su fecha propia.",
		"fixture_anomalo": "cache_de_recurso_imposible",
		"refs": ["#667"],
	},
	{
		"id": "firma_catalogada_detectada",
		"superficie": "software",
		"evento": "firma_catalogada",
		"causa":
		"El limpiador ficticio encontró una firma catalogada en un objeto del OS simulado.",
		"resolucion":
		"Neutralizar la incidencia o cerrar el aviso sin modificar archivos del sistema real.",
		"salida_segura": "cerrar_aviso",
		"regla_normal":
		"El limpiador ficticio solo detecta firmas presentes en su catálogo interno.",
		"fixture_anomalo": "firma_no_catalogada_detectada",
		"refs": ["#668", "#539"],
	},
]

const FIRMAS_LIMPIADOR := [
	{
		"id": "macro-marmota-98",
		"nombre": "Macro Marmota 98",
		"tipo": "macro_ficticia",
		"descripcion": "Macro de demostración que reaparece al abrir un documento simulado.",
	},
	{
		"id": "residente-cinta-azul",
		"nombre": "Cinta Azul residente",
		"tipo": "residente_ficticio",
		"descripcion": "Utilidad residente dudosa que solo existe dentro del estado del OS98.",
	},
]


static func catalogo() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for valor in REGLAS:
		salida.append((valor as Dictionary).duplicate(true))
	return salida


static func regla(id: String) -> Dictionary:
	for valor in REGLAS:
		var declaracion := valor as Dictionary
		if String(declaracion.get("id", "")) == id:
			return declaracion.duplicate(true)
	return {}


static func firmas_limpiador() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for valor in FIRMAS_LIMPIADOR:
		salida.append((valor as Dictionary).duplicate(true))
	return salida


static func firma_limpiador(id: String) -> Dictionary:
	for valor in FIRMAS_LIMPIADOR:
		var firma := valor as Dictionary
		if String(firma.get("id", "")) == id:
			return firma.duplicate(true)
	return {}


## Escanea exclusivamente objetos ya presentes en el estado ficticio del OS98.
## Una firma desconocida se ignora: #539 podrá violar después esa regla de forma explícita.
static func escanear_limpiador(estado_os: Dictionary) -> Array[Dictionary]:
	var detecciones: Array[Dictionary] = []
	var objetos: Variant = estado_os.get("objetos_simulados", [])
	if not objetos is Array:
		return detecciones
	for valor in objetos as Array:
		if not valor is Dictionary:
			continue
		var objeto := valor as Dictionary
		if not bool(objeto.get("activo", false)):
			continue
		var firma := firma_limpiador(String(objeto.get("firma_id", "")))
		if firma.is_empty():
			continue
		(
			detecciones
			. append(
				{
					"objeto_id": String(objeto.get("id", "")),
					"firma_id": String(firma.get("id", "")),
					"nombre": String(firma.get("nombre", "")),
					"tipo": String(firma.get("tipo", "")),
				}
			)
		)
	detecciones.sort_custom(_orden_detecciones_limpiador)
	return detecciones


## Neutraliza una detección conocida mutando solo el diccionario simulado recibido.
## No borra el objeto: marca un estado reversible para que guardar/cerrar siga siendo seguro.
static func neutralizar_limpiador(estado_os: Dictionary, objeto_id: String) -> Dictionary:
	var objetos: Variant = estado_os.get("objetos_simulados", [])
	if not objetos is Array:
		return {"ok": false, "motivo": "estado_invalido"}
	var lista := objetos as Array
	for indice in range(lista.size()):
		var valor: Variant = lista[indice]
		if not valor is Dictionary:
			continue
		var objeto := valor as Dictionary
		if String(objeto.get("id", "")) != objeto_id:
			continue
		var firma := firma_limpiador(String(objeto.get("firma_id", "")))
		if firma.is_empty():
			return {"ok": false, "motivo": "firma_no_catalogada"}
		if not bool(objeto.get("activo", false)):
			return {"ok": false, "motivo": "ya_inactivo"}
		var copia := objeto.duplicate(true)
		copia["activo"] = false
		copia["neutralizado"] = true
		lista[indice] = copia
		estado_os["objetos_simulados"] = lista
		return {
			"ok": true,
			"objeto_id": objeto_id,
			"firma": firma,
			"incidencia": evaluar("firma_catalogada_detectada", {"evento": "firma_catalogada"}),
		}
	return {"ok": false, "motivo": "objeto_desconocido"}


## Reversión explícita para pruebas/UX de recuperación: tampoco toca nada fuera del estado simulado.
static func restaurar_limpiador(estado_os: Dictionary, objeto_id: String) -> bool:
	var objetos: Variant = estado_os.get("objetos_simulados", [])
	if not objetos is Array:
		return false
	var lista := objetos as Array
	for indice in range(lista.size()):
		var valor: Variant = lista[indice]
		if not valor is Dictionary:
			continue
		var objeto := valor as Dictionary
		if String(objeto.get("id", "")) != objeto_id:
			continue
		if firma_limpiador(String(objeto.get("firma_id", ""))).is_empty():
			return false
		if not bool(objeto.get("neutralizado", false)):
			return false
		var copia := objeto.duplicate(true)
		copia["activo"] = true
		copia["neutralizado"] = false
		lista[indice] = copia
		estado_os["objetos_simulados"] = lista
		return true
	return false


static func _orden_detecciones_limpiador(a: Dictionary, b: Dictionary) -> bool:
	var objeto_a := String(a.get("objeto_id", ""))
	var objeto_b := String(b.get("objeto_id", ""))
	if objeto_a == objeto_b:
		return String(a.get("firma_id", "")) < String(b.get("firma_id", ""))
	return objeto_a < objeto_b


## Evalúa únicamente estado ficticio suministrado por el consumidor.
##
## `evento` reproduce el fallo normal. `fixture_anomalo` es un hook deliberado
## para pruebas/consumidores de #539: nunca se activa por azar ni por inspección
## del sistema real.
static func evaluar(id: String, contexto: Dictionary = {}) -> Dictionary:
	var declaracion := regla(id)
	if declaracion.is_empty():
		return {
			"id": id,
			"estado": ESTADO_DESCONOCIDO,
			"activo": false,
			"viola_regla": false,
			"causa": "",
			"resolucion": "",
			"salida_segura": "cerrar_aviso",
			"regla_normal": "",
		}

	var evento := String(contexto.get("evento", ""))
	var activo := evento == String(declaracion.get("evento", ""))
	var fixture := String(contexto.get("fixture_anomalo", ""))
	var esperado := String(declaracion.get("fixture_anomalo", ""))
	var viola_regla := not fixture.is_empty() and fixture == esperado
	var estado := ESTADO_NORMAL
	if viola_regla:
		estado = ESTADO_FIXTURE_ANOMALO
		activo = true
	elif activo:
		estado = ESTADO_FALLO_MUNDANO

	return {
		"id": String(declaracion.get("id", id)),
		"estado": estado,
		"activo": activo,
		"viola_regla": viola_regla,
		"causa": String(declaracion.get("causa", "")) if activo else "",
		"resolucion": String(declaracion.get("resolucion", "")) if activo else "",
		"salida_segura": String(declaracion.get("salida_segura", "cerrar_aviso")),
		"regla_normal": String(declaracion.get("regla_normal", "")),
		"superficie": String(declaracion.get("superficie", "")),
		"fixture_anomalo": esperado,
	}
