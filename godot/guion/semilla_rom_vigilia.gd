## Adaptador común entre ROMs propias y semillas oníricas (#442).
##
## Las ROMs publican una evidencia mínima y determinista en memoria; este nodo
## traduce esa evidencia al contrato de SemillasOniricas. ConsolaPortatil98 y
## Siga98GB permanecen genéricos y no conocen mitologías, direcciones ni premios.
##
## Cada vertical conserva una fachada pequeña con sus constantes de ABI y llama
## a configurar_contrato(). Así una nueva ROM no duplica polling, pausa, fuente
## estable ni persistencia.
class_name SemillaRomVigilia
extends Node

var _jornada: Dictionary = {}
var _consola: ConsolaPortatil98 = null
var _contrato: Dictionary = {}
var _registrada := false


func configurar_contrato(
	jornada: Dictionary,
	consola: ConsolaPortatil98,
	contrato: Dictionary,
) -> void:
	_jornada = jornada
	_consola = consola
	_contrato = contrato.duplicate(true)
	_registrada = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(_contrato_valido())


func _process(_delta: float) -> void:
	if _registrada:
		return
	if not is_instance_valid(_consola):
		set_process(false)
		return
	if _consola.titulo_rom_activa() != String(_contrato.get("titulo_rom", "")):
		return

	var direccion := int(_contrato.get("direccion", -1))
	var valor := int(_contrato.get("valor", -1))
	if _consola.leer_memoria_rom_u8(direccion) != valor:
		return

	var id_rom := String(_contrato.get("id_rom", ""))
	var fuente := RomsPropias.fuente_semilla(id_rom)
	if fuente.is_empty():
		return

	_registrada = SemillasOniricas.activar_semilla_onirica(
		_jornada,
		String(_contrato.get("id_mito", "")),
		fuente,
		int(_contrato.get("intensidad", 1)),
	)
	if _registrada:
		set_process(false)


func registrada() -> bool:
	return _registrada


func _contrato_valido() -> bool:
	var id_rom := String(_contrato.get("id_rom", "")).strip_edges()
	var id_mito := String(_contrato.get("id_mito", "")).strip_edges()
	var titulo := String(_contrato.get("titulo_rom", "")).strip_edges()
	var direccion := int(_contrato.get("direccion", -1))
	var valor := int(_contrato.get("valor", -1))
	var intensidad := int(_contrato.get("intensidad", 0))
	return (
		not id_rom.is_empty()
		and not id_mito.is_empty()
		and not titulo.is_empty()
		and direccion >= 0
		and direccion <= 0xFFFF
		and valor >= 0
		and valor <= 0xFF
		and intensidad > 0
	)
