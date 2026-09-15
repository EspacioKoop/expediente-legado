## Segundo corte de escenografía reactiva de #400, limitado al archivo.
##
## Igual que los demás controllers hijos de `dia.tscn`, observa cuándo cambia el
## mundo montado por el día. No altera jornada ni transiciones: añade utilería
## únicamente al mundo de la fase `archivo` y una sola vez por instancia.
extends Node

var _mundo_vestido_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_vestido_id:
		return

	_mundo_vestido_id = mundo_id
	if String(dia.jornada.get("fase", "")) == "archivo":
		OficinaUtileria.montar(mundo)
		OficinaAssetsCc0.montar(mundo)
		PostersOficina.montar(mundo)
		CuadrosOficina.montar(mundo)
