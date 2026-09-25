## Dónde vive una partida.
##
## En el original el estado estaba en `localStorage`, que es un almacén que no
## se corrompe a medias y del que no se puede perder el fichero. Un fichero sí,
## así que este módulo no es un port de `cargarEstado`/`guardarEstado`: es lo
## mismo hecho con las precauciones que un fichero exige.
##
## Tres decisiones que el original no tenía que tomar:
##
## 1. **La escritura es atómica.** Se escribe a un temporal y se renombra
##    encima. Renombrar en el mismo sistema de ficheros no deja estados
##    intermedios, así que un cierre a destiempo deja la partida anterior
##    entera en vez de media partida nueva.
## 2. **Una partida ilegible NO se pisa.** El original hacía `catch {}` y
##    seguía con el estado vacío, o sea que el primer guardado posterior
##    borraba para siempre lo que hubiera. Aquí se aparta con extensión
##    `.roto` y se empieza de cero al lado: si el fallo era del disco o de una
##    versión futura, lo que había sigue ahí para recuperarlo.
## 3. **El formato va versionado.** El original resolvía los ids renombrados
##    con una tabla de alias, que funciona pero no dice desde qué versión.
##    El alias se conserva (los ids ya renombrados siguen renombrados), pero
##    ahora hay un número al que colgar la próxima migración.
##
## Lo que NO se guarda es el contenido, solo ids y estado. Los documentos viven
## en `casos.json` y los títulos de logros y cartas en `prometeo.json`, así que
## reescribir una cartela o la descripción de un logro no invalida ninguna
## partida — y no deja partidas viejas mostrando el texto antiguo, que es lo
## que pasaría si el guardado se llevara una copia.
class_name Partida
extends RefCounted

const RUTA := "user://partida.json"
const CATALOGOS := "res://datos/prometeo.json"

## Se sube cuando un cambio de formato necesite migración. La partida que
## llegue con una versión MAYOR que esta es de un futuro que este binario no
## entiende, y se aparta en vez de interpretarse a medias.
const VERSION := 1

const VIDA_MAXIMA := 3

## Ids que cambiaron de nombre: clave la actual, valor la antigua.
const ALIAS := {}

## JSON no distingue un entero de un decimal, así que todo número vuelve como
## coma flotante: una racha de 4 se relee como 4.0, se muestra como "4.0" y
## deja de ser igual a 4 en cualquier comparación. Es el mismo fallo que puso
## "Expediente 1999.0" en la barra de título, y por eso no se arregla en el
## sitio donde se ve sino aquí, que es por donde entra.
const CAMPOS_ENTEROS := ["vida", "coliseo_racha_mejor", "semilla"]

## Los campos de estado de cada catálogo: lo único suyo que la partida guarda.
## Todo lo demás (título, descripción, requisito) es contenido y se vuelve a
## leer de `prometeo.json` en cada arranque.
const ESTADO_LOGRO := ["desbloqueado"]
const ESTADO_CARTA := ["recogida", "gastada"]

var estado: Dictionary = {}

## Cierto desde que un guardado falla hasta que otro sale bien. Lo que hay en
## memoria SIGUE siendo la partida buena —lo que se quedó atrás es el disco—,
## así que la pantalla que lo mire puede avisar y ofrecer reintentar en vez de
## tirar el día del jugador.
var guardado_pendiente := false

## Lo último que impidió guardar, para poder decir qué pasó y no solo que algo
## pasó. Vacío mientras no haya nada pendiente.
var fallo_de_guardado := ""


