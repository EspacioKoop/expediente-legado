## Selector de consola de QA / manual de servicio de release (#116).
##
## QA carga la implementación completa desde res://debug/**. Release nunca toca
## esa ruta: instancia una consola distinta y limitada cuyo acceso depende del
## progreso permanente de Bit 98.
extends Node

const RUTA_CONSOLA_QA := "res://debug/consola_depuracion.gd"
const RUTA_EDITOR_EXPEDIENTES := "res://debug/editor_expedientes.gd"
const RUTA_EDITOR_NIVELES_CINEMATICAS := "res://escenas/editor_niveles_cinematicas.tscn"
# Se componen para que la guarda de claves i18n no confunda configuración con texto UI.
const ENV_EDITOR_EXPEDIENTES := "SIGA98" + "_EDITOR_EXPEDIENTES"
const ENV_EDITOR_NIVELES_CINEMATICAS := "SIGA98" + "_EDITOR_NIVELES_CINEMATICAS"
const RUTA_CONSOLA_RELEASE := "res://guion/consola_trucos_release.gd"


func _ready() -> void:
	if OS.is_debug_build() or OS.has_feature("qa_tools"):
		_instanciar(RUTA_CONSOLA_QA, "ConsolaDepuracionUI")
		if OS.get_environment(ENV_EDITOR_EXPEDIENTES) == "1":
			_instanciar(RUTA_EDITOR_EXPEDIENTES, "EditorExpedientesQA")
		if OS.get_environment(ENV_EDITOR_NIVELES_CINEMATICAS) == "1":
			_instanciar_escena(RUTA_EDITOR_NIVELES_CINEMATICAS, "EditorNivelesCinematicasQA")
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


func _instanciar_escena(ruta: String, nombre: String) -> void:
	if not ResourceLoader.exists(ruta):
		return
	var escena := load(ruta) as PackedScene
	if escena == null:
		return
	var instancia := escena.instantiate()
	instancia.name = nombre
	add_child(instancia)
