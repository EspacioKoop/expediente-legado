## Capa de presentación del contexto de investigación en el careo (#366).
##
## Reutiliza el folio y el estado que el careo ya recibe. La conclusión se
## muestra como recordatorio documental sin alterar ninguna regla del duelo.
extends "res://guion/careo_app.gd"

var _contexto_investigacion: Dictionary = {}
var _opciones_dialogo: VBoxContainer
var _texto_duelo_base := ""


func _ready() -> void:
	var contenido_contexto := Contenido.new()
	if contenido_contexto.cargar():
		_contexto_investigacion = (
			ContextoCareo
			. de_folio(
				contenido_contexto.casos,
				folio,
				estado.get("pistas_descubiertas", []),
			)
		)
	super._ready()


func _empezar_duelo() -> void:
	super._empezar_duelo()
	var prefijos: Array[String] = []

	var variante := (
		DialogoIdeologico
		. resolver(
			DialogoIdeologico.SUPERFICIE_CAREO_EXPOSICION,
			estado,
		)
	)
	var clave_ideologica := String(variante.get("clave", ""))
	if not clave_ideologica.is_empty():
		prefijos.append(tr(clave_ideologica))

	if not _contexto_investigacion.is_empty():
		var descripcion := String(_contexto_investigacion.get("descripcion", ""))
		if not descripcion.is_empty():
			prefijos.append(descripcion)

	if not prefijos.is_empty():
		_cronica.text = "\n".join(prefijos) + "\n" + _cronica.text
	_texto_duelo_base = _cronica.text
	_preparar_dialogo_previo()



func _preparar_dialogo_previo() -> void:
	var jornada_var = estado.get("jornada", {})
	if typeof(jornada_var) != TYPE_DICTIONARY or folio.strip_edges().is_empty():
		return
	var jornada: Dictionary = jornada_var
	var reentrada := DialogoCareoContextual.reentrada(jornada, folio)
	if not reentrada.is_empty():
		_cronica.text = tr(reentrada) + "\n" + _texto_duelo_base
		return

	var opciones := DialogoCareoContextual.opciones(not _contexto_investigacion.is_empty())
	if opciones.is_empty() or _botones == null or _botones.get_parent() == null:
		return

	_botones.visible = false
	_opciones_dialogo = VBoxContainer.new()
	_opciones_dialogo.name = "OpcionesDialogoCareo"
	_opciones_dialogo.add_theme_constant_override("separation", 6)
	_botones.get_parent().add_child(_opciones_dialogo)
	_cronica.text = tr("DIALOGO_CAREO_APERTURA") + "\n" + _texto_duelo_base

	var primer_boton: Button
	for opcion in opciones:
		var id_rama := String(opcion.get("id", ""))
		var clave_texto := String(opcion.get("texto", ""))
		if id_rama.is_empty() or clave_texto.is_empty():
			continue
		var boton := Button.new()
		boton.text = tr(clave_texto)
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.focus_mode = Control.FOCUS_ALL
		boton.pressed.connect(_al_elegir_enfoque.bind(id_rama))
		_opciones_dialogo.add_child(boton)
		if primer_boton == null:
			primer_boton = boton
	if primer_boton != null:
		primer_boton.call_deferred("grab_focus")
	else:
		_retirar_opciones_dialogo()


func _al_elegir_enfoque(id_rama: String) -> void:
	var jornada_var = estado.get("jornada", {})
	if typeof(jornada_var) != TYPE_DICTIONARY:
		_retirar_opciones_dialogo()
		return
	var jornada: Dictionary = jornada_var
	var resultado := DialogoCareoContextual.registrar(jornada, folio, id_rama)
	if bool(resultado.get("valida", false)):
		estado["jornada"] = jornada
		var respuesta := String(resultado.get("respuesta", ""))
		if not respuesta.is_empty():
			_cronica.text = tr(respuesta) + "\n" + _texto_duelo_base
	_retirar_opciones_dialogo()


func _retirar_opciones_dialogo() -> void:
	if is_instance_valid(_opciones_dialogo):
		_opciones_dialogo.queue_free()
	_opciones_dialogo = null
	if is_instance_valid(_botones):
		_botones.visible = true
		if _botones.get_child_count() > 0:
			var primero := _botones.get_child(0) as Button
			if primero != null:
				primero.call_deferred("grab_focus")