## Una partida recién empezada, con los catálogos en su estado de serie.
static func nueva() -> Dictionary:
	var catalogos := _leer_json(CATALOGOS)
	return {
		"version": VERSION,
		# La raíz del azar de esta partida (#147). Va en el guardado porque lo
		# que define una partida no es solo lo que has hecho, sino con qué
		# sorteo te tocó hacerlo: sin esto, recargar sería volver a sortear.
		# Una partida vieja que no la traiga recibe una aquí al cargarse, y a
		# partir de ese momento ya es reproducible.
		"semilla": Azar.raiz_nueva(),
		"pistas_descubiertas": [],
		"sellos_obtenidos": [],
		# #149: dos lecturas del mismo catálogo. La total sobrevive a una
		# reasignación; la de vuelta se vacía al empezar otra vida laboral.
		"anomalias_descubiertas": [],
		"anomalias_descubiertas_vuelta": [],
		"inventario": Inventario.nuevo(),
		# #701: la identidad pertenece a esta partida. No es una preferencia
		# global: borrar o empezar otra partida debe producir otra ficha.
		"perfil_jugador": PerfilJugador.nuevo(),
		# #931: un único historial transversal de hechos religiosos observables.
		# Vive en Partida para atravesar escenas, jornadas y reasignaciones sin
		# convertir prácticas/exposición en una identidad o puntuación global.
		ReligionEventos.CLAVE_ESTADO: ReligionEventos.nuevo(),
		# #1184: historial literario transversal persistente. Sobrevive a jornadas
		# y reasignaciones; borrar/empezar una partida crea uno vacío.
		LiteraturaEventos.CLAVE_ESTADO: LiteraturaEventos.nuevo(),
		# #152: condiciones opcionales de la vida laboral. Vacío por defecto;
		# la futura selección de SIGA activará ids antes de empezar la vuelta.
		Auditorias.CLAVE_ESTADO: Auditorias.nueva(),
		# La fusión solo recupera claves del molde. Si faltan aquí, guardar
		# escribe el día y las firmas, pero cargar los descarta silenciosamente.
		"jornada": Jornada.nueva(),
		"veredictos": {},
		# #150: historial inmutable de evaluaciones ya selladas. Vive en Partida
		# para sobrevivir a reasignaciones; nunca sustituye el estado vivo de Jornada.
		"evaluaciones_desempeno": [],
		# #155: mejores reconstrucciones por expediente. Solo son estado
		# derivado (ids/puntuación/cobertura/rango), nunca copias de documentos.
		"reconstrucciones": {},
		# #959: marcas diegéticas producidas por uso reiterado del entorno. Solo
		# ids y estado visual; no guardamos nodos, posiciones ni contenido.
		"huellas_ambientales": {},
		# #153: historial de pronósticos del auditor. Es de la partida, no de la
		# jornada, para sobrevivir a cambios de día y reasignaciones.
		"pronosticos": Pronosticos.nuevo(),
		"logros": catalogos.get("logros", []),
		"tarot": catalogos.get("tarot", []),
		"vida": VIDA_MAXIMA,
		"dificultad": "normal",
		"historias_cartas": {},
		# #954: estado acumulativo de decisiones. Las marcas y contadores son
		# de la vuelta activa; el historial conserva el rastro de toda la partida.
		"historias_pospuestas": [],
		"historias_pospuestas_conteo": {},
		"historial_decisiones": [],
		# #925: snapshots factuales de cada vida, separados del estado activo.
		Prometeo.CLAVE_HISTORIAL_IDEOLOGICO: [],
		"cartas_conocidas": [],
		"coliseo_racha_mejor": 0,
		"despido_mostrado": false,
		# #1205: vida==0 puede esperar una decisión entre canje y cese.
		"despido_pendiente": false,
		"epilogo_avisado": false,
		"final_politico_mostrado": false,
		# #1103: progreso reanudable del clímax, aislado por raíz+vuelta.
		"climax_hastur": {},
		"final_verdadero_mostrado": false,
		"perdio_vida_en_esta_vuelta": false,
		# Cuántas veces se ha visto cada cinemática, para que se acorten solas
		# (#67). Es de por vida y NO de la vuelta: quien ya ha visto veinte
		# veces la entrada de un careo no necesita verla entera porque le hayan
		# reasignado.
		"cinematicas_vistas": {},
		# A quién has vencido en un combate onírico (#88). Va con los
		# veredictos y no con la vuelta: es de lo que firmaste, y a quien ya
		# callaste no lo devuelve un despido.
		"sueno_vencidos": [],
	}


