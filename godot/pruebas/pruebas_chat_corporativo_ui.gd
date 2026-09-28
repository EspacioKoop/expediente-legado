## Prueba headless de la interfaz del chat corporativo OS98 (#666).
extends SceneTree

var _fallos := 0
var _pasadas := 0


func _initialize() -> void:
	var watchdog := create_timer(15.0)
	watchdog.timeout.connect(_agotar_tiempo)
	call_deferred("_probar")


func _agotar_tiempo() -> void:
	push_error("Timeout interno en pruebas_chat_corporativo_ui.gd")
	quit(1)


func _probar() -> void:
	var chat := ChatCorporativoSiga.new()
	var senales := {"mensaje": "", "opcion": "", "enlace": ""}
	chat.respuesta_elegida.connect(
		func(mensaje_id: String, opcion_id: String):
			senales["mensaje"] = mensaje_id
			senales["opcion"] = opcion_id
	)
	chat.enlace_abierto.connect(func(recurso_id: String): senales["enlace"] = recurso_id)
	chat.configurar_contexto(_contexto(1, Jornada.ACCIONES_POR_DIA - 1))
	get_root().add_child(chat)
	await process_frame

	var canales := chat.find_child("Canales", true, false) as ItemList
	var presencias := chat.find_child("Presencias", true, false) as ItemList
	var mensajes := chat.find_child("Mensajes", true, false) as ItemList
	var detalle := chat.find_child("DetalleMensaje", true, false) as RichTextLabel
	var enlace := chat.find_child("AbrirWeb98", true, false) as Button
	_comprobar(canales != null and canales.item_count == 4, "la UI muestra los cuatro canales normales")
	_comprobar(presencias != null, "la UI expone presencia por canal")
	_comprobar(mensajes != null, "la UI expone historial seleccionable")
	_comprobar(detalle != null and detalle.selection_enabled, "el texto del mensaje se puede seleccionar")
	_comprobar(canales.focus_mode == Control.FOCUS_ALL, "los canales aceptan foco de teclado/mando")
	_comprobar(mensajes.focus_mode == Control.FOCUS_ALL, "los mensajes aceptan foco de teclado/mando")
	_comprobar(not _contiene_entrada_libre(chat), "el primer corte no ofrece chat de texto libre")

	var indice_planta := _indice_por_id(canales, "planta4")
	_seleccionar(canales, indice_planta)
	_comprobar(
		_alguno_empieza(canales, "#planta4"),
		"los canales conservan nombres diegéticos declarativos",
	)
	_comprobar(
		_alguno_empieza(mensajes, "[SISTEMA]"),
		"los mensajes del sistema se diferencian del chat normal",
	)

	var indice_cafe := _indice_por_id(canales, "cafe")
	_seleccionar(canales, indice_cafe)
	_comprobar(presencias.item_count >= 4, "el canal de café muestra presencia diferenciada")
	var indice_cunado := _indice_por_id(mensajes, "cunado-cafe")
	_seleccionar(mensajes, indice_cunado)
	var respuestas := chat.find_child("Respuestas", true, false) as VBoxContainer
	_comprobar(_botones(respuestas).size() == 2, "el mensaje ofrece exactamente sus dos respuestas cerradas")
	_botones(respuestas)[0].pressed.emit()
	await process_frame
	var guardadas := chat.respuestas_guardadas()
	_comprobar(guardadas.has("cunado-cafe"), "la elección queda en estado local exportable")
	_comprobar(senales["mensaje"] == "cunado-cafe", "la UI emite el mensaje respondido")
	_comprobar(not String(senales["opcion"]).is_empty(), "la UI emite una opción catalogada")
	_comprobar(_botones(respuestas).is_empty(), "una respuesta persistida no puede enviarse dos veces")

	chat.configurar_contexto(_contexto(1, Jornada.ACCIONES_POR_DIA - 2))
	await process_frame
	_seleccionar(canales, _indice_por_id(canales, "sistemas"))
	_seleccionar(mensajes, _indice_por_id(mensajes, "becario-byte-local"))
	_comprobar(enlace.visible, "un mensaje con recurso visible ofrece enlace Web98")
	enlace.pressed.emit()
	_comprobar(senales["enlace"] == "byte-local", "el enlace conserva el id canónico de Web98")

	var dia_tres := _contexto(3, Jornada.ACCIONES_POR_DIA - 2)
	chat.configurar_contexto(dia_tres)
	await process_frame
	_seleccionar(canales, _indice_por_id(canales, "sistemas"))
	_comprobar(
		_indice_por_id(mensajes, "sistema-diagnostico-reservado") < 0,
		"la UI no filtra el diagnóstico restringido sin conocimiento",
	)
	dia_tres["conocimiento"] = ["enlace13"]
	chat.configurar_contexto(dia_tres)
	await process_frame
	_seleccionar(canales, _indice_por_id(canales, "sistemas"))
	_comprobar(
		_indice_por_id(mensajes, "sistema-diagnostico-reservado") >= 0,
		"el mismo conocimiento canónico habilita el mensaje restringido",
	)

	var fuera := _contexto(1, Jornada.ACCIONES_POR_DIA)
	fuera["fase"] = "casa"
	chat.configurar_contexto(fuera)
	await process_frame
	_comprobar(canales.item_count == 0, "ignorar el chat fuera del archivo no bloquea otras fases")

	chat.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _contexto(dia: int, acciones: int) -> Dictionary:
	return {
		"fase": "archivo",
		"dia": dia,
		"acciones": acciones,
		"companeros": ["becario", "telefono", "cunado", "correspondencia", "jubilacion"],
		"conocimiento": [],
		"eventos": [],
	}


func _indice_por_id(lista: ItemList, id: String) -> int:
	if lista == null:
		return -1
	for indice in lista.item_count:
		var valor: Variant = lista.get_item_metadata(indice)
		if valor is Dictionary and String((valor as Dictionary).get("id", "")) == id:
			return indice
	return -1


func _seleccionar(lista: ItemList, indice: int) -> void:
	if lista == null or indice < 0 or indice >= lista.item_count:
		return
	lista.select(indice)
	lista.item_selected.emit(indice)


func _alguno_empieza(lista: ItemList, prefijo: String) -> bool:
	if lista == null:
		return false
	for indice in lista.item_count:
		if lista.get_item_text(indice).begins_with(prefijo):
			return true
	return false


func _botones(nodo: Node) -> Array[Button]:
	var resultado: Array[Button] = []
	if nodo == null:
		return resultado
	for hijo in nodo.get_children():
		if hijo is Button:
			resultado.append(hijo as Button)
		if hijo is Node:
			resultado.append_array(_botones(hijo as Node))
	return resultado


func _contiene_entrada_libre(nodo: Node) -> bool:
	if nodo is LineEdit or nodo is TextEdit:
		return true
	for hijo in nodo.get_children():
		if hijo is Node and _contiene_entrada_libre(hijo as Node):
			return true
	return false


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
