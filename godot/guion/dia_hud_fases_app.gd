## Ajuste de composición del HUD por fase (#397).
##
## Controller hijo: conserva `dia_clima_app.gd` como raíz histórica y observa la
## fase efectiva de Jornada. Solo gobierna el slot ESTADO del HUD común; prompts,
## diálogo y modales siguen siendo responsabilidad de HUDLayer y del día.
extends Node

var _fase_anterior := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var jornada = dia.get("jornada")
	if not jornada is Dictionary:
		return
	var fase := String(jornada.get("fase", ""))
	if fase == _fase_anterior:
		return
	var hud = dia.get("_hud_prioridades")
	if not hud is HUDLayer:
		return
	_fase_anterior = fase
	_sincronizar_estado_hud(hud, fase)


func _sincronizar_estado_hud(hud: HUDLayer, fase: String) -> void:
	if fase == "archivo":
		hud.activar(HUDLayer.ESTADO)
	else:
		hud.desactivar(HUDLayer.ESTADO)
