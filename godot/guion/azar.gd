## De dónde sale el azar de una partida.
##
## Hasta ahora cada sistema sorteaba por su cuenta: los compañeros con `randi()`
## global, el combate con un `randomize()` en `_ready`, el sueño con un hash del
## día. Funciona —hasta que algo sale raro y no hay forma de volver a verlo. Un
## informe de bug que dice «me salió mal el careo» no es reproducible si la
## tirada salió de la hora del reloj.
##
## Aquí no se añade azar: se le pone una raíz. Una partida tiene **una semilla**
## y todo lo que se sortea sale de ella por derivación, así que la misma semilla
## con las mismas acciones da la misma partida, y guardar y recargar no cambia
## ninguna decisión — porque no se vuelve a sortear, se vuelve a derivar.
##
## Tres reglas que esto impone al resto del código:
##
## 1. **Nada jugable sale de `randi()` / `randf()` globales.** Lo global no
##    tiene raíz y no se puede reproducir. Lo que sí puede seguir ahí es la
##    presentación —el tono de una pisada, hacia dónde mira el gato—: no decide
##    nada y nadie va a querer repetirlo clavado.
## 2. **Cada dominio deriva por su lado.** Que el sueño de la noche 3 no cambie
##    porque el combate haya tirado una vez más. Un generador compartido
##    encadena sistemas por accidente y convierte cualquier cambio en un
##    cambio de todo.
## 3. **La semilla no se le enseña al jugador.** Va en la partida y en el
##    manifiesto de depuración (#116), no en la interfaz: esto es para poder
##    arreglar el juego, no una mecánica.
class_name Azar
extends RefCounted

## Los dominios que derivan. Es una lista cerrada a propósito: un dominio nuevo
## se declara aquí, y así «qué cosas sortea este juego» se puede leer de un
## vistazo en vez de buscándolo por el árbol.
const DOMINIOS := [
	"vida",  # qué trae cada vida laboral
	"companeros",  # con quién compartes planta (#125)
	"dia",  # lo que varía de un día a otro
	"clima",  # el tiempo que hace (#143)
	"sueno",  # salas y deformaciones de la noche (#79, #86, #87)
	"combate",  # las tiradas de la Ventanilla y del careo
	"presentacion",  # variaciones que no deciden nada
]

## Los catálogos cuyo contenido identifica una partida. Si cambian, dos
## partidas con la misma semilla ya no son comparables, y el manifiesto tiene
## que poder decirlo.
const CATALOGOS := ["res://datos/casos.json", "res://datos/prometeo.json"]

## Constantes de FNV-1a de 64 bits. Se mezcla a mano y no con `hash()` porque
## `hash()` es un detalle del motor: puede cambiar entre versiones de Godot, y
## una semilla que cambia al actualizar el motor no es una semilla.
##
## La base va escrita en decimal negativo porque los enteros de GDScript son
## con signo: 0xCBF29CE484222325 no cabe, y su patrón de bits es este número.
## El desbordamiento al multiplicar es el comportamiento que FNV espera.
const _FNV_BASE := -3750763034362895579
const _FNV_PRIMO := 0x100000001B3

## Máscara de 63 bits: quita el bit de signo sin perder mezcla.
const _SIN_SIGNO := 0x7FFFFFFFFFFFFFFF

## Máscara de 32 bits, para todo número que vaya a GUARDARSE.
##
## JSON no tiene enteros: un número vuelve siempre como coma flotante, y un
## entero de 63 bits no cabe en un `double` — se redondea, y la partida
## recargada sortea otra cosa. Se descubrió con la plantilla de compañeros:
## guardar y recargar te cambiaba a media oficina. 32 bits sí caben exactos,
## y para sembrar un generador sobran.
const _GUARDABLE := 0xFFFFFFFF


## Una semilla de partida nueva. Es el ÚNICO sitio del juego donde se mira el
## reloj para sortear: de aquí para abajo todo es derivación.
##
## Cabe en 32 bits porque se guarda (ver [constant _GUARDABLE]). Nunca sale
## cero: el cero es el valor que dice «esta partida es anterior a la semilla»,
## y una partida nueva que naciera con él se trataría como vieja para siempre.
static func raiz_nueva() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return maxi(1, rng.randi() & _GUARDABLE)


