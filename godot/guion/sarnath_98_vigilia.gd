## Fachada del tercer vertical de #932.
##
## Contexto documentado: Ancient Buddhist Site of Sarnath, India, inscrito por
## UNESCO en 2026 como propiedad serial de dos componentes. La ROM abstrae
## orientación y memoria; no reconstruye una ruta histórica ni una práctica.
class_name Sarnath98Vigilia
extends "res://guion/religion_rom_vigilia.gd"

const ID_ROM := "sarnath_98"
const TITULO_ROM := "SARNATH98"
const DIRECCION_ESTADO := 0xC100
const ESTADO_COMPLETADO := 0xA5
const TRADICION := "budismo"
const CONTEXTO := "india:varanasi:sarnath:sitio_arqueologico:unesco_2026"
const ETIQUETAS := [
	"orientacion",
	"memoria_espacial",
	"sitio_arqueologico",
	"chaukhandi_stupa",
	"restos_sarnath",
	"propiedad_serial",
	"fuente:unesco_927",
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
