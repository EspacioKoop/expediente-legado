## Contrato de bucle de la candidata CC0 sin depender del binario LFS (#76).
extends SceneTree

var _fallos := 0


func _init() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var original := AudioStreamOggVorbis.new()
	var careo := (
		Musica.preparar_pista("careo", original, "battle_music_01-loop.ogg") as AudioStreamOggVorbis
	)
	_comprobar(careo is AudioStreamOggVorbis, "la copia conserva el formato")
	_comprobar(careo != original, "el recurso compartido no se modifica")
	_comprobar(careo.loop, "el careo se repite")
	_comprobar(is_equal_approx(careo.loop_offset, 7.5), "el intro no se repite")
	_comprobar(not original.loop, "el original conserva su política")
	_comprobar(is_zero_approx(original.loop_offset), "el original conserva su offset")

	var otro := Musica.preparar_pista("careo", original, "otra-pista.ogg") as AudioStreamOggVorbis
	_comprobar(otro.loop, "otra pista de careo también puede repetir")
	_comprobar(is_zero_approx(otro.loop_offset), "otra pista empieza desde cero")

	var final := (
		Musica.preparar_pista("final", original, "battle_music_01-loop.ogg") as AudioStreamOggVorbis
	)
	_comprobar(not final.loop, "el final no se repite")
	_comprobar(is_zero_approx(final.loop_offset), "el final no conserva offset")
	_comprobar(careo.loop, "configurar el final no altera la voz de careo")

	var generador := AudioStreamGenerator.new()
	_comprobar(
		Musica.preparar_pista("careo", generador, "otra-pista.ogg") == generador,
		"otros formatos mantienen el recurso",
	)
	print("musica puntual 76: %d fallos" % _fallos)
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, descripcion: String) -> void:
	if not condicion:
		_fallos += 1
		push_error(descripcion)
