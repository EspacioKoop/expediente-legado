## Smoke aislado de la presencia sonora del Minotauro (#437).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var pista := SuenoMinotauroAudio.respiracion()
	_comprobar(pista != null, "stream procedural disponible")
	_comprobar(pista.format == AudioStreamWAV.FORMAT_16_BITS, "stream PCM de 16 bits")
	_comprobar(pista.mix_rate == SuenoMinotauroAudio.FRECUENCIA, "frecuencia estable")
	_comprobar(not pista.stereo, "respiración mono para espacialización 3D")
	_comprobar(pista.loop_mode == AudioStreamWAV.LOOP_FORWARD, "respiración en bucle")
	_comprobar(pista.data.size() > 40_000, "stream contiene muestras reales")
	_comprobar(
		SuenoMinotauroAudio.respiracion() == pista,
		"stream procedural se reutiliza y no se regenera por frame",
	)
	_comprobar(
		SuenoMinotauroAudio.volumen_db("lejano") < SuenoMinotauroAudio.volumen_db("respiracion"),
		"la respiración sube al aproximarse",
	)
	_comprobar(
		SuenoMinotauroAudio.volumen_db("respiracion") < SuenoMinotauroAudio.volumen_db("cruce"),
		"el cruce aumenta presencia sonora",
	)
	_comprobar(
		SuenoMinotauroAudio.volumen_db("cruce") < SuenoMinotauroAudio.volumen_db("cerca"),
		"el estado cerca es el más audible",
	)

	var minotauro := SuenoMinotauro3D.new()
	minotauro.reduccion_movimiento = true
	root.add_child(minotauro)
	minotauro.preparar()
	var audio := (
		minotauro.get_node_or_null("LaberintoMinotauro/PresenciaMinotauro/RespiracionMinotauro")
		as AudioStreamPlayer3D
	)
	_comprobar(audio != null, "presencia monta AudioStreamPlayer3D")
	if audio != null:
		_comprobar(audio.stream == pista, "presencia usa el stream procedural común")
		_comprobar(
			is_equal_approx(audio.volume_db, SuenoMinotauroAudio.volumen_db("lejano")),
			"volumen inicial corresponde a presencia lejana",
		)

	_comprobar(
		minotauro.marcar_y_cruzar(SuenoMinotauro.BISAGRA),
		"primer cruce avanza presencia",
	)
	if audio != null:
		_comprobar(
			is_equal_approx(audio.volume_db, SuenoMinotauroAudio.volumen_db("respiracion")),
			"estado respiración actualiza volumen espacial",
		)
		_comprobar(
			is_equal_approx(audio.pitch_scale, SuenoMinotauroAudio.pitch_scale("respiracion")),
			"estado respiración actualiza pitch",
		)

	_comprobar(
		minotauro.marcar_y_cruzar(SuenoMinotauro.CENTRO),
		"segundo cruce avanza presencia",
	)
	if audio != null:
		_comprobar(
			is_equal_approx(audio.volume_db, SuenoMinotauroAudio.volumen_db("cruce")),
			"estado cruce actualiza volumen espacial",
		)

	_finalizar(minotauro)


func _finalizar(minotauro: Node) -> void:
	if is_instance_valid(minotauro):
		minotauro.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO audio Minotauro: " + nombre)
