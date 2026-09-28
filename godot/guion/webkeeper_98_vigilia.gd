## Puente de vigilia entre WEBKEEPER 98 y el contrato común de semillas (#748/#442).
##
## WEBKEEPER mantiene su ABI en WRAM: la final deja 0xA5 en $C100. Este
## adaptador no conoce gameplay ni emulador; solo declara el contrato y delega
## polling, fuente estable e idempotencia a SemillaRomVigilia.
class_name Webkeeper98Vigilia
extends "res://guion/semilla_rom_vigilia.gd"

const ID_ROM := "webkeeper_98"
const ID_MITO := "anansi_akan"
const TITULO_ROM := "WEBKEEPER98"
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
