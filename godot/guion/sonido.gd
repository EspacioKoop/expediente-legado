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

## Los pasos son varios a propósito: uno solo repetido a cada zancada deja de
## ser un paso y pasa a ser un tic.
const PASOS := ["footstep00.ogg", "footstep01.ogg", "footstep02.ogg", "footstep03.ogg"]

## Lo que se pisa suena a lo que es: moqueta que amortigua en casa, suelo duro en
## la oficina y la calle, nieve cuando nieva fuera. La clave es la
## `textura_suelo` que ya declara cada espacio en `EspaciosCatalogo`, más la
## nieve, que no es un suelo sino el tiempo encima de uno. Un suelo sin entrada
## conserva los pasos genéricos de `PASOS`.
const NIEVE := "nieve"
const PASOS_POR_SUELO := {
	"moqueta":
	[
		"footstep_carpet_000.ogg",
		"footstep_carpet_001.ogg",
		"footstep_carpet_002.ogg",
		"footstep_carpet_003.ogg",
		"footstep_carpet_004.ogg",
	],
	"linoleo":
	[
		"footstep_concrete_000.ogg",
		"footstep_concrete_001.ogg",
		"footstep_concrete_002.ogg",
		"footstep_concrete_003.ogg",
		"footstep_concrete_004.ogg",
	],
	"asfalto":
	[
		"footstep_concrete_000.ogg",
		"footstep_concrete_001.ogg",
		"footstep_concrete_002.ogg",
		"footstep_concrete_003.ogg",
		"footstep_concrete_004.ogg",
	],
	NIEVE:
	[
		"footstep_snow_000.ogg",
		"footstep_snow_001.ogg",
		"footstep_snow_002.ogg",
		"footstep_snow_003.ogg",
		"footstep_snow_004.ogg",
	],
}

## Golpe seco del careo y de la pared: una sola toma para que no cambie entre
## repeticiones del mismo duelo.
const IMPACTO_CAREO := "impactWood_heavy_000.ogg"

const CATALOGO := {
	"puerta_abre": "doorOpen_1.ogg",
	"puerta_cierra": "doorClose_1.ogg",
	"documento": "bookFlip1.ogg",
	"nomina": "handleCoins.ogg",
	"pulsar": "click_001.ogg",
	"error": "error_003.ogg",
	"firmar": "confirmation_001.ogg",
	"marcar": "switch_002.ogg",
	# El mismo impacto blando ya auditado para objetos sirve como apoyo físico
	# de la cama sin añadir un asset ni reutilizar el nombre semántico `coger`.
	"cama": "impactSoft_medium_000.ogg",
}

## Gestos físicos que se repiten mucho —abrir el mismo archivador diez veces al
## día—. Cada uno es una familia de tomas de **Impact Sounds** de Kenney: el
## `AudioStreamRandomizer` alterna toma y tono para que la décima vez no sea un
## calco de la primera.
const FAMILIAS := {
	"abrir": ["impactMetal_light_000.ogg", "impactMetal_light_001.ogg"],
	"cerrar": ["impactMetal_medium_000.ogg"],
	"coger": ["impactSoft_medium_000.ogg", "impactSoft_medium_001.ogg"],
}
const VARIACION_TONO := 1.08

static var _familias := {}


static func stream(nombre: String) -> AudioStream:
	if FAMILIAS.has(nombre):
		return _familia(nombre)
	if not CATALOGO.has(nombre):
		return null
	return load(RUTA + CATALOGO[nombre])


static func _familia(nombre: String) -> AudioStreamRandomizer:
	if _familias.has(nombre):
		return _familias[nombre]
	var familia := AudioStreamRandomizer.new()
	familia.random_pitch = VARIACION_TONO
	familia.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
	for fichero in FAMILIAS[nombre]:
		familia.add_stream(-1, load(RUTA + fichero))
	_familias[nombre] = familia
	return familia


