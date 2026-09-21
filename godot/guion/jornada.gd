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

## #963: el reloj laboral es estado de Jornada, no tiempo real. Solo avanza
## cuando ocurre una acción significativa o una transición de fase, de modo que
## observar, leer texto o quedarse quieto nunca castiga al jugador.
const MINUTOS_INICIO_JORNADA := 9 * 60
const MINUTOS_FIN_OFICINA := 18 * 60
const MINUTOS_LLEGADA_CASA := 19 * 60
const MINUTOS_INICIO_SUENO := 23 * 60
const MINUTOS_POR_ACCION := 150
const MINUTOS_DIA := 24 * 60

## Primer catálogo de disponibilidad. Son ventanas ambientales/optativas: ningún
## consumidor debe usarlas para bloquear progreso principal.
const HORARIOS_SERVICIOS := {
	"archivo_fisico": {"desde": 9 * 60, "hasta": 14 * 60},
	"cafeteria": {"desde": 10 * 60, "hasta": 16 * 60},
	"jefe": {"desde": 9 * 60, "hasta": 13 * 60},
	"limpieza": {"desde": 17 * 60, "hasta": 20 * 60},
}

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

## Tope duro de #93: como mucho una acción extra por jornada, sin importar
## cuántos consumibles de trabajo se posean. Sin este tope, un café que da
## acciones y unas acciones que dan dinero disparan la economía sin fin.
const BONUS_ACCIONES_MAX_POR_DIA := 1

## Lo que cuesta el café. Convierte dinero en tiempo, pero solo hasta el tope:
## comprar un segundo no da una segunda acción.
const PRECIO_CAFE := 12

## Días seguidos sin comer que aguanta el gato antes de irse. No se muere ni
## deja cadáver: un día no está. En este sistema las cosas no terminan, se
## traspapelan.
const PACIENCIA_GATO := 3

## Lo que cuesta una lata. Casi la mitad de lo que cuesta vivir un día, y por
## eso es una decisión y no un botón: en una racha mala, darle de comer se nota
## en lo que te queda.
const PRECIO_COMIDA_GATO := 10