## La semilla de un dominio, opcionalmente afinada por índices (la vuelta, el
## día, el turno del combate...).
##
## Es una función pura: los mismos argumentos dan siempre el mismo número, en
## cualquier máquina y en cualquier orden. Eso es lo que permite reproducir el
## sueño de la noche 4 sin haber jugado las tres anteriores.
static func derivar(raiz: int, dominio: String, indices: Array = []) -> int:
	assert(dominio in DOMINIOS, "dominio de azar no declarado: " + dominio)
	var mezcla := _mezclar_texto(_FNV_BASE, dominio)
	mezcla = _mezclar_entero(mezcla, raiz)
	for indice in indices:
		mezcla = _mezclar_entero(mezcla, int(indice))
	# Se devuelve en positivo: hay semillas que acaban en un `%` o en un
	# `slice`, y un negativo ahí es un bug silencioso en vez de un error.
	return mezcla & _SIN_SIGNO


## Como [method derivar], pero con un texto dentro de la mezcla — lo leído de
## un día, el id de una sala. El texto entra byte a byte por FNV y no por
## `String.hash()`, que es del motor y puede cambiar al actualizarlo.
static func derivar_texto(raiz: int, dominio: String, texto: String, indices: Array = []) -> int:
	assert(dominio in DOMINIOS, "dominio de azar no declarado: " + dominio)
	var mezcla := _mezclar_texto(_FNV_BASE, dominio)
	mezcla = _mezclar_entero(mezcla, raiz)
	for indice in indices:
		mezcla = _mezclar_entero(mezcla, int(indice))
	mezcla = _mezclar_texto(mezcla, texto)
	return mezcla & _SIN_SIGNO


## Como [method derivar], pero para un número que va a GUARDARSE en la partida.
##
## Todo lo que se persiste pasa por JSON y vuelve como coma flotante, así que
## solo lo que cabe exacto en 32 bits vuelve siendo lo mismo. Quien derive algo
## que acabe en el fichero de partida usa esto y no [method derivar].
static func derivar_guardable(raiz: int, dominio: String, indices: Array = []) -> int:
	return derivar(raiz, dominio, indices) & _GUARDABLE


## El generador ya sembrado de un dominio. Quien sortee usa esto y no un
## `RandomNumberGenerator` suyo sin sembrar.
static func generador(raiz: int, dominio: String, indices: Array = []) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = derivar(raiz, dominio, indices)
	return rng


## Con qué se jugó esta partida: semilla, versión del guardado y huella de los
## catálogos. Es lo que acompaña a un informe de bug para que el fallo se pueda
## volver a ver — no se muestra en la interfaz del juego (#116).
static func manifiesto(estado: Dictionary) -> Dictionary:
	var jornada: Dictionary = estado.get("jornada", {})
	return {
		"semilla": int(estado.get("semilla", 0)),
		"version_guardado": int(estado.get("version", 0)),
		"datos": huella_catalogos(),
		"vuelta": int(jornada.get("vuelta", 0)),
		"dia": int(jornada.get("dia", 0)),
	}


## Una línea pegable en un informe de bug.
static func manifiesto_en_texto(estado: Dictionary) -> String:
	var m := manifiesto(estado)
	return (
		"semilla=%d vuelta=%d día=%d guardado=v%d datos=%s"
		% [m["semilla"], m["vuelta"], m["dia"], m["version_guardado"], m["datos"]]
	)


## La huella del contenido con el que se generó la partida. Dos partidas con la
## misma semilla y distinta huella NO tienen por qué coincidir, y saberlo evita
## perseguir un fantasma cuando lo único que pasó es que se editó un caso.
static func huella_catalogos() -> String:
	var mezcla := _FNV_BASE
	for ruta in CATALOGOS:
		mezcla = _mezclar_texto(mezcla, ruta)
		var fichero := FileAccess.open(ruta, FileAccess.READ)
		if fichero == null:
			mezcla = _mezclar_texto(mezcla, "<ausente>")
			continue
		mezcla = _mezclar_texto(mezcla, fichero.get_as_text())
		fichero.close()
	# En dos mitades de 32 bits: "%x" sobre un negativo daría un signo delante,
	# y una huella con menos dígitos según el día no sirve para comparar.
	return "%08x%08x" % [(mezcla >> 32) & 0xFFFFFFFF, mezcla & 0xFFFFFFFF]


static func _mezclar_texto(desde: int, texto: String) -> int:
	var mezcla := desde
	for byte in texto.to_utf8_buffer():
		mezcla = (mezcla ^ byte) * _FNV_PRIMO
	return mezcla


## Un entero entra byte a byte y no de golpe: FNV mezcla de ocho en ocho bits,
## y meterle los 64 de una vez dejaría los altos casi sin propagar.
static func _mezclar_entero(desde: int, valor: int) -> int:
	var mezcla := desde
	for i in 8:
		mezcla = (mezcla ^ ((valor >> (i * 8)) & 0xFF)) * _FNV_PRIMO
	return mezcla
