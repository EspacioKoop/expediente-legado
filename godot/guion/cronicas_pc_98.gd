## Ejecutable ficticio de PC de 1998 de Crónicas (#2589, #2744).
## Su campaña reutiliza diez salas 3D con salidas verificadas. No escribe
## Partida, SIGA, semillas oníricas ni hechos reales del expediente.
class_name CronicasPc98
extends Control

signal cerrar_solicitado
signal prologo_completado
signal capitulo_completado

const TITULO := "CRONICAS_PC_TITULO"
const NOMBRES_ETAPA := {
	"bastion": "Bastión de los Nombres Ausentes",
	"patio_juramentos": "Patio de los Juramentos",
	"scriptorium_versiones": "Scriptorium de las Versiones",
	"torre_tiempo": "Torre del Tiempo",
	"galeria_identidades": "Galería de Identidades",
	"puente_ausencia": "Puente de la Ausencia",
	"estuario_maestro": "Estuario del Maestro",
	"umbral_heredera": "Umbral de la Heredera",
	"archivo_cronista": "Archivo del Cronista",
	"camara_guardian": "Cámara del Guardián",
}

var modo_ventana_os98 := false
var _marco_3d: SubViewportContainer
var _portada: Control
var _boton_jugar: Button
var _estado: Label
var _indicador_etapa: Label
var _boton_menu: Button
var _sala: Node3D
var _etapa_activa := ""
var _sesion: Dictionary = {}
var _prologos_locales := 0
var _recompensas_locales: Array[String] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sesion = CronicasCapituloRutas.nueva_sesion()
	_montar_portada()
	visibility_changed.connect(_al_visibilidad_cambiada)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_boton_jugar.grab_focus.call_deferred()


func juego_en_curso() -> bool:
	return is_instance_valid(_sala) and not _sala.is_queued_for_deletion()


func prologos_locales() -> int:
	return _prologos_locales


func recompensas_locales() -> Array[String]:
	return _recompensas_locales.duplicate()


## El avance solo vive en la instancia del CD-ROM; no acredita progreso SIGA.
func estado_capitulo_local() -> Dictionary:
	return _sesion.duplicate(true)


func comenzar() -> bool:
	if juego_en_curso():
		return false
	var siguiente := CronicasCapituloRutas.etapa_actual(_sesion)
	if String(siguiente.get("estado", "")) == CronicasCapituloRutas.ESTADO_TERMINADO:
		_sesion = CronicasCapituloRutas.nueva_sesion()
	return _abrir_etapa_actual()


func _abrir_etapa_actual() -> bool:
	var etapa := CronicasCapituloRutas.etapa_actual(_sesion)
	if String(etapa.get("estado", "")) != CronicasCapituloRutas.ESTADO_JUGABLE:
		_volver_a_portada("Esta sala todavía no está disponible en el CD-ROM.")
		return false

	var recurso := ResourceLoader.load(String(etapa["escena"])) as PackedScene
	if recurso == null:
		_volver_a_portada("No se pudo cargar la sala del capítulo.")
		return false

	var instancia := recurso.instantiate()
	if not instancia is Node3D or not instancia.has_signal("completado"):
		instancia.free()
		_volver_a_portada("La sala carece de un umbral de salida jugable.")
		return false

	_sala = instancia as Node3D
	_etapa_activa = String(etapa["id"])
	_sala.name = "PartidaCronicas"
	_sala.connect("completado", Callable(self, "_al_finalizar").bind(_etapa_activa))
	if modo_ventana_os98:
		if not is_instance_valid(_marco_3d):
			_montar_visor_3d()
		else:
			var viewport := _marco_3d.get_node("ViewportCronicas") as SubViewport
			viewport.add_child(_sala)
	else:
		add_child(_sala)

	_portada.hide()
	_mostrar_etapa(int(etapa["indice"]), _etapa_activa)
	return true


## Solo se acepta la salida real de la sala activa. La misma señal no puede
## registrar otra etapa ni premiar al jugador por abrir o cerrar el programa.
func _al_finalizar(etapa_id: String) -> void:
	if not juego_en_curso() or etapa_id != _etapa_activa:
		return
	var resultado := CronicasCapituloRutas.registrar_salida(_sesion, etapa_id, true)
	if not bool(resultado.get("registrado", false)):
		return

	_sesion = resultado["sesion"]
	var anterior := _sala
	_sala = null
	_etapa_activa = ""
	# El nodo saliente sigue en el árbol hasta el fin del frame. Liberar el
	# nombre permite que la siguiente sala conserve la ruta estable del visor.
	anterior.name = "PartidaCronicasSaliente"
	anterior.queue_free()

	# Contrato OS98 preexistente: haber atravesado el Bastión acredita
	# el prólogo, no las nueve etapas posteriores ni un hecho de SIGA.
	if etapa_id == "bastion":
		_prologos_locales += 1
		prologo_completado.emit()

	var siguiente: Dictionary = resultado["siguiente"]
	if String(siguiente.get("estado", "")) == CronicasCapituloRutas.ESTADO_JUGABLE:
		call_deferred("_abrir_etapa_actual")
		return

	_cerrar_visor()
	if String(siguiente.get("estado", "")) == CronicasCapituloRutas.ESTADO_TERMINADO:
		if not _recompensas_locales.has("sello_custodio_siete_registros"):
			_recompensas_locales.append("sello_custodio_siete_registros")
		_volver_a_portada(
			(
				"Capítulo completado. Reliquia obtenida: Sello del Custodio de "
				+ "los Siete Registros. Es ficción: no constituye prueba para SIGA-98."
			)
		)
		_boton_jugar.text = "Volver a jugar el capítulo"
		capitulo_completado.emit()
	else:
		_volver_a_portada("Capítulo en pausa: la siguiente sala no está disponible.")


