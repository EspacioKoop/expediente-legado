## Cargador seguro de la consola de QA (#116).
##
## La implementación real vive en res://debug/**, ruta excluida de los presets
## distribuibles. Este autoload sí puede viajar en release porque no contiene
## comandos ni preloads de recursos de depuración: solo los instancia en el
## editor/build debug o en una alpha marcada explícitamente con `qa_tools`.
extends Node

const RUTA_CONSOLA := "res://debug/consola_depuracion.gd"


func _ready() -> void:
	if not OS.is_debug_build() and not OS.has_feature("qa_tools"):
		return
	if not ResourceLoader.exists(RUTA_CONSOLA):
		return
	var script: Script = load(RUTA_CONSOLA) as Script
	if script == null:
		return
	var consola := script.new() as Node
	if consola == null:
		return
	consola.name = "ConsolaDepuracionUI"
	add_child(consola)
