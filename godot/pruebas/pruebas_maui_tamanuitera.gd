extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_gate_y_semilla()
	_probar_vigilia_deliberada()
	_probar_tensores_y_puente()
	_probar_tensores_interactivos()
	_probar_reduccion_movimiento()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_gate_y_semilla() -> void:
	var jornada := {"dia": 8}
	_comprobar(
		not SuenoMauiTamanuitera.puede_entrar(jornada),
		"sin semilla Māui/Tamanuiterā no entra",
	)
	_comprobar(
		not SuenoMauiTamanuitera.registrar_semilla(jornada, 1, true),
		"una lectura no basta aunque el libro se cierre",
	)
	_comprobar(
		not SuenoMauiTamanuitera.registrar_semilla(jornada, 2, false),
		"dos lecturas sin cierre no bastan",
	)
	_comprobar(
		SuenoMauiTamanuitera.registrar_semilla(jornada, 2, true),
		"lectura deliberada registra la semilla",
	)
	_comprobar(
		SuenoMauiTamanuitera.puede_entrar(jornada),
		"la semilla común habilita la familia",
	)
	_comprobar(
		SemillasOniricas.familias_activas(jornada),
		["maui_tamanuitera"],
		"Māui/Tamanuiterā participa en el catálogo común",
	)
	var entrada: Dictionary = (
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_maui_tamanuitera"]
	)
	_comprobar(
		entrada["fuentes"],
		["libro:maui_tamanuitera_98"],
		"la procedencia queda estable",
	)
	jornada["dia"] = 9
	_comprobar(
		not SuenoMauiTamanuitera.puede_entrar(jornada),
		"la semilla no cruza de jornada",
	)


func _probar_vigilia_deliberada() -> void:
	var jornada := {"dia": 4}
	var libro := MauiTamanuiteraVigilia.new()
	get_root().add_child(libro)
	libro.configurar(jornada)
	_comprobar(not libro.esta_activada(), "el libro presente no activa por sí solo")
	libro.examinar()
	_comprobar(libro.paginas_leidas(), 1, "primera lectura cuenta")
	_comprobar(not libro.esta_activada(), "primera lectura no activa")
	libro.examinar()
	_comprobar(libro.paginas_leidas(), 2, "segunda lectura completa la observación")
	_comprobar(not libro.esta_cerrado(), "leer no equivale a cerrar")
	_comprobar(not libro.esta_activada(), "dos lecturas siguen sin activar")
	libro.examinar()
	_comprobar(libro.esta_cerrado(), "tercera interacción cierra el libro")
	_comprobar(libro.esta_activada(), "cierre deliberado activa la semilla")
	var intensidad := int(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_maui_tamanuitera"]["intensidad"]
	)
	libro.examinar()
	_comprobar(
		(
			SemillasOniricas
			. obtener_semillas(jornada)["semilla_onirica_maui_tamanuitera"]["intensidad"]
		),
		intensidad,
		"repetir la misma fuente es idempotente",
	)
	libro.queue_free()


