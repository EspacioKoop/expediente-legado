## Anomalía sonora de la montaña onírica (#284).
##
## Genera viento con crujidos de madera deterministas sin importar audio externo.
## La pista se espacializa desde la cabaña, pero los crujidos no tienen una
## acción visible asociada: se oye una puerta o una tabla detrás de algo que no
## se ha movido.
class_name SuenoMontanaAudio
extends RefCounted

const FRECUENCIA := 22_050
const DURACION := 8.0
const CRUJIDOS := [1.55, 4.20, 6.45]

static var _pista: AudioStreamWAV


static func viento_y_madera() -> AudioStreamWAV:
	if _pista != null:
		return _pista

	var pista := AudioStreamWAV.new()
	pista.format = AudioStreamWAV.FORMAT_16_BITS
	pista.mix_rate = FRECUENCIA
	pista.stereo = false
	pista.loop_mode = AudioStreamWAV.LOOP_FORWARD
	pista.loop_begin = 0

	var muestras := int(FRECUENCIA * DURACION)
	pista.loop_end = muestras
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / FRECUENCIA
		# Ruido determinista filtrado por una envolvente lenta: no depende del
		# RNG global y por tanto la misma escena conserva la misma respiración.
		var entero := ((i * 1103515245 + 12345) >> 16) & 0x7FFF
		var ruido := float(entero) / 16384.0 - 1.0
		var rafaga := 0.38 + (sin(TAU * 0.125 * t) * 0.5 + 0.5) * 0.62
		var muestra := ruido * 0.030 * rafaga
		muestra += sin(TAU * 83.0 * t) * 0.006 * rafaga

		for instante in CRUJIDOS:
			var desde := t - float(instante)
			if desde < 0.0 or desde > 1.15:
				continue
			var ataque := minf(desde * 28.0, 1.0)
			var envolvente := exp(-desde * 3.1) * ataque
			# Dos parciales de madera con una deriva mínima producen un crujido
			# reconocible sin copiar una grabación concreta.
			var madera := (
				sin(TAU * (61.0 + desde * 19.0) * desde) * 0.090 + sin(TAU * 137.0 * desde) * 0.034
			)
			muestra += madera * envolvente

		var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
		if valor < 0:
			valor += 65536
		datos[i * 2] = valor & 0xFF
		datos[i * 2 + 1] = (valor >> 8) & 0xFF
	pista.data = datos
	_pista = pista
	return pista
