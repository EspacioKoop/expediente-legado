## Composición contextual del HUD por fase (#397) e inventario transversal (#97).
##
## Controller hijo: conserva `dia_clima_app.gd` como raíz histórica y observa la
## fase efectiva de Jornada. Gobierna el slot ESTADO, una banda compacta de
## recursos, una tarjeta transitoria de fase y la superficie modal del inventario;
## prompts y diálogo siguen siendo responsabilidad de HUDLayer.
extends Node

const DURACION_TARJETA_FASE := 1.5
const RUTA_TEXTOS_RECURSOS := "res://datos/hud_recursos_textos.json"
const FASES_RECURSOS := ["archivo", "trayecto", "casa"]
const NOMBRES_FASE := {
	"archivo": "ARCHIVO · PLANTA 4",
	"trayecto": "TRAYECTO",
	"casa": "CASA",
	"sueño": "SUEÑO",
}

var _fase_anterior := ""
var _tarjeta_fase: PanelContainer
var _texto_fase: Label
var _temporizador_fase: Timer
var _recursos_panel: PanelContainer
var _texto_recursos: Label
var _firma_recursos := ""
var _textos_recursos: Dictionary = {}
var _inventario_panel: InventarioMenuApp
var _mouse_previo := Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_textos_recursos = _cargar_textos_recursos()
	_temporizador_fase = Timer.new()
	_temporizador_fase.name = "TemporizadorTarjetaFase"
	_temporizador_fase.one_shot = true
	_temporizador_fase.wait_time = DURACION_TARJETA_FASE
	_temporizador_fase.timeout.connect(_ocultar_tarjeta_fase)
	add_child(_temporizador_fase)


func _unhandled_input(evento: InputEvent) -> void:
	if (
		is_instance_valid(_inventario_panel)
		and _inventario_panel.visible
		and evento.is_action_pressed("cancelar")
	):
		_cerrar_inventario()
		get_viewport().set_input_as_handled()
		return
	if not evento.is_action_pressed("inventario"):
		return
	if is_instance_valid(_inventario_panel) and _inventario_panel.visible:
		_cerrar_inventario()
	else:
		_abrir_inventario()
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var jornada = dia.get("jornada")
	if not jornada is Dictionary:
		return
	var fase := String(jornada.get("fase", ""))
	var hud = dia.get("_hud_prioridades")
	if not hud is HUDLayer:
		return
	# La entrada 3D oculta el HUD completo. No consumimos la tarjeta detrás de la
	# cinemática ni refrescamos superficies que el jugador todavía no puede ver.
	if not hud.visible:
		return
	# Los recursos cambian dentro de una misma fase (leer, comprar, gastar una
	# acción...), por eso se sincronizan antes del corte por cambio de fase.
	_sincronizar_recursos(hud, dia, jornada)
	if fase == _fase_anterior:
		return
	_fase_anterior = fase
	_sincronizar_estado_hud(hud, fase)
	_mostrar_tarjeta_fase(hud, fase)


func _sincronizar_estado_hud(hud: HUDLayer, fase: String) -> void:
	if fase == "archivo":
		hud.activar(HUDLayer.ESTADO)
	else:
		hud.desactivar(HUDLayer.ESTADO)


static func modelo_recursos(estado_partida: Dictionary) -> Dictionary:
	var jornada = estado_partida.get("jornada", {})
	if not jornada is Dictionary:
		return {"visible": false}
	var fase := String(jornada.get("fase", ""))
	if fase not in FASES_RECURSOS:
		return {"visible": false, "fase": fase}

	var pistas = estado_partida.get("pistas_descubiertas", [])
	var inventario_bruto = estado_partida.get("inventario", {})
	var inventario: Dictionary = (
		inventario_bruto.duplicate(true) if inventario_bruto is Dictionary else Inventario.nuevo()
	)
	Inventario.completar(inventario)

	var dia := maxi(1, int(jornada.get("dia", 1)))
	var modelo := {
		"visible": true,
		"fase": fase,
		"dia": dia,
		"hora_minutos": Jornada.hora_minutos(jornada),
		"dinero": int(jornada.get("dinero", 0)),
	}

	match fase:
		"archivo":
			var leido_hoy = jornada.get("leido_hoy", [])
			var lecturas_hechas := leido_hoy.size() if leido_hoy is Array else 0
			modelo["acciones"] = int(jornada.get("acciones", 0))
			modelo["pistas"] = pistas.size() if pistas is Array else 0
			modelo["lecturas_gratis"] = maxi(0, Jornada.DOCUMENTOS_GRATIS_POR_DIA - lecturas_hechas)
		"trayecto":
			modelo["acciones"] = int(jornada.get("acciones", 0))
			modelo["objetos"] = Inventario.visibles(inventario, false).size()
			var vencimiento := Jornada.alquiler_vencimiento(dia)
			modelo["alquiler_hoy"] = (dia == vencimiento and Jornada.alquiler_pendiente(jornada))
			modelo["alquiler_importe"] = Jornada.PRECIO_ALQUILER
		"casa":
			modelo["objetos"] = Inventario.visibles(inventario, true).size()

	return modelo


