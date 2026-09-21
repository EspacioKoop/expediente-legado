## Fachada del vertical JALI 98 (#932).
##
## Contexto histórico documentado: jali mogol de arenisca roja, probablemente
## Agra, segunda mitad del siglo XVI (The Met 1993.67.1). El juego es una
## abstracción original de geometría + luz/sombra, no una reconstrucción.
class_name Jali98Vigilia
extends "res://guion/religion_rom_vigilia.gd"

const ID_ROM := "jali_98"
const TITULO_ROM := "JALI98"
const DIRECCION_ESTADO := 0xC100
const ESTADO_COMPLETADO := 0xA5
const TRADICION := "islam"
const CONTEXTO := "mughal_india:agra:segunda_mitad_siglo_xvi"
const ETIQUETAS := [
	"arquitectura",
	"calado",
	"geometria",
	"jali",
	"luz_sombra",
	"mughal_india",
	"fuente:met_1993_67_1",
]


func configurar(
	registro: Dictionary, jornada: Dictionary, consola: ConsolaPortatil98
) -> void:
	configurar_contrato(
		registro,
		jornada,
		consola,
		{
			"id_rom": ID_ROM,
			"titulo_rom": TITULO_ROM,
			"direccion": DIRECCION_ESTADO,
			"valor": ESTADO_COMPLETADO,
			"tradicion": TRADICION,
			"contexto": CONTEXTO,
			"etiquetas": ETIQUETAS,
		},
	)
