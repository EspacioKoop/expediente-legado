## Una cinemática es una lista de planos declarada. Nada más.
##
## El medio lo elige cada momento —un careo pide 3D, un sello pide una mesa en
## 2D— y **no hay regla** que diga cuál va dónde. Lo que evita que diez
## cinemáticas parezcan diez juegos distintos no es una regla: es que todas se
## declaran igual y las reproduce el mismo sitio (`cinematica_app.gd`), que
## aporta lo que las hace reconocerse entre sí — mismo ritmo, mismo rótulo,
## mismo salto, mismo acortado.
##
## **Un plano común** lleva `tipo` (`3d` | `2d`), `segundos`, y opcionalmente
## `rotulo` y `voz`. Lo demás lo pide su tipo:
##
## - `3d`: `camara` y `mira`, en coordenadas del mundo de la escena.
## - `2d`: `figura` —una lista de rectángulos con color, no un nombre— más
##   `desde` y `hasta` para moverla. La figura va como DATOS y no como un
##   nombre a propósito: si el reproductor tuviera que saber qué es un "sello",
##   volveríamos a tener el nombre de una cosa concreta dentro del motor.
##
## Todas se saltan. Todas se repiten. En un juego de vueltas, un momento que no
## vuelve se pierde para siempre.
class_name Cinematica
extends RefCounted

const TIPOS := ["3d", "2d"]

## Cuánto se recorta cada plano por cada vez que ya se ha visto la cinemática.
## Las que más se repiten —el inicio del día, el sello— son las que más lo
## necesitan, y es comportamiento del reproductor y no de cada cinemática: un
## contador por cinemática se implementaría diez veces y divergiría.
const RECORTE_POR_VISTA := 0.3

## Por debajo de esto no baja un plano, por muy visto que esté.
const SUELO := 0.25

## Y el ÚLTIMO plano no baja de aquí. Es el remate: una cinemática muy vista
## puede quedarse en nada, pero no puede desaparecer sin avisar de que ha
## pasado algo.
const SUELO_REMATE := 0.6


## Resuelve las plantillas de los rótulos con los datos del momento
## (`{nombre}` en la declaración) y aplica el acortado por repetición.
##
## Devuelve copias: reproducir una cinemática no puede estropear la siguiente.
static func resolver(planos: Array, datos: Dictionary = {}, vistas: int = 0) -> Array:
	var rodaje := []
	for i in planos.size():
		var plano: Dictionary = planos[i].duplicate(true)
		# El rótulo y la voz se declaran por CLAVE de traducción y se rellenan
		# DESPUÉS: al revés, los huecos se sustituirían en la clave y ya no
		# habría clave que buscar.
		plano["rotulo"] = _rellenar(
			TranslationServer.translate(String(plano.get("rotulo", ""))), datos
		)
		plano["voz"] = _rellenar(TranslationServer.translate(String(plano.get("voz", ""))), datos)
		plano["segundos"] = (
			float(plano.get("segundos", 0.0)) * factor(vistas, i == planos.size() - 1)
		)
		rodaje.append(plano)
	return rodaje


## Cuánto dura un plano respecto a su duración declarada, según cuántas veces
## se haya visto ya la cinemática.
static func factor(vistas: int, es_remate: bool) -> float:
	var suelo := SUELO_REMATE if es_remate else SUELO
	return maxf(suelo, 1.0 - RECORTE_POR_VISTA * float(maxi(0, vistas)))


static func duracion(rodaje: Array) -> float:
	var total := 0.0
	for plano in rodaje:
		total += float(plano.get("segundos", 0.0))
	return total


## Los planos mal declarados revientan al construir el catálogo, no a mitad de
## una cinemática: un plano sin tipo o sin duración se quedaría clavado en
## pantalla y parecería un cuelgue.
static func validar(planos: Array) -> Array:
	var problemas := []
	if planos.is_empty():
		return ["sin planos"]
	for i in planos.size():
		var plano: Dictionary = planos[i]
		var tipo := String(plano.get("tipo", ""))
		if not TIPOS.has(tipo):
			problemas.append("plano %d: tipo desconocido '%s'" % [i, tipo])
		if float(plano.get("segundos", 0.0)) <= 0.0:
			problemas.append("plano %d: sin duración" % i)
		if tipo == "3d":
			for campo in ["camara", "mira"]:
				if not plano.has(campo):
					problemas.append("plano %d: 3d sin %s" % [i, campo])
		elif tipo == "2d":
			if (
				not plano.has("figura")
				or not (plano["figura"] is Array)
				or plano["figura"].is_empty()
			):
				problemas.append("plano %d: 2d sin figura" % i)
	return problemas


## Cuántas veces se ha visto ya una cinemática en esta partida.
static func vistas_de(estado: Dictionary, id: String) -> int:
	return int(estado.get("cinematicas_vistas", {}).get(id, 0))


## Anota que se ha visto una vez más. Se llama al TERMINAR o al saltar: saltarla
## cuenta, porque quien la salta ya la conoce.
static func anotar_vista(estado: Dictionary, id: String) -> int:
	var vistas: Dictionary = estado.get("cinematicas_vistas", {})
	vistas[id] = vistas_de(estado, id) + 1
	estado["cinematicas_vistas"] = vistas
	return vistas[id]


static func _rellenar(texto: String, datos: Dictionary) -> String:
	var salida := texto
	for clave in datos:
		salida = salida.replace("{%s}" % clave, str(datos[clave]))
	return salida
