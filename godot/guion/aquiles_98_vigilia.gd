## Puente de vigilia entre MYRMIDON 98 y el contrato común de semillas (#438/#442).
##
## Esta fachada conserva el ABI de MYRMIDON 98: wEstado vive en el primer byte
## de su única sección WRAM0 ($C000) y ESTADO_VICTORIA vale 2. El observer común
## solo registra la semilla cuando cabecera y byte coinciden.
class_name Aquiles98Vigilia
extends "res://guion/semilla_rom_vigilia.gd"

const ID_ROM := "aquiles_98"
const ID_MITO := "aquiles"
const TITULO_ROM := "MYRMIDON98"
const DIRECCION_ESTADO := 0xC000
const ESTADO_VICTORIA := 2
const INTENSIDAD_SEMILLA := 2


func configurar(jornada: Dictionary, consola: ConsolaPortatil98) -> void:
	configurar_contrato(
		jornada,
		consola,
		{
			"id_rom": ID_ROM,
			"id_mito": ID_MITO,
			"titulo_rom": TITULO_ROM,
			"direccion": DIRECCION_ESTADO,
			"valor": ESTADO_VICTORIA,
			"intensidad": INTENSIDAD_SEMILLA,
		},
	)
