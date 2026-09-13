## Ambiente continuo del mundo (#119).
##
## Separado de `Sonido` (efectos puntuales) y `Musica` (momentos dramáticos).
## Este primer corte genera en código el zumbido de fluorescentes del archivo:
## no hay binario que registrar en procedencia y no se finge haber importado un
## asset externo antes de que pueda entrar correctamente por Git LFS.
class_name Ambiente
extends RefCounted

const NODO := "AmbienteContinuo"
const FRECUENCIA := 22_050
const DURACION := 1.0

static var _archivo: AudioStreamWAV


static func stream(fase: String) -> AudioStream:
	if fase != "archivo":
		return null
	return zumbido_archivo()


static func zumbido_archivo() -> AudioStreamWAV:
	if _archivo != null:
		return _archivo

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
		# Red eléctrica + segundo armónico, con ruido determinista muy bajo.
		# La amplitud es deliberadamente pequeña: debe llenar el silencio, no
		# competir con documentos, pasos o diálogos.
		var ruido := float(((i * 1103515245 + 12345) >> 16) & 0x7FFF) / 16384.0 - 1.0
		var muestra := sin(TAU * 50.0 * t) * 0.055 + sin(TAU * 100.0 * t) * 0.018 + ruido * 0.006
		var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
		if valor < 0:
			valor += 65536
		datos[i * 2] = valor & 0xFF
		datos[i * 2 + 1] = (valor >> 8) & 0xFF
	pista.data = datos
	_archivo = pista
	return pista


static func reproducir(nodo: Node, fase: String, volumen_db: float = -24.0) -> AudioStreamPlayer:
	if nodo == null:
		return null
	var pista := stream(fase)
	if pista == null:
		detener(nodo)
		return null

	detener(nodo)
	var voz := AudioStreamPlayer.new()
	voz.name = NODO
	voz.stream = pista
	voz.volume_db = volumen_db
	nodo.add_child(voz)
	voz.play()
	return voz


static func detener(nodo: Node) -> void:
	if nodo == null:
		return
	var voz := nodo.get_node_or_null(NODO) as AudioStreamPlayer
	if voz == null:
		return
	voz.stop()
	voz.queue_free()
