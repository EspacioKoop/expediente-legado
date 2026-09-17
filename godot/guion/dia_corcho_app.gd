## Controlador auxiliar de #101: materializa en casa el grafo de conceptos como
## un corcho físico sin sustituir la capa raíz histórica de `dia.tscn`.
##
## Observa los cambios de mundo/fase ya resueltos por `dia_clima_app.gd` y solo
## monta presentación doméstica. No decide transiciones, vivienda ni reglas de
## jornada.
##
## Desde #785 el corcho de la pared solo se usa: reordenar fichas e hilos pasa
## en `CorchoPanel`, que se abre encima del día como el resto de pantallas.
extends Node

var _host
var _mundo_visto: Node3D = null
var _fase_vista := ""
var _corcho_3d: Corcho3D = null
var _panel: CorchoPanel = null


func _ready() -> void:
	_host = get_parent()


func _process(_delta: float) -> void:
	if _host == null or not is_instance_valid(_host):
		return
	if _host.jornada.is_empty() or _host._mundo == null:
		return

	var fase := String(_host.jornada.get("fase", ""))
	var vivienda := String(_host._vivienda())
	_limpiar_si_perdio_casa(vivienda)

	if _host._mundo == _mundo_visto and fase == _fase_vista:
		return

	_mundo_visto = _host._mundo
	_fase_vista = fase
	_corcho_3d = null
	if fase == "casa" and vivienda == "casa":
		_montar_corcho()


func _montar_corcho() -> void:
	var conceptos: Array = _host.contenido.conceptos_desbloqueados(
		_host.partida.estado.get("pistas_descubiertas", [])
	)
	_corcho_3d = Corcho3D.new()
	_corcho_3d.name = "CorchoConceptos"
	_corcho_3d.cambiado.connect(_al_cambiar_corcho)
	_corcho_3d.abrir_pedido.connect(abrir_panel)
	_host._mundo.add_child(_corcho_3d)
	_corcho_3d.configurar(_host.jornada, conceptos)


## El conocimiento del expediente sobrevive a perder la vivienda; el montaje
## doméstico no. Si una partida antigua conserva por error un tablero después
## de quedarse sin casa, también se sanea al cargarla.
func _limpiar_si_perdio_casa(vivienda: String) -> void:
	if vivienda == "casa":
		return
	var tablero = _host.jornada.get(Corcho.CLAVE, {})
	if typeof(tablero) != TYPE_DICTIONARY:
		return
	var fichas = tablero.get("fichas", {})
	var enlaces = tablero.get("enlaces", [])
	if fichas.is_empty() and enlaces.is_empty():
		return
	Corcho.perder_casa(_host.jornada)
	_host._guardar_o_avisar("")
	if is_instance_valid(_corcho_3d):
		_corcho_3d.queue_free()
	_corcho_3d = null


func _al_cambiar_corcho() -> void:
	_host._guardar_o_avisar("")


func panel() -> CorchoPanel:
	return _panel


func abrir_panel() -> void:
	if _host._pantalla != null or not is_instance_valid(_corcho_3d):
		return
	_host._caminante.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var capa := CanvasLayer.new()
	capa.name = "PantallaCorcho"
	_host._pantalla = capa
	_host.add_child(capa)
	_panel = CorchoPanel.new()
	_panel.name = "CorchoPanel"
	_panel.configurar(_host.jornada, _corcho_3d.conceptos())
	_panel.cambiado.connect(_al_cambiar_corcho)
	_panel.cerrado.connect(cerrar_panel)
	capa.add_child(_panel)


## La pared se vuelve a clavar con lo que se dejó en la interfaz.
func cerrar_panel() -> void:
	if _panel == null:
		return
	var capa: Node = _panel.get_parent()
	_panel = null
	if _host._pantalla == capa:
		_host._pantalla = null
	if is_instance_valid(capa):
		capa.queue_free()
	if is_instance_valid(_corcho_3d):
		_corcho_3d.refrescar()
	_host._guardar_o_avisar("")
	_host._caminante.set_physics_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