## Un paso, el que toque. [param cual] hace la elección determinista para quien
## quiera repetirla; sin él, va sorteado.
static func paso(cual: int = -1) -> AudioStream:
	var i := cual if cual >= 0 else randi()
	return load(RUTA + PASOS[i % PASOS.size()])


## Un paso sobre [param suelo], con las mismas reglas que [method paso].
static func paso_sobre(suelo: String, cual: int = -1) -> AudioStream:
	if not PASOS_POR_SUELO.has(suelo):
		return paso(cual)
	var tomas: Array = PASOS_POR_SUELO[suelo]
	var i := cual if cual >= 0 else randi()
	return load(RUTA + tomas[i % tomas.size()])


## Golpe seco del careo: un impacto de madera de Kenney, que suena a mesa y no
## a notificación de interfaz.
static func impacto_careo() -> AudioStream:
	return load(RUTA + IMPACTO_CAREO)


## Suena una vez, en la pantalla que lo pide.
##
## El reproductor se crea y se tira solo: una pantalla que guarda su propio
## `AudioStreamPlayer` acaba con uno por cada sitio desde el que suena algo, y
## el primero que se olvida de pararlo se solapa con el siguiente.
static func sonar(nodo: Node, nombre: String, tono: float = 1.0) -> void:
	sonar_stream(nodo, stream(nombre), tono)


## La variante para pistas que no salen del catálogo de ficheros, como el
## impacto procedimental del careo. Mantiene un único ciclo de vida para todas
## las voces efímeras.
static func sonar_stream(nodo: Node, pista: AudioStream, tono: float = 1.0) -> void:
	if pista == null or nodo == null:
		return
	var voz := AudioStreamPlayer.new()
	voz.stream = pista
	# El tono permite variaciones diegéticas del mismo material sin duplicar
	# archivos. Se acota para evitar valores inválidos o efectos extremos.
	voz.pitch_scale = clampf(tono, 0.5, 2.0)
	voz.finished.connect(voz.queue_free)
	nodo.add_child(voz)
	voz.play()


## Corta las voces efímeras 2D que cuelgan directamente de [param nodo].
##
## Sirve para pantallas de vida muy corta —como una cinemática que se salta—:
## esperar únicamente a `finished` deja al servidor de audio usando el stream
## cuando el árbol ya se está desmontando. Parar, soltar el stream y liberar la
## voz ANTES de emitir la salida da al motor un frame limpio para cerrar.
static func detener(nodo: Node) -> void:
	if nodo == null:
		return
	for hijo in nodo.get_children():
		if hijo is AudioStreamPlayer:
			hijo.stop()
			hijo.stream = null
			hijo.free()


## Suena una vez donde está [param origen], en el espacio 3D.
##
## La voz no cuelga del objeto sino de la escena: quien la pide puede
## desaparecer en el mismo gesto —un recogible se libera al cogerlo— y el
## sonido de cogerlo no debe cortarse con él.
static func sonar_en(origen: Node3D, nombre: String) -> void:
	var pista := stream(nombre)
	if pista == null or origen == null or not origen.is_inside_tree():
		return
	var anfitrion: Node = origen.get_tree().current_scene
	if anfitrion == null:
		anfitrion = origen.get_parent()
	var voz := AudioStreamPlayer3D.new()
	voz.stream = pista
	voz.finished.connect(voz.queue_free)
	anfitrion.add_child(voz)
	voz.global_position = origen.global_position
	voz.play()


## Todos los ficheros que el catálogo puede pedir. Para que una prueba
## compruebe que existen TODOS: un nombre que apunta a un fichero que no está
## no falla al arrancar, falla el día que alguien abre esa puerta.
static func ficheros() -> Array:
	var todos := PASOS.duplicate()
	for nombre in CATALOGO:
		todos.append(CATALOGO[nombre])
	for nombre in FAMILIAS:
		todos.append_array(FAMILIAS[nombre])
	for suelo in PASOS_POR_SUELO:
		for fichero in PASOS_POR_SUELO[suelo]:
			if not todos.has(fichero):
				todos.append(fichero)
	todos.append(IMPACTO_CAREO)
	return todos
