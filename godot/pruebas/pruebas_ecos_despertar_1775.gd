extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_candidatos()
	_probar_material_desde_noche()
	_probar_captura_runtime()
	_probar_preparacion_runtime()
	_probar_seleccion()
	_probar_persistencia_y_consumo()
	_probar_descarte()
	_probar_reduccion_movimiento()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _material() -> Array:
	return [
		{"tipo": EcosDespertar.HUMEDAD, "origen_id": "noche:hidra"},
		{"tipo": EcosDespertar.CRT, "origen_id": "noche:archivo"},
		{"tipo": EcosDespertar.OBJETO_DESPLAZADO, "origen_id": "noche:casa"},
		{"tipo": EcosDespertar.SONIDO_RESIDUAL, "origen_id": "noche:telefono"},
	]


func _probar_candidatos() -> void:
	var entrada := _material()
	entrada.append({"tipo": EcosDespertar.HUMEDAD, "origen_id": "noche:hidra"})
	entrada.append({"tipo": "desconocido", "origen_id": "noche:x"})
	entrada.append({"tipo": EcosDespertar.CRT, "origen_id": ""})
	var salida := EcosDespertar.candidatos(entrada)
	_comprobar(salida.size() == 4, "filtra inválidos y duplicados")
	_comprobar(String(salida[0]["tipo"]) == EcosDespertar.HUMEDAD, "conserva tipo autorizado")
	_comprobar(String(salida[0]["origen_id"]) == "noche:hidra", "conserva origen vivido")
	_comprobar(EcosDespertar.candidatos([]).is_empty(), "sin material no inventa eco")


func _probar_material_desde_noche() -> void:
	var material := (
		EcosDespertar
		. material_desde_noche(
			{"id": MutadoresSueno.HUMEDAD},
			["monitor", "silla", "desconocido", "monitor"],
		)
	)
	_comprobar(material.size() == 3, "solo usa presentacion nocturna reconocida")
	_comprobar(
		material.has({"tipo": EcosDespertar.HUMEDAD, "origen_id": "mutador:humedad"}),
		"humedad nace del mutador que si se presento",
	)
	_comprobar(
		material.has({"tipo": EcosDespertar.CRT, "origen_id": "utileria:monitor"}),
		"monitor realmente montado habilita eco CRT",
	)
	_comprobar(
		material.has({"tipo": EcosDespertar.OBJETO_DESPLAZADO, "origen_id": "utileria:silla"}),
		"objeto montado habilita desplazamiento ambiguo",
	)
	_comprobar(
		EcosDespertar.material_desde_noche({}, ["objeto_tocado_no_montado"]).is_empty(),
		"un id fuera del catalogo no fabrica material",
	)

	var sonido := EcosDespertar.material_desde_noche({"id": MutadoresSueno.DESFASE}, [])
	_comprobar(
		(
			sonido
			== [
				{
					"tipo": EcosDespertar.SONIDO_RESIDUAL,
					"origen_id": "mutador:desfase",
				}
			]
		),
		"desfase conserva solo el pulso audible que ya existio en sueno",
	)
	_comprobar(
		EcosDespertar.material_desde_noche({"id": MutadoresSueno.APAGONES}, []).is_empty(),
		"un mutador sin familia de eco no se fuerza a encajar",
	)


