extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_comprobar(TelefonoFijo.catalogo().size() >= 5, "hay al menos cinco llamadas declarativas")
	_comprobar(TelefonoFijo.contactos().size() >= 3, "hay numeros salientes declarados")
	for llamada in TelefonoFijo.catalogo():
		_comprobar(not String(llamada.get("hora", "")).is_empty(), "cada llamada tiene hora narrativa")
		_comprobar(not String(llamada.get("texto", "")).is_empty(), "cada llamada tiene transcript")
		_comprobar(not String(llamada.get("mensaje", "")).is_empty(), "cada llamada puede dejar mensaje")

	var dia_uno := _jornada(1)
	var primera := TelefonoFijo.preparar_casa(dia_uno)
	_comprobar(String(primera.get("id", "")) == "companero_fin_jornada", "el primer dia llama un companero")
	_comprobar(not TelefonoFijo.llamada_activa(dia_uno).is_empty(), "la llamada queda activa hasta decidir")
	var atendida := TelefonoFijo.descolgar(dia_uno)
	_comprobar(bool(atendida.get("ok", false)), "se puede descolgar")
	_comprobar(String(atendida.get("tipo", "")) == "entrante", "descolgar atiende la llamada activa")
	_comprobar(TelefonoFijo.llamada_activa(dia_uno).is_empty(), "atender consume la llamada")
	_comprobar(bool(TelefonoFijo.estado(dia_uno).get("descolgado", false)), "el auricular queda descolgado")
	_comprobar(bool(TelefonoFijo.colgar(dia_uno).get("ok", false)), "se puede colgar")
	_comprobar(not bool(TelefonoFijo.estado(dia_uno).get("descolgado", true)), "colgar restaura el auricular")

	var dia_dos := _jornada(2)
	var equivocada := TelefonoFijo.preparar_casa(dia_dos)
	_comprobar(String(equivocada.get("id", "")) == "numero_equivocado", "el numero equivocado usa otra condicion")
	var grabada := TelefonoFijo.pasar_a_contestador(dia_dos)
	_comprobar(bool(grabada.get("ok", false)), "una llamada puede pasar al contestador")
	_comprobar(TelefonoFijo.mensajes_nuevos(dia_dos) == 1, "el piloto puede derivar un mensaje nuevo")
	var escuchado := TelefonoFijo.escuchar_siguiente(dia_dos)
	_comprobar(bool(escuchado.get("ok", false)), "se puede escuchar el siguiente mensaje")
	_comprobar(TelefonoFijo.mensajes_nuevos(dia_dos) == 0, "escuchar apaga el estado de nuevo")
	_comprobar(TelefonoFijo.estado(dia_dos)["mensajes"].size() == 1, "el mensaje permanece guardado")

	var dia_tres := _jornada(3)
	_comprobar(
		String(TelefonoFijo.preparar_casa(dia_tres).get("id", "")) == "comercial_enciclopedia",
		"la llamada comercial entra por calendario declarativo",
	)

	var dia_cuatro := _jornada(4)
	_comprobar(TelefonoFijo.preparar_casa(dia_cuatro).is_empty(), "el cierre laboral filtra la llamada sin expedientes")
	var dia_cuatro_con_cierre := _jornada(4)
	dia_cuatro_con_cierre["cerrados_hoy"] = 1
	_comprobar(
		String(TelefonoFijo.preparar_casa(dia_cuatro_con_cierre).get("id", "")) == "companera_cierre",
		"el estado del trabajo habilita una llamada distinta",
	)

	var dia_nueve := _jornada(9)
	_comprobar(
		String(TelefonoFijo.preparar_casa(dia_nueve).get("id", "")) == "administracion_alquiler",
		"el alquiler pendiente habilita el recordatorio administrativo",
	)
	var dia_nueve_resuelto := _jornada(9)
	dia_nueve_resuelto["alquiler"]["ultimo_resuelto"] = 10
	_comprobar(
		TelefonoFijo.preparar_casa(dia_nueve_resuelto).is_empty(),
		"el recordatorio desaparece si el vencimiento ya esta resuelto",
	)

	var dia_once := _jornada(11)
	dia_once["cerrados_hoy"] = 2
	_comprobar(
		String(TelefonoFijo.preparar_casa(dia_once).get("id", "")) == "centralita_interna",
		"la centralita tiene condicion propia de cierres y calendario",
	)

	var ignorada := _jornada(1)
	TelefonoFijo.preparar_casa(ignorada)
	var perdida := TelefonoFijo.perder_activa(ignorada)
	_comprobar(bool(perdida.get("ok", false)), "abandonar casa deriva la llamada al contestador")
	_comprobar(TelefonoFijo.mensajes_nuevos(ignorada) == 1, "ignorar no pierde el contenido")
	_comprobar(TelefonoFijo.preparar_casa(ignorada).is_empty(), "recargar el mismo dia no duplica la llamada")

	var saliente := _jornada(6)
	_comprobar(
		not bool(TelefonoFijo.llamar(saliente, "centralita_siga").get("ok", false)),
		"no se llama con el auricular colgado",
	)
	TelefonoFijo.descolgar(saliente)
	var llamada_saliente := TelefonoFijo.llamar(saliente, "centralita_siga")
	_comprobar(bool(llamada_saliente.get("ok", false)), "un numero declarado admite llamada saliente")
	_comprobar(
		not bool(TelefonoFijo.llamar(saliente, "numero_inventado").get("ok", false)),
		"un numero no declarado se rechaza",
	)
	_comprobar(
		TelefonoFijo.estado(saliente)["historial"].size() >= 1,
		"las comunicaciones dejan historial guardable",
	)

	var archivo := _jornada(1)
	archivo["fase"] = "archivo"
	_comprobar(TelefonoFijo.preparar_casa(archivo).is_empty(), "el telefono no prepara llamadas fuera de casa")
	_comprobar(not bool(TelefonoFijo.descolgar(archivo).get("ok", false)), "no se descuelga fuera de casa")

	var aparato := TelefonoFijoInteractivo3D.new()
	root.add_child(aparato)
	aparato.configurar(dia_dos)
	_comprobar(aparato.get_node_or_null("Auricular") != null, "el aparato tiene auricular fisico")
	_comprobar(aparato.get_node_or_null("Teclado") != null, "el aparato tiene teclado fisico")
	_comprobar(aparato.get_node_or_null("PilotoMensajes") != null, "el contestador tiene piloto visual")
	_comprobar(aparato.get_node_or_null("VolumenInteraccion") != null, "el telefono usa interaccion 3D")
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
