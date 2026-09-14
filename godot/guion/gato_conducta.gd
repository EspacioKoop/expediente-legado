## Qué hace el gato, sin saber cómo se dibuja.
##
## Un gato no se comporta según una variable que se le enseñe al jugador: se
## comporta, y de ahí se deduce cómo le has tratado (#92). Aquí no hay barras
## ni avisos — hay un bicho que se acerca o no se acerca.
##
## Tres estados y nada más. Añadir uno cuarto («jugando», «durmiendo en el
## alféizar») es una entrada más y no toca el dibujo.
class_name GatoConducta
extends RefCounted

## Lo que anda un gato. Menos que una persona (2,6) y a rachas, que es lo que
## lo hace un gato y no un perro.
const VELOCIDAD := 1.35

## A partir de cuántos días sin comer deja de acercarse. Es UNO, no los tres de
## `Jornada.PACIENCIA_GATO`: mucho antes de irse ya no viene, y esa es toda la
## señal que se da. Quien lo note a tiempo puede arreglarlo.
const DIAS_PARA_DESCONFIAR := 1

## Cuánto se para entre paseo y paseo, en segundos.
const ESPERA_MINIMA := 1.2
const ESPERA_MAXIMA := 4.5

## A qué distancia del jugador reacciona.
const CERCA := 2.2


## El gato al empezar el día.
static func nuevo(donde: Vector3) -> Dictionary:
	return {"pos": donde, "destino": donde, "espera": ESPERA_MINIMA, "estado": "parado"}


## Un paso de tiempo. [param sitios] son los sitios por los que se mueve —el
## cuenco, la cama, un rincón—, y los declara la casa: este módulo no sabe qué
## hay en ella.
##
## [param hambre] son los días que lleva sin comer y [param jugador] dónde
## estás tú. Con hambre se queda junto al cuenco, que es el primer sitio de la
## lista, y no se acerca a nadie.
static func avanzar(
	gato: Dictionary, sitios: Array, hambre: int, jugador: Vector3, delta: float
) -> Dictionary:
	if sitios.is_empty():
		return gato

	var desconfia := hambre > DIAS_PARA_DESCONFIAR
	var pos: Vector3 = gato["pos"]

	# Con hambre, el cuenco. Es lo único que le importa y es lo que se ve desde
	# la puerta sin que nadie lo diga.
	if desconfia:
		gato["destino"] = sitios[0]
		gato["estado"] = "hambriento"
	elif gato["estado"] != "viene" and pos.distance_to(jugador) < CERCA * 2.0 and hambre == 0:
		# Bien comido, se acerca. Es la única recompensa que da el juego por
		# cuidarlo, y no lleva ningún número.
		gato["destino"] = jugador
		gato["estado"] = "viene"

	var hacia: Vector3 = gato["destino"]
	var falta := Vector3(hacia.x - pos.x, 0, hacia.z - pos.z)
	if falta.length() > 0.35:
		gato["pos"] = pos + falta.normalized() * VELOCIDAD * delta
		if gato["estado"] == "parado":
			gato["estado"] = "anda"
		return gato

	# Ha llegado. Espera, y luego elige otro sitio — salvo que esté esperando
	# junto al cuenco, que ahí se queda.
	gato["espera"] -= delta
	if gato["estado"] == "anda" or gato["estado"] == "viene":
		gato["estado"] = "parado"
	if gato["espera"] > 0.0 or desconfia:
		return gato

	gato["espera"] = randf_range(ESPERA_MINIMA, ESPERA_MAXIMA)
	gato["destino"] = sitios[randi() % sitios.size()]
	return gato


## Si está lo bastante cerca para que se le pueda dar de comer.
static func al_alcance(gato: Dictionary, jugador: Vector3) -> bool:
	return Vector3(gato["pos"].x - jugador.x, 0, gato["pos"].z - jugador.z).length() < CERCA
