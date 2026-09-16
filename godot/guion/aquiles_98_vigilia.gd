## Puente de vigilia entre MYRMIDON 98 y el contrato común de semillas (#438).
##
## La consola y Siga98GB siguen siendo genéricos: este observer conoce la
## cabecera de la ROM y su estado de victoria. El estado vive en el primer byte
## de la única sección WRAM0 de MYRMIDON 98 (`wEstado`, $C000).
##
## Se procesa incluso con el árbol pausado porque EmuladorPortatilApp pausa el
## mundo mientras la ROM está abierta. Comprar, insertar o arrancar el cartucho
## no basta: solo `ESTADO_VICTORIA` registra la semilla.
class_name Aquiles98Vigilia
extends Node

const ID_ROM := "aquiles_98"
const ID_MITO := "aquiles"
const TITULO_ROM := "MYRMIDON98"
const DIRECCION_ESTADO := 0xC000
const ESTADO_VICTORIA := 2
const INTENSIDAD_SEMILLA := 2

var _jornada: Dictionary = {}
var _consola: ConsolaPortatil98 = null
var _registrada := false


func configurar(jornada: Dictionary, consola: ConsolaPortatil98) -> void:
	_jornada = jornada
	_consola = consola
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _process(_delta: float) -> void:
	if _registrada or not is_instance_valid(_consola):
		return
	if _consola.titulo_rom_activa() != TITULO_ROM:
		return
	if _consola.leer_memoria_rom_u8(DIRECCION_ESTADO) != ESTADO_VICTORIA:
		return

	var fuente := RomsPropias.fuente_semilla(ID_ROM)
	if fuente.is_empty():
		return
	_registrada = (
		SemillasOniricas
		. activar_semilla_onirica(
			_jornada,
			ID_MITO,
			fuente,
			INTENSIDAD_SEMILLA,
		)
	)
	if _registrada:
		set_process(false)


func registrada() -> bool:
	return _registrada
