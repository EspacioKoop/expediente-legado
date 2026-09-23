## Fachada literaria de SUEÑO 98 (#1179).
##
## La adaptación usa motivos de apariencia/vigilia como reglas abstractas. No
## contiene texto de Calderón ni convierte jugar la ROM en haber leído la obra.
class_name Sueno98Vigilia
extends "res://guion/literatura_rom_vigilia.gd"

const ID_ROM := "sueno_98"
const TITULO_ROM := "SUENO98"
const OBRA_ID := "vida_es_sueno_1635"
const DIRECCION_ESTADO := 0xC100
const ESTADO_COMPLETADO := 0xA5
const CONTEXTO := "adaptacion_jugable:apariencia_vigilia"
const ETIQUETAS := [
	"adaptacion",
	"apariencia",
	"doble",
	"umbral",
	"vigilia",
]


func configurar(gestor: Node, jornada: Dictionary, consola: ConsolaPortatil98) -> void:
	configurar_contrato(
		gestor,
		jornada,
		consola,
		{
			"id_rom": ID_ROM,
			"titulo_rom": TITULO_ROM,
			"obra_id": OBRA_ID,
			"direccion": DIRECCION_ESTADO,
			"valor": ESTADO_COMPLETADO,
			"contexto": CONTEXTO,
			"etiquetas": ETIQUETAS,
		},
	)
