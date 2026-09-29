extends SceneTree

const Ambiental := preload("res://guion/interaccion_combate_ambiental.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_opt_in()
	_probar_empujar()
	_probar_volcar()
	_probar_activar()
	_probar_invalidos_no_mutan()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_opt_in() -> void:
	var silla := (
		Ambiental
		. declaracion(
			"silla-ligera",
			[Ambiental.EMPUJAR],
		)
	)
	_comprobar(
		(
			Ambiental
			. disponible(
				silla,
				Ambiental.EMPUJAR,
				true,
			)
		),
		"verbo declarado disponible en combate",
	)
	_comprobar(
		not (
			Ambiental
			. disponible(
				silla,
				Ambiental.VOLCAR,
				true,
			)
		),
		"verbo no declarado no aparece",
	)
	_comprobar(
		not (
			Ambiental
			. disponible(
				silla,
				Ambiental.EMPUJAR,
				false,
			)
		),
		"fuera de combate no se habilita",
	)
	var vacia := Ambiental.declaracion("", [Ambiental.EMPUJAR])
	_comprobar(
		not (
			Ambiental
			. disponible(
				vacia,
				Ambiental.EMPUJAR,
				true,
			)
		),
		"declaración sin id no habilita nada",
	)


func _probar_empujar() -> void:
	var silla := (
		Ambiental
		. declaracion(
			"silla-ligera",
			[Ambiental.EMPUJAR],
			"",
			1.25,
		)
	)
	var estado := Ambiental.estado_inicial()
	var antes := JSON.stringify(estado)
	var resultado := (
		Ambiental
		. aplicar(
			silla,
			estado,
			Ambiental.EMPUJAR,
			true,
		)
	)
	_comprobar(bool(resultado["ok"]), "empujar se resuelve")
	_comprobar(String(resultado["intencion"]["tipo"]) == "desplazar", "empujar desplaza")
	_comprobar(is_equal_approx(float(resultado["intencion"]["metros"]), 1.25), "respeta distancia")
	_comprobar(bool(resultado["intencion"]["interrumpe"]), "empujar puede interrumpir")
	_comprobar(JSON.stringify(estado) == antes, "empujar no muta el estado recibido")


func _probar_volcar() -> void:
	var caja := (
		Ambiental
		. declaracion(
			"caja-preparada",
			[Ambiental.VOLCAR],
			"",
			0.85,
			2.5,
		)
	)
	var estado := Ambiental.estado_inicial()
	var resultado := (
		Ambiental
		. aplicar(
			caja,
			estado,
			Ambiental.VOLCAR,
			true,
		)
	)
	_comprobar(bool(resultado["ok"]), "volcar funciona una vez")
	_comprobar(bool(resultado["estado"]["volcado"]), "volcar queda reflejado en estado local")
	_comprobar(
		String(resultado["intencion"]["tipo"]) == "obstaculo_temporal",
		"volcar crea intención de obstáculo",
	)
	_comprobar(
		is_equal_approx(float(resultado["intencion"]["segundos"]), 2.5),
		"obstáculo tiene duración declarada",
	)
	var repetido := (
		Ambiental
		. aplicar(
			caja,
			resultado["estado"],
			Ambiental.VOLCAR,
			true,
		)
	)
	_comprobar(not bool(repetido["ok"]), "volcar no se duplica")
	_comprobar(String(repetido["motivo"]) == "ya_volcado", "repetición explica idempotencia")


func _probar_activar() -> void:
	var interruptor := (
		Ambiental
		. declaracion(
			"interruptor-preparado",
			[Ambiental.ACTIVAR],
			"luz_pasillo_izquierda",
		)
	)
	var resultado := (
		Ambiental
		. aplicar(
			interruptor,
			Ambiental.estado_inicial(),
			Ambiental.ACTIVAR,
			true,
		)
	)
	_comprobar(bool(resultado["ok"]), "activar funciona con efecto declarado")
	_comprobar(bool(resultado["estado"]["activado"]), "activar queda consumido localmente")
	_comprobar(
		String(resultado["intencion"]["tipo"]) == "activar_efecto",
		"activar devuelve intención genérica",
	)
	_comprobar(
		String(resultado["intencion"]["efecto_id"]) == "luz_pasillo_izquierda",
		"solo devuelve el efecto authored",
	)
	var sin_efecto := (
		Ambiental
		. declaracion(
			"interruptor-incompleto",
			[Ambiental.ACTIVAR],
		)
	)
	var fallo := (
		Ambiental
		. aplicar(
			sin_efecto,
			Ambiental.estado_inicial(),
			Ambiental.ACTIVAR,
			true,
		)
	)
	_comprobar(not bool(fallo["ok"]), "activar exige efecto explícito")
	_comprobar(String(fallo["motivo"]) == "sin_efecto_declarado", "explica efecto ausente")


func _probar_invalidos_no_mutan() -> void:
	var prop := (
		Ambiental
		. declaracion(
			"prop-mixto",
			[
				Ambiental.EMPUJAR,
				Ambiental.VOLCAR,
				Ambiental.ACTIVAR,
				"desconocido",
			],
			"luz_local",
		)
	)
	_comprobar((prop["verbos_combate"] as Array).size() == 3, "filtra verbos desconocidos")
	var estado := Ambiental.estado_inicial()
	var antes := JSON.stringify(estado)
	var fuera := (
		Ambiental
		. aplicar(
			prop,
			estado,
			Ambiental.EMPUJAR,
			false,
		)
	)
	_comprobar(not bool(fuera["ok"]), "combate no autorizado falla cerrado")
	_comprobar(JSON.stringify(fuera["estado"]) == antes, "rechazo conserva estado")
	_comprobar(JSON.stringify(estado) == antes, "rechazo no muta el original")
	var desconocido := Ambiental.aplicar(prop, estado, "romper", true)
	_comprobar(not bool(desconocido["ok"]), "verbo desconocido se rechaza")
	_comprobar(JSON.stringify(desconocido["estado"]) == antes, "verbo inválido conserva estado")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
