## Contrato persistente para experiencias religiosas/culturales (#931/#936).
##
## Mantiene separados cuatro canales deliberadamente distintos. Un evento de
## exposición no se convierte en práctica; una práctica no se convierte en
## convicción; y un vínculo solo registra una relación observable.
##
## El registro vive dentro de Partida bajo CLAVE_ESTADO. Los cuatro canales son
## historial de la partida: cambiar de jornada o de vuelta no borra hechos ya
## ocurridos. Una partida nueva sí empieza con los cuatro canales vacíos.
class_name ReligionEventos
extends RefCounted

const CLAVE_ESTADO := "religion"
const CLAVE_HISTORIAL := "historial_trayectorias_religiosas"

const CANAL_EXPOSICION := "exposicion"
const CANAL_PRACTICA := "practica"
const CANAL_CONVICCION := "conviccion_declarada"
const CANAL_VINCULO := "vinculo"
const CANALES := [
	CANAL_EXPOSICION,
	CANAL_PRACTICA,
	CANAL_CONVICCION,
	CANAL_VINCULO,
]

const DECLARACION_AFIRMACION := "afirmacion"
const DECLARACION_DUDA := "duda"
const DECLARACION_NO_ADSCRIPCION := "no_adscripcion"
const DECLARACION_CAMBIO := "cambio"
const DECLARACIONES := [
	DECLARACION_AFIRMACION,
	DECLARACION_DUDA,
	DECLARACION_NO_ADSCRIPCION,
	DECLARACION_CAMBIO,
]


static func nuevo() -> Dictionary:
	return {
		CANAL_EXPOSICION: [],
		CANAL_PRACTICA: [],
		CANAL_CONVICCION: [],
		CANAL_VINCULO: [],
	}


## Devuelve el único registro religioso de una Partida.
##
## Partida valida el guardado antes de llegar aquí. Esta normalización existe
## para estados sintéticos de pruebas y para migrar partidas antiguas que aún
## no tenían la clave, nunca como sustituto de la validación del disco.
static func asegurar_en_estado(estado: Dictionary) -> Dictionary:
	var registro = estado.get(CLAVE_ESTADO, null)
	if typeof(registro) != TYPE_DICTIONARY:
		registro = nuevo()
		estado[CLAVE_ESTADO] = registro
		return registro

	for canal in CANALES:
		if typeof(registro.get(canal, null)) != TYPE_ARRAY:
			registro[canal] = []
	return registro


## Construye un hecho explícito de la partida.
##
## `tradicion` es metadato documental opcional, nunca una clase de personaje.
## `reglas_conflicto` declara compromisos que la experiencia realmente puede
## habilitar. Exponer esa lista no significa que todos los canales puedan
## activarla: ReligionConflicto aplica una segunda frontera por canal/contexto.
##
## `metadatos` admite:
## - vuelta: vida laboral en la que ocurrió el hecho;
## - procedencia: cómo se obtuvo la información (observación, diálogo, ROM...);
## - actor: persona/comunidad/institución de un vínculo;
## - declaracion: afirmación, duda, no adscripción o cambio, solo para convicción.
static func crear_evento(
	id_evento: String,
	canal: String,
	fuente: String,
	contexto: String = "",
	jornada: int = 0,
	tradicion: String = "",
	etiquetas: Array = [],
	reglas_conflicto: Array = [],
	publico: bool = false,
	conocido_por: Array = [],
	metadatos: Dictionary = {},
) -> Dictionary:
	var id := id_evento.strip_edges()
	var origen := fuente.strip_edges()
	if id.is_empty() or origen.is_empty() or not CANALES.has(canal):
		return {}

	var declaracion := String(metadatos.get("declaracion", "")).strip_edges()
	if not declaracion.is_empty():
		if canal != CANAL_CONVICCION or not DECLARACIONES.has(declaracion):
			return {}

	var actor := String(metadatos.get("actor", "")).strip_edges()
	if not actor.is_empty() and canal != CANAL_VINCULO:
		return {}

	var procedencia := String(metadatos.get("procedencia", origen)).strip_edges()
	if procedencia.is_empty():
		procedencia = origen

	var evento := {
		"id": id,
		"canal": canal,
		"fuente": origen,
		"procedencia": procedencia,
		"contexto": contexto.strip_edges(),
		"jornada": maxi(0, jornada),
		"vuelta": maxi(0, int(metadatos.get("vuelta", 0))),
		"tradicion": tradicion.strip_edges(),
		"etiquetas": _normalizar_lista(etiquetas),
		"reglas_conflicto": _normalizar_lista(reglas_conflicto),
		"publico": publico,
		"conocido_por": _normalizar_lista(conocido_por),
	}
	if not actor.is_empty():
		evento["actor"] = actor
	if not declaracion.is_empty():
		evento["declaracion"] = declaracion
	return evento


