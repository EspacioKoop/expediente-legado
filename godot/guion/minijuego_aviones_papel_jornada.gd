## Adaptador de jornada para la superficie jugable de #160.
##
## La escena base sigue siendo autocontenida y testeable; este adaptador solo
## consume su señal `finalizada` y aplica las reglas ambientales del descanso.
extends Control

signal finalizada(resultado: Dictionary)

var jornada: Dictionary = {}

@onready var minijuego: Control = $MinijuegoAvionesPapel


func _ready() -> void:
	minijuego.finalizada.connect(_al_finalizar)


## El host entrega la MISMA jornada que ya persiste Partida. No se crea un
## contador paralelo ni se guarda desde aquí.
func configurar_jornada(valor: Dictionary) -> void:
	jornada = valor


func _al_finalizar(resultado: Dictionary) -> void:
	var salida := resultado.duplicate(true)
	salida["descanso"] = AvionesPapelDescanso.finalizar(jornada, resultado)
	finalizada.emit(salida)