## Carga la partida guardada, o empieza una nueva si no hay ninguna.
##
## Devuelve además qué pasó, porque la interfaz debe poder DECIRLO: que una
## partida no se haya podido leer no puede parecerse a no haber jugado nunca.
func cargar(ruta: String = RUTA) -> Dictionary:
	estado = nueva()

	if not FileAccess.file_exists(ruta):
		return {"resultado": "nueva"}

	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		return _apartar(ruta, "ilegible")
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()

	if typeof(crudo) != TYPE_DICTIONARY:
		return _apartar(ruta, "corrupta")

	var errores := validar(crudo)
	if not errores.is_empty():
		return _apartar(ruta, "corrupta: " + "; ".join(errores))

	var version := int(crudo.get("version", 0))
	estado = _fusionar(crudo)
	return {"resultado": "cargada", "version": version}


## Guarda el estado actual. Devuelve true solo si la partida quedó escrita de
## verdad: quien llame puede avisar, en vez de dar por hecho que se guardó.
##
## Volver a llamar es la forma de reintentar, y no cuesta nada: esto no aplica
## ningún cambio, solo copia a disco el estado que ya está en memoria. Por eso
## un reintento no duplica una firma, ni un pago, ni una acción gastada — el
## trabajo de no repetirlos es de quien llama, que debe reintentar el GUARDADO
## en vez de rehacer la jugada.
func guardar(ruta: String = RUTA) -> bool:
	var temporal := ruta + ".nuevo"
	var fichero := FileAccess.open(temporal, FileAccess.WRITE)
	if fichero == null:
		return _no_se_guardo("No se pudo escribir %s" % temporal, temporal)
	fichero.store_string(JSON.stringify(_para_guardar(), "\t"))
	fichero.close()

	# El renombrado es lo que hace atómico el guardado: hasta esta línea, la
	# partida buena sigue siendo la de antes.
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporal), ProjectSettings.globalize_path(ruta)
	)
	if error != OK:
		return _no_se_guardo("No se pudo reemplazar %s (error %d)" % [ruta, error], temporal)

	# La versión se sella AQUÍ, con el fichero ya en su sitio. Marcarla antes
	# dejaba el estado en memoria diciendo que era de una versión que nunca
	# llegó a escribirse.
	estado["version"] = VERSION
	guardado_pendiente = false
	fallo_de_guardado = ""
	return true


## Un guardado que no salió. Se apunta el motivo, se deja el fichero bueno como
## estaba y se barre el temporal: un `.nuevo` a medias no es una partida, y
## dejarlo ahí solo confunde a quien vaya a mirar la carpeta.
func _no_se_guardo(motivo: String, temporal: String) -> bool:
	push_error(motivo)
	guardado_pendiente = true
	fallo_de_guardado = motivo
	if FileAccess.file_exists(temporal):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporal))
	return false


## Borra el avance PERMANENTE y empieza de cero.
##
## No es `Prometeo.reiniciar_vuelta`, que deja a cero una vida laboral y
## conserva a propósito la memoria de por vida —las cartas ya conocidas, la
## mejor racha, la dificultad, los logros de vitrina—. Esto borra también eso:
## es el "no he jugado nunca", y por eso no puede ocurrir por un clic suelto.
##
## La partida anterior no se tira: se aparta con el mismo mecanismo que una
## partida corrupta, así que un borrado por error sigue siendo recuperable
## desde el disco por quien sepa buscarlo.
##
## Devuelve true si al terminar no queda partida guardada, que es lo que el
## jugador ha pedido. Si no había ninguna, ya estaba hecho.
func borrar(ruta: String = RUTA) -> bool:
	if FileAccess.file_exists(ruta):
		_apartar(ruta, "borrada a petición")
		if FileAccess.file_exists(ruta):
			push_error("No se pudo borrar %s" % ruta)
			return false

	estado = nueva()
	return true


## El estado reducido a lo que es de la partida: los catálogos se quedan en sus
## ids y sus banderas.
func _para_guardar() -> Dictionary:
	var reducido := estado.duplicate()
	reducido["version"] = VERSION
	reducido["logros"] = _solo_estado(estado.get("logros", []), ESTADO_LOGRO)
	reducido["tarot"] = _solo_estado(estado.get("tarot", []), ESTADO_CARTA)
	return reducido


static func _solo_estado(entradas: Array, campos: Array) -> Array:
	var reducidas := []
	for entrada in entradas:
		var minima := {"id": entrada["id"]}
		for campo in campos:
			if entrada.has(campo):
				minima[campo] = entrada[campo]
		reducidas.append(minima)
	return reducidas


