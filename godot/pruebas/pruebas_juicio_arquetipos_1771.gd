extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_determinismo()
	_probar_hostigador()
	_probar_bloqueador()
	_probar_enjambre()
	_probar_mezcla_y_reduccion_movimiento()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_determinismo() -> void:
	var a := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.HOSTIGADOR, 1771, 3)
	var b := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.HOSTIGADOR, 1771, 3)
	_comprobar(a == b, "misma raíz e índice producen el mismo estado")
	var enjambre := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.ENJAMBRE, 1771, 4)
	_comprobar(int(enjambre["determinacion"]) == 1, "enjambre usa unidades débiles")
	_comprobar(float(enjambre["cooldown"]) >= 0.10, "enjambre deriva fase inicial reproducible")


func _probar_hostigador() -> void:
	var unidad := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.HOSTIGADOR, 1771)
	var paso := JuicioCombateArquetipos.avanzar(
		unidad, 0.01, {"distancia": 6.0, "rumbo_objetivo": 1.25}
	)
	unidad = paso["unidad"]
	_comprobar(String(unidad["estado"]) == JuicioCombateArquetipos.TELEGRAFIAR, "hostigador telegrafía")
	var rumbo := float(unidad["rumbo_bloqueado"])
	paso = JuicioCombateArquetipos.avanzar(
		unidad, 0.30, {"distancia": 6.0, "rumbo_objetivo": 2.75}
	)
	unidad = paso["unidad"]
	_comprobar(float(unidad["rumbo_bloqueado"]) == rumbo, "telegraph congela el rumbo")
	_comprobar(not bool(paso["ventana_respuesta"]), "telegraph aún no es ventana")
	paso = JuicioCombateArquetipos.avanzar(unidad, 0.40, {"distancia": 6.0})
	unidad = paso["unidad"]
	_comprobar(String(unidad["estado"]) == JuicioCombateArquetipos.DISPARAR_LINEA, "dispara tras aviso")
	paso = JuicioCombateArquetipos.avanzar(unidad, 0.10, {"distancia": 6.0})
	unidad = paso["unidad"]
	_comprobar(String(unidad["estado"]) == JuicioCombateArquetipos.VULNERABLE, "disparo siempre abre ventana")
	_comprobar(bool(paso["ventana_respuesta"]), "ventana del hostigador es explícita")


func _probar_bloqueador() -> void:
	var unidad := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.BLOQUEADOR, 1771)
	var paso := JuicioCombateArquetipos.avanzar(unidad, 1.25)
	unidad = paso["unidad"]
	_comprobar(String(unidad["estado"]) == JuicioCombateArquetipos.APERTURA, "guardia expira sola")
	_comprobar(bool(paso["ventana_respuesta"]), "la apertura permite respuesta")
	var flanco := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.BLOQUEADOR, 1771, 2)
	paso = JuicioCombateArquetipos.avanzar(flanco, 0.01, {"flanqueado": true})
	_comprobar(String(paso["unidad"]["estado"]) == JuicioCombateArquetipos.APERTURA, "flanquear fuerza apertura")
	var rota := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.BLOQUEADOR, 1771, 3)
	paso = JuicioCombateArquetipos.avanzar(rota, 0.01, {"guardia_rota": true})
	_comprobar(String(paso["unidad"]["estado"]) == JuicioCombateArquetipos.APERTURA, "romper guardia fuerza apertura")


func _probar_enjambre() -> void:
	var a := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.ENJAMBRE, 1771, 0)
	var b := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.ENJAMBRE, 1771, 1)
	var c := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.ENJAMBRE, 1771, 2)
	a["cooldown"] = 0.0
	b["cooldown"] = 0.0
	c["cooldown"] = 0.0
	var paso_a := JuicioCombateArquetipos.avanzar(a, 0.01, {"atacantes_activos": 0})
	a = paso_a["unidad"]
	var paso_b := JuicioCombateArquetipos.avanzar(b, 0.01, {"atacantes_activos": 1})
	b = paso_b["unidad"]
	var activos := JuicioCombateArquetipos.cuenta_presupuesto([a, b, c])
	_comprobar(activos == 2, "dos unidades reservan el presupuesto común")
	var paso_c := JuicioCombateArquetipos.avanzar(c, 0.01, {"atacantes_activos": activos})
	c = paso_c["unidad"]
	_comprobar(String(c["estado"]) == JuicioCombateArquetipos.ESPERA, "tercera unidad espera presupuesto")
	_comprobar(String(paso_c["intencion"]) == "rodear", "esperar no congela el movimiento")


func _probar_mezcla_y_reduccion_movimiento() -> void:
	var hostigador := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.HOSTIGADOR, 1771)
	hostigador["estado"] = JuicioCombateArquetipos.VULNERABLE
	hostigador["temporizador"] = 0.5
	var bloqueador := JuicioCombateArquetipos.nuevo(JuicioCombateArquetipos.BLOQUEADOR, 1771)
	_comprobar(
		JuicioCombateArquetipos.arena_tiene_ventana([hostigador, bloqueador]),
		"mezcla puede conservar una ventana resoluble",
	)
	var resultado := JuicioCombateArquetipos.avanzar(hostigador, 0.1)
	var normal := JuicioCombateArquetipos.presentacion(resultado, false)
	var reducida := JuicioCombateArquetipos.presentacion(resultado, true)
	_comprobar(normal["estado"] == reducida["estado"], "reducción no cambia estado lógico")
	_comprobar(normal["temporizador"] == reducida["temporizador"], "reducción no cambia timing")
	_comprobar(
		normal["ventana_respuesta"] == reducida["ventana_respuesta"],
		"reducción no cambia ventana de respuesta",
	)
	_comprobar(normal["estilo"] != reducida["estilo"], "reducción solo cambia presentación")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
