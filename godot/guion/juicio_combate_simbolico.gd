## Capa simbólica del Juicio por Combate.
##
## Resuelve ideologías, tarot, mitología y rituales a partir del estado de
## partida, y entrega al orquestador una configuración ya normalizada.
class_name JuicioCombateSimbolico
extends RefCounted

const RELIGION_EVENTOS = preload("res://guion/religion_eventos.gd")
const RELIGION_CONFLICTO = preload("res://guion/religion_conflicto.gd")
const CONTEXTO_JUICIO := "juicio:%s"


static func resolver(
	anfitrion: Node,
	acusado: Dictionary,
	radio_base: float,
	velocidad_base: float,
	recarga_fuerte_base: float,
) -> Dictionary:
	var estado := estado_partida(anfitrion)
	if estado.is_empty():
		return {}

	var clave := clave_acusado(acusado)
	var arcano: Dictionary = {}
	var tarot = estado.get("tarot", [])
	if typeof(tarot) == TYPE_ARRAY:
		arcano = JuicioSimbolico.arcano_para(tarot, clave)

	var mito_id := ""
	var jornada = estado.get("jornada", {})
	if typeof(jornada) == TYPE_DICTIONARY:
		mito_id = JuicioSimbolico.mito_para(jornada, clave)

	var ritual := JuicioSimbolico.ritual_para(arcano, mito_id)
	var configuracion := configuracion_ritual(
		ritual,
		radio_base,
		velocidad_base,
		recarga_fuerte_base,
	)
	return {
		"cargas_doctrina": Prometeo.cargas_ideologicas(estado, Historias.TOPE_CARGAS),
		"arcano": arcano,
		"mito_id": mito_id,
		"ritual": ritual,
		"radio_arena": configuracion["radio_arena"],
		"velocidad_rival": configuracion["velocidad_rival"],
		"recarga_fuerte": configuracion["recarga_fuerte"],
		"compromisos_religion": compromisos_religion(estado, clave),
	}


## Compromisos religiosos contextuales (#936) disponibles para este acusado.
##
## Consume exclusivamente hechos ya catalogados por ReligionEventos a través
## de ReligionConflicto; el Juicio nunca decide por sí mismo qué cuenta como
## práctica o convicción religiosa.
static func compromisos_religion(estado: Dictionary, clave: String) -> Array:
	var registro = estado.get(RELIGION_EVENTOS.CLAVE_ESTADO, {})
	if typeof(registro) != TYPE_DICTIONARY:
		return []
	return RELIGION_CONFLICTO.compromisos_disponibles(registro, CONTEXTO_JUICIO % clave, clave)


static func compromiso_religion_bloqueante(
	compromisos: Array, rival_inicio_agresion: bool
) -> Dictionary:
	for compromiso_bruto in compromisos:
		if typeof(compromiso_bruto) != TYPE_DICTIONARY:
			continue
		var compromiso: Dictionary = compromiso_bruto
		if not RELIGION_CONFLICTO.puede_iniciar_accion_ofensiva(compromiso, rival_inicio_agresion):
			return compromiso
	return {}


static func estado_partida(anfitrion: Node) -> Dictionary:
	var padre := anfitrion.get_parent()
	if padre == null:
		return {}
	var tiene_partida := false
	for bruto in padre.get_property_list():
		if typeof(bruto) == TYPE_DICTIONARY and String(bruto.get("name", "")) == "partida":
			tiene_partida = true
			break
	if not tiene_partida:
		return {}
	var partida_actual = padre.get("partida")
	if partida_actual is Partida:
		return partida_actual.estado
	return {}


static func clave_acusado(acusado: Dictionary) -> String:
	return String(acusado.get("id", acusado.get("nombre", "acusado")))


static func configuracion_ritual(
	ritual: Dictionary,
	radio_base: float,
	velocidad_base: float,
	recarga_fuerte_base: float,
) -> Dictionary:
	return {
		"radio_arena": float(ritual.get("radio_arena", radio_base)),
		"velocidad_rival": velocidad_base * float(ritual.get("velocidad_rival_mul", 1.0)),
		"recarga_fuerte": float(ritual.get("recarga_fuerte", recarga_fuerte_base)),
	}


static func hay_cargas_doctrina(cargas: Dictionary) -> bool:
	for eje in Prometeo.EJES:
		if int(cargas.get(eje, 0)) > 0:
			return true
	return false
