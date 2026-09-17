## Reacción diegética del gato a estados anómalos reales (#539 / #787).
##
## Es presentación pura: deriva la fase del mismo contexto que consumen
## Explorador/Web98 y observa anomalías oníricas ya montadas en el mundo. No
## concede progreso, no persiste estado paralelo y nunca modifica objetivos.
extends Node

const NOMBRE_REACCION := "ReaccionContaminacionOs98"

var _pantalla_id := 0
var _fase_aplicada := -1
var _guia_id := 0
var _reaccion_guia := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return

	var controlador := dia.get_node_or_null("EscritorioSigaController")
	if controlador == null or not controlador.has_method("_contexto_os98"):
		return
	var contexto: Variant = controlador.call("_contexto_os98", dia)
	if not contexto is Dictionary:
		return

	var fase := int((contexto as Dictionary).get("fase_contaminacion", 0))
	var gato: Dictionary = dia.jornada.get("gato", {})
	var ayuda_completa := GatoAyuda.nivel(gato) == GatoAyuda.COMPLETA
	_sincronizar_siga(dia, fase, ayuda_completa)
	_sincronizar_guia_sueno(dia, fase, ayuda_completa)


func _sincronizar_siga(dia: Node, fase: int, ayuda_completa: bool) -> void:
	var pantalla: Variant = dia.get("_pantalla")
	if pantalla == null or not is_instance_valid(pantalla):
		_pantalla_id = 0
		_fase_aplicada = -1
		return

	var id_pantalla := (pantalla as Node).get_instance_id()
	if id_pantalla == _pantalla_id and fase == _fase_aplicada:
		return
	var activa := fase >= ContaminacionOs98.FASE_CONTAMINACION_CRUZADA and ayuda_completa
	if _sincronizar_reaccion(pantalla as Node, activa):
		_pantalla_id = id_pantalla
		_fase_aplicada = fase


## El sueño no recibe otra copia del estado de #539: usa la misma fase viva del
## escritorio y mira si el mundo ya contiene anomalías 3D legitimadas por #87.
## La reacción solo cambia la pose. En particular, no gira al gato ni conoce la
## posición de la anomalía, así que jamás funciona como flecha o detector de pista.
func _sincronizar_guia_sueno(dia: Node, fase: int, ayuda_completa: bool) -> void:
	if String(dia.jornada.get("fase", "")) != "sueño":
		_guia_id = 0
		_reaccion_guia = ""
		return

	var guia: Variant = dia.get("_gato_guia")
	if guia == null or not is_instance_valid(guia) or not guia is Gato:
		_guia_id = 0
		_reaccion_guia = ""
		return

	var mundo: Variant = dia.get("_mundo")
	var anomalias := _contar_anomalias(mundo as Node if mundo is Node else null)
	var reaccion := GatoReaccionContextual.decidir(fase, anomalias, ayuda_completa)
	var id_guia := (guia as Gato).get_instance_id()
	var id_reaccion := String(reaccion.get("id", ""))
	if id_guia == _guia_id and id_reaccion == _reaccion_guia:
		return

	if not reaccion.is_empty():
		(guia as Gato).presentar_estado(String(reaccion.get("estado", "parado")))
	_guia_id = id_guia
	_reaccion_guia = id_reaccion


func _contar_anomalias(raiz: Node) -> int:
	if raiz == null:
		return 0
	var total := 1 if raiz is AnomaliaSueno3D else 0
	for hijo in raiz.get_children():
		total += _contar_anomalias(hijo)
	return total


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
