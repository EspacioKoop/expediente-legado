## Audio procedural y determinista de la escuela onírica (#284).
##
## No usa muestras externas ni RNG global. El timbre es una suma breve de
## parciales metálicos y las voces son ruido filtrado con pulsos graves que se
## perciben como conversación lejana sin contener palabras ni hechos nuevos.
class_name SuenoEscuelaAudio
extends RefCounted

const MUESTRAS_POR_SEGUNDO := 22050
const DURACION_VOCES := 7.0
const DURACION_TIMBRE := 1.35


static func timbre() -> AudioStreamWAV:
	var total := int(MUESTRAS_POR_SEGUNDO * DURACION_TIMBRE)
	var datos := PackedByteArray()
	datos.resize(total * 2)
	for i in total:
		var t := float(i) / MUESTRAS_POR_SEGUNDO
		var envolvente := exp(-t * 2.65) * minf(1.0, t * 36.0)
		var muestra := (
			sin(TAU * 720.0 * t)
			+ sin(TAU * 1080.0 * t) * 0.62
			+ sin(TAU * 1510.0 * t) * 0.33
		) * envolvente * 0.22
		_escribir_i16(datos, i, muestra)
	return _onda(datos, false)


static func voces_vacias() -> AudioStreamWAV:
	var total := int(MUESTRAS_POR_SEGUNDO * DURACION_VOCES)
	var datos := PackedByteArray()
	datos.resize(total * 2)
	var anterior := 0.0
	for i in total:
		var t := float(i) / MUESTRAS_POR_SEGUNDO
		var pseudo := float(((i * 1103515245 + 12345) >> 16) & 0x7FFF) / 16383.5 - 1.0
		anterior = lerpf(anterior, pseudo, 0.018)
		var silabas := (
			maxf(0.0, sin(TAU * 2.1 * t)) * 0.46
			+ maxf(0.0, sin(TAU * 2.8 * t + 1.7)) * 0.35
		)
		var grave := sin(TAU * 118.0 * t) * silabas * 0.035
		var muestra := anterior * (0.018 + silabas * 0.035) + grave
		_escribir_i16(datos, i, muestra)
	return _onda(datos, true)


static func _onda(datos: PackedByteArray, bucle: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MUESTRAS_POR_SEGUNDO
	stream.stereo = false
	stream.data = datos
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if bucle else AudioStreamWAV.LOOP_DISABLED
	stream.loop_begin = 0
	stream.loop_end = datos.size() / 2
	return stream


static func _escribir_i16(datos: PackedByteArray, indice: int, muestra: float) -> void:
	var valor := clampi(int(muestra * 32767.0), -32768, 32767)
	if valor < 0:
		valor += 65536
	datos[indice * 2] = valor & 0xFF
	datos[indice * 2 + 1] = (valor >> 8) & 0xFF
