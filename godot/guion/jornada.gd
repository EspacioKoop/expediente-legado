## El día: la columna que faltaba.
##
## Hasta ahora una "vuelta" no era nada — el sistema te reasignaba por acumular
## fallos y empezabas otra, sin tiempo, sin jornada y sin vida fuera del
## archivo. La jornada le da cuerpo: una vuelta es **una vida laboral**, y las
## cartas que recuerdas de vueltas anteriores (#46) dejan de ser una regla rara
## para ser lo obvio — el sueño recuerda lo que el archivo olvidó.
##
## El ciclo es una máquina de estados y NADA más: qué se pinta en cada fase lo
## dice un catálogo, no un `if` con el nombre de una sala dentro del motor.
## Añadir una fase es una entrada más, no tocar esto.
class_name Jornada
extends RefCounted

## En orden. El día empieza en el archivo y termina soñando.
const FASES := ["archivo", "trayecto", "casa", "sueño"]

## Lo que se cobra por fichar la salida, haya pasado lo que haya pasado. La
## nómina no premia acertar: en este juego no hay sospechoso correcto, y pagar
## por acertar desmontaría la sátira entera.
const BASE_DIARIA := 40

## Lo que suma cada expediente cerrado ese día. Se cobra por CERRAR, no por
## cerrar bien: un expediente mal cerrado paga lo mismo, y el gato come de eso.
const POR_EXPEDIENTE := 60

## Lo que cuesta vivir un día, se haga lo que se haga. Sube desde 25, pero solo
## hasta 26: el día 10 hay que reservar además una acción para pagar el alquiler;
## con siete cierres, subirlo más haría imposible reunir los 700 sin trabajillos.
const COSTE_DIARIO := 26

## Tres acciones pagadas al día. La primera lectura nueva sale gratis; el día de
## alquiler una de estas acciones tiene que sobrevivir al archivo para pagar en
## el trayecto. Así el vencimiento llega mientras todavía queda trabajo por hacer.
const ACCIONES_POR_DIA := 3
const DOCUMENTOS_GRATIS_POR_DIA := 1

## Días seguidos sin comer que aguanta el gato antes de irse. No se muere ni
## deja cadáver: un día no está. En este sistema las cosas no terminan, se
## traspapelan.
const PACIENCIA_GATO := 3

## Lo que cuesta una lata. Casi la mitad de lo que cuesta vivir un día, y por
## eso es una decisión y no un botón: en una racha mala, darle de comer se nota
## en lo que te queda.
const PRECIO_COMIDA_GATO := 10

## El alquiler introduce el mes sin convertirlo en un contador separado del día.
## Se vence cada diez días y se paga manualmente en el trayecto (#83/#85).
const DIAS_POR_MES := 10
const PRECIO_ALQUILER := 700


## [param raiz] es la semilla de la partida (#147) y [param vuelta] el número
## de vida laboral. Juntas deciden lo que esta vuelta trae sorteado: la misma
## semilla da siempre la misma primera vuelta, y la segunda no se parece a la
## primera porque el índice cambia, no porque se haya vuelto a tirar.
static func nueva(raiz: int = 0, vuelta: int = 1) -> Dictionary:
	return {
		"dia": 1,
		# De dónde sale lo que se sortea en esta vida laboral. Viaja dentro de
		# la jornada para que nada de aquí tenga que ir a preguntarle a la
		# partida cada vez que quiere sortear algo.
		"raiz": raiz,
		"vuelta": vuelta,
		"fase": "archivo",
		"dinero": 120,
		"cerrados_hoy": 0,
		"acciones": ACCIONES_POR_DIA,
		# El gato NO es estado de la vuelta: sobrevive a que te reasignen,
		# porque es tuyo y no del trabajo. Acaba siendo lo único cálido del
		# registro permanente, al lado de las cartas que recuerdas.
		"gato": {"presente": true, "dias_sin_comer": 0},
		# Último vencimiento resuelto: pagado o registrado como impago.
		"alquiler": {"ultimo_resuelto": 0, "pagados": 0, "impagos": 0},
		# Lo leído hoy: es lo que alimenta el sueño de esta noche. Se vacía al
		# despertar, porque un sueño es de su día.
		"leido_hoy": [],
		# Las salas del sueño ya vistas. Es de la VUELTA y no de por vida
		# (#86): cada vida laboral sueña lo suyo, así que el mapa se lo lleva
		# el despido igual que el dinero — sin borrarlo en ningún sitio, porque
		# reiniciar una vuelta es volver a esto.
		"mapa": [],
		# Las escenas que quedan por recorrer de la noche en curso. Se van
		# gastando por delante, así que «cuántas quedan» y «cuál toca» son el
		# mismo dato y no pueden contradecirse.
		"sueno_escenas": [],
		# Lo que queda de noche, en segundos. La salida del sueño no se ve
		# (#90), así que hace falta algo que corte: un sitio del que no se sale
		# es un juego colgado.
		"sueno_resto": 0.0,
		# Referencia fija para el indicador: las salas pendientes se consumen,
		# pero salir de una sala no hace que la noche vuelva a empezar (#163).
		"sueno_total": 0.0,
		# El mapa tal y como estaba al dormirse. Si la noche se acaba sin haber
		# salido, se vuelve a él: **el mapa no crece esa noche**, que es un
		# castigo que es exactamente lo que perdiste — no llegaste.
		"mapa_anoche": [],
		# Con quién te toca compartir planta esta vida laboral. Ya no se sortea
		# con el azar global: se DERIVA de la semilla y de la vuelta, así que
		# los compañeros cambian cuando te reasignan y solo entonces — ni al
		# recargar, ni al reinstalar, ni en otra máquina.
		"plantilla": Azar.derivar_guardable(raiz, "companeros", [vuelta]),
	}


