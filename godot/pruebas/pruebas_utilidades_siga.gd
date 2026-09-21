extends SceneTree

const Bloc := preload("res://guion/bloc_notas_siga.gd")
const Calculadora := preload("res://guion/calculadora_siga.gd")

var _fallos := 0
var _pasadas := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var bloc := Bloc.new()
	bloc.configurar_texto("Revisar expediente 14-B")
	get_root().add_child(bloc)
	await process_frame
	_comprobar(bloc.exportar_texto() == "Revisar expediente 14-B", "el bloc restaura su texto")
	_comprobar(bloc.get_node_or_null("Editor") is TextEdit, "el bloc expone un editor de teclado")
	bloc.configurar_texto("Llamar a archivo antes de las 12")
	_comprobar(
		bloc.exportar_texto() == "Llamar a archivo antes de las 12",
		"el bloc actualiza el contenido sin tocar ficheros del host"
	)
	bloc.queue_free()

	var calculadora := Calculadora.new()
	get_root().add_child(calculadora)
	await process_frame
	_comprobar(calculadora.resolver("2 + 3 * 4") == "14", "respeta precedencia aritmética")
	_comprobar(calculadora.resolver("(10 + 2) / 3") == "4", "acepta paréntesis y división")
	_comprobar(calculadora.resolver("1,5 + 2,5") == "4.0", "acepta coma decimal")
	_comprobar(
		calculadora.resolver("OS.execute()") == calculadora.tr("CALCULADORA_ENTRADA_NO_VALIDA"),
		"rechaza APIs del host"
	)
	_comprobar(
		calculadora.resolver("sqrt(9)") == calculadora.tr("CALCULADORA_ENTRADA_NO_VALIDA"),
		"rechaza llamadas a funciones"
	)
	_comprobar(
		calculadora.find_child("Entrada", true, false) is LineEdit,
		"la entrada es accesible por teclado"
	)
	_comprobar(
		calculadora.get_node_or_null("Pantalla") is PanelContainer,
		"la calculadora usa un display visual propio"
	)
	var teclado := calculadora.get_node_or_null("Teclado") as GridContainer
	_comprobar(teclado != null, "la calculadora expone un teclado propio")
	_comprobar(
		teclado != null and teclado.get_child_count() == 20, "el teclado ofrece veinte teclas"
	)
	calculadora.queue_free()

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
