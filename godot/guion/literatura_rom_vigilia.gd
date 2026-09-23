## Observer externo para ROMs literarias (#1179).
##
## La ROM publica únicamente un byte. Esta capa traduce la finalización a un
## insight literario y nunca puede crear conocimiento: leer la obra sigue siendo
## una acción documental independiente.
class_name LiteraturaRomVigilia
extends Node

var _gestor: Node = null
var _jornada: Dictionary = {}
var _consola: ConsolaPortatil98 = null
var _contrato: Dictionary = {}
var _procesada := false


func configurar_contrato(
	gestor: Node,
	jornada: Dictionary,
	consola: ConsolaPortatil98,
	contrato: Dictionary,
) -> void:
	_gestor = gestor
	_jornada = jornada
	_consola = consola
	_contrato = contrato.duplicate(true)
	_procesada = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(_contrato_valido())


func _process(_delta: float) -> void:
	if _procesada:
		return
	if not is_instance_valid(_gestor) or not is_instance_valid(_consola):
		set_process(false)
		return
	if _consola.titulo_rom_activa() != String(_contrato.get("titulo_rom", "")):
		return
	if (
		_consola.leer_memoria_rom_u8(int(_contrato.get("direccion", -1)))
		!= int(_contrato.get("valor", -1))
	):
		return

	var evento := evento_handshake()
	if evento.is_empty():
		set_process(false)
		return

	# Un evento repetido devuelve false, pero sigue estando procesado: el id
	# estable impide que reabrir/rejugar la ROM duplique el insight.
	_gestor.call("registrar_evento_externo", evento)
	_procesada = true
	set_process(false)


func evento_handshake() -> Dictionary:
	if not _contrato_valido():
		return {}
	var id_rom := String(_contrato.get("id_rom", ""))
	var obra_id := String(_contrato.get("obra_id", ""))
	return (
		LiteraturaEventos
		. crear_evento(
			"insight:rom:%s:objetivo_completado" % id_rom,
			LiteraturaEventos.CANAL_INSIGHT,
			obra_id,
			"rom:%s" % id_rom,
			String(_contrato.get("contexto", "")),
			int(_jornada.get("dia", 0)),
			_contrato.get("etiquetas", []),
			{
				"rom_id": id_rom,
				"procedencia": "rom:handshake:c100",
				"adaptacion_original": true,
				"vuelta": int(_jornada.get("vuelta", 0)),
			},
		)
	)


func procesada() -> bool:
	return _procesada


func _contrato_valido() -> bool:
	var id_rom := String(_contrato.get("id_rom", "")).strip_edges()
	var titulo := String(_contrato.get("titulo_rom", "")).strip_edges()
	var obra := String(_contrato.get("obra_id", "")).strip_edges()
	var direccion := int(_contrato.get("direccion", -1))
	var valor := int(_contrato.get("valor", -1))
	var etiquetas = _contrato.get("etiquetas", [])
	return (
		not id_rom.is_empty()
		and not titulo.is_empty()
		and not obra.is_empty()
		and direccion >= 0
		and direccion <= 0xFFFF
		and valor >= 0
		and valor <= 0xFF
		and typeof(etiquetas) == TYPE_ARRAY
	)