func _probar_tensores_y_puente() -> void:
	var sueno := SuenoMauiTamanuitera.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var inicial := sueno.estado_actual()
	_comprobar(inicial["estado"], "0:0", "empieza en estado estable")
	_comprobar(not inicial["puente_activo"], "la ruta no existe al entrar")
	_comprobar(not sueno.colision_puente_activa(), "la colisión del puente empieza retirada")

	var solo_persiana := sueno.ajustar_tensor(SuenoMauiTamanuitera.TENSOR_PERSIANA, 2)
	_comprobar(solo_persiana["estado"], "2:0", "la persiana cambia el estado solar")
	_comprobar(not solo_persiana["puente_activo"], "un tensor solo no basta")

	var solapado := sueno.ajustar_tensor(SuenoMauiTamanuitera.TENSOR_CABLE, 1)
	_comprobar(solapado["estado"], "2:1", "el segundo tensor completa la combinación")
	_comprobar(solapado["solapamiento"], "las sombras se solapan")
	_comprobar(solapado["puente_activo"], "el solapamiento crea la ruta")
	_comprobar(sueno.colision_puente_activa(), "la sombra activa colisión transitable")
	_comprobar(
		sueno.get_node_or_null("Arquitectura/SombraPuente/Colision") != null,
		"el puente usa CollisionShape3D real",
	)

	var fuera := sueno.ajustar_tensor(SuenoMauiTamanuitera.TENSOR_CABLE, 1)
	_comprobar(fuera["estado"], "2:2", "el cable puede abandonar el solapamiento")
	_comprobar(not fuera["puente_activo"], "la ruta desaparece fuera del estado válido")
	_comprobar(not sueno.colision_puente_activa(), "la colisión se retira de nuevo")

	var repetido := SuenoMauiTamanuitera.resolver_geometria(2, 1)
	_comprobar(repetido["estado"], solapado["estado"], "la combinación se reproduce")
	_comprobar(repetido["azimut_sol"], solapado["azimut_sol"], "geometría solar determinista")
	_comprobar(repetido["sombra_a_x"], solapado["sombra_a_x"], "sombra A determinista")
	_comprobar(repetido["sombra_b_x"], solapado["sombra_b_x"], "sombra B determinista")
	sueno.queue_free()


func _probar_tensores_interactivos() -> void:
	var sueno := SuenoMauiTamanuitera.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var persiana := sueno.get_node_or_null("Arquitectura/UsarTensorPersiana") as Interactuable3D
	var cable := sueno.get_node_or_null("Arquitectura/UsarTensorCable") as Interactuable3D
	_comprobar(persiana != null, "la persiana expone interacción 3D real")
	_comprobar(cable != null, "el cable expone interacción 3D real")
	var actor := Node.new()
	sueno.add_child(actor)

	persiana.activado.emit(actor)
	_comprobar(sueno.valor_tensor(SuenoMauiTamanuitera.TENSOR_PERSIANA), 1, "usar persiana avanza estado")
	persiana.activado.emit(actor)
	_comprobar(sueno.valor_tensor(SuenoMauiTamanuitera.TENSOR_PERSIANA), 2, "persiana alcanza estado de solapamiento")
	cable.activado.emit(actor)
	_comprobar(sueno.valor_tensor(SuenoMauiTamanuitera.TENSOR_CABLE), 1, "usar cable avanza estado")
	_comprobar(sueno.puente_activo(), "las interacciones del jugador pueden crear el puente")
	cable.activado.emit(actor)
	_comprobar(not sueno.puente_activo(), "seguir usando el cable retira el puente")
	cable.activado.emit(actor)
	_comprobar(sueno.valor_tensor(SuenoMauiTamanuitera.TENSOR_CABLE), 0, "el tensor cicla sin dejar al jugador bloqueado")
	sueno.queue_free()


func _probar_reduccion_movimiento() -> void:
	var normal := SuenoMauiTamanuitera.plan_transicion(false)
	var reducida := SuenoMauiTamanuitera.plan_transicion(true)
	_comprobar(not normal["timing_precision"], "el modo normal tampoco exige timing")
	_comprobar(reducida["modo"], "corte_fundido", "movimiento reducido usa corte/fundido")
	_comprobar(reducida["duracion"], 0.0, "movimiento reducido no interpola")
	_comprobar(not reducida["barrido_solar"], "movimiento reducido elimina barridos")
	_comprobar(not reducida["mover_camara"], "movimiento reducido no desplaza cámara")
	var geometria_normal := SuenoMauiTamanuitera.resolver_geometria(2, 1)
	var geometria_reducida := SuenoMauiTamanuitera.resolver_geometria(2, 1)
	_comprobar(
		geometria_normal,
		geometria_reducida,
		"reducción de movimiento conserva la mecánica",
	)


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Māui/Tamanuiterā: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
