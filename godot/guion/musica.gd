## Música puntual de escenas (#76).
##
## Separada de `Sonido` (efectos) y del ambiente continuo de #119. Solo conoce
## momentos dramáticos explícitos. Mientras una pista no haya entrado por LFS
## con procedencia verificada, su fichero queda vacío y la llamada es un no-op.
class_name Musica
extends RefCounted

const RUTA := "res://assets/audio/musica/"
const NODO := "MusicaPuntual"

const CATALOGO := {
	"careo": "",
	"final": "",
}

## El bucle también es una decisión musical, no una propiedad accidental del
## formato. El careo puede repetirse mientras dure el duelo; un final debe poder
## terminar por sí mismo y no alargar una cinemática ni obligarla a cortar audio.
const BUCLE := {
	"careo": true,
	"final": false,
}

## La candidata CC0 de #76 lleva una introducción que su autor excluye de las
## repeticiones. La clave es el fichero, no el momento: otra pista de careo
## vuelve a 0 salvo que se documente su propio punto de bucle.
const INICIO_BUCLE_POR_FICHERO := {
	"battle_music_01-loop.ogg": 7.5,
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


static func en_bucle(nombre: String) -> bool:
	return bool(BUCLE.get(nombre, false))


static func preparar_pista(nombre: String, pista: AudioStream, fichero: String) -> AudioStream:
	if pista is AudioStreamOggVorbis:
		# load() comparte el recurso: cada voz configura su copia para que un
		# final no cambie el bucle de un careo que esté sonando en otra escena.
		var copia := pista.duplicate() as AudioStreamOggVorbis
		copia.loop = en_bucle(nombre)
		copia.loop_offset = (
			float(INICIO_BUCLE_POR_FICHERO.get(fichero, 0.0)) if copia.loop else 0.0
		)
		return copia
	return pista


static func reproducir(nodo: Node, nombre: String, volumen_db: float = -8.0) -> AudioStreamPlayer:
	if nodo == null:
		return null
	var pista := stream(nombre)
	if pista == null:
		return null

	detener(nodo)
	var voz := AudioStreamPlayer.new()
	voz.name = NODO
	voz.stream = preparar_pista(nombre, pista, String(CATALOGO[nombre]))
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
