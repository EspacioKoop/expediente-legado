## Música puntual de escenas (#76).
##
## Separada de `Sonido` (efectos) y del ambiente continuo de #119. Solo conoce
## momentos dramáticos explícitos. Mientras una pista no haya entrado por LFS
## con procedencia verificada, su fichero queda vacío y la llamada es un no-op.
class_name Musica
extends RefCounted

const RUTA := "res://assets/audio/"
const NODO := "MusicaPuntual"

const CATALOGO := {
	"careo": "",
	"final": "",
}


static func stream(nombre: String) -> AudioStream:
	if not CATALOGO.has(nombre):
		return null
	var fichero := String(CATALOGO[nombre])
	if fichero.is_empty():
		return null
	var ruta := RUTA + fichero
	if not ResourceLoader.exists(ruta):
		return null
	var pista := load(ruta)
	return pista if pista is AudioStream else null


static func reproducir(nodo: Node, nombre: String, volumen_db: float = -8.0) -> AudioStreamPlayer:
	if nodo == null:
		return null
	var pista := stream(nombre)
	if pista == null:
		return null

	detener(nodo)
	var voz := AudioStreamPlayer.new()
	voz.name = NODO
	voz.stream = pista
	voz.volume_db = volumen_db
	if pista is AudioStreamOggVorbis:
		pista.loop = true
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
