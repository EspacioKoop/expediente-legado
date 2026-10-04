## Regresión del Constructor demiúrgico sobre CONSTRUCTOR (#2089/#2352).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_ciclo_con_cupo()
	_probar_revalidacion_de_cupo()
	_probar_limite_duro()
	_probar_reduccion_movimiento()
	_probar_no_mutacion()
	print("constructor_demiurgico_2089: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_ciclo_con_cupo() -> void:
	var inicial := JuicioCombateConstructorDemiurgicoRuntime2089.nuevo(2089, 3)
	_comprobar(
		String(inicial.get("estado", "")) == JuicioCombateArquetipos.REPOSICIONAR,
		"nace en reposicionar",
	)

	var construir := (
		JuicioCombateConstructorDemiurgicoRuntime2089
		. avanzar(
			inicial,
			0.0,
			0,
			2,
		)
	)
	_comprobar(
		String(construir["unidad"].get("estado", "")) == JuicioCombateArquetipos.CONSTRUIR,
		"con cupo entra en construir",
	)
	_comprobar(bool(construir["ventana_respuesta"]), "construir abre ventana de respuesta")
	_comprobar(not bool(construir["crear_auxiliar"]), "telegraph no crea auxiliar todavía")

	var creado := (
		JuicioCombateConstructorDemiurgicoRuntime2089
		. avanzar(
			construir["unidad"],
			JuicioCombateArquetipos.CONSTRUCTOR_CONSTRUCCION,
			0,
			2,
		)
	)
	_comprobar(bool(creado["crear_auxiliar"]), "al completar construcción solicita un auxiliar")
	_comprobar(
		String(creado["unidad"].get("estado", "")) == JuicioCombateArquetipos.ACTIVO,
		"tras crear entra en activo",
	)
	_comprobar(float(creado["unidad"].get("cooldown", 0.0)) > 0.0, "crear inicia recarga")

	var sin_duplicar := (
		JuicioCombateConstructorDemiurgicoRuntime2089
		. avanzar(
			creado["unidad"],
			0.0,
			1,
			2,
		)
	)
	_comprobar(not bool(sin_duplicar["crear_auxiliar"]), "activo no repite creación")

	var recuperar := (
		JuicioCombateConstructorDemiurgicoRuntime2089
		. avanzar(
			sin_duplicar["unidad"],
			JuicioCombateArquetipos.CONSTRUCTOR_ACTIVO,
			1,
			2,
		)
	)
	_comprobar(
		String(recuperar["unidad"].get("estado", "")) == JuicioCombateArquetipos.RECUPERAR,
		"activo termina en recuperación",
	)
	_comprobar(bool(recuperar["ventana_respuesta"]), "recuperación sigue vulnerable")


func _probar_revalidacion_de_cupo() -> void:
	var inicial := JuicioCombateConstructorDemiurgicoRuntime2089.nuevo(2089, 5)
	var construir := (
		JuicioCombateConstructorDemiurgicoRuntime2089
		. avanzar(
			inicial,
			0.0,
			1,
			2,
		)
	)
	var bloqueado := (
		JuicioCombateConstructorDemiurgicoRuntime2089
		. avanzar(
			construir["unidad"],
			JuicioCombateArquetipos.CONSTRUCTOR_CONSTRUCCION,
			2,
			2,
		)
	)
	_comprobar(
		String(bloqueado["unidad"].get("estado", "")) == JuicioCombateArquetipos.RECUPERAR,
		"si otro llena el cupo durante el aviso pasa a recuperar",
	)
	_comprobar(not bool(bloqueado["crear_auxiliar"]), "cupo revalidado cancela creación")


func _probar_limite_duro() -> void:
	var inicial := JuicioCombateConstructorDemiurgicoRuntime2089.nuevo(2089, 7)
	var lleno := (
		JuicioCombateConstructorDemiurgicoRuntime2089
		. avanzar(
			inicial,
			0.0,
			JuicioCombateArquetipos.CONSTRUCTOR_LIMITE_AUXILIARES,
			99,
		)
	)
	_comprobar(
		String(lleno["unidad"].get("estado", "")) == JuicioCombateArquetipos.REPOSICIONAR,
		"un límite pedido mayor se recorta al máximo canónico",
	)
	_comprobar(not bool(lleno["crear_auxiliar"]), "límite lleno no crea")

	var desactivado := (
		JuicioCombateConstructorDemiurgicoRuntime2089
		. avanzar(
			inicial,
			0.0,
			0,
			0,
		)
	)
	_comprobar(
		String(desactivado["unidad"].get("estado", "")) == JuicioCombateArquetipos.REPOSICIONAR,
		"límite cero desactiva construcción",
	)


func _probar_reduccion_movimiento() -> void:
	var inicial := JuicioCombateConstructorDemiurgicoRuntime2089.nuevo(2089, 11)
	var normal := (
		JuicioCombateConstructorDemiurgicoRuntime2089
		. avanzar(
			inicial,
			0.0,
			0,
			2,
			false,
		)
	)
	var reducido := (
		JuicioCombateConstructorDemiurgicoRuntime2089
		. avanzar(
			inicial,
			0.0,
			0,
			2,
			true,
		)
	)
	for clave in ["unidad", "intencion", "telegraph", "ventana_respuesta", "crear_auxiliar"]:
		_comprobar(normal[clave] == reducido[clave], "reducción no cambia " + clave)
	_comprobar(
		String(normal["presentacion"].get("estilo", "")) == "animado",
		"presentación normal conserva estilo animado",
	)
	_comprobar(
		String(reducido["presentacion"].get("estilo", "")) == "corte",
		"reducción solo cambia estilo de presentación",
	)


func _probar_no_mutacion() -> void:
	var inicial := JuicioCombateConstructorDemiurgicoRuntime2089.nuevo(2089, 13)
	var antes := inicial.duplicate(true)
	JuicioCombateConstructorDemiurgicoRuntime2089.avanzar(inicial, 0.2, 0, 2)
	_comprobar(inicial == antes, "el adaptador no muta el estado de entrada")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error("FALLO #2352: " + mensaje)