## Registra el evento una sola vez. El id es único entre canales para impedir
## que el mismo hecho termine contado como exposición y convicción por accidente.
static func registrar(registro: Dictionary, evento: Dictionary) -> bool:
	if not evento_valido(evento):
		return false

	var id := String(evento["id"])
	for canal in CANALES:
		for existente in _lista_canal(registro, canal):
			if typeof(existente) == TYPE_DICTIONARY and String(existente.get("id", "")) == id:
				return false

	var canal := String(evento["canal"])
	var destino := _lista_canal(registro, canal)
	destino.append(evento.duplicate(true))
	registro[canal] = destino
	return true


## Devuelve una copia: los consumidores no reciben la colección interna.
static func eventos(registro: Dictionary, canal: String) -> Array:
	if not CANALES.has(canal):
		return []
	return _lista_canal(registro, canal)


## Vista derivada del canal de vínculo: actor/comunidad -> hechos observables.
##
## Los eventos legacy sin `actor` siguen siendo válidos para no romper partidas
## o pruebas anteriores, pero no aparecen en esta vista hasta que un emisor
## conozca explícitamente con quién existe el vínculo.
static func vinculos_por_actor(registro: Dictionary) -> Dictionary:
	var resultado := {}
	for evento_bruto in eventos(registro, CANAL_VINCULO):
		if typeof(evento_bruto) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = evento_bruto
		var actor := String(evento.get("actor", "")).strip_edges()
		if actor.is_empty():
			continue
		var hechos: Array = resultado.get(actor, [])
		hechos.append(evento.duplicate(true))
		resultado[actor] = hechos
	return resultado


## Última declaración explícita registrada. No inventa una identidad si nunca
## hubo declaración y conserva la historia previa de duda/cambio/no adscripción.
static func ultima_declaracion(registro: Dictionary) -> Dictionary:
	var declaraciones := eventos(registro, CANAL_CONVICCION)
	for indice in range(declaraciones.size() - 1, -1, -1):
		var evento = declaraciones[indice]
		if (
			typeof(evento) == TYPE_DICTIONARY
			and not String(evento.get("declaracion", "")).is_empty()
		):
			return evento.duplicate(true)
	return {}


## Devuelve únicamente los hechos registrados durante una vida concreta.
## El registro común de #931 sigue siendo histórico; esta vista evita que un
## consumidor de una vida nueva trate hechos previos como estado activo.
static func eventos_de_vuelta(registro: Dictionary, canal: String, vuelta: int) -> Array:
	if vuelta < 1 or not CANALES.has(canal):
		return []
	var resultado := []
	for valor in eventos(registro, canal):
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = valor
		if int(evento.get("vuelta", 0)) == vuelta:
			resultado.append(evento.duplicate(true))
	return resultado


## Fotografía factual y reducida de la vida actual.
## No sintetiza una identidad: conserva los cuatro canales separados y copia
## solo hechos ya registrados por #931.
static func resumen_trayectoria(estado: Dictionary) -> Dictionary:
	var jornada = estado.get("jornada", {})
	var vuelta := 1
	if typeof(jornada) == TYPE_DICTIONARY:
		vuelta = maxi(1, int(jornada.get("vuelta", 1)))
	var registro := asegurar_en_estado(estado)
	var canales := {}
	for canal in CANALES:
		var hechos := []
		for valor in eventos_de_vuelta(registro, canal, vuelta):
			var evento: Dictionary = valor
			hechos.append(_reducir_evento(evento))
		canales[canal] = hechos
	return {
		"vuelta": vuelta,
		"canales": canales,
	}


## Sella una sola instantánea por vida antes del reset de #925/#937.
## Repetir el cierre de la misma vuelta devuelve la copia existente.
static func archivar_trayectoria(
	estado: Dictionary, motivo: String = "reinicio_vuelta"
) -> Dictionary:
	var resumen := resumen_trayectoria(estado)
	var vuelta := int(resumen["vuelta"])
	var valor_historial = estado.get(CLAVE_HISTORIAL, [])
	var historial: Array = (
		valor_historial.duplicate(true) if typeof(valor_historial) == TYPE_ARRAY else []
	)
	for valor in historial:
		if typeof(valor) == TYPE_DICTIONARY and int(valor.get("vuelta", -1)) == vuelta:
			return Dictionary(valor).duplicate(true)

	var motivo_limpio := motivo.strip_edges()
	resumen["motivo"] = motivo_limpio if not motivo_limpio.is_empty() else "otro"
	historial.append(resumen)
	estado[CLAVE_HISTORIAL] = historial
	return resumen.duplicate(true)


static func historial_trayectorias(estado: Dictionary) -> Array:
	var valor = estado.get(CLAVE_HISTORIAL, [])
	return valor.duplicate(true) if typeof(valor) == TYPE_ARRAY else []