func _sincronizar_recursos(hud: HUDLayer, dia: Node, jornada: Dictionary) -> void:
	var partida_actual = dia.get("partida")
	if not partida_actual is Partida:
		hud.desactivar(HUDLayer.RECURSOS)
		return
	# Jornada se comparte normalmente con Partida, pero la UI toma la referencia
	# efectiva del host para no depender de ese detalle de implementación.
	var estado: Dictionary = partida_actual.estado.duplicate(false)
	estado["jornada"] = jornada
	var modelo := modelo_recursos(estado)
	if not bool(modelo.get("visible", false)):
		hud.desactivar(HUDLayer.RECURSOS)
		_firma_recursos = ""
		return

	_asegurar_recursos(hud)
	var firma := JSON.stringify(modelo)
	if firma != _firma_recursos:
		_texto_recursos.text = _texto_de_recursos(modelo)
		_firma_recursos = firma
	hud.activar(HUDLayer.RECURSOS)


func _asegurar_recursos(hud: HUDLayer) -> void:
	if is_instance_valid(_recursos_panel):
		return
	_recursos_panel = PanelContainer.new()
	_recursos_panel.name = "RecursosContextuales"
	_recursos_panel.theme = EstiloSiga.tema()
	_recursos_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_recursos_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_recursos_panel.offset_left = -720.0
	_recursos_panel.offset_top = 12.0
	_recursos_panel.offset_right = -12.0
	_recursos_panel.offset_bottom = 50.0
	_recursos_panel.visible = false
	hud.add_child(_recursos_panel)

	_texto_recursos = Label.new()
	_texto_recursos.name = "TextoRecursos"
	_texto_recursos.custom_minimum_size = Vector2(0.0, 30.0)
	_texto_recursos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_texto_recursos.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto_recursos.add_theme_font_size_override("font_size", 14)
	_recursos_panel.add_child(_texto_recursos)

	hud.registrar(HUDLayer.RECURSOS, _recursos_panel)


func _texto_de_recursos(modelo: Dictionary) -> String:
	var partes: Array[String] = []
	var minutos := int(modelo.get("hora_minutos", 0))
	_anadir_parte(partes, _formatear_recurso("dia", [int(modelo.get("dia", 1))]))
	_anadir_parte(partes, _formatear_recurso("hora", [int(minutos / 60), minutos % 60]))

	match String(modelo.get("fase", "")):
		"archivo":
			_anadir_parte(partes, _formatear_recurso("acciones", [modelo.get("acciones", 0)]))
			_anadir_parte(partes, _formatear_recurso("dinero", [modelo.get("dinero", 0)]))
			_anadir_parte(partes, _formatear_recurso("pistas", [modelo.get("pistas", 0)]))
			if int(modelo.get("lecturas_gratis", 0)) > 0:
				_anadir_parte(
					partes,
					_formatear_recurso("lecturas_gratis", [modelo.get("lecturas_gratis", 0)])
				)
		"trayecto":
			_anadir_parte(partes, _formatear_recurso("dinero", [modelo.get("dinero", 0)]))
			_anadir_parte(partes, _formatear_recurso("acciones", [modelo.get("acciones", 0)]))
			_anadir_parte(partes, _formatear_recurso("objetos_fuera", [modelo.get("objetos", 0)]))
			if bool(modelo.get("alquiler_hoy", false)):
				_anadir_parte(
					partes,
					_formatear_recurso(
						"alquiler_hoy", [modelo.get("alquiler_importe", Jornada.PRECIO_ALQUILER)]
					)
				)
		"casa":
			_anadir_parte(partes, _formatear_recurso("dinero", [modelo.get("dinero", 0)]))
			_anadir_parte(partes, _formatear_recurso("objetos_casa", [modelo.get("objetos", 0)]))

	return String(_textos_recursos.get("separador", " ")).join(PackedStringArray(partes))


