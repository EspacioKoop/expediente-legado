## Escenografía reactiva de oficina y dueño jugable del café (#400/#93).
##
## OficinaUtileria sigue siendo presentación pura. Esta capa conecta la máquina
## física con Jornada: un café útil por día, cobro único y guardado inmediato.
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
		OficinaUtileria.montar(mundo, Jornada.PRECIO_CAFE)
		OficinaAssetsCc0.montar(mundo)
		OficinaFotorealista98.montar(mundo)
		PostersOficina.montar(mundo)
		CuadrosOficina.montar(mundo)
		_conectar_cafe(dia, mundo)


func _conectar_cafe(dia, mundo: Node3D) -> void:
	var maquina := mundo.get_node_or_null("MaquinaCafeInteractuable") as MaquinaCafeInteractiva3D
	if maquina == null:
		return
	if int(dia.jornada.get("acciones_bonus_hoy", 0)) >= Jornada.BONUS_ACCIONES_MAX_POR_DIA:
		maquina.marcar_agotado()
	var callback := _al_usar_cafe.bind(dia, maquina)
	if not maquina.activado.is_connected(callback):
		maquina.activado.connect(callback)


func _al_usar_cafe(_actor: Node, dia, maquina: MaquinaCafeInteractiva3D) -> void:
	if String(dia.jornada.get("fase", "")) != "archivo":
		return
	if maquina.taza_visible():
		maquina.retirar_taza()
		if int(dia.jornada.get("acciones_bonus_hoy", 0)) >= Jornada.BONUS_ACCIONES_MAX_POR_DIA:
			maquina.marcar_agotado()
		return
	if int(dia.jornada.get("acciones_bonus_hoy", 0)) >= Jornada.BONUS_ACCIONES_MAX_POR_DIA:
		maquina.marcar_agotado()
		return
	if not Jornada.tomar_cafe(dia.jornada, Jornada.PRECIO_CAFE):
		if int(dia.jornada.get("dinero", 0)) < Jornada.PRECIO_CAFE:
			maquina.marcar_sin_dinero()
		else:
			maquina.marcar_agotado()
		return
	maquina.servir()
	if dia.has_method("_guardar_o_avisar"):
		dia._guardar_o_avisar("")
