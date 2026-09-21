## Capa simbólica del Juicio por Combate (#779).
##
## El combate puede contaminarse con dos memorias que ya pertenecen a la partida:
## - un Arcano recogido y todavía no gastado;
## - una familia mitológica activada deliberadamente durante la jornada.
##
## La selección nunca consume progreso. Algunas parejas concretas sí forman un
## ritual jugable: la combinación, no cada símbolo por separado, define un
## modificador pequeño y explícito que `JuicioCombate3D` puede interpretar.
class_name JuicioSimbolico
extends RefCounted

const RUTA_TAROT := "res://assets/tarot/%s.png"

const MITOS := {
	"gilgamesh": {"forma": "puerta", "color": Color("a4773f")},
	"minotauro": {"forma": "laberinto", "color": Color("9d2f35")},
	"aquiles": {"forma": "escudo", "color": Color("b99745")},
	"hidra": {"forma": "hidra", "color": Color("47764a")},
	"dragon_japones": {"forma": "serpiente", "color": Color("3d7568")},
	"duat": {"forma": "balanza", "color": Color("a47d35")},
	"simurgh": {"forma": "ala", "color": Color("8f765d")},
	"yggdrasil": {"forma": "arbol", "color": Color("57704a")},
	"tir_na_nog": {"forma": "piedras", "color": Color("6c8069")},
	"mari": {"forma": "montana", "color": Color("6e7080")},
	"anansi_akan": {"forma": "telarana", "color": Color("735b78")},
	"maui_tamanuitera": {"forma": "sol", "color": Color("b87931")},
}

## Vocabulario mecánico del Juicio. Se mantiene cerrado a parejas con una
## lectura clara para que descubrir dos símbolos no genere buffs procedurales
## difíciles de explicar o balancear.
const RITUALES := {
	"la-luna|minotauro":
	{
		"id": "laberinto_lunar",
		"nombre": "Laberinto lunar",
		"radio_arena": 4.15,
		"velocidad_rival_mul": 0.86,
		"tags": ["control_espacio", "movilidad"],
	},
	"la-justicia|duat":
	{
		"id": "balanza_duat",
		"nombre": "Balanza del Duat",
		"contraataque_esquiva": 1,
		"tags": ["contraataque"],
	},
	"la-fuerza|aquiles":
	{
		"id": "talon_fuerza",
		"nombre": "Talón de la Fuerza",
		"dano_fuerte_bonus": 1,
		"recarga_fuerte": 0.82,
		"tags": ["riesgo"],
	},
	"el-sol|maui_tamanuitera":
	{
		"id": "robo_del_sol",
		"nombre": "Robo del Sol",
		"interrumpe_telegrafo_fuerte": true,
		"dano_interrupcion_bonus": 1,
		"tags": ["telegraph", "neutralizar"],
	},
	"el-colgado|anansi_akan":
	{
		"id": "nudo_suspendido",
		"nombre": "Nudo suspendido",
		"enredo_ligero_segundos": 1.10,
		"velocidad_enredado_mul": 0.45,
		"tags": ["control_espacio", "movilidad"],
	},
	"la-muerte|hidra":
	{
		"id": "retorno_hidra",
		"nombre": "Retorno de la Hidra",
		"retornos_rival": 1,
		"determinacion_retorno": 2,
		"tags": ["segunda_fase"],
	},
}


## El Arcano rector sale solo de cartas disponibles de verdad. Una carta gastada
## por el sistema de último recurso queda fuera, y aquí nunca se muta la lista.
static func arcano_para(tarot: Array, clave: String) -> Dictionary:
	var por_id := {}
	for bruto in tarot:
		if typeof(bruto) != TYPE_DICTIONARY:
			continue
		var carta: Dictionary = bruto
		if not bool(carta.get("recogida", false)) or bool(carta.get("gastada", false)):
			continue
		var id := String(carta.get("id", "")).strip_edges()
		if id.is_empty():
			continue
		var copia := carta.duplicate(true)
		copia["id"] = id
		por_id[id] = copia

	var ids: Array = por_id.keys()
	ids.sort()
	if ids.is_empty():
		return {}
	var indice := posmod(hash("arcano|%s" % clave), ids.size())
	return por_id[ids[indice]].duplicate(true)


## El eco mitológico procede de las semillas activas HOY. La ordenación estable
## de SemillasOniricas más la clave del acusado evita rerolls por recargar.
static func mito_para(jornada: Dictionary, clave: String) -> String:
	var familias := SemillasOniricas.familias_activas(jornada)
	if familias.is_empty():
		return ""
	var indice := posmod(hash("mito|%s" % clave), familias.size())
	return familias[indice]


static func descriptor_mito(id_mito: String) -> Dictionary:
	if not MITOS.has(id_mito):
		return {}
	return MITOS[id_mito].duplicate(true)


## Solo una pareja declarada activa reglas. Un Arcano o mito sueltos siguen
## siendo presencia visual y nunca modifican el combate por sí solos.
static func ritual_para(carta: Dictionary, id_mito: String) -> Dictionary:
	var id_arcano := String(carta.get("id", "")).strip_edges()
	var mito := id_mito.strip_edges()
	if id_arcano.is_empty() or mito.is_empty():
		return {}
	var clave := "%s|%s" % [id_arcano, mito]
	if not RITUALES.has(clave):
		return {}
	return RITUALES[clave].duplicate(true)


static func ruta_arcano(carta: Dictionary) -> String:
	var id := String(carta.get("id", "")).strip_edges()
	return "" if id.is_empty() else RUTA_TAROT % id