## Valida la forma del guardado antes de entregarlo a los consumidores.
##
## La sintaxis JSON no basta: `{"jornada": null}` es JSON válido, pero no es
## una partida. Se permite que falten claves que una versión antigua todavía no
## conocía — `_fusionar` las migra desde `nueva()` —, pero las estructuras
## presentes deben conservar su tipo y sus límites.
static func validar(guardado) -> Array:
	var errores := []
	if typeof(guardado) != TYPE_DICTIONARY:
		return ["la raíz no es un objeto"]

	var version = guardado.get("version", 0)
	if not _entero_valido(version, 0, VERSION):
		errores.append("versión inválida")
	elif int(version) > VERSION:
		errores.append("versión futura")

	# Las partidas anteriores a la jornada se migran desde nueva(). Si la
	# clave aparece, en cambio, su forma debe ser válida.
	if guardado.has("jornada"):
		if typeof(guardado["jornada"]) != TYPE_DICTIONARY:
			errores.append("jornada no es un objeto")
		else:
			errores.append_array(_validar_jornada(guardado["jornada"]))

	if guardado.has(Auditorias.CLAVE_ESTADO):
		if typeof(guardado[Auditorias.CLAVE_ESTADO]) != TYPE_DICTIONARY:
			errores.append("%s no es un objeto" % Auditorias.CLAVE_ESTADO)
		else:
			for error in Auditorias.validar(guardado[Auditorias.CLAVE_ESTADO]):
				errores.append("%s.%s" % [Auditorias.CLAVE_ESTADO, error])

	if guardado.has("inventario"):
		if typeof(guardado["inventario"]) != TYPE_DICTIONARY:
			errores.append("inventario no es un objeto")
		else:
			errores.append_array(_validar_inventario(guardado["inventario"]))

	if guardado.has("perfil_jugador") and typeof(guardado["perfil_jugador"]) != TYPE_DICTIONARY:
		errores.append("perfil_jugador no es un objeto")
	if guardado.has(ReligionEventos.CLAVE_ESTADO):
		if typeof(guardado[ReligionEventos.CLAVE_ESTADO]) != TYPE_DICTIONARY:
			errores.append("%s no es un objeto" % ReligionEventos.CLAVE_ESTADO)
		else:
			for error in ReligionEventos.validar(guardado[ReligionEventos.CLAVE_ESTADO]):
				errores.append("%s.%s" % [ReligionEventos.CLAVE_ESTADO, error])
	if guardado.has(LiteraturaEventos.CLAVE_ESTADO):
		if typeof(guardado[LiteraturaEventos.CLAVE_ESTADO]) != TYPE_DICTIONARY:
			errores.append("%s no es un objeto" % LiteraturaEventos.CLAVE_ESTADO)
		else:
			for error in LiteraturaEventos.validar(guardado[LiteraturaEventos.CLAVE_ESTADO]):
				errores.append("%s.%s" % [LiteraturaEventos.CLAVE_ESTADO, error])
	if guardado.has("pronosticos"):
		if typeof(guardado["pronosticos"]) != TYPE_DICTIONARY:
			errores.append("pronosticos no es un objeto")
		else:
			for error in Pronosticos.validar(guardado["pronosticos"]):
				errores.append("pronosticos.%s" % error)
	if guardado.has("vida") and not _entero_valido(guardado["vida"], 0, VIDA_MAXIMA):
		errores.append("vida inválida")
	if guardado.has("despido_pendiente") and typeof(guardado["despido_pendiente"]) != TYPE_BOOL:
		errores.append("despido_pendiente no es booleano")
	for clave in [
		"pistas_descubiertas",
		"cartas_conocidas",
		"sueno_vencidos",
		"sellos_obtenidos",
		"historias_pospuestas",
		"historial_decisiones",
	]:
		if guardado.has(clave) and typeof(guardado[clave]) != TYPE_ARRAY:
			errores.append("%s no es una lista" % clave)
	if guardado.has("evaluaciones_desempeno"):
		if typeof(guardado["evaluaciones_desempeno"]) != TYPE_ARRAY:
			errores.append("evaluaciones_desempeno no es una lista")
		else:
			for error in EvaluacionDesempeno.validar_historial(guardado["evaluaciones_desempeno"]):
				errores.append("evaluaciones_desempeno.%s" % error)
	if guardado.has(Prometeo.CLAVE_HISTORIAL_IDEOLOGICO):
		var historial_ideologico = guardado[Prometeo.CLAVE_HISTORIAL_IDEOLOGICO]
		if typeof(historial_ideologico) != TYPE_ARRAY:
			errores.append("%s no es una lista" % Prometeo.CLAVE_HISTORIAL_IDEOLOGICO)
		else:
			for error in Prometeo.validar_historial_trayectorias_ideologicas(historial_ideologico):
				errores.append("%s.%s" % [Prometeo.CLAVE_HISTORIAL_IDEOLOGICO, error])
	for clave in ["anomalias_descubiertas", "anomalias_descubiertas_vuelta"]:
		if guardado.has(clave) and typeof(guardado[clave]) != TYPE_ARRAY:
			errores.append("%s no es una lista" % clave)
	for clave in ["logros", "tarot"]:
		if guardado.has(clave) and typeof(guardado[clave]) != TYPE_ARRAY:
			errores.append("%s no es una lista" % clave)
	for clave in [
		"veredictos",
		"historias_cartas",
		"historias_pospuestas_conteo",
		"cinematicas_vistas",
		"reconstrucciones",
	]:
		if guardado.has(clave) and typeof(guardado[clave]) != TYPE_DICTIONARY:
			errores.append("%s no es un objeto" % clave)
	if (
		guardado.has("historias_pospuestas_conteo")
		and typeof(guardado["historias_pospuestas_conteo"]) == TYPE_DICTIONARY
	):
		for carta_id in guardado["historias_pospuestas_conteo"]:
			if not _entero_valido(guardado["historias_pospuestas_conteo"][carta_id], 0, 2147483647):
				errores.append("historias_pospuestas_conteo.%s inválido" % String(carta_id))
	if guardado.has("huellas_ambientales"):
		if typeof(guardado["huellas_ambientales"]) != TYPE_DICTIONARY:
			errores.append("huellas_ambientales no es un objeto")
		else:
			for error in HuellasAmbientales.validar(guardado["huellas_ambientales"]):
				errores.append("huellas_ambientales.%s" % error)
	for clave in CAMPOS_ENTEROS:
		if guardado.has(clave) and not _entero_valido(guardado[clave], 0, 9223372036854775807):
			errores.append("%s inválido" % clave)
	return errores


