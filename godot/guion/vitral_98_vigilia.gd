## Fachada del segundo vertical de #932.
##
## Contexto documentado: taller de vidriera cristiana medieval europea; el V&A
## reproduce técnicas históricas a partir de un panel de Erfurt Cathedral,
## Alemania, hacia 1375. El puzzle usa solo materialidad y ensamblado abstracto.
class_name Vitral98Vigilia
extends "res://guion/religion_rom_vigilia.gd"

const ID_ROM := "vitral_98"
const TITULO_ROM := "VITRAL98"
const DIRECCION_ESTADO := 0xC100
const ESTADO_COMPLETADO := 0xA5
const TRADICION := "cristianismo"
const CONTEXTO := "europa_cristiana:vidriera_taller:ca_1375"
const ETIQUETAS := [
	"arquitectura",
	"vidriera",
	"vidrio_coloreado",
	"red_plomo",
	"luz_color",
	"taller_medieval",
	"fuente:vam_stained_glass",
]


func configurar(registro: Dictionary, jornada: Dictionary, consola: ConsolaPortatil98) -> void:
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
