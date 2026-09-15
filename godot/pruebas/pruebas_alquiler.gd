## Contrato económico del alquiler (#83/#85).
##
## Aquí se prueba el calendario y el registro puro. La ventanilla visual y la
## consecuencia de perder la casa pertenecen a #85 y #84 respectivamente.
class_name PruebasAlquiler
extends RefCounted


static func todo(comprobar: Callable) -> void:
	comprobar.call("la jornada calibrada tiene tres acciones", Jornada.ACCIONES_POR_DIA, 3)
	comprobar.call(
		"la primera lectura nueva del día es gratis", Jornada.DOCUMENTOS_GRATIS_POR_DIA, 1
	)
	comprobar.call("vivir cuesta veintiséis al día", Jornada.COSTE_DIARIO, 26)
	comprobar.call("el mes SIGA dura diez días", Jornada.DIAS_POR_MES, 10)
	comprobar.call("el alquiler cuesta setecientos", Jornada.PRECIO_ALQUILER, 700)

	var lectura := Jornada.nueva()
	var acciones_inicio: int = lectura["acciones"]
	comprobar.call(
		"la primera lectura se puede abrir", Jornada.gastar_lectura(lectura, "DOC-A"), true
	)
	comprobar.call("la primera lectura no gasta acción", lectura["acciones"], acciones_inicio)
	Jornada.anotar_lectura(lectura, "DOC-A")
	comprobar.call(
		"la segunda lectura se puede abrir", Jornada.gastar_lectura(lectura, "DOC-B"), true
	)
	comprobar.call("la segunda lectura ya gasta acción", lectura["acciones"], acciones_inicio - 1)
	Jornada.anotar_lectura(lectura, "DOC-B")
	var acciones_tras_dos: int = lectura["acciones"]
	comprobar.call("releer sigue permitido", Jornada.gastar_lectura(lectura, "DOC-A"), true)
	comprobar.call("releer no vuelve a gastar", lectura["acciones"], acciones_tras_dos)

	# Benchmark de #83: 32 documentos + 8 firmas = 40 operaciones. En diez días
	# hay 30 acciones pagadas y 10 lecturas gratuitas, pero el día diez UNA de
	# las acciones pagadas se reserva para la ventanilla. Por tanto el alquiler
	# aparece cuando quedan exactamente una operación y un cierre por hacer.
	var capacidad_trabajo_hasta_alquiler := (
		Jornada.ACCIONES_POR_DIA * Jornada.DIAS_POR_MES
		+ Jornada.DOCUMENTOS_GRATIS_POR_DIA * Jornada.DIAS_POR_MES
		- 1
	)
	comprobar.call(
		"el alquiler llega antes de completar las cuarenta operaciones",
		capacidad_trabajo_hasta_alquiler,
		39
	)

	# Con 39 operaciones solo pueden haberse firmado siete de los ocho casos.
	# Saldo antes de pagar el primer alquiler: 120 iniciales + diez bases + siete
	# cierres - nueve noches de coste. El día diez aún no ha dormido.
	var saldo_antes_alquiler := (
		120
		+ Jornada.BASE_DIARIA * Jornada.DIAS_POR_MES
		+ Jornada.POR_EXPEDIENTE * 7
		- Jornada.COSTE_DIARIO * (Jornada.DIAS_POR_MES - 1)
	)
	comprobar.call(
		"el primer alquiler sigue siendo pagable",
		saldo_antes_alquiler >= Jornada.PRECIO_ALQUILER,
		true
	)
	var margen := saldo_antes_alquiler - Jornada.PRECIO_ALQUILER
	comprobar.call("el margen del primer alquiler queda en seis", margen, 6)
	comprobar.call(
		"el alquiler deja menos margen que un mes de comida del gato",
		margen < Jornada.PRECIO_COMIDA_GATO * Jornada.DIAS_POR_MES,
		true
	)

	var pago := Jornada.nueva()
	pago["dia"] = 10
	pago["fase"] = "trayecto"
	pago["dinero"] = Jornada.PRECIO_ALQUILER + 100
	var acciones_antes: int = pago["acciones"]
	var resultado := Jornada.pagar_alquiler(pago)

	comprobar.call("el primer vencimiento cae en el día diez", Jornada.alquiler_vencimiento(1), 10)
	comprobar.call(
		"pagar el alquiler descuenta el importe y una acción",
		[resultado["importe"], pago["dinero"], pago["acciones"]],
		[Jornada.PRECIO_ALQUILER, 100, acciones_antes - 1]
	)
	comprobar.call("el pago queda registrado", pago["alquiler"]["pagados"], 1)
	comprobar.call("el vencimiento queda resuelto", Jornada.alquiler_pendiente(pago), false)

	var dinero_despues: int = pago["dinero"]
	var acciones_despues: int = pago["acciones"]
	comprobar.call("repetir el pago no cobra dos veces", Jornada.pagar_alquiler(pago), {})
	comprobar.call(
		"repetir conserva saldo y acciones",
		[pago["dinero"], pago["acciones"]],
		[dinero_despues, acciones_despues]
	)

	var siguiente := Jornada.nueva()
	siguiente["dia"] = 20
	siguiente["fase"] = "trayecto"
	siguiente["dinero"] = Jornada.PRECIO_ALQUILER + 100
	siguiente["alquiler"]["ultimo_resuelto"] = 10
	comprobar.call(
		"el segundo vencimiento cae en el día veinte", Jornada.alquiler_vencimiento(20), 20
	)
	comprobar.call(
		"el siguiente vencimiento sigue pendiente", Jornada.alquiler_pendiente(siguiente), true
	)
	comprobar.call(
		"el segundo pago también funciona", Jornada.pagar_alquiler(siguiente)["vencimiento"], 20
	)

	var impago := Jornada.nueva()
	impago["dia"] = 10
	impago["fase"] = "casa"
	var noche := Jornada.dormir(impago)
	comprobar.call("dormir sin pagar registra un impago", noche["alquiler_impago"], true)
	comprobar.call("el impago no crea deuda negativa", impago["dinero"] >= 0, true)
	comprobar.call("el impago se registra una sola vez", impago["alquiler"]["impagos"], 1)
	comprobar.call("la vivienda no cobra automáticamente", impago["alquiler"]["pagados"], 0)

	# --- Trabajillos de casa (#94) -------------------------------------------
	# Esta suite es de contratos puros. La composición de la capa `dia_*` se
	# comprueba estáticamente en Python para no construir aquí toda la cadena de
	# escena del día; eso puede arrancar procesos/nodos ajenos al contrato y
	# convirtió este test puro en un timeout de 120 s en CI.
	var trabajo := Jornada.nueva()
	trabajo["fase"] = "casa"
	var saldo_trabajo: int = trabajo["dinero"]
	var acciones_trabajo: int = trabajo["acciones"]
	var cobro := Trabajillos.hacer_transcripcion(trabajo)
	comprobar.call("la transcripción paga veinte", cobro["importe"], 20)
	comprobar.call(
		"el trabajillo suma dinero",
		trabajo["dinero"],
		saldo_trabajo + Trabajillos.PAGO_TRANSCRIPCION
	)
	comprobar.call(
		"el trabajillo no consume acciones del archivo", trabajo["acciones"], acciones_trabajo
	)
	var tras_cobro: int = trabajo["dinero"]
	comprobar.call(
		"el trabajillo solo se cobra una vez por noche",
		Trabajillos.hacer_transcripcion(trabajo),
		{}
	)
	comprobar.call("repetir no imprime dinero", trabajo["dinero"], tras_cobro)
	comprobar.call(
		"trabajar recorta una escena del sueño",
		Trabajillos.escenas_de_sueno(trabajo, Sueno.ESCENAS_POR_NOCHE),
		Sueno.ESCENAS_POR_NOCHE - 1
	)

	# Antes del primer alquiler solo caben nueve noches de trabajo: el día diez
	# se paga en el trayecto, antes de llegar a casa. Incluso haciendo todos los
	# lotes, el salario base sin cerrar expedientes no alcanza los 700.
	var saldo_sin_cierres_con_trabajillos := (
		120
		+ Jornada.BASE_DIARIA * Jornada.DIAS_POR_MES
		+ Trabajillos.PAGO_TRANSCRIPCION * (Jornada.DIAS_POR_MES - 1)
		- Jornada.COSTE_DIARIO * (Jornada.DIAS_POR_MES - 1)
	)
	comprobar.call(
		"los trabajillos no sustituyen resolver expedientes para pagar alquiler",
		saldo_sin_cierres_con_trabajillos < Jornada.PRECIO_ALQUILER,
		true
	)

	# --- El café: tope duro de una acción extra por jornada (#93) ------------
	# El riesgo del diseño es un consumible que dé acciones y unas acciones que
	# den dinero: sin tope, la economía se dispara. Se prueba el tope, no solo
	# el efecto.
	comprobar.call(
		"el café cuesta menos que vivir un día", Jornada.PRECIO_CAFE < Jornada.COSTE_DIARIO, true
	)

	var oficina := Jornada.nueva()
	var acciones_sin_cafe: int = oficina["acciones"]
	var saldo_sin_cafe: int = oficina["dinero"]
	comprobar.call(
		"el primer café da una acción y cobra",
		[Jornada.tomar_cafe(oficina, Jornada.PRECIO_CAFE), oficina["acciones"], oficina["dinero"]],
		[true, acciones_sin_cafe + 1, saldo_sin_cafe - Jornada.PRECIO_CAFE]
	)
	var saldo_tras_uno: int = oficina["dinero"]
	comprobar.call(
		"el segundo café del mismo día no da nada ni cobra",
		[Jornada.tomar_cafe(oficina, Jornada.PRECIO_CAFE), oficina["acciones"], oficina["dinero"]],
		[false, acciones_sin_cafe + 1, saldo_tras_uno]
	)

	var sin_dinero := Jornada.nueva()
	sin_dinero["dinero"] = Jornada.PRECIO_CAFE - 1
	comprobar.call(
		"sin dinero no hay café ni acción de más",
		Jornada.tomar_cafe(sin_dinero, Jornada.PRECIO_CAFE),
		false
	)

	var fuera_de_horario := Jornada.nueva()
	fuera_de_horario["fase"] = "trayecto"
	comprobar.call(
		"el café solo se toma en el archivo, que es donde se usa la acción",
		Jornada.tomar_cafe(fuera_de_horario, Jornada.PRECIO_CAFE),
		false
	)

	var otro_dia := Jornada.nueva()
	Jornada.tomar_cafe(otro_dia, Jornada.PRECIO_CAFE)
	otro_dia["fase"] = "sueño"
	Jornada.despertar(otro_dia)
	comprobar.call(
		"un día nuevo resetea el tope del café",
		Jornada.tomar_cafe(otro_dia, Jornada.PRECIO_CAFE),
		true
	)
