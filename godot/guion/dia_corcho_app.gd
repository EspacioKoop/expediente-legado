## Capa de #101 sobre el día: materializa en casa el grafo de conceptos como
## un corcho físico y conserva únicamente las conexiones que hace el jugador.
extends "res://guion/dia_clima_app.gd"

var _corcho_3d: Corcho3D


func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	_corcho_3d = null
	if fase != "casa" or _vivienda() != "casa":
		return

	var conceptos := contenido.conceptos_desbloqueados(
		partida.estado.get("pistas_descubiertas", [])
	)
	_corcho_3d = Corcho3D.new()
	_corcho_3d.name = "CorchoConceptos"
	_corcho_3d.cambiado.connect(_al_cambiar_corcho)
	_mundo.add_child(_corcho_3d)
	_corcho_3d.configurar(jornada, conceptos)


## La transición ya se guarda en la capa base. Limpiar aquí evita mantener una
## segunda bandera de vivienda y garantiza que el corcho desaparece junto con
## el resto de objetos domésticos de #97.
func _perder_vivienda() -> void:
	super._perder_vivienda()
	Corcho.perder_casa(jornada)


func _al_cambiar_corcho() -> void:
	_guardar_o_avisar("")