## Rellena lo que le falte a una jornada guardada.
##
## Una partida escrita por una versión anterior no trae las claves que esa
## versión no tenía —el mapa del sueño, el reloj de la noche—. Se completa
## con `nueva()` sin pisar lo que ya estaba: esto no reinicia días ni relojes.
static func completar(jornada: Dictionary, raiz: int = 0) -> Dictionary:
	# Hay que distinguir un reloj ausente de uno agotado ANTES de completar
	# el molde. Cargar cero segundos no debe conceder otra noche entera.
	var sin_reloj := not jornada.has("sueno_resto")
	var sin_total := not jornada.has("sueno_total")
	var molde := nueva(raiz)
	for clave in molde:
		if not jornada.has(clave):
			jornada[clave] = molde[clave]
		elif typeof(molde[clave]) == TYPE_INT:
			jornada[clave] = int(jornada[clave])
	jornada["gato"]["dias_sin_comer"] = int(jornada["gato"].get("dias_sin_comer", 0))
	for clave in ["ultimo_resuelto", "pagados", "impagos"]:
		jornada["alquiler"][clave] = int(jornada["alquiler"].get(clave, 0))
	# Una jornada guardada antes de que existiera la semilla (#147) trae un
	# cero: se le pone la de la partida, y de ahí en adelante ya es
	# reproducible. Lo que NO se toca es su plantilla — los compañeros de esa
	# vuelta ya están puestos, y cambiarlos al actualizar el juego sería
	# vaciarle la oficina a quien va por el día quince.
	if int(jornada.get("raiz", 0)) == 0 and raiz != 0:
		jornada["raiz"] = raiz
	if jornada["fase"] == "sueño":
		# Solo las partidas anteriores al reloj necesitan recibir tiempo.
		if sin_reloj:
			if jornada["sueno_escenas"].is_empty():
				jornada["sueno_escenas"] = Sueno.noche(
					jornada["dia"],
					jornada["leido_hoy"],
					jornada["mapa"],
					int(jornada.get("raiz", 0))
				)
			jornada["sueno_resto"] = Sueno.segundos_de_noche(jornada["sueno_escenas"])
			jornada["mapa_anoche"] = jornada["mapa"].duplicate()
		if sin_total:
			# El formato antiguo no conserva el itinerario completo. Se fija
			# una referencia con lo que queda sin inventar el total original
			# ni cambiar segundos, salas, semilla o mapa. Solo se hace una vez.
			jornada["sueno_total"] = maxf(
				jornada["sueno_resto"], Sueno.segundos_de_noche(jornada["sueno_escenas"])
			)
	return jornada


## Gasta una acción del día. Devuelve si se pudo: agotadas, en el archivo no se
## puede hacer nada más y hay que fichar.
static func gastar_accion(jornada: Dictionary) -> bool:
	if jornada["fase"] != "archivo" or jornada["acciones"] <= 0:
		return false
	jornada["acciones"] -= 1
	return true


## Abrir un documento nuevo tiene una franquicia diaria: la primera lectura
## nueva sale gratis. Releer nunca llega aquí desde el visor, pero se acepta de
## forma idempotente para que el contrato siga siendo seguro desde otros sitios.
static func gastar_lectura(jornada: Dictionary, folio: String) -> bool:
	if jornada["fase"] != "archivo":
		return false
	if jornada["leido_hoy"].has(folio):
		return true
	if jornada["leido_hoy"].size() < DOCUMENTOS_GRATIS_POR_DIA:
		return true
	return gastar_accion(jornada)


