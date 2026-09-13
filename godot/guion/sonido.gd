## Qué suena y cuándo.
##
## Un catálogo por NOMBRE, no rutas repartidas por las pantallas: quien quiere
## que suene un paso pide `"paso"` y no sabe qué fichero es. Cambiar el sonido
## de una cosa se hace aquí, y una sola vez.
##
## Todo lo que hay son assets **CC0 de Kenney**, con su ficha en
## `assets/procedencia.json` (autor, licencia, la página que declara la licencia
## y sha256) y con la prueba que lo exige en las dos direcciones. Nada entra sin
## ficha, y eso no es higiene: con destino comercial (#99) es lo que protege.
##
## **Lo que todavía NO hay es ambiente** —el zumbido del fluorescente del
## archivo, la calle de noche, el silencio raro del sueño—: Kenney no tiene
## ambientes, así que eso sigue esperando a #119. Lo que hay es lo que se toca
## y lo que se pisa.
class_name Sonido
extends RefCounted

const RUTA := "res://assets/audio/"
const FRECUENCIA_IMPACTO := 22_050
const DURACION_IMPACTO := 0.09

## Los pasos son varios a propósito: uno solo repetido a cada zancada deja de
## ser un paso y pasa a ser un tic.
const PASOS := ["footstep00.ogg", "footstep01.ogg", "footstep02.ogg", "footstep03.ogg"]

const CATALOGO := {
	"puerta_abre": "doorOpen_1.ogg",
	"puerta_cierra": "doorClose_1.ogg",
	"documento": "bookFlip1.ogg",
	"nomina": "handleCoins.ogg",
	"pulsar": "click_001.ogg",
	"error": "error_003.ogg",
	"firmar": "confirmation_001.ogg",
	"marcar": "switch_002.ogg",
}

static var _impacto_careo: AudioStreamWAV


static func stream(nombre: String) -> AudioStream:
	if not CATALOGO.has(nombre):
		return null
	return load(RUTA + CATALOGO[nombre])


## Un paso, el que toque. [param cual] hace la elección determinista para quien
## quiera repetirla; sin él, va sorteado.
static func paso(cual: int = -1) -> AudioStream:
	var i := cual if cual >= 0 else randi()
	return load(RUTA + PASOS[i % PASOS.size()])


## Golpe seco del careo.
##
## Es procedimental a propósito mientras el asset final no pueda entrar por el
## flujo LFS: no reutiliza un clic o un error de interfaz y, al ser determinista,
## tampoco cambia entre repeticiones del mismo duelo. La función queda aislada
## para que sustituirla por un `Impact Sounds` de Kenney sea cambiar un solo
## sitio cuando se suba el `.ogg` por Git/LFS normal.
static func impacto_careo() -> AudioStreamWAV:
	if _impacto_careo != null:
		return _impacto_careo

	var pista := AudioStreamWAV.new()
	pista.format = AudioStreamWAV.FORMAT_16_BITS
	pista.mix_rate = FRECUENCIA_IMPACTO
	pista.stereo = false

	var muestras := int(FRECUENCIA_IMPACTO * DURACION_IMPACTO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / FRECUENCIA_IMPACTO
		var avance := float(i) / muestras
		var envolvente := pow(1.0 - avance, 3.0)
		# Grave corto + ruido determinista: un golpe, no una notificación.
		var ruido := float(((i * 1103515245 + 12345) >> 16) & 0x7FFF) / 16384.0 - 1.0
		var muestra := clampf((sin(TAU * 82.0 * t) * 0.72 + ruido * 0.28) * envolvente, -1.0, 1.0)
		var valor := int(muestra * 32767.0)
		if valor < 0:
			valor += 65536
		datos[i * 2] = valor & 0xFF
		datos[i * 2 + 1] = (valor >> 8) & 0xFF
	pista.data = datos
	_impacto_careo = pista
	return pista


## Suena una vez, en la pantalla que lo pide.
##
## El reproductor se crea y se tira solo: una pantalla que guarda su propio
## `AudioStreamPlayer` acaba con uno por cada sitio desde el que suena algo, y
## el primero que se olvida de pararlo se solapa con el siguiente.
static func sonar(nodo: Node, nombre: String) -> void:
	sonar_stream(nodo, stream(nombre))


## La variante para pistas que no salen del catálogo de ficheros, como el
## impacto procedimental del careo. Mantiene un único ciclo de vida para todas
## las voces efímeras.
static func sonar_stream(nodo: Node, pista: AudioStream) -> void:
	if pista == null or nodo == null:
		return
	var voz := AudioStreamPlayer.new()
	voz.stream = pista
	voz.finished.connect(voz.queue_free)
	nodo.add_child(voz)
	voz.play()


## Todos los ficheros que el catálogo puede pedir. Para que una prueba
## compruebe que existen TODOS: un nombre que apunta a un fichero que no está
## no falla al arrancar, falla el día que alguien abre esa puerta.
static func ficheros() -> Array:
	var todos := PASOS.duplicate()
	for nombre in CATALOGO:
		todos.append(CATALOGO[nombre])
	return todos