func _probar_captura_runtime() -> void:
	var jornada := {"fase": "sueño"}
	var mundo := Node3D.new()
	get_root().add_child(mundo)

	var presentador := SuenoMutadorPresentacion3D.new()
	presentador.name = SuenoMutadorPresentacion3D.NOMBRE
	presentador.set_meta("presentacion", {"id": MutadoresSueno.HUMEDAD})
	mundo.add_child(presentador)

	var monitor := Node3D.new()
	monitor.set_meta("objeto_origen", "monitor")
	mundo.add_child(monitor)
	var silla := Node3D.new()
	silla.set_meta("objeto_origen", "silla")
	mundo.add_child(silla)
	var documento := Node3D.new()
	documento.set_meta("documento_origen", "folio-irrelevante")
	mundo.add_child(documento)

	var capturado := EcosDespertarRuntime.registrar_sala(
		jornada, mundo, [monitor, silla, documento]
	)
	_comprobar(capturado.size() == 3, "captura solo material realmente montado")
	_comprobar(
		capturado.has({"tipo": EcosDespertar.HUMEDAD, "origen_id": "mutador:humedad"}),
		"el mutador cuenta solo desde su presentador runtime",
	)
	_comprobar(
		capturado.has({"tipo": EcosDespertar.CRT, "origen_id": "utileria:monitor"}),
		"objeto_origen montado habilita CRT",
	)
	_comprobar(
		capturado.has({"tipo": EcosDespertar.OBJETO_DESPLAZADO, "origen_id": "utileria:silla"}),
		"objeto_origen montado habilita desplazamiento",
	)

	var repetido := EcosDespertarRuntime.registrar_sala(jornada, mundo, [monitor, silla])
	_comprobar(repetido.size() == 3, "remontar la misma sala no duplica material")
	_comprobar(
		jornada[EcosDespertarRuntime.CLAVE_MATERIAL] == repetido,
		"el material queda en Jornada para el despertar posterior",
	)

	presentador.queue_free()
	await process_frame
	var sin_presentador := {"fase": "sueño"}
	var solo_objeto := EcosDespertarRuntime.registrar_sala(sin_presentador, mundo, [monitor])
	_comprobar(solo_objeto.size() == 1, "sin presentador no se inventa mutador")
	_comprobar(
		String(solo_objeto[0]["tipo"]) == EcosDespertar.CRT,
		"la utileria montada sigue siendo evidencia independiente",
	)

	var fuera := {"fase": "archivo"}
	_comprobar(
		EcosDespertarRuntime.registrar_sala(fuera, mundo, [monitor]).is_empty(),
		"fuera del sueño no se registra material",
	)
	_comprobar(not fuera.has(EcosDespertarRuntime.CLAVE_MATERIAL), "fuera no muta Jornada")
	mundo.queue_free()


func _probar_preparacion_runtime() -> void:
	var jornada := {
		"fase": "sueño",
		"dia": 4,
		"raiz": 1775,
		EcosDespertarRuntime.CLAVE_MATERIAL: _material(),
	}
	var primero := EcosDespertarRuntime.preparar_despertar(jornada)
	_comprobar(not primero.is_empty(), "despertar prepara un eco desde material vivido")
	_comprobar(
		not jornada.has(EcosDespertarRuntime.CLAVE_MATERIAL),
		"preparar consume el acumulador nocturno",
	)
	_comprobar(
		jornada.get(EcosDespertarRuntime.CLAVE_PENDIENTE, {}) == primero,
		"el pendiente queda persistido en Jornada",
	)

	var repetido := EcosDespertarRuntime.preparar_despertar(jornada)
	_comprobar(repetido == primero, "reintentar la misma noche conserva el mismo pendiente")
	_comprobar(
		jornada.get(EcosDespertarRuntime.CLAVE_PENDIENTE, {}) == primero,
		"reintentar no duplica ni reemplaza el pendiente",
	)

	var vacia := {
		"fase": "sueño",
		"dia": 8,
		"raiz": 1775,
		EcosDespertarRuntime.CLAVE_PENDIENTE: primero.duplicate(true),
	}
	_comprobar(
		EcosDespertarRuntime.preparar_despertar(vacia).is_empty(),
		"noche sin material no fabrica un eco nuevo",
	)
	_comprobar(
		not vacia.has(EcosDespertarRuntime.CLAVE_PENDIENTE),
		"pendiente de otra mañana se descarta al preparar una noche vacia",
	)

	var fuera := {
		"fase": "archivo",
		"dia": 5,
		"raiz": 1775,
		EcosDespertarRuntime.CLAVE_MATERIAL: _material(),
	}
	_comprobar(
		EcosDespertarRuntime.preparar_despertar(fuera).is_empty(),
		"fuera del sueño no se prepara el eco",
	)
	_comprobar(
		fuera.has(EcosDespertarRuntime.CLAVE_MATERIAL),
		"llamada fuera de sueño no consume material",
	)