## Si ya no queda nada que hacer hoy. Quien pinte la oficina lo usa para decir
## que la jornada se acabó, en vez de dejar al jugador probando botones muertos.
static func jornada_agotada(jornada: Dictionary) -> bool:
	return jornada["acciones"] <= 0


## Ficha la salida: cobra y pasa al trayecto.
##
## Devuelve el desglose, porque la nómina hay que poder enseñarla — un número
## que cambia solo es indistinguible de un error.
static func fichar_salida(jornada: Dictionary) -> Dictionary:
	if jornada["fase"] != "archivo":
		return {}

	var cerrados: int = jornada["cerrados_hoy"]
	var bruto := BASE_DIARIA + POR_EXPEDIENTE * cerrados
	jornada["dinero"] += bruto
	jornada["fase"] = "trayecto"

	return {
		"base": BASE_DIARIA,
		"expedientes": cerrados,
		"por_expedientes": POR_EXPEDIENTE * cerrados,
		"bruto": bruto,
		"dinero": jornada["dinero"],
	}


## Gastar en algo. Devuelve si se pudo: sin dinero no hay compra, y eso es toda
## la economía. No hay deuda ni crédito porque un sistema como este no te
## fiaría nada.
static func gastar(jornada: Dictionary, importe: int) -> bool:
	if importe <= 0 or jornada["dinero"] < importe:
		return false
	jornada["dinero"] -= importe
	return true


## Dar de comer al gato. Es una compra como otra cualquiera, y por eso puede no
## poder hacerse: ahí está la decisión.
static func alimentar_gato(jornada: Dictionary, precio: int) -> bool:
	var gato: Dictionary = jornada["gato"]
	if not gato["presente"] or not gastar(jornada, precio):
		return false
	gato["dias_sin_comer"] = 0
	return true


## Día de vencimiento del alquiler. El calendario sale solo del día, no del azar.
static func alquiler_vencimiento(dia: int) -> int:
	return maxi(DIAS_POR_MES, int(ceil(float(dia) / DIAS_POR_MES)) * DIAS_POR_MES)


## Si el vencimiento actual ya se resolvió, no se vuelve a ofrecer ni cobrar.
static func alquiler_pendiente(jornada: Dictionary) -> bool:
	var vencimiento := alquiler_vencimiento(int(jornada.get("dia", 1)))
	return int(jornada["alquiler"].get("ultimo_resuelto", 0)) < vencimiento


## Pagar el alquiler en la fase de trayecto. El pago consume una acción y es
## idempotente: después de resolver el vencimiento, repetirlo no cobra nada.
static func pagar_alquiler(jornada: Dictionary) -> Dictionary:
	if jornada.get("fase", "") != "trayecto" or not alquiler_pendiente(jornada):
		return {}
	var vencimiento := alquiler_vencimiento(int(jornada["dia"]))
	if int(jornada["dia"]) != vencimiento or jornada["acciones"] <= 0:
		return {}
	if not gastar(jornada, PRECIO_ALQUILER):
		return {}
	jornada["acciones"] -= 1
	jornada["alquiler"]["ultimo_resuelto"] = vencimiento
	jornada["alquiler"]["pagados"] += 1
	return {
		"vencimiento": vencimiento,
		"importe": PRECIO_ALQUILER,
		"impago": false,
		"dinero": jornada["dinero"],
		"acciones": jornada["acciones"],
	}


## Cerrar el día de vencimiento sin pagar registra un único impago. No crea
## deuda ni saldo negativo: la consecuencia de vivienda la decide #84.
static func resolver_impago_alquiler(jornada: Dictionary) -> bool:
	var vencimiento := alquiler_vencimiento(int(jornada["dia"]))
	if int(jornada["dia"]) != vencimiento or not alquiler_pendiente(jornada):
		return false
	jornada["alquiler"]["ultimo_resuelto"] = vencimiento
	jornada["alquiler"]["impagos"] += 1
	return true


## Dormir: cierra el día, cobra la vida y decide qué queda por la mañana.
##
## Devuelve lo que hay que contar al despertar. El gato que se va no se anuncia
## con un aviso: se nota porque no está, así que quien llame decide si lo dice.
static func dormir(jornada: Dictionary) -> Dictionary:
	if jornada["fase"] != "casa":
		return {}

	jornada["dinero"] = maxi(0, jornada["dinero"] - COSTE_DIARIO)

	var impago := resolver_impago_alquiler(jornada)

	var gato: Dictionary = jornada["gato"]
	var se_fue := false
	if gato["presente"]:
		gato["dias_sin_comer"] += 1
		if gato["dias_sin_comer"] > PACIENCIA_GATO:
			gato["presente"] = false
			se_fue = true

	jornada["fase"] = "sueño"
	jornada["sueno_escenas"] = Sueno.noche(
		jornada["dia"], jornada["leido_hoy"], jornada["mapa"], int(jornada.get("raiz", 0))
	)
	jornada["sueno_total"] = Sueno.segundos_de_noche(jornada["sueno_escenas"])
	jornada["sueno_resto"] = jornada["sueno_total"]
	jornada["mapa_anoche"] = jornada["mapa"].duplicate()
	return {
		"coste": COSTE_DIARIO,
		"dinero": jornada["dinero"],
		"gato_se_fue": se_fue,
		"alquiler_impago": impago,
	}


