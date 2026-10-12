## Ejecutable ficticio de PC de 1998 de Cronicas (#2589).
## El progreso aqui es local: no altera Partida, SIGA, ni semillas oniricas.
class_name CronicasPc98
extends Control

signal cerrar_solicitado
signal prologo_completado

const ESCENA_BASTION := preload("res://escenas/cronicas/bastion_nombres_ausentes.tscn")
const TITULO := "CRONICAS_PC_TITULO"

var _portada: Control
var _boton_jugar: Button
var _estado: Label
var _sala: CronicasBastion3D
var _prologos_locales := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_montar_portada()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_boton_jugar.grab_focus.call_deferred()


func juego_en_curso() -> bool:
	return is_instance_valid(_sala) and not _sala.is_queued_for_deletion()


func prologos_locales() -> int:
	return _prologos_locales


func comenzar() -> bool:
	if juego_en_curso():
		return false
	_sala = ESCENA_BASTION.instantiate() as CronicasBastion3D
	if _sala == null:
		return false
	_sala.name = "PartidaCronicas"
	_sala.completado.connect(_al_finalizar)
	add_child(_sala)
	_portada.hide()
	return true


func _al_finalizar() -> void:
	if not juego_en_curso():
		return
	_prologos_locales += 1
	_sala.queue_free()
	_sala = null
	_portada.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_estado.text = tr("CRONICAS_PC_FINAL")
	_boton_jugar.grab_focus.call_deferred()
	prologo_completado.emit()


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
	instrucciones.text = tr("CRONICAS_PC_INSTRUCCIONES")
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