func _volver_a_portada(mensaje: String) -> void:
	_portada.show()
	if is_instance_valid(_indicador_etapa):
		_indicador_etapa.hide()
	if is_instance_valid(_boton_menu):
		_boton_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_estado.text = mensaje
	_boton_jugar.grab_focus.call_deferred()


func _cerrar_visor() -> void:
	if is_instance_valid(_marco_3d):
		_marco_3d.queue_free()
	_marco_3d = null


## SubViewport propio: Crónicas 3D no debe dibujarse sobre el puesto real.
## Cada etapa reutiliza el mismo visor, sin cargar otro mundo de SIGA.
func _montar_visor_3d() -> void:
	_marco_3d = SubViewportContainer.new()
	_marco_3d.name = "Area3DCronicas"
	_marco_3d.stretch = true
	_marco_3d.mouse_filter = Control.MOUSE_FILTER_STOP
	_marco_3d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_marco_3d)

	var viewport := SubViewport.new()
	viewport.name = "ViewportCronicas"
	viewport.size = Vector2i(960, 720)
	viewport.own_world_3d = true
	viewport.handle_input_locally = true
	_marco_3d.add_child(viewport)
	viewport.add_child(_sala)


func _mostrar_etapa(indice: int, etapa_id: String) -> void:
	if not is_instance_valid(_indicador_etapa):
		_indicador_etapa = Label.new()
		_indicador_etapa.name = "MarcadorCapitulo"
		_indicador_etapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_indicador_etapa.anchor_left = 0.55
		_indicador_etapa.anchor_right = 0.98
		_indicador_etapa.anchor_top = 0.01
		_indicador_etapa.anchor_bottom = 0.09
		_indicador_etapa.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_indicador_etapa.add_theme_font_size_override("font_size", 16)
		add_child(_indicador_etapa)
	_indicador_etapa.text = (
		"%d/%d · %s"
		% [
			indice + 1,
			CronicasCapituloRutas.ETAPAS.size(),
			String(NOMBRES_ETAPA.get(etapa_id, etapa_id)),
		]
	)
	_indicador_etapa.show()
	if not is_instance_valid(_boton_menu):
		_boton_menu = Button.new()
		_boton_menu.name = "VolverAlMenu"
		_boton_menu.text = "Volver al menú"
		_boton_menu.anchor_left = 0.76
		_boton_menu.anchor_right = 0.97
		_boton_menu.anchor_top = 0.93
		_boton_menu.anchor_bottom = 0.99
		_boton_menu.pressed.connect(_salir_al_menu)
		add_child(_boton_menu)
	_boton_menu.show()


## Al salir al menú se conserva la última etapa completada, pero se reinicia
## el desafío actual. Ningún progreso se escribe en los guardados SIGA.
func _salir_al_menu() -> void:
	if not juego_en_curso():
		return
	var anterior := _sala
	_sala = null
	_etapa_activa = ""
	anterior.queue_free()
	_cerrar_visor()
	_volver_a_portada(
		(
			"Punto de paso local: continuarás desde el comienzo de la sala actual. "
			+ "Se perderá al cerrar el CD-ROM."
		)
	)
	_boton_jugar.text = "Continuar capítulo"


## Minimizar o cerrar OS98 libera el cursor y suspende el duelo local.
## Restaurar NO recaptura el ratón a la fuerza; exige intención del jugador.
func _al_visibilidad_cambiada() -> void:
	if not is_instance_valid(_sala):
		return
	if not is_visible_in_tree():
		_sala.process_mode = Node.PROCESS_MODE_DISABLED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_sala.process_mode = Node.PROCESS_MODE_INHERIT


func _exit_tree() -> void:
	if is_instance_valid(_sala):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _montar_portada() -> void:
	_portada = Control.new()
	_portada.name = "Portada1998"
	_portada.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_portada)
	var fondo := ColorRect.new()
	fondo.name = "FondoMonocromo"
	fondo.color = Color(0.04, 0.06, 0.085)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portada.add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portada.add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 390)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.10, 0.115, 0.15)
	estilo.border_color = Color(0.68, 0.52, 0.26)
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(25)
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 18)
	panel.add_child(columna)
	var titulo := Label.new()
	titulo.name = "TituloCronicas"
	titulo.text = tr(TITULO)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 30)
	columna.add_child(titulo)
	var subtitulo := Label.new()
	subtitulo.text = tr("CRONICAS_PC_SUBTITULO")
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(subtitulo)
	_boton_jugar = Button.new()
	_boton_jugar.name = "JugarPrologo"
	_boton_jugar.text = tr("CRONICAS_PC_JUGAR")
	_boton_jugar.pressed.connect(comenzar)
	columna.add_child(_boton_jugar)
	var instrucciones := Label.new()
	instrucciones.name = "Instrucciones"
	instrucciones.text = (
		"Explora las salas 3D, examina testimonios, resuelve mecanismos y vence a sus custodios. "
		+ "Cada umbral desbloquea la siguiente estancia. Puedes reintentar los desafíos."
	)
	instrucciones.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(instrucciones)
	_estado = Label.new()
	_estado.name = "EstadoLocal"
	_estado.text = tr("CRONICAS_PC_DEMO")
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_estado)
	var cerrar := Button.new()
	cerrar.name = "CerrarPrograma"
	cerrar.text = tr("CRONICAS_PC_CERRAR")
	cerrar.pressed.connect(func(): cerrar_solicitado.emit())
	columna.add_child(cerrar)