## Despertar: día nuevo, contadores a cero y el sueño de anoche olvidado.
static func despertar(jornada: Dictionary) -> int:
	if jornada["fase"] != "sueño":
		return jornada["dia"]
	jornada["dia"] += 1
	jornada["fase"] = "archivo"
	jornada["cerrados_hoy"] = 0
	jornada["acciones"] = ACCIONES_POR_DIA
	jornada["leido_hoy"] = []
	# La noche se acabó aunque queden escenas: despertar de golpe (#90) no
	# puede dejar media noche esperando a la siguiente.
	jornada["sueno_escenas"] = []
	jornada["sueno_resto"] = 0.0
	jornada["sueno_total"] = 0.0
	jornada["mapa_anoche"] = []
	return jornada["dia"]


## Gasta noche. Devuelve si se ha acabado.
##
## El reloj corre en tiempo real y no en pasos: pararse a leer una pared cuesta
## noche igual que andar. Es duro con quien mira, y es lo que hace que el sueño
## tenga prisa cuando el día no la tiene.
static func gastar_sueno(jornada: Dictionary, segundos: float) -> bool:
	if jornada["fase"] != "sueño":
		return false
	jornada["sueno_resto"] = maxf(0.0, jornada["sueno_resto"] - segundos)
	return jornada["sueno_resto"] <= 0.0


## Cuánto queda de noche, de 1 a 0. Para enseñarlo SIN un número: un reloj con
## cifras dentro de un sueño es una interfaz de videojuego dentro de la parte
## del juego que menos tiene que parecerlo.
static func noche_restante(jornada: Dictionary) -> float:
	var total: float = jornada.get("sueno_total", 0.0)
	if total <= 0.0:
		return 0.0
	return clampf(jornada["sueno_resto"] / total, 0.0, 1.0)


## Despertar de golpe, sin haber encontrado la salida.
##
## Empieza el día igual que despertar bien —no hay deuda ni castigo escondido—
## y se lleva por delante UNA cosa: las salas de esta noche no quedan en el
## mapa. Es el castigo más justo que hay, porque es lo que de verdad pasó.
static func despertar_de_golpe(jornada: Dictionary) -> int:
	if jornada["fase"] != "sueño":
		return jornada["dia"]
	var antes: Array = jornada["mapa_anoche"].duplicate()
	var dia := despertar(jornada)
	jornada["mapa"] = antes
	return dia


## Anota un documento leído hoy. Es lo que el sueño de esta noche tendrá para
## deformar: sin esto el sueño sería ruido, y con esto es el archivo devuelto
## del revés.
static func anotar_lectura(jornada: Dictionary, folio: String) -> void:
	if not folio.is_empty() and not jornada["leido_hoy"].has(folio):
		jornada["leido_hoy"].append(folio)


## Qué fase viene después. Vive aquí y no repartido por las pantallas: el orden
## del día es una sola cosa y se cambia en un solo sitio.
static func siguiente_fase(fase: String) -> String:
	var i := FASES.find(fase)
	if i < 0:
		return FASES[0]
	return FASES[(i + 1) % FASES.size()]


## Te reasignan: empieza otra vida laboral.
##
## Se va el día, el dinero y lo leído — otra persona en el mismo puesto. **El
## gato se queda**, tal y como lo dejaste: si lo cuidaste sigue ahí, y si se fue
## no vuelve. Es la única continuidad que no pasa por el archivo, y por eso es
## la que más dice de cómo llevaste la vuelta anterior.
static func reiniciar_vuelta(jornada: Dictionary) -> Dictionary:
	var gato: Dictionary = jornada["gato"]
	# La raíz es de la PARTIDA y sobrevive al despido; el contador de vuelta
	# avanza, que es lo que hace que la planta 4 se llene de otra gente.
	var nueva_vida := nueva(int(jornada.get("raiz", 0)), int(jornada.get("vuelta", 1)) + 1)
	nueva_vida["gato"] = gato
	for clave in nueva_vida:
		jornada[clave] = nueva_vida[clave]
	return jornada
