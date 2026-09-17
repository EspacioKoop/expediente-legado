## Puente declarativo entre la contaminación OS98 y el clímax de #9.
##
## No inicia escenas, combate ni finales. Solo observa el contexto que ya posee
## EscritorioSigaController y emite una señal una vez por partida/vuelta cuando
## fase 4 queda pendiente. La futura capa dueña de Hastur puede consumirla sin
## interpretar documentos, credenciales ni estado privado de aplicaciones.
extends Node

signal climax_hastur_pendiente(contexto: Dictionary)

var _emitido_para := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var escritorio := dia.get_node_or_null("EscritorioSigaController")
	if escritorio == null or not escritorio.has_method("_contexto_os98"):
		return
	var contexto: Dictionary = escritorio.call("_contexto_os98", dia)
	if not bool(contexto.get("climax_hastur_pendiente", false)):
		return
	var clave := (
		"%s:%s"
		% [
			str(int(dia.jornada.get("raiz", 0))),
			str(int(dia.jornada.get("vuelta", 1))),
		]
	)
	if clave == _emitido_para:
		return
	_emitido_para = clave
	climax_hastur_pendiente.emit(contexto.duplicate(true))
