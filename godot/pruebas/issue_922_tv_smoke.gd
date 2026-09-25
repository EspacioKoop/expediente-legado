extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_registro_exposicion()
	_probar_rotulo_visible()
	print("issue_922_tv: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_registro_exposicion() -> void:
	var estado := {"historias_cartas": {}}
	var bloque := {
		"boletin":
		{
			"exposicion_ideologica":
			{
				"id": "tv:fixture:turnos",
				"fuente": "tv:fixture",
				"eje": "centrista",
				"etiquetas": ["procedimiento"],
			},
		},
	}
	_comprobar(
		TelevisionInteractiva3D.registrar_exposicion_de_bloque(estado, bloque, 1),
		true,
		"el primer consumo registra exposición",
	)
	_comprobar(
		TelevisionInteractiva3D.registrar_exposicion_de_bloque(estado, bloque, 1),
		false,
		"repetir el mismo bloque es idempotente",
	)
	_comprobar(
		estado.get(Prometeo.CLAVE_EXPOSICION_IDEOLOGICA, []).size(),
		1,
		"TV usa el canal de exposición",
	)
	_comprobar(
		Prometeo.elecciones_ideologicas(estado).size(),
		0,
		"ver TV no crea una elección ideológica",
	)


func _probar_rotulo_visible() -> void:
	var televisor := TelevisionInteractiva3D.new()
	televisor.configurar(Vector3(1.0, 0.8, 0.5))
	var bloque := {
		"boletin":
		{
			"tratamiento":
			{
				"rotulo": "NUEVO TURNO · PRUEBA 2 SEMANAS",
			},
		},
	}
	var texto := TelevisionInteractiva3D.rotulo_de_bloque(bloque)
	var rotulo := televisor.get_node_or_null("RotuloBoletinTV") as Label3D
	_comprobar(rotulo != null, true, "el CRT monta un rótulo de boletín")
	_comprobar(not texto.is_empty(), true, "un bloque válido produce información visible")
	televisor.free()


func _comprobar(actual: Variant, esperado: Variant, mensaje: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("%s: esperado=%s actual=%s" % [mensaje, esperado, actual])
