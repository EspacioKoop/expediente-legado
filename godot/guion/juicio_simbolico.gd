## Capa simbólica del Juicio por Combate (#779).
##
## El combate puede contaminarse con dos memorias que ya pertenecen a la partida:
## - un Arcano recogido y todavía no gastado;
## - una familia mitológica activada deliberadamente durante la jornada.
##
## Esta capa NO altera reglas ni consume progreso. Selecciona de forma estable lo
## que se representa y describe el vocabulario visual de cada mito para que el
## renderer 3D no tenga que conocer cómo se guarda Tarot o SemillasOniricas.
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


static func ruta_arcano(carta: Dictionary) -> String:
	var id := String(carta.get("id", "")).strip_edges()
	return "" if id.is_empty() else RUTA_TAROT % id
