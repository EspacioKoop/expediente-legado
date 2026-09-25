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
	var reducir_movimiento := bool(preferencias.get("reduccion_movimiento", false))
	_sincronizar_documento(
		pantalla as Node if pantalla is Node else null,
		contexto,
		reducir_movimiento,
		delta,
	)
	var mundo: Variant = dia.get("_mundo")
	_sincronizar_rotulos_3d(
		mundo as Node if mundo is Node else null,
		contexto,
		reducir_movimiento,
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
	if (
		not configuracion is Dictionary
		or not bool((configuracion as Dictionary).get("activo", false))
	):
		_restaurar_documento(visor)
		return
	if reducir_movimiento:
		_restaurar_documento(visor)
		return

	var ajuste := (configuracion as Dictionary).duplicate(true)
	ajuste["semilla"] = (
		"%s:%d"
		% [
			String(ajuste.get("semilla", "contaminacion-os98")),
			hash(_texto_original),
		]
	)
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


## Aplica el mismo contrato narrativo a los rótulos físicos del archivado (#157).
## Son superficies 3D reales del recorrido; el estado visual vive como metadata
## local del Label3D y nunca modifica la lógica de clasificación.
func _sincronizar_rotulos_3d(
	mundo: Node, contexto: Dictionary, reducir_movimiento: bool, delta: float
) -> void:
	if mundo == null:
		return
	var configuracion: Variant = contexto.get("efecto_texto", {})
	for nodo in mundo.find_children("DestinoArchivado", "Label3D", true, false):
		var rotulo := nodo as Label3D
		if rotulo == null:
			continue
		_sincronizar_rotulo_3d(rotulo, configuracion, reducir_movimiento, delta)


func _sincronizar_rotulo_3d(
	rotulo: Label3D, configuracion: Variant, reducir_movimiento: bool, delta: float
) -> void:
	var original := String(rotulo.get_meta("_texto_corrupto_original_806", rotulo.text))
	var visual := String(rotulo.get_meta("_texto_corrupto_visual_806", rotulo.text))
	if rotulo.text != visual:
		original = rotulo.text
		visual = rotulo.text
		rotulo.set_meta("_texto_corrupto_original_806", original)
		rotulo.set_meta("_texto_corrupto_visual_806", visual)
		rotulo.set_meta("_texto_corrupto_tiempo_806", 0.0)
	elif not rotulo.has_meta("_texto_corrupto_original_806"):
		rotulo.set_meta("_texto_corrupto_original_806", original)
		rotulo.set_meta("_texto_corrupto_visual_806", visual)
		rotulo.set_meta("_texto_corrupto_tiempo_806", 0.0)

	if (
		not configuracion is Dictionary
		or not bool((configuracion as Dictionary).get("activo", false))
		or reducir_movimiento
	):
		_restaurar_rotulo_3d(rotulo, original)
		return

	var ajuste := (configuracion as Dictionary).duplicate(true)
	ajuste["semilla"] = (
		"%s:rotulo:%d"
		% [
			String(ajuste.get("semilla", "contaminacion-os98")),
			hash(original),
		]
	)
	var duracion := maxf(0.01, float(ajuste.get("duracion", 1.35)))
	var tiempo := float(rotulo.get_meta("_texto_corrupto_tiempo_806", 0.0))
	tiempo = fmod(tiempo + maxf(delta, 0.0), duracion * 2.0)
	rotulo.set_meta("_texto_corrupto_tiempo_806", tiempo)
	var progreso := TextoCorruptoNarrativo.progreso_para_tiempo(tiempo, duracion)
	if tiempo > duracion:
		progreso = TextoCorruptoNarrativo.progreso_para_tiempo(tiempo - duracion, duracion, true)
	var critico := bool(rotulo.get_meta("texto_corrupto_critico", false))
	var presentacion := TextoCorruptoNarrativo.aplicar(
		rotulo, original, progreso, ajuste, false, critico
	)
	(
		rotulo
		. set_meta(
			"_texto_corrupto_visual_806",
			String(presentacion.get("texto_visual", original)),
		)
	)


func _restaurar_rotulo_3d(rotulo: Label3D, original: String) -> void:
	if rotulo.text != original:
		rotulo.text = original
	rotulo.set_meta("_texto_corrupto_visual_806", original)
	rotulo.set_meta("_texto_corrupto_tiempo_806", 0.0)
