## Puente de vigilia entre la micro-ROM RYU FLOW y el contrato común #442.
##
## La consola y Siga98GB permanecen genéricos: este observer es quien conoce la
## cabecera propia de la ROM y su byte de finalización. Se procesa incluso con
## el árbol pausado porque EmuladorPortatilApp pausa el mundo mientras la ROM
## está abierta.
class_name RyuFlowVigilia
extends Node

const ID_ROM := "ryu_flow_98"
const ID_MITO := "dragon_japones"
const TITULO_ROM := "RYUFLOW98"
const DIRECCION_COMPLETADO := 0xC100
const MARCA_COMPLETADO := 0xA5
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
	if _consola.leer_memoria_rom_u8(DIRECCION_COMPLETADO) != MARCA_COMPLETADO:
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
