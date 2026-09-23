## Paisaje sonoro procedural del sueño sin lecturas (#786).
##
## El silencio absoluto hacía que la sala pareciera incompleta. Esta pista no
## introduce información del expediente: solo devuelve el zumbido eléctrico y
## pequeños relés de una oficina vacía. Es determinista y no usa assets externos.
class_name SuenoVacioAudio
extends RefCounted

const FRECUENCIA := 22_050
const DURACION := 6.0
const PULSOS_RELE := [1.15, 2.85, 4.70]

static var _ambiente: AudioStreamWAV


static func ambiente_oficina_vacia() -> AudioStreamWAV:
	if _ambiente != null:
		return _ambiente

	var pista := AudioStreamWAV.new()
	pista.format = AudioStreamWAV.FORMAT_16_BITS
	pista.mix_rate = FRECUENCIA
	pista.stereo = false
	pista.loop_mode = AudioStreamWAV.LOOP_FORWARD
	pista.loop_begin = 0
	pista.loop_end = int(FRECUENCIA * DURACION)

	var muestras := int(FRECUENCIA * DURACION)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / FRECUENCIA
		var muestra := sin(TAU * 50.0 * t) * 0.012
		muestra += sin(TAU * 100.0 * t) * 0.005
		muestra += sin(TAU * 37.0 * t) * 0.003 * (0.5 + 0.5 * sin(TAU * 0.17 * t))

		for instante in PULSOS_RELE:
			var desde := t - float(instante)
			if desde < 0.0 or desde > 0.16:
				continue
			var envolvente := exp(-desde * 24.0)
			muestra += sin(TAU * 720.0 * desde) * 0.024 * envolvente
			muestra += sin(TAU * 1180.0 * desde) * 0.010 * envolvente

		_escribir_muestra(datos, i, muestra)

	pista.data = datos
	_ambiente = pista
	return pista


static func _escribir_muestra(datos: PackedByteArray, indice: int, muestra: float) -> void:
	var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
	if valor < 0:
		valor += 65536
	datos[indice * 2] = valor & 0xFF
	datos[indice * 2 + 1] = (valor >> 8) & 0xFF
