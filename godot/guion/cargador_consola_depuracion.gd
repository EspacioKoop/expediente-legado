## Selector de consola de QA / manual de servicio de release (#116).
##
## QA carga la implementación completa desde res://debug/**. Release nunca toca
## esa ruta: instancia una consola distinta y limitada cuyo acceso depende del
## progreso permanente de Bit 98.
extends Node

const RUTA_CONSOLA_QA := "res://debug/consola_depuracion.gd"
const RUTA_EDITOR_EXPEDIENTES := "res://debug/editor_expedientes.gd"
# Se compone para que la guarda de claves i18n no confunda configuración con texto UI.
const ENV_EDITOR_EXPEDIENTES := "SIGA98" + "_EDITOR_EXPEDIENTES"
const RUTA_CONSOLA_RELEASE := "res://guion/consola_trucos_release.gd"


func _ready() -> void:
	if OS.is_debug_build() or OS.has_feature("qa_tools"):
		_instanciar(RUTA_CONSOLA_QA, "ConsolaDepuracionUI")
		if OS.get_environment(ENV_EDITOR_EXPEDIENTES) == "1":
			_instanciar(RUTA_EDITOR_EXPEDIENTES, "EditorExpedientesQA")
	else:
		_instanciar(RUTA_CONSOLA_RELEASE, "ConsolaTrucosRelease")


func _instanciar(ruta: String, nombre: String) -> void:
	if not ResourceLoader.exists(ruta):
		return
	var script: Script = load(ruta) as Script
	if script == null:
		return
	var instancia := script.new() as Node
	if instancia == null:
		return
	instancia.name = nombre
	add_child(instancia)
