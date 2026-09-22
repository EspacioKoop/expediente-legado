## Qué hace el gato, sin saber cómo se dibuja.
##
## Un gato no se comporta según una variable que se le enseñe al jugador: se
## comporta, y de ahí se deduce cómo le has tratado (#92). Aquí no hay barras
## ni avisos — hay un bicho que se acerca o no se acerca.
##
## Los estados son observables. Añadir uno («mimos», «durmiendo junto a la
## cama») no toca el dibujo ni el estado de hambre de la jornada.
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

## Con hambre no abandona el cuenco, pero tampoco se congela: hace pequeños
## recorridos alrededor de él. El radio es suficientemente corto para que la
## señal siga siendo inequívoca desde la puerta.
const RADIO_HAMBRIENTO := 0.55
const VELOCIDAD_HAMBRIENTO := 0.45
const ESPERA_HAMBRIENTO := 0.8
const LLEGADA_HAMBRIENTO := 0.08

## Al alcanzar a alguien que lo ha cuidado no se limita a quedarse parado:
## durante un instante se frota contra él. Es puramente conductual — no cambia
## hambre, dinero ni afinidad — y después deja un margen antes de volver.
const DURACION_MIMOS := 1.8
const PAUSA_MIMOS := 5.0

## #787: las affordances de casa se traducen a estados observables. El catálogo
## decide qué significa cada sitio; la conducta solo conoce este vocabulario.
const ESTADO_POR_RUTINA := {
	"dormir": "durmiendo",
	"sentarse": "sentado",
	"observar": "observando",
	"esconderse": "escondido",
}
const ESPERA_POR_RUTINA := {
	"dormir": 6.0,
	"sentarse": 4.0,
	"observar": 4.5,
	"esconderse": 3.0,
}


## El gato al empezar el día.
static func nuevo(donde: Vector3) -> Dictionary:
	return {
		"pos": donde,
		"destino": donde,
		"espera": ESPERA_MINIMA,
		"estado": "parado",
		"rutina_destino": "",
		"mimos_resto": 0.0,
		"mimos_pausa": 0.0,
		"paso_hambriento": 0,
	}