func _formatear_recurso(clave: String, valores: Array = []) -> String:
	var plantilla := String(_textos_recursos.get(clave, ""))
	if plantilla.is_empty() or valores.is_empty():
		return plantilla
	if valores.size() == 1:
		return plantilla % valores[0]
	return plantilla % valores


func _anadir_parte(partes: Array[String], texto: String) -> void:
	if not texto.is_empty():
		partes.append(texto)


func _cargar_textos_recursos() -> Dictionary:
	if not FileAccess.file_exists(RUTA_TEXTOS_RECURSOS):
		return {}
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS_RECURSOS))
	return datos if datos is Dictionary else {}


func _mostrar_tarjeta_fase(hud: HUDLayer, fase: String) -> void:
	if not NOMBRES_FASE.has(fase):
		return
	_asegurar_tarjeta_fase(hud)
	_texto_fase.text = String(NOMBRES_FASE[fase])
	hud.activar(HUDLayer.FASE)
	_temporizador_fase.start(DURACION_TARJETA_FASE)


func _asegurar_tarjeta_fase(hud: HUDLayer) -> void:
	if is_instance_valid(_tarjeta_fase):
		return
	_tarjeta_fase = PanelContainer.new()
	_tarjeta_fase.name = "TarjetaFase"
	_tarjeta_fase.theme = EstiloSiga.tema()
	_tarjeta_fase.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_tarjeta_fase.offset_left = -180.0
	_tarjeta_fase.offset_top = 30.0
	_tarjeta_fase.offset_right = 180.0
	_tarjeta_fase.offset_bottom = 80.0
	_tarjeta_fase.visible = false
	hud.add_child(_tarjeta_fase)

	_texto_fase = Label.new()
	_texto_fase.name = "TextoFase"
	_texto_fase.custom_minimum_size = Vector2(340.0, 42.0)
	_texto_fase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto_fase.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tarjeta_fase.add_child(_texto_fase)

	hud.registrar(HUDLayer.FASE, _tarjeta_fase)


func _abrir_inventario() -> void:
	if get_tree().paused:
		return
	var dia := get_parent()
	if dia == null:
		return
	var hud = dia.get("_hud_prioridades")
	var partida_actual = dia.get("partida")
	if not hud is HUDLayer or not partida_actual is Partida or not hud.visible:
		return
	if hud.esta_activa(HUDLayer.MODAL):
		return
	_asegurar_inventario(hud)
	_mouse_previo = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_inventario_panel.abrir(partida_actual.estado)
	hud.activar(HUDLayer.MODAL)
	get_tree().paused = true


func _asegurar_inventario(hud: HUDLayer) -> void:
	if is_instance_valid(_inventario_panel):
		return
	_inventario_panel = InventarioMenuApp.new()
	_inventario_panel.name = "InventarioModal"
	_inventario_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_inventario_panel.volver.connect(_cerrar_inventario)
	hud.add_child(_inventario_panel)
	hud.registrar(HUDLayer.MODAL, _inventario_panel)


func _cerrar_inventario() -> void:
	if not is_instance_valid(_inventario_panel) or not _inventario_panel.visible:
		return
	_inventario_panel.visible = false
	var dia := get_parent()
	var hud = dia.get("_hud_prioridades") if dia != null else null
	if hud is HUDLayer:
		hud.desactivar(HUDLayer.MODAL)
	get_tree().paused = false
	Input.mouse_mode = _mouse_previo


func _ocultar_tarjeta_fase() -> void:
	var dia := get_parent()
	if dia == null:
		return
	var hud = dia.get("_hud_prioridades")
	if hud is HUDLayer:
		hud.desactivar(HUDLayer.FASE)
