## Presencia sonora procedural del Minotauro (#437).
##
## Genera una respiración/ronquido grave, determinista y en bucle. No depende de
## assets externos: `SuenoMinotauro3D` la espacializa con AudioStreamPlayer3D y
## solo cambia volumen/pitch según el estado de presencia que ya calcula el
## contrato lógico.
class_name SuenoMinotauroAudio
extends RefCounted

const FRECUENCIA := 22_050
const DURACION := 2.0

const VOLUMEN_DB := {
	"lejano": -31.0,
	"respiracion": -23.0,
	"cruce": -16.0,
	"cerca": -10.0,
}

const PITCH := {
	"lejano": 0.90,
	"respiracion": 0.95,
	"cruce": 1.0,
	"cerca": 1.06,
}

static var _respiracion: AudioStreamWAV


static func respiracion() -> AudioStreamWAV:
	if _respiracion != null:
		return _respiracion

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
		# Una respiración completa por bucle, sobre dos parciales graves que
		# cierran exactamente el ciclo. El ruido es determinista y muy bajo.
		var respiracion_ciclo := sin(TAU * 0.5 * t) * 0.5 + 0.5
		var envolvente := 0.14 + pow(respiracion_ciclo, 1.6) * 0.86
		var ruido := float(((i * 1103515245 + 12345) >> 16) & 0x7FFF) / 16384.0 - 1.0
		var onda := sin(TAU * 43.0 * t) * 0.085 + sin(TAU * 86.0 * t) * 0.032
		var muestra := onda * envolvente + ruido * 0.006 * envolvente
		var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
		if valor < 0:
			valor += 65536
		datos[i * 2] = valor & 0xFF
		datos[i * 2 + 1] = (valor >> 8) & 0xFF
	pista.data = datos
	_respiracion = pista
	return pista


static func volumen_db(presencia: String) -> float:
	return float(VOLUMEN_DB.get(presencia, VOLUMEN_DB["lejano"]))


static func pitch_scale(presencia: String) -> float:
	return float(PITCH.get(presencia, PITCH["lejano"]))
