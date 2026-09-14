## Ajuste de composición del HUD por fase (#397).
##
## El bloque de estado general ayuda en el archivo, donde contextualiza la jornada,
## pero fuera compite con el espacio 3D sin aportar una acción inmediata. Esta capa
## conserva el mismo HUDLayer para interacción, diálogo y modales y solo retira el
## estado permanente en trayecto, casa y sueño.
extends "res://guion/dia_clima_app.gd"


func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	_sincronizar_estado_hud(fase)


func _sincronizar_estado_hud(fase: String) -> void:
	if _hud_prioridades == null:
		return
	if fase == "archivo":
		_hud_prioridades.activar(HUDLayer.ESTADO)
	else:
		_hud_prioridades.desactivar(HUDLayer.ESTADO)