## Compatibilidad del contrato: un sitio histórico puede seguir siendo Vector3,
## mientras que uno nuevo declara {"pos": Vector3, "rutina": "..."}.
static func posicion_sitio(sitio: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if sitio is Vector3:
		return sitio
	if sitio is Dictionary:
		var pos: Variant = sitio.get("pos", fallback)
		if pos is Vector3:
			return pos
	return fallback


static func rutina_sitio(sitio: Variant) -> String:
	if sitio is Dictionary:
		return String(sitio.get("rutina", ""))
	return ""


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
	gato["mimos_pausa"] = maxf(0.0, float(gato.get("mimos_pausa", 0.0)) - delta)

	# Con hambre, el cuenco. Es lo único que le importa y es lo que se ve desde
	# la puerta sin que nadie lo diga. Tiene prioridad incluso sobre los mimos:
	# la jornada sigue siendo la única fuente de verdad del hambre.
	if desconfia:
		return _avanzar_hambriento(gato, posicion_sitio(sitios[0], pos), delta)
	elif gato["estado"] == "hambriento":
		# Al comer se nota en el acto: no arrastra durante varios segundos la
		# postura de hambre mientras la jornada ya dice otra cosa.
		gato["estado"] = "parado"
		gato["espera"] = 0.0
		gato["paso_hambriento"] = 0
	elif gato["estado"] == "mimos":
		gato["mimos_resto"] = maxf(0.0, float(gato.get("mimos_resto", 0.0)) - delta)
		gato["destino"] = pos
		gato["rutina_destino"] = ""
		if gato["mimos_resto"] > 0.0:
			return gato
		gato["estado"] = "parado"
		gato["espera"] = ESPERA_MINIMA
		gato["mimos_pausa"] = PAUSA_MIMOS
		return gato
	elif (
		hambre == 0
		and gato["mimos_pausa"] <= 0.0
		and not ESTADO_POR_RUTINA.values().has(String(gato["estado"]))
	):
		var distancia_jugador := Vector3(pos.x - jugador.x, 0, pos.z - jugador.z).length()
		if gato["estado"] == "viene" or distancia_jugador < CERCA * 2.0:
			# Mientras viene, el destino se actualiza: sigue a una persona, no al
			# punto del suelo donde estaba cuando la vio.
			gato["destino"] = jugador
			gato["rutina_destino"] = ""
			gato["estado"] = "viene"

	var hacia: Vector3 = gato["destino"]
	var falta := Vector3(hacia.x - pos.x, 0, hacia.z - pos.z)
	if falta.length() > 0.35:
		var paso := minf(VELOCIDAD * delta, falta.length())
		gato["pos"] = pos + falta.normalized() * paso
		if gato["estado"] != "viene" and gato["estado"] != "hambriento":
			gato["estado"] = "anda"
		return gato

	# Si venía hacia el jugador y ya lo ha alcanzado, no convierte el final de
	# la ruta en otro «parado»: se frota contra él durante un instante. Eso es
	# una interacción visible nueva, pero no concede ni consume nada.
	if gato["estado"] == "viene":
		gato["estado"] = "mimos"
		gato["mimos_resto"] = DURACION_MIMOS
		gato["destino"] = pos
		gato["rutina_destino"] = ""
		return gato

	# Llegar a una affordance cambia la postura durante un rato. Un Vector3
	# histórico no declara rutina y conserva exactamente el viejo «parado».
	if gato["estado"] == "anda" or gato["estado"] == "parado":
		_aplicar_rutina(gato)

	# Ha llegado. Espera, y luego elige otro sitio — salvo que esté esperando
	# junto al cuenco con hambre, que ahí se queda.
	gato["espera"] -= delta
	if gato["espera"] > 0.0 or desconfia:
		return gato

	gato["espera"] = randf_range(ESPERA_MINIMA, ESPERA_MAXIMA)
	var sitio: Variant = sitios[randi() % sitios.size()]
	gato["destino"] = posicion_sitio(sitio, pos)
	gato["rutina_destino"] = rutina_sitio(sitio)
	var destino_elegido: Vector3 = gato["destino"]
	if destino_elegido.distance_to(pos) > 0.35:
		gato["estado"] = "anda"
	else:
		_aplicar_rutina(gato)
	return gato


static func _avanzar_hambriento(
	gato: Dictionary, cuenco: Vector3, delta: float
) -> Dictionary:
	var pos: Vector3 = gato["pos"]
	var primera_vez := String(gato.get("estado", "")) != "hambriento"
	gato["estado"] = "hambriento"
	gato["mimos_resto"] = 0.0
	gato["rutina_destino"] = ""

	if primera_vez:
		gato["destino"] = cuenco
		gato["espera"] = 0.0

	var destino: Vector3 = gato.get("destino", cuenco)
	var desde_cuenco := Vector3(pos.x - cuenco.x, 0, pos.z - cuenco.z)
	var destino_desde_cuenco := Vector3(destino.x - cuenco.x, 0, destino.z - cuenco.z)
	if (
		desde_cuenco.length() > RADIO_HAMBRIENTO
		or destino_desde_cuenco.length() > RADIO_HAMBRIENTO
	):
		gato["destino"] = cuenco
		gato["espera"] = 0.0
		destino = cuenco

	var falta := Vector3(destino.x - pos.x, 0, destino.z - pos.z)
	if falta.length() <= LLEGADA_HAMBRIENTO:
		gato["espera"] = float(gato.get("espera", 0.0)) - delta
		if gato["espera"] > 0.0:
			return gato
		var paso_cuenco := int(gato.get("paso_hambriento", 0))
		gato["destino"] = _punto_hambriento(cuenco, paso_cuenco)
		gato["paso_hambriento"] = paso_cuenco + 1
		gato["espera"] = ESPERA_HAMBRIENTO
		destino = gato["destino"]
		falta = Vector3(destino.x - pos.x, 0, destino.z - pos.z)

	if falta.length() > 0.0:
		var paso := minf(VELOCIDAD_HAMBRIENTO * delta, falta.length())
		gato["pos"] = pos + falta.normalized() * paso
	return gato


static func _punto_hambriento(cuenco: Vector3, paso: int) -> Vector3:
	match paso % 4:
		0:
			return cuenco + Vector3(RADIO_HAMBRIENTO, 0, 0)
		1:
			return cuenco + Vector3(0, 0, RADIO_HAMBRIENTO)
		2:
			return cuenco + Vector3(-RADIO_HAMBRIENTO, 0, 0)
		3:
			return cuenco + Vector3(0, 0, -RADIO_HAMBRIENTO)
	return cuenco


static func _aplicar_rutina(gato: Dictionary) -> void:
	var rutina := String(gato.get("rutina_destino", ""))
	var estado_rutina := String(ESTADO_POR_RUTINA.get(rutina, ""))
	if estado_rutina.is_empty():
		if gato["estado"] == "anda":
			gato["estado"] = "parado"
		return
	gato["estado"] = estado_rutina
	gato["espera"] = float(ESPERA_POR_RUTINA.get(rutina, ESPERA_MINIMA))


## Si está lo bastante cerca para que se le pueda dar de comer.
static func al_alcance(gato: Dictionary, jugador: Vector3) -> bool:
	return Vector3(gato["pos"].x - jugador.x, 0, gato["pos"].z - jugador.z).length() < CERCA
