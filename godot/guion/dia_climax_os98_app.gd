## Puente declarativo entre la contaminación OS98 y el clímax de #9.
##
## No inicia escenas, combate ni finales. Solo observa el contexto que ya posee
## EscritorioSigaController y emite una señal una vez por partida/vuelta cuando
## fase 4 queda pendiente. La futura capa dueña de Hastur puede consumirla sin
## interpretar documentos, credenciales ni estado privado de aplicaciones.
extends Node

signal climax_hastur_pendiente(contexto: Dictionary)

var _emitido_para := ""
var _visor_id := 0
var _texto_original := ""
var _texto_visual := ""
var _tiempo_texto := 0.0


func _process(delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var escritorio := dia.get_node_or_null("EscritorioSigaController")
	if escritorio == null or not escritorio.has_method("_contexto_os98"):
		return
	var contexto: Dictionary = escritorio.call("_contexto_os98", dia)
	var preferencias := PreferenciasSiga.cargar()
	var pantalla: Variant = dia.get("_pantalla")
	_sincronizar_documento(
		pantalla as Node if pantalla is Node else null,
		contexto,
		bool(preferencias.get("reduccion_movimiento", false)),
		delta,
	)
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



## Aplica #806 únicamente al visor documental ya montado por Explorador. El
## texto original se conserva fuera del renderer para que refrescos del visor,
## reducción de movimiento o una fase normal puedan restaurarlo sin pérdida.
func _sincronizar_documento(
	pantalla: Node, contexto: Dictionary, reducir_movimiento: bool, delta: float
) -> void:
	var visor: RichTextLabel = null
	if pantalla != null:
		visor = pantalla.find_child("VisorDocumento", true, false) as RichTextLabel
	if visor == null:
		_olvidar_documento()
		return

	var id_visor := visor.get_instance_id()
	if id_visor != _visor_id:
		_visor_id = id_visor
		_texto_original = visor.text
		_texto_visual = visor.text
		_tiempo_texto = 0.0
	elif visor.text != _texto_visual:
		# El propio Explorador acaba de abrir/refrescar otro documento.
		_texto_original = visor.text
		_texto_visual = visor.text
		_tiempo_texto = 0.0

	var configuracion: Variant = contexto.get("efecto_texto", {})
	if not configuracion is Dictionary or not bool((configuracion as Dictionary).get("activo", false)):
		_restaurar_documento(visor)
		return
	if reducir_movimiento:
		_restaurar_documento(visor)
		return

	var ajuste := (configuracion as Dictionary).duplicate(true)
	ajuste["semilla"] = "%s:%d" % [
		String(ajuste.get("semilla", "contaminacion-os98")),
		_texto_original.hash(),
	]
	var duracion := maxf(0.01, float(ajuste.get("duracion", 1.35)))
	_tiempo_texto = fmod(_tiempo_texto + maxf(delta, 0.0), duracion * 2.0)
	var progreso := TextoCorruptoNarrativo.progreso_para_tiempo(_tiempo_texto, duracion)
	if _tiempo_texto > duracion:
		progreso = TextoCorruptoNarrativo.progreso_para_tiempo(
			_tiempo_texto - duracion, duracion, true
		)
	var critico := bool(visor.get_meta("texto_corrupto_critico", false))
	var presentacion := TextoCorruptoNarrativo.aplicar(
		visor, _texto_original, progreso, ajuste, false, critico
	)
	_texto_visual = String(presentacion.get("texto_visual", _texto_original))


func _restaurar_documento(visor: RichTextLabel) -> void:
	if visor.text != _texto_original:
		visor.text = _texto_original
	_texto_visual = _texto_original
	_tiempo_texto = 0.0


func _olvidar_documento() -> void:
	_visor_id = 0
	_texto_original = ""
	_texto_visual = ""
	_tiempo_texto = 0.0
