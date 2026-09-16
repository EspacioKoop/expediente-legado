extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_comprobar(TelefonoFijo.catalogo().size() >= 5, "catálogo con cinco llamadas")
	_comprobar(TelefonoFijo.contactos().size() >= 3, "tres números salientes")
	for llamada in TelefonoFijo.catalogo():
		_comprobar(not String(llamada.get("hora", "")).is_empty(), "hora narrativa")
		_comprobar(not String(llamada.get("texto", "")).is_empty(), "transcript")
		_comprobar(not String(llamada.get("mensaje", "")).is_empty(), "mensaje de cinta")

	var dia_uno := _jornada(1)
	var primera := TelefonoFijo.preparar_casa(dia_uno)
	_comprobar(String(primera.get("id", "")) == "companero_fin_jornada", "llamada día uno")
	_comprobar(not TelefonoFijo.llamada_activa(dia_uno).is_empty(), "llamada activa")
	var atendida := TelefonoFijo.descolgar(dia_uno)
	_comprobar(bool(atendida.get("ok", false)), "descolgar")
	_comprobar(String(atendida.get("tipo", "")) == "entrante", "atender entrante")
	_comprobar(TelefonoFijo.llamada_activa(dia_uno).is_empty(), "consume llamada")
	var telefono_uno := TelefonoFijo.estado(dia_uno)
	_comprobar(bool(telefono_uno.get("descolgado", false)), "auricular descolgado")
	_comprobar(bool(TelefonoFijo.colgar(dia_uno).get("ok", false)), "colgar")
	_comprobar(not bool(telefono_uno.get("descolgado", true)), "auricular colgado")

	var dia_dos := _jornada(2)
	var equivocada := TelefonoFijo.preparar_casa(dia_dos)
	_comprobar(String(equivocada.get("id", "")) == "numero_equivocado", "número equivocado")
	var grabada := TelefonoFijo.pasar_a_contestador(dia_dos)
	_comprobar(bool(grabada.get("ok", false)), "grabar en contestador")
	_comprobar(TelefonoFijo.mensajes_nuevos(dia_dos) == 1, "mensaje nuevo")
	var escuchado := TelefonoFijo.escuchar_siguiente(dia_dos)
	_comprobar(bool(escuchado.get("ok", false)), "escuchar mensaje")
	_comprobar(TelefonoFijo.mensajes_nuevos(dia_dos) == 0, "mensaje escuchado")
	var mensajes_dos: Array = TelefonoFijo.estado(dia_dos)["mensajes"]
	_comprobar(mensajes_dos.size() == 1, "mensaje persistente")

	var dia_tres := _jornada(3)
	var comercial := TelefonoFijo.preparar_casa(dia_tres)
	_comprobar(String(comercial.get("id", "")) == "comercial_enciclopedia", "comercial")

	var dia_cuatro := _jornada(4)
	var sin_cierre := TelefonoFijo.preparar_casa(dia_cuatro)
	_comprobar(sin_cierre.is_empty(), "cierre filtra llamada")
	var dia_cuatro_con_cierre := _jornada(4)
	dia_cuatro_con_cierre["cerrados_hoy"] = 1
	var companera := TelefonoFijo.preparar_casa(dia_cuatro_con_cierre)
	_comprobar(String(companera.get("id", "")) == "companera_cierre", "llamada por cierre")

	var dia_nueve := _jornada(9)
	var alquiler := TelefonoFijo.preparar_casa(dia_nueve)
	_comprobar(String(alquiler.get("id", "")) == "administracion_alquiler", "aviso alquiler")
	var dia_nueve_resuelto := _jornada(9)
	dia_nueve_resuelto["alquiler"]["ultimo_resuelto"] = 10
	var sin_aviso := TelefonoFijo.preparar_casa(dia_nueve_resuelto)
	_comprobar(sin_aviso.is_empty(), "sin aviso con alquiler resuelto")

	var dia_once := _jornada(11)
	dia_once["cerrados_hoy"] = 2
	var centralita := TelefonoFijo.preparar_casa(dia_once)
	_comprobar(String(centralita.get("id", "")) == "centralita_interna", "centralita")

	var ignorada := _jornada(1)
	TelefonoFijo.preparar_casa(ignorada)
	var perdida := TelefonoFijo.perder_activa(ignorada)
	_comprobar(bool(perdida.get("ok", false)), "ignorada va a cinta")
	_comprobar(TelefonoFijo.mensajes_nuevos(ignorada) == 1, "ignorada conserva contenido")
	_comprobar(TelefonoFijo.preparar_casa(ignorada).is_empty(), "sin duplicado diario")

	var saliente := _jornada(6)
	var colgado := TelefonoFijo.llamar(saliente, "centralita_siga")
	_comprobar(not bool(colgado.get("ok", false)), "no llama colgado")
	TelefonoFijo.descolgar(saliente)
	var llamada_saliente := TelefonoFijo.llamar(saliente, "centralita_siga")
	_comprobar(bool(llamada_saliente.get("ok", false)), "llamada saliente declarada")
	var inventada := TelefonoFijo.llamar(saliente, "numero_inventado")
	_comprobar(not bool(inventada.get("ok", false)), "rechaza número no declarado")
	var historial: Array = TelefonoFijo.estado(saliente)["historial"]
	_comprobar(historial.size() >= 1, "historial guardable")

	var archivo := _jornada(1)
	archivo["fase"] = "archivo"
	_comprobar(TelefonoFijo.preparar_casa(archivo).is_empty(), "sin llamadas fuera de casa")
	var fuera := TelefonoFijo.descolgar(archivo)
	_comprobar(not bool(fuera.get("ok", false)), "no descuelga fuera de casa")

	var aparato := TelefonoFijoInteractivo3D.new()
	root.add_child(aparato)
	aparato.configurar(dia_dos)
	_comprobar(aparato.get_node_or_null("Auricular") != null, "auricular físico")
	_comprobar(aparato.get_node_or_null("Teclado") != null, "teclado físico")
	_comprobar(aparato.get_node_or_null("PilotoMensajes") != null, "piloto visual")
	_comprobar(aparato.get_node_or_null("VolumenInteraccion") != null, "interacción 3D")
	aparato.queue_free()

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _jornada(dia: int) -> Dictionary:
	var jornada := Jornada.nueva(671, 1)
	jornada["dia"] = dia
	jornada["fase"] = "casa"
	return jornada


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
