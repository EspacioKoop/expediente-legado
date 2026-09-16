## Anomalía sonora propia del castillo onírico (#284).
##
## Genera campanadas metálicas deterministas sin depender de audio externo. La
## fuente queda deliberadamente sin objeto visible: la presentación 3D la sitúa
## sobre el patio y el jugador oye la campana sin poder encontrar campanario.
class_name SuenoCastilloAudio
extends RefCounted

const FRECUENCIA := 22_050
const DURACION := 6.0
const CAMPANADAS := [0.35, 2.25, 4.65]

static var _pista: AudioStreamWAV


static func campanadas() -> AudioStreamWAV:
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
		var muestra := 0.0
		for instante in CAMPANADAS:
			var desde := t - float(instante)
			if desde < 0.0:
				continue
			# Parciales no armónicos y una caída larga dan lectura de metal grande
			# sin imitar una grabación concreta. El ataque corto evita clics.
			var ataque := minf(desde * 32.0, 1.0)
			var envolvente := exp(-desde * 2.7) * ataque
			var metal := (
				sin(TAU * 196.0 * desde) * 0.105
				+ sin(TAU * 277.0 * desde) * 0.067
				+ sin(TAU * 419.0 * desde) * 0.038
				+ sin(TAU * 613.0 * desde) * 0.021
			)
			muestra += metal * envolvente
		var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
		if valor < 0:
			valor += 65536
		datos[i * 2] = valor & 0xFF
		datos[i * 2 + 1] = (valor >> 8) & 0xFF
	pista.data = datos
	_pista = pista
	return pista