func _probar_seleccion() -> void:
	var a := EcosDespertar.preparar(_material(), 1775, 4)
	var b := EcosDespertar.preparar(_material(), 1775, 4)
	_comprobar(a == b, "misma raíz y noche producen el mismo eco")
	_comprobar(not a.is_empty(), "material compatible produce como máximo un pendiente")
	_comprobar(int(a["dia_vigilia"]) == 5, "el eco pertenece a la mañana siguiente")
	_comprobar(not bool(a["consumido"]), "nace sin consumir")
	_comprobar(String(a["id"]).begins_with("eco:5:"), "id estable incluye la mañana")
	_comprobar(EcosDespertar.preparar([], 1775, 4).is_empty(), "noche sin material queda sin eco")


func _probar_persistencia_y_consumo() -> void:
	var pendiente := EcosDespertar.preparar(_material(), 9123, 8)
	var serializado := JSON.stringify(pendiente)
	var releido: Dictionary = JSON.parse_string(serializado)
	var antes := releido.duplicate(true)
	var oferta_a := EcosDespertar.oferta(releido, 9)
	var oferta_b := EcosDespertar.oferta(releido, 9)
	_comprobar(oferta_a == oferta_b, "guardar y releer conserva exactamente una oferta")
	_comprobar(releido == antes, "consultar no consume el pendiente")
	var id := String(oferta_a["id"])
	var aceptado := EcosDespertar.aceptar(releido, id, 9)
	_comprobar(bool(aceptado["ok"]), "el consumidor puede confirmar montaje")
	_comprobar(bool(aceptado["estado"]["consumido"]), "confirmar marca consumido")
	var repetido := EcosDespertar.aceptar(aceptado["estado"], id, 9)
	_comprobar(not bool(repetido["ok"]), "el mismo eco no se consume dos veces")
	_comprobar(
		EcosDespertar.oferta(aceptado["estado"], 9).is_empty(),
		"consumido ya no se vuelve a ofrecer"
	)
	var equivocado := EcosDespertar.aceptar(releido, "otro-id", 9)
	_comprobar(not bool(equivocado["ok"]), "un consumidor no puede aceptar otro id")
	_comprobar(not bool(equivocado["estado"]["consumido"]), "id incorrecto no muta estado")


func _probar_descarte() -> void:
	var pendiente := EcosDespertar.preparar(_material(), 44, 2)
	_comprobar(EcosDespertar.vigente(pendiente, 3), "solo vive en su mañana")
	_comprobar(not EcosDespertar.vigente(pendiente, 4), "otra mañana no lo reactiva")
	_comprobar(
		not EcosDespertar.descartar_al_avanzar(pendiente, 3).is_empty(),
		"durante su mañana sigue disponible",
	)
	_comprobar(
		EcosDespertar.descartar_al_avanzar(pendiente, 4).is_empty(),
		"al avanzar de día se descarta",
	)


func _probar_reduccion_movimiento() -> void:
	var pendiente := EcosDespertar.preparar(_material(), 77, 5)
	var normal := EcosDespertar.presentacion(pendiente, false)
	var reducida := EcosDespertar.presentacion(pendiente, true)
	_comprobar(normal["id"] == reducida["id"], "accesibilidad conserva identidad")
	_comprobar(normal["tipo"] == reducida["tipo"], "accesibilidad conserva tipo")
	_comprobar(normal["origen_id"] == reducida["origen_id"], "accesibilidad conserva origen")
	_comprobar(normal["estilo"] != reducida["estilo"], "solo cambia el estilo visual")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
