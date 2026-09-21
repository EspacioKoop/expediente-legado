## Observer común para ROMs culturales/religiosas (#932).
##
## La ROM solo publica un byte de finalización. Esta capa externa lo traduce a
## ReligionEventos.CANAL_EXPOSICION y nunca escribe práctica o convicción.
class_name ReligionRomVigilia
extends Node

var _registro: Dictionary = {}
var _jornada: Dictionary = {}
var _consola: ConsolaPortatil98 = null
var _contrato: Dictionary = {}
var _registrada := false


func configurar_contrato(
	registro: Dictionary,
	jornada: Dictionary,
	consola: ConsolaPortatil98,
	contrato: Dictionary,
) -> void:
	_registro = registro
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
	var dia := int(_jornada.get("dia", 0))
	var evento := ReligionEventos.crear_evento(
		"exposicion:rom:%s:jornada:%d" % [id_rom, dia],
		ReligionEventos.CANAL_EXPOSICION,
		"rom:%s" % id_rom,
		String(_contrato.get("contexto", "")),
		dia,
		String(_contrato.get("tradicion", "")),
		_contrato.get("etiquetas", [])
	)
	_registrada = ReligionEventos.registrar(_registro, evento)
	if _registrada:
		set_process(false)


func registrada() -> bool:
	return _registrada


func _contrato_valido() -> bool:
	var id_rom := String(_contrato.get("id_rom", "")).strip_edges()
	var titulo := String(_contrato.get("titulo_rom", "")).strip_edges()
	var tradicion := String(_contrato.get("tradicion", "")).strip_edges()
	var direccion := int(_contrato.get("direccion", -1))
	var valor := int(_contrato.get("valor", -1))
	var etiquetas = _contrato.get("etiquetas", [])
	return (
		not id_rom.is_empty()
		and not titulo.is_empty()
		and not tradicion.is_empty()
		and direccion >= 0
		and direccion <= 0xFFFF
		and valor >= 0
		and valor <= 0xFF
		and typeof(etiquetas) == TYPE_ARRAY
	)
