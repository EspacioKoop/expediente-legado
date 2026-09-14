extends SceneTree

const VisorCombinaciones := preload("res://guion/visor_combinaciones_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var ficha := {
		"pistas":
		[
			{"id": "simple", "registroOrigen": "A", "fraseGatillo": "x"},
			{
				"id": "conclusion",
				"registroOrigen": "A",
				"registroOrigen2": "B",
				"descripcion": "A y B encajan",
			},
		]
	}
	_comprobar(
		VisorCombinaciones._buscar_relacion(ficha, "A", "B").get("id") == "conclusion",
		"A+B encuentra conclusión"
	)
	_comprobar(
		VisorCombinaciones._buscar_relacion(ficha, "B", "A").get("id") == "conclusion",
		"B+A es equivalente"
	)
	_comprobar(
		VisorCombinaciones._buscar_relacion(ficha, "A", "A").is_empty(), "rechaza mismo documento"
	)
	_comprobar(
		VisorCombinaciones._buscar_relacion(ficha, "A", "C").is_empty(),
		"pareja sin evidencia no inventa conclusión"
	)
	_comprobar(
		VisorCombinaciones._buscar_relacion(ficha, "", "B").is_empty(), "rechaza origen vacío"
	)

	var ruta := "user://prueba-combinaciones-%d.json" % Time.get_ticks_usec()
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	partida.estado["jornada"]["leidos_total"] = ["A", "B"]
	partida.estado["pistas_descubiertas"].append("conclusion")
	_comprobar(partida.guardar(ruta), "guarda lectura y conclusión")

	var recargada := Partida.new()
	var carga := recargada.cargar(ruta)
	_comprobar(carga.get("resultado") == "cargada", "recarga partida")
	_comprobar(
		recargada.estado["jornada"].get("leidos_total", []) == ["A", "B"],
		"lecturas sobreviven cambio de sesión"
	)
	_comprobar(
		recargada.estado["pistas_descubiertas"].count("conclusion") == 1,
		"conclusión persiste sin duplicado"
	)

	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