## Lo que cuesta comer tú (#93). Por debajo del coste de vivir, que ya paga lo
## mínimo: comer de verdad es un extra, y compite con la lata del gato por el
## mismo dinero — ahí está la decisión, no en una barra de hambre.
const PRECIO_COMIDA_PROPIA := 15

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
		# Minutos desde medianoche. Se persiste para que guardar/cargar no cambie
		# la franja ambiental ni la disponibilidad de servicios.
		"hora_minutos": MINUTOS_INICIO_JORNADA,
		"dinero": 120,
		"cerrados_hoy": 0,
		# Señal factual para reconocimientos diegéticos: cuántas firmas del día
		# fueron precipitadas. Se reinicia al despertar y no concede nada por sí sola.
		"acusaciones_precipitadas_hoy": 0,
		"acciones": ACCIONES_POR_DIA,
		# Cuántas acciones extra ha dado ya el café hoy. Vive separado de
		# "acciones" para poder aplicar el tope sin depender de cuánto quede
		# por gastar.
		"acciones_bonus_hoy": 0,
		# El gato NO es estado de la vuelta: sobrevive a que te reasignen,
		# porque es tuyo y no del trabajo. Acaba siendo lo único cálido del
		# registro permanente, al lado de las cartas que recuerdas.
		"gato": {"presente": true, "dias_sin_comer": 0},
		# Comer tú es una compra aparte de la del gato: mismo dinero, dos
		# hambres. No lleva barra visible (#93): la cuenta es interna hasta
		# que #96 decida cómo se nota en la casa.
		"comida_propia": {"dias_sin_comer": 0},
		# Último vencimiento resuelto y cómo terminó. El estado textual conserva
		# un hecho real para que #96 pueda dejar su papel físico en casa.
		"alquiler":
		{
			"ultimo_resuelto": 0,
			"ultimo_estado": "",
			"pagados": 0,
			"impagos": 0,
		},
		# Lo inesperado se decide una vez por vida laboral. La misma semilla y
		# vuelta conservan el plan al recargar; al reasignar se genera otro.
		"imprevistos": Imprevistos.planificar(raiz, vuelta),
		# Lo leído hoy: es lo que alimenta el sueño de esta noche. Se vacía al
		# despertar, porque un sueño es de su día.
		"leido_hoy": [],
		# #162: hasta tres folios leídos que el jugador decide llevarse a la
		# noche. Vive en Jornada para que guardar/recargar conserve la misma
		# preparación y se borra al despertar o al empezar otra vida laboral.
		"seleccion_nocturna": [],
		# Tarjeta diaria del Bingo SIGA y su histórico de esta vida laboral.
		# Va en Jornada para usar el mismo guardado y reiniciarse al reasignar.
		"bingo_siga": {"actual": {}, "historial": []},
		# #156: progreso de la ronda opcional del día. Vacío hasta que una capa
		# física la abra; al vivir dentro de Jornada viaja con el guardado normal.
		"ronda_cierre": {},
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
	var sin_hora_laboral := not jornada.has("hora_minutos")
	var molde := nueva(raiz)
	for clave in molde:
		if not jornada.has(clave):
			jornada[clave] = molde[clave]
		elif typeof(molde[clave]) == TYPE_INT:
			jornada[clave] = int(jornada[clave])
	if sin_hora_laboral:
		jornada["hora_minutos"] = _hora_migrada(jornada)
	jornada["hora_minutos"] = clampi(
		int(jornada.get("hora_minutos", MINUTOS_INICIO_JORNADA)), 0, MINUTOS_DIA - 1
	)
	jornada["gato"]["dias_sin_comer"] = int(jornada["gato"].get("dias_sin_comer", 0))
	jornada["comida_propia"]["dias_sin_comer"] = int(
		jornada["comida_propia"].get("dias_sin_comer", 0)
	)
	jornada["acciones_bonus_hoy"] = int(jornada.get("acciones_bonus_hoy", 0))
	for clave in ["ultimo_resuelto", "pagados", "impagos"]:
		jornada["alquiler"][clave] = int(jornada["alquiler"].get(clave, 0))
	jornada["alquiler"]["ultimo_estado"] = String(jornada["alquiler"].get("ultimo_estado", ""))
	# Una jornada guardada antes de que existiera la semilla (#147) trae un
	# cero: se le pone la de la partida, y de ahí en adelante ya es
	# reproducible. Lo que NO se toca es su plantilla — los compañeros de esa
	# vuelta ya están puestos, y cambiarlos al actualizar el juego sería
	# vaciarle la oficina a quien va por el día quince.
	if int(jornada.get("raiz", 0)) == 0 and raiz != 0:
		jornada["raiz"] = raiz
	# Partida.nueva() construye primero una Jornada con raíz 0 y añade la
	# semilla después. Completar es el punto donde el plan de #93 ya puede
	# derivarse de la raíz real sin volver a sortear en cada carga.
	Imprevistos.completar(jornada)
	if jornada["fase"] == "sueño":
		# Solo las partidas anteriores al reloj necesitan recibir tiempo.
		if sin_reloj:
			if jornada["sueno_escenas"].is_empty():
				jornada["sueno_escenas"] = Sueno.noche(
					jornada["dia"],
					jornada["leido_hoy"],
					jornada["mapa"],
					int(jornada.get("raiz", 0)),
					SeleccionNocturna.opciones_sueno(jornada)
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
	avanzar_reloj(jornada, MINUTOS_POR_ACCION)
	return true


## Consulta cuánto costaría abrir este folio sin modificar la jornada. La UI
## usa exactamente la misma regla que el cobro: primera lectura nueva gratis,
## relectura del día gratis y las demás lecturas nuevas a una acción.
static func coste_lectura(jornada: Dictionary, folio: String) -> int:
	if jornada["leido_hoy"].has(folio):
		return 0
	if jornada["leido_hoy"].size() < DOCUMENTOS_GRATIS_POR_DIA:
		return 0
	return 1


## Abrir un documento nuevo tiene una franquicia diaria: la primera lectura
## nueva sale gratis. Releer nunca llega aquí desde el visor, pero se acepta de
## forma idempotente para que el contrato siga siendo seguro desde otros sitios.
static func gastar_lectura(jornada: Dictionary, folio: String) -> bool:
	if jornada["fase"] != "archivo":
		return false
	if coste_lectura(jornada, folio) == 0:
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
	sincronizar_reloj_fase(jornada, "trayecto")

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


## Comer tú, no el gato. La misma frontera: sin dinero no se come, y no se
## queda a deber. Compite por el mismo saldo que la lata, que es la decisión
## que pide #93.
static func comer(jornada: Dictionary, precio: int) -> bool:
	if not gastar(jornada, precio):
		return false
	jornada["comida_propia"]["dias_sin_comer"] = 0
	return true


## El café: convierte dinero en tiempo, pero con tope duro (#93). Solo en el
## archivo, que es donde se gastan las acciones que da. Pasado el tope de hoy,
## no cobra ni concede — no hay motivo para pagar por nada.
static func tomar_cafe(jornada: Dictionary, precio: int) -> bool:
	if jornada["fase"] != "archivo":
		return false
	if int(jornada.get("acciones_bonus_hoy", 0)) >= BONUS_ACCIONES_MAX_POR_DIA:
		return false
	if not gastar(jornada, precio):
		return false
	jornada["acciones"] += 1
	jornada["acciones_bonus_hoy"] = int(jornada.get("acciones_bonus_hoy", 0)) + 1
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
	jornada["alquiler"]["ultimo_estado"] = "pagado"
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
	jornada["alquiler"]["ultimo_estado"] = "impago"
	jornada["alquiler"]["impagos"] += 1
	return true


## Resuelve el imprevisto que toca hoy al cerrar la casa. Es un gasto que no se
## elige (#93): si cabe en el saldo se paga; si no, queda una consecuencia para
## que #96 la haga visible. Nunca se pide crédito ni se baja de cero.
static func resolver_imprevisto_del_dia(jornada: Dictionary) -> Dictionary:
	if jornada.get("fase", "") != "casa":
		return {}
	var evento := Imprevistos.pendiente(jornada)
	if evento.is_empty():
		return {}
	var coste := int(evento.get("coste", 0))
	var pagado := coste > 0 and gastar(jornada, coste)
	return Imprevistos.resolver(jornada, pagado)


## Devuelve la ronda del día, creándola una sola vez cuando la capa física la necesite.
##
## La ruta se deriva de los datos ya persistidos en Jornada. Recargar o volver a
## pedirla conserva exactamente el mismo progreso; un día nuevo empieza vacío.
static func asegurar_ronda_cierre(jornada: Dictionary, cunado_presente: bool = true) -> Dictionary:
	var actual = jornada.get("ronda_cierre", {})
	if actual is Dictionary and not actual.is_empty():
		if int(actual.get("dia", 0)) == int(jornada.get("dia", 1)):
			return actual
	var creada := RondaCierre.nueva(
		int(jornada.get("dia", 1)), int(jornada.get("raiz", 0)), cunado_presente
	)
	jornada["ronda_cierre"] = creada
	return creada


## Fija la memoria que se llevará a la noche (#162).
##
## Solo se prepara en casa y únicamente con folios realmente leídos hoy. La
## selección puede estar vacía y puede repetir un folio: tres huecos son tres
## recuerdos, no un conjunto. Si algo no cumple el contrato no se modifica la
## selección anterior.
static func preparar_sueno(jornada: Dictionary, seleccion: Array) -> bool:
	if String(jornada.get("fase", "")) != "casa":
		return false
	return SeleccionNocturna.establecer(jornada, seleccion)


## Dormir: cierra el día, cobra la vida y decide qué queda por la mañana.
##
## Devuelve lo que hay que contar al despertar. El gato que se va no se anuncia
## con un aviso: se nota porque no está, así que quien llame decide si lo dice.
static func dormir(jornada: Dictionary) -> Dictionary:
	if jornada["fase"] != "casa":
		return {}

	var imprevisto := resolver_imprevisto_del_dia(jornada)
	jornada["dinero"] = maxi(0, jornada["dinero"] - COSTE_DIARIO)

	var impago := resolver_impago_alquiler(jornada)

	var gato: Dictionary = jornada["gato"]
	var se_fue := false
	if gato["presente"]:
		gato["dias_sin_comer"] += 1
		if gato["dias_sin_comer"] > PACIENCIA_GATO:
			gato["presente"] = false
			se_fue = true
	jornada["comida_propia"]["dias_sin_comer"] += 1

	# Congela el Bingo cuando todas las consecuencias del día ya son definitivas,
	# pero antes de que el sueño/despertar pueda limpiar sus contadores.
	BingoSiga.cerrar_jornada(jornada)

	jornada["seleccion_nocturna"] = SeleccionNocturna.normalizar(
		jornada["leido_hoy"], jornada.get("seleccion_nocturna", [])
	)
	jornada["fase"] = "sueño"
	jornada["sueno_escenas"] = Sueno.noche(
		jornada["dia"],
		jornada["leido_hoy"],
		jornada["mapa"],
		int(jornada.get("raiz", 0)),
		SeleccionNocturna.opciones_sueno(jornada)
	)
	jornada["sueno_total"] = Sueno.segundos_de_noche(jornada["sueno_escenas"])
	jornada["sueno_resto"] = jornada["sueno_total"]
	jornada["mapa_anoche"] = jornada["mapa"].duplicate()
	return {
		"coste": COSTE_DIARIO,
		"dinero": jornada["dinero"],
		"gato_se_fue": se_fue,
		"alquiler_impago": impago,
		"imprevisto": imprevisto,
		"seleccion_nocturna": jornada["seleccion_nocturna"].duplicate(),
	}


## Despertar: día nuevo, contadores a cero y el sueño de anoche olvidado.
static func despertar(jornada: Dictionary) -> int:
	if jornada["fase"] != "sueño":
		return jornada["dia"]
	jornada["dia"] += 1
	jornada["fase"] = "archivo"
	jornada["cerrados_hoy"] = 0
	jornada["acusaciones_precipitadas_hoy"] = 0
	jornada["acciones"] = ACCIONES_POR_DIA
	jornada["acciones_bonus_hoy"] = 0
	jornada["hora_minutos"] = MINUTOS_INICIO_JORNADA
	jornada["leido_hoy"] = []
	jornada["seleccion_nocturna"] = []
	# La noche se acabó aunque queden escenas: despertar de golpe (#90) no
	# puede dejar media noche esperando a la siguiente.
	jornada["sueno_escenas"] = []
	jornada["sueno_resto"] = 0.0
	jornada["sueno_total"] = 0.0
	jornada["mapa_anoche"] = []
	jornada["ronda_cierre"] = {}
	return jornada["dia"]


## Hora laboral actual en minutos desde medianoche.
static func hora_minutos(jornada: Dictionary) -> int:
	return clampi(int(jornada.get("hora_minutos", MINUTOS_INICIO_JORNADA)), 0, MINUTOS_DIA - 1)


## Hora decimal para consumidores ambientales como #966.
static func hora_decimal(jornada: Dictionary) -> float:
	return float(hora_minutos(jornada)) / 60.0


## Franja estable y discreta; evita que cada consumidor invente sus propios cortes.
static func franja_horaria(jornada: Dictionary) -> String:
	var hora := hora_decimal(jornada)
	if hora < 7.0 or hora >= 19.0:
		return "noche"
	if hora < 11.0:
		return "manana"
	if hora < 15.0:
		return "mediodia"
	return "tarde"


## Disponibilidad optativa de un servicio conocido. Desconocido = no declarado,
## no "abierto por defecto": así un typo no materializa contenido fantasma.
static func servicio_disponible(jornada: Dictionary, servicio: String) -> bool:
	if not HORARIOS_SERVICIOS.has(servicio):
		return false
	var horario: Dictionary = HORARIOS_SERVICIOS[servicio]
	var ahora := hora_minutos(jornada)
	return ahora >= int(horario["desde"]) and ahora < int(horario["hasta"])


## Avanza el reloj sin poder retroceder ni saltar de día. No cambia fase,
## acciones, dinero ni progreso; por sí solo jamás expulsa al jugador.
static func avanzar_reloj(jornada: Dictionary, minutos: int) -> int:
	if minutos <= 0:
		return hora_minutos(jornada)
	jornada["hora_minutos"] = mini(MINUTOS_DIA - 1, hora_minutos(jornada) + minutos)
	return int(jornada["hora_minutos"])


## Las transiciones garantizan horas mínimas diegéticas. Si el jugador hizo
## horas extra no se rebobina el reloj.
static func sincronizar_reloj_fase(jornada: Dictionary, fase: String) -> int:
	var minimo := MINUTOS_INICIO_JORNADA
	match fase:
		"trayecto":
			minimo = MINUTOS_FIN_OFICINA
		"casa":
			minimo = MINUTOS_LLEGADA_CASA
		"sueño":
			minimo = MINUTOS_INICIO_SUENO
		_:
			minimo = MINUTOS_INICIO_JORNADA
	jornada["hora_minutos"] = maxi(hora_minutos(jornada), minimo)
	return int(jornada["hora_minutos"])


## Migración conservadora de guardados anteriores a #963. En archivo se infiere
## solo desde acciones base ya consumidas; café/bonos nunca hacen retroceder.
static func _hora_migrada(jornada: Dictionary) -> int:
	var fase := String(jornada.get("fase", "archivo"))
	if fase == "archivo":
		var restantes := clampi(int(jornada.get("acciones", ACCIONES_POR_DIA)), 0, ACCIONES_POR_DIA)
		var gastadas := ACCIONES_POR_DIA - restantes
		return MINUTOS_INICIO_JORNADA + gastadas * MINUTOS_POR_ACCION
	if fase == "trayecto":
		return MINUTOS_FIN_OFICINA
	if fase == "casa":
		return MINUTOS_LLEGADA_CASA
	return MINUTOS_INICIO_SUENO


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