static func _validar_inventario(inventario: Dictionary) -> Array:
	var errores := []
	var ids := {}
	for ubicacion in [Inventario.CARRIED, Inventario.HOME_STORAGE]:
		if inventario.has(ubicacion) and typeof(inventario[ubicacion]) != TYPE_ARRAY:
			errores.append("inventario.%s no es una lista" % ubicacion)
			continue
		for objeto in inventario.get(ubicacion, []):
			if typeof(objeto) != TYPE_DICTIONARY:
				errores.append("inventario.%s contiene un objeto inválido" % ubicacion)
				continue
			var objeto_id := String(objeto.get("id", "")).strip_edges()
			if objeto_id.is_empty():
				errores.append("inventario.%s contiene un id vacío" % ubicacion)
			elif ids.has(objeto_id):
				errores.append("inventario contiene id duplicado: %s" % objeto_id)
			else:
				ids[objeto_id] = true
	return errores


static func _validar_jornada(jornada: Dictionary) -> Array:
	var errores := []
	if jornada.has("gato") and typeof(jornada["gato"]) != TYPE_DICTIONARY:
		errores.append("gato no es un objeto")
	elif jornada.has("gato"):
		var gato: Dictionary = jornada["gato"]
		if gato.has("presente") and typeof(gato["presente"]) != TYPE_BOOL:
			errores.append("gato.presente inválido")
		if (
			gato.has("dias_sin_comer")
			and not _entero_valido(gato["dias_sin_comer"], 0, Jornada.PACIENCIA_GATO + 1)
		):
			errores.append("gato.dias_sin_comer inválido")
		for error in GatoEcoSueno.validar(gato):
			errores.append("gato.%s" % error)
	if jornada.has("ronda_cierre"):
		if typeof(jornada["ronda_cierre"]) != TYPE_DICTIONARY:
			errores.append("jornada.ronda_cierre no es un objeto")
		else:
			for error in RondaCierre.validar(jornada["ronda_cierre"]):
				errores.append("jornada.ronda_cierre.%s" % error)
	for clave in ["leido_hoy", "mapa", "sueno_escenas", "mapa_anoche"]:
		if jornada.has(clave) and typeof(jornada[clave]) != TYPE_ARRAY:
			errores.append("jornada.%s no es una lista" % clave)
	if (
		jornada.has("hora_minutos")
		and not _entero_valido(jornada["hora_minutos"], 0, Jornada.MINUTOS_DIA - 1)
	):
		errores.append("jornada.hora_minutos inválido")
	for clave in ["dia", "raiz", "vuelta", "dinero", "cerrados_hoy", "acciones"]:
		var maximo := 9223372036854775807 if clave == "raiz" else 2147483647
		if jornada.has(clave) and not _entero_valido(jornada[clave], 0, maximo):
			errores.append("jornada.%s inválido" % clave)
	for clave in ["sueno_resto", "sueno_total"]:
		if (
			jornada.has(clave)
			and (
				typeof(jornada[clave]) not in [TYPE_INT, TYPE_FLOAT]
				or not is_finite(float(jornada[clave]))
				or float(jornada[clave]) < 0.0
			)
		):
			errores.append("jornada.%s inválido" % clave)
	if (
		jornada.has("fase")
		and (typeof(jornada["fase"]) != TYPE_STRING or not Jornada.FASES.has(jornada["fase"]))
	):
		errores.append("jornada.fase inválida")
	return errores


