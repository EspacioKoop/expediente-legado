## Paisaje sonoro procedural del desierto onírico (#284).
##
## No usa grabaciones externas: el viento incorpora ecos de oficina irreconocibles
## como fuente concreta y el teléfono mantiene un tono continuo determinista.
class_name SuenoDesiertoAudio
extends RefCounted

const FRECUENCIA := 22_050
const DURACION_VIENTO := 8.0
const DURACION_TONO := 2.0
const GOLPES_OFICINA := [1.20, 2.95, 5.10, 6.70]

static var _viento: AudioStreamWAV
static var _tono: AudioStreamWAV


static func viento_con_oficina() -> AudioStreamWAV:
	if _viento != null:
		return _viento

	var pista := _crear_pista(DURACION_VIENTO)
	var muestras := int(FRECUENCIA * DURACION_VIENTO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / FRECUENCIA
		var entero := ((i * 1664525 + 1013904223) >> 16) & 0x7FFF
		var ruido := float(entero) / 16384.0 - 1.0
		var oleada := 0.30 + (sin(TAU * 0.09 * t) * 0.5 + 0.5) * 0.70
		var muestra := ruido * 0.026 * oleada
		muestra += sin(TAU * 54.0 * t) * 0.004 * oleada

		for instante in GOLPES_OFICINA:
			var desde := t - float(instante)
			if desde < 0.0 or desde > 0.34:
				continue
			var envolvente := exp(-desde * 12.0)
			var golpe := sin(TAU * 680.0 * desde) * 0.052
			golpe += sin(TAU * 920.0 * desde) * 0.018
			muestra += golpe * envolvente

		_escribir_muestra(datos, i, muestra)
	pista.data = datos
	_viento = pista
	return pista


static func tono_telefono() -> AudioStreamWAV:
	if _tono != null:
		return _tono

	var pista := _crear_pista(DURACION_TONO)
	var muestras := int(FRECUENCIA * DURACION_TONO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / FRECUENCIA
		var muestra := sin(TAU * 350.0 * t) * 0.055
		muestra += sin(TAU * 440.0 * t) * 0.045
		_escribir_muestra(datos, i, muestra)
	pista.data = datos
	_tono = pista
	return pista


static func _crear_pista(duracion: float) -> AudioStreamWAV:
	var pista := AudioStreamWAV.new()
	pista.format = AudioStreamWAV.FORMAT_16_BITS
	pista.mix_rate = FRECUENCIA
	pista.stereo = false
	pista.loop_mode = AudioStreamWAV.LOOP_FORWARD
	pista.loop_begin = 0
	pista.loop_end = int(FRECUENCIA * duracion)
	return pista


static func _escribir_muestra(datos: PackedByteArray, indice: int, muestra: float) -> void:
	var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
	if valor < 0:
		valor += 65536
	datos[indice * 2] = valor & 0xFF
	datos[indice * 2 + 1] = (valor >> 8) & 0xFF
