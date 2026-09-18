## Puente de vigilia entre la micro-ROM RYU FLOW y el contrato común #442.
##
## Esta fachada declara el ABI propio de RYU FLOW. El polling, la pausa del
## mundo, la fuente estable y la persistencia viven en SemillaRomVigilia para
## que futuras ROMs no repitan el mismo observer.
class_name RyuFlowVigilia
extends "res://guion/semilla_rom_vigilia.gd"

const ID_ROM := "ryu_flow_98"
const ID_MITO := "dragon_japones"
const TITULO_ROM := "RYUFLOW98"
const DIRECCION_COMPLETADO := 0xC100
const MARCA_COMPLETADO := 0xA5
const INTENSIDAD_SEMILLA := 2


func configurar(jornada: Dictionary, consola: ConsolaPortatil98) -> void:
	configurar_contrato(
		jornada,
		consola,
		{
			"id_rom": ID_ROM,
			"id_mito": ID_MITO,
			"titulo_rom": TITULO_ROM,
			"direccion": DIRECCION_COMPLETADO,
			"valor": MARCA_COMPLETADO,
			"intensidad": INTENSIDAD_SEMILLA,
		},
	)