## Valida snapshots históricos sin convertirlos en una clasificación global.
static func validar_historial_trayectorias(historial: Array) -> Array:
	var errores := []
	var vueltas := {}
	for indice in historial.size():
		var valor = historial[indice]
		if typeof(valor) != TYPE_DICTIONARY:
			errores.append("%d no es un objeto" % indice)
			continue
		var resumen: Dictionary = valor
		var vuelta = resumen.get("vuelta", -1)
		if not _entero_positivo(vuelta):
			errores.append("%d.vuelta inválida" % indice)
			continue
		var vuelta_id := int(vuelta)
		if vueltas.has(vuelta_id):
			errores.append("%d.vuelta duplicada" % indice)
		else:
			vueltas[vuelta_id] = true

		if (
			typeof(resumen.get("motivo")) != TYPE_STRING
			or String(resumen.get("motivo", "")).strip_edges().is_empty()
		):
			errores.append("%d.motivo inválido" % indice)

		var canales = resumen.get("canales")
		if typeof(canales) != TYPE_DICTIONARY:
			errores.append("%d.canales no es un objeto" % indice)
			continue
		for canal in CANALES:
			var hechos = canales.get(canal)
			if typeof(hechos) != TYPE_ARRAY:
				errores.append("%d.canales.%s no es una lista" % [indice, canal])
				continue
			for posicion in hechos.size():
				var hecho = hechos[posicion]
				if typeof(hecho) != TYPE_DICTIONARY:
					errores.append(
					"%d.canales.%s[%d] no es un objeto" % [indice, canal, posicion]
				)
					continue
				if not evento_valido(hecho):
					errores.append("%d.canales.%s[%d] inválido" % [indice, canal, posicion])
					continue
				if String(hecho.get("canal", "")) != canal:
					errores.append("%d.canales.%s[%d] declara otro canal" % [indice, canal, posicion])
				if int(hecho.get("vuelta", -1)) != vuelta_id:
					errores.append("%d.canales.%s[%d] pertenece a otra vuelta" % [indice, canal, posicion])
	return errores


static func _reducir_evento(evento: Dictionary) -> Dictionary:
	var reducido := {
		"id": String(evento.get("id", "")),
		"canal": String(evento.get("canal", "")),
		"fuente": String(evento.get("fuente", "")),
		"procedencia": String(evento.get("procedencia", "")),
		"contexto": String(evento.get("contexto", "")),
		"jornada": int(evento.get("jornada", 0)),
		"vuelta": int(evento.get("vuelta", 0)),
	}
	for clave in ["tradicion", "actor", "declaracion"]:
		var texto := String(evento.get(clave, "")).strip_edges()
		if not texto.is_empty():
			reducido[clave] = texto
	return reducido


static func _entero_positivo(valor) -> bool:
	return _entero_no_negativo(valor) and int(valor) >= 1


## Valida la forma completa del registro persistido.
static func validar(registro) -> Array:
	var errores := []
	if typeof(registro) != TYPE_DICTIONARY:
		return ["no es un objeto"]

	var ids := {}
	for canal in CANALES:
		var lista = registro.get(canal, null)
		if typeof(lista) != TYPE_ARRAY:
			errores.append("%s no es una lista" % canal)
			continue
		for indice in lista.size():
			var evento = lista[indice]
			if typeof(evento) != TYPE_DICTIONARY:
				errores.append("%s[%d] no es un objeto" % [canal, indice])
				continue
			if not evento_valido(evento):
				errores.append("%s[%d] inválido" % [canal, indice])
				continue
			if String(evento.get("canal", "")) != canal:
				errores.append("%s[%d] declara otro canal" % [canal, indice])
			var id := String(evento.get("id", ""))
			if ids.has(id):
				errores.append("id duplicado: %s" % id)
			else:
				ids[id] = true
	return errores


static func evento_valido(evento: Dictionary) -> bool:
	if String(evento.get("id", "")).strip_edges().is_empty():
		return false
	if String(evento.get("fuente", "")).strip_edges().is_empty():
		return false
	if String(evento.get("procedencia", "")).strip_edges().is_empty():
		return false

	var canal := String(evento.get("canal", ""))
	if not CANALES.has(canal):
		return false
	for clave in ["etiquetas", "reglas_conflicto", "conocido_por"]:
		if evento.has(clave) and typeof(evento[clave]) != TYPE_ARRAY:
			return false
	if evento.has("publico") and typeof(evento["publico"]) != TYPE_BOOL:
		return false
	for clave in ["jornada", "vuelta"]:
		if evento.has(clave) and not _entero_no_negativo(evento[clave]):
			return false

	var declaracion := String(evento.get("declaracion", "")).strip_edges()
	if (
		not declaracion.is_empty()
		and (canal != CANAL_CONVICCION or not DECLARACIONES.has(declaracion))
	):
		return false
	var actor := String(evento.get("actor", "")).strip_edges()
	if not actor.is_empty() and canal != CANAL_VINCULO:
		return false
	return true


static func _lista_canal(registro: Dictionary, canal: String) -> Array:
	var valor = registro.get(canal, [])
	return valor.duplicate(true) if typeof(valor) == TYPE_ARRAY else []


static func _normalizar_lista(valores: Array) -> Array:
	var resultado := []
	for valor in valores:
		var texto := String(valor).strip_edges()
		if not texto.is_empty() and not resultado.has(texto):
			resultado.append(texto)
	resultado.sort()
	return resultado


static func _entero_no_negativo(valor) -> bool:
	if typeof(valor) == TYPE_INT:
		return valor >= 0
	if typeof(valor) != TYPE_FLOAT or not is_finite(valor):
		return false
	return floor(valor) == valor and valor >= 0.0