static func _entero_valido(valor, minimo: int, maximo: int) -> bool:
	if typeof(valor) == TYPE_INT:
		return valor >= minimo and valor <= maximo
	if typeof(valor) != TYPE_FLOAT or not is_finite(valor):
		return false
	return floor(valor) == valor and valor >= minimo and valor <= maximo


## Combina lo guardado con los catálogos vigentes: conserva lo conseguido y
## adopta los logros y cartas que la versión nueva haya añadido.
##
## Reutiliza `Prometeo.fusionar_con_guardado`, que es exactamente esto y ya
## está probado. Una segunda implementación aquí acabaría divergiendo de la que
## usa la interfaz, y entonces un logro estaría desbloqueado en una pantalla y
## bloqueado en otra.
func _fusionar(guardado: Dictionary) -> Dictionary:
	var fusionado := nueva()

	for clave in fusionado:
		if clave in ["version", "logros", "tarot"]:
			continue
		if guardado.has(clave):
			fusionado[clave] = int(guardado[clave]) if clave in CAMPOS_ENTEROS else guardado[clave]

	fusionado["logros"] = Prometeo.fusionar_con_guardado(
		guardado.get("logros", []), fusionado["logros"], ESTADO_LOGRO, ALIAS
	)
	fusionado["tarot"] = Prometeo.fusionar_con_guardado(
		guardado.get("tarot", []), fusionado["tarot"], ESTADO_CARTA, ALIAS
	)
	Jornada.completar(fusionado["jornada"])
	Inventario.completar(fusionado["inventario"])
	fusionado["perfil_jugador"] = PerfilJugador.completar(fusionado["perfil_jugador"])
	ReligionEventos.asegurar_en_estado(fusionado)
	LiteraturaEventos.asegurar_en_estado(fusionado)
	Pronosticos.completar(fusionado["pronosticos"])
	Auditorias.asegurar_en_estado(fusionado)
	return fusionado


## Aparta una partida que no se puede interpretar, en vez de pisarla.
func _apartar(ruta: String, motivo: String) -> Dictionary:
	var destino := ruta + ".roto"
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(ruta), ProjectSettings.globalize_path(destino)
	)
	push_warning("Partida %s; apartada en %s" % [motivo, destino])
	return {
		"resultado": "apartada",
		"motivo": motivo,
		"copia": destino if error == OK else "",
	}


static func _leer_json(ruta: String) -> Dictionary:
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		push_error("No se pudo abrir %s" % ruta)
		return {}
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	return crudo if typeof(crudo) == TYPE_DICTIONARY else {}
