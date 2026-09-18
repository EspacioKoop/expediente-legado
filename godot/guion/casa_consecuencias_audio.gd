## Sonido procedural de consecuencias domésticas (#96).
##
## Solo representa hechos que físicamente producen sonido. No añade música,
## narración ni una capa emocional sintética: el grifo averiado gotea porque el
## estado ya dice que el grifo está averiado.
class_name CasaConsecuenciasAudio
extends RefCounted

const FRECUENCIA := 22_050
const DURACION := 2.0
const VOLUMEN_GOTEO_DB := -18.0

static var _goteo: AudioStreamWAV


static func goteo() -> AudioStreamWAV:
	if _goteo != null:
		return _goteo

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
		var muestra := _muestra_goteo(i, t)
		var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
		if valor < 0:
			valor += 65536
		datos[i * 2] = valor & 0xFF
		datos[i * 2 + 1] = (valor >> 8) & 0xFF
	pista.data = datos
	_goteo = pista
	return pista


static func _muestra_goteo(indice: int, t: float) -> float:
	var fase := fmod(t, 0.50)
	if fase > 0.075:
		return 0.0

	var envolvente := exp(-fase * 52.0)
	var cuerpo := sin(TAU * 820.0 * fase) * 0.22
	var grave := sin(TAU * 190.0 * fase) * 0.07
	var ruido := float(((indice * 1103515245 + 12345) >> 16) & 0x7FFF) / 16384.0 - 1.0
	return (cuerpo + grave + ruido * 0.03) * envolvente
