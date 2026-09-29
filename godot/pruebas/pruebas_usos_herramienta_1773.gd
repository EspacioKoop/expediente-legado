extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_usos_y_alias()
	_probar_solo_carried()
	_probar_ids_intercambiables()
	_probar_sin_mutacion()
	_probar_consumo_explicito()
	_probar_datos_invalidos()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _inventario() -> Dictionary:
	return {
		Inventario.CARRIED:
		[
			{"id": "barra_sin_marca", "usos": ["forzar"], "origen": "calle"},
			{"id": "luz_auxiliar", "usos": ["iluminar"], "origen": "casa"},
			{"id": "cuña_madera", "usos": ["estabilizar"], "origen": "archivo"},
		],
		Inventario.HOME_STORAGE:
		[
			{"id": "lampara_guardada", "usos": ["iluminar"], "origen": "casa"},
		],
	}


func _probar_usos_y_alias() -> void:
	var inventario := _inventario()
	for uso in [
		UsosHerramienta.FORZAR,
		UsosHerramienta.ILUMINAR,
		UsosHerramienta.ESTABILIZAR,
	]:
		_comprobar(UsosHerramienta.puede(inventario, uso), "resuelve %s" % uso)
		var resultado := UsosHerramienta.resolver(inventario, uso)
		_comprobar(bool(resultado["ok"]), "%s devuelve exito" % uso)
		_comprobar(String(resultado["uso"]) == uso, "%s conserva uso canonico" % uso)
	_comprobar(
		UsosHerramienta.uso_canonico("calzar") == UsosHerramienta.ESTABILIZAR,
		"calzar comparte contrato con estabilizar",
	)
	_comprobar(UsosHerramienta.puede(inventario, "calzar"), "el alias encuentra una cuña")
	_comprobar(not UsosHerramienta.puede(inventario, "teletransportar"), "uso ajeno se rechaza")


func _probar_solo_carried() -> void:
	var inventario := {
		Inventario.CARRIED: [],
		Inventario.HOME_STORAGE: [{"id": "guardada", "usos": ["iluminar"]}],
	}
	var resultado := UsosHerramienta.resolver(inventario, "iluminar")
	_comprobar(
		not bool(resultado["ok"]), "almacenamiento de casa no cuenta como herramienta llevada"
	)
	_comprobar(String(resultado["motivo"]) == "sin_herramienta", "explica ausencia compatible")


func _probar_ids_intercambiables() -> void:
	var uno := {
		Inventario.CARRIED: [{"id": "herramienta_a", "usos": ["forzar"]}],
	}
	var otro := {
		Inventario.CARRIED: [{"id": "objeto_totalmente_distinto", "usos": ["forzar"]}],
	}
	var res_a := UsosHerramienta.resolver(uno, "forzar")
	var res_b := UsosHerramienta.resolver(otro, "forzar")
	_comprobar(bool(res_a["ok"]) and bool(res_b["ok"]), "dos IDs con mismo uso sirven")
	_comprobar(
		String(res_a["herramienta"]["id"]) != String(res_b["herramienta"]["id"]),
		"la compatibilidad no depende del ID",
	)
	_comprobar(String(res_b["uso"]) == "forzar", "el segundo objeto conserva semantica")


func _probar_sin_mutacion() -> void:
	var inventario := _inventario()
	var antes := JSON.stringify(inventario)
	var compatibles := UsosHerramienta.compatibles(inventario, "iluminar")
	_comprobar(compatibles.size() == 1, "devuelve solo llevados compatibles")
	compatibles[0]["id"] = "mutado_fuera"
	_comprobar(JSON.stringify(inventario) == antes, "las opciones son copias profundas")
	UsosHerramienta.resolver(inventario, "forzar")
	_comprobar(JSON.stringify(inventario) == antes, "resolver no mueve ni consume inventario")


func _probar_consumo_explicito() -> void:
	var normal := {"id": "reutilizable", "usos": ["forzar"]}
	var consumible := {
		"id": "pieza_fungible",
		"usos": ["forzar", "estabilizar"],
		"consumir_usos": ["forzar"],
	}
	_comprobar(not UsosHerramienta.consumo_declarado(normal, "forzar"), "por defecto reutilizable")
	_comprobar(
		UsosHerramienta.consumo_declarado(consumible, "forzar"),
		"consumo exige declaracion por uso",
	)
	_comprobar(
		not UsosHerramienta.consumo_declarado(consumible, "estabilizar"),
		"declarar consumo de un uso no consume los demas",
	)
	var inventario := {Inventario.CARRIED: [consumible]}
	var resultado := UsosHerramienta.resolver(inventario, "forzar")
	_comprobar(bool(resultado["consumir"]), "resolver expone consumo explicito")
	_comprobar(inventario[Inventario.CARRIED].size() == 1, "resolver nunca retira el consumible")


func _probar_datos_invalidos() -> void:
	var inventario := {
		Inventario.CARRIED:
		[
			"ruido",
			{"id": "sin_usos"},
			{"id": "usos_rotos", "usos": "forzar"},
			{"id": "valida", "usos": ["iluminar"]},
		],
	}
	var resultado := UsosHerramienta.resolver(inventario, "iluminar")
	_comprobar(bool(resultado["ok"]), "ignora entradas corruptas y encuentra la valida")
	_comprobar(String(resultado["herramienta"]["id"]) == "valida", "devuelve la herramienta valida")
	var roto := {Inventario.CARRIED: "no-array"}
	_comprobar(
		UsosHerramienta.compatibles(roto, "forzar").is_empty(), "carried corrupto falla cerrado"
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
