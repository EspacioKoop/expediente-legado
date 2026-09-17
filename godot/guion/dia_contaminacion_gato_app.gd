## Reacción diegética del gato a la contaminación cruzada del OS98 (#539).
##
## Es presentación pura: deriva la fase del mismo contexto que consumen
## Explorador/Web98, no concede progreso ni persiste estado paralelo. El gato
## solo añade una observación cuando ya está presente y orientando con normalidad.
extends Node

const NOMBRE_REACCION := "ReaccionContaminacionOs98"

var _pantalla_id := 0
var _fase_aplicada := -1


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var pantalla: Variant = dia.get("_pantalla")
	if pantalla == null or not is_instance_valid(pantalla):
		_pantalla_id = 0
		_fase_aplicada = -1
		return

	var controlador := dia.get_node_or_null("EscritorioSigaController")
	if controlador == null or not controlador.has_method("_contexto_os98"):
		return
	var contexto: Variant = controlador.call("_contexto_os98", dia)
	if not contexto is Dictionary:
		return
	var fase := int((contexto as Dictionary).get("fase_contaminacion", 0))
	var id_pantalla := (pantalla as Node).get_instance_id()
	if id_pantalla == _pantalla_id and fase == _fase_aplicada:
		return

	var gato: Dictionary = dia.jornada.get("gato", {})
	var activa := (
		fase >= ContaminacionOs98.FASE_CONTAMINACION_CRUZADA
		and GatoAyuda.nivel(gato) == GatoAyuda.COMPLETA
	)
	if _sincronizar_reaccion(pantalla as Node, activa):
		_pantalla_id = id_pantalla
		_fase_aplicada = fase


func _sincronizar_reaccion(pantalla: Node, activa: bool) -> bool:
	var conjunto := pantalla.find_child("AsistenteSiga", true, false)
	if conjunto == null:
		# El asistente se monta en otro controlador durante el mismo arranque;
		# reintentamos en el siguiente frame sin fijar la fase como aplicada.
		return false
	var existente := conjunto.find_child(NOMBRE_REACCION, true, false)
	if not activa:
		if existente != null:
			existente.queue_free()
		return true
	if existente != null:
		return true

	var burbuja := conjunto.find_child("BocadilloGato", true, false)
	if burbuja == null:
		return false
	var caja := _buscar_caja_texto(burbuja)
	if caja == null:
		return false
	var frase := Label.new()
	frase.name = NOMBRE_REACCION
	frase.text = tr("GATO_SIGA_DESCUBRIMIENTO")
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frase.custom_minimum_size.x = 320
	frase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(frase)
	return true


func _buscar_caja_texto(nodo: Node) -> VBoxContainer:
	if nodo is VBoxContainer:
		return nodo as VBoxContainer
	for hijo in nodo.get_children():
		var encontrada := _buscar_caja_texto(hijo)
		if encontrada != null:
			return encontrada
	return null
