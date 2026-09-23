extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_gate_y_semilla()
	_probar_vigilia_deliberada()
	_probar_umbral_y_marcas()
	_probar_fuera_de_campo()
	_probar_controles_interactivos()
	_probar_accesibilidad_y_reproduccion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_gate_y_semilla() -> void:
	var jornada := {"dia": 15}
	_comprobar(not SuenoBabaYaga.puede_entrar(jornada), "sin semilla Baba Yaga no entra")
	_comprobar(
		not SuenoBabaYaga.registrar_semilla(jornada, 1, true, true),
		"una lectura no basta",
	)
	_comprobar(
		not SuenoBabaYaga.registrar_semilla(jornada, 2, false, true),
		"libro cerrado no activa",
	)
	_comprobar(
		not SuenoBabaYaga.registrar_semilla(jornada, 2, true, false),
		"sin comparar versiones no activa",
	)
	_comprobar(
		SuenoBabaYaga.registrar_semilla(jornada, 2, true, true),
		"interacción completa registra semilla",
	)
	_comprobar(SuenoBabaYaga.puede_entrar(jornada), "semilla común habilita familia")
	_comprobar(
		SemillasOniricas.familias_activas(jornada),
		["baba_yaga"],
		"Baba Yaga usa catálogo común",
	)
	var entrada: Dictionary = (
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_baba_yaga"]
	)
	_comprobar(entrada["fuentes"], ["libro:cuentos_eslavos_98"], "procedencia estable")
	_comprobar(entrada["intensidad"], 2, "intensidad declarada conservada")
	jornada["dia"] = 16
	_comprobar(not SuenoBabaYaga.puede_entrar(jornada), "semilla no cruza de jornada")


func _probar_vigilia_deliberada() -> void:
	var jornada := {"dia": 5}
	var libro := BabaYagaVigilia.new()
	get_root().add_child(libro)
	libro.configurar(jornada)
	_comprobar(not libro.esta_activada(), "libro presente no activa solo")
	libro.examinar()
	_comprobar(libro.lecturas(), 1, "primera lectura cuenta")
	_comprobar(not libro.esta_activada(), "primera lectura no activa")
	libro.examinar()
	_comprobar(libro.lecturas(), 2, "segunda lectura completa el mínimo")
	_comprobar(not libro.esta_abierto(), "leer no equivale a abrir desplegable")
	libro.examinar()
	_comprobar(libro.esta_abierto(), "tercera interacción abre el libro")
	_comprobar(not libro.comparo_versiones(), "abrir no equivale a comparar")
	_comprobar(not libro.esta_activada(), "abrir aún no activa")
	libro.examinar()
	_comprobar(libro.comparo_versiones(), "cuarta interacción compara versiones")
	_comprobar(libro.esta_activada(), "comparar activa semilla")
	var intensidad := int(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_baba_yaga"]["intensidad"]
	)
	libro.examinar()
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_baba_yaga"]["intensidad"],
		intensidad,
		"misma fuente es idempotente",
	)
	libro.queue_free()


func _probar_umbral_y_marcas() -> void:
	var sueno := SuenoBabaYaga.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var inicial := sueno.posiciones_actuales()
	_comprobar(sueno.cabana_visible(), "cabaña visible desde el inicio")
	_comprobar(sueno.ruta_retorno_disponible(), "retorno disponible desde el inicio")
	_comprobar(
		sueno.dejar_marca("cinta_roja", SuenoBabaYaga.OBJETO_ARBOL),
		"se puede dejar una marca persistente",
	)
	_comprobar(
		not sueno.dejar_marca("cinta_roja", SuenoBabaYaga.OBJETO_VALLA),
		"una marca existente no se teletransporta",
	)
	var marca_inicial: Dictionary = sueno.marcas_persistentes()["cinta_roja"]
	var cambio := sueno.aplicar_evento(SuenoBabaYaga.EVENTO_UMBRAL)
	var despues: Dictionary = cambio["posiciones"]
	_comprobar(cambio["ok"], "cruzar umbral aplica una regla")
	_comprobar(
		despues[SuenoBabaYaga.OBJETO_ARBOL] != inicial[SuenoBabaYaga.OBJETO_ARBOL],
		"árbol/tabique cambia al cruzar umbral",
	)
	_comprobar(
		despues[SuenoBabaYaga.OBJETO_VALLA] != inicial[SuenoBabaYaga.OBJETO_VALLA],
		"valla cambia al cruzar umbral",
	)
	_comprobar(
		despues[SuenoBabaYaga.OBJETO_CABANA] != inicial[SuenoBabaYaga.OBJETO_CABANA],
		"cabaña-ancla cambia al cruzar umbral",
	)
	_comprobar(
		despues[SuenoBabaYaga.OBJETO_ARCHIVADOR] == inicial[SuenoBabaYaga.OBJETO_ARCHIVADOR],
		"archivador no usa la regla del umbral",
	)
	_comprobar(
		sueno.marcas_persistentes()["cinta_roja"]["posicion"],
		marca_inicial["posicion"],
		"marca permanece en su posición original",
	)
	var comparacion := sueno.comparar_marca("cinta_roja")
	_comprobar(comparacion["ok"], "marca se puede consultar")
	_comprobar(comparacion["movido"], "marca permite detectar que el árbol se movió")
	_comprobar(float(comparacion["distancia"]) > 0.0, "comparación cuantifica desplazamiento")
	_comprobar(cambio["cabana_visible"], "cabaña nunca desaparece al moverse")
	_comprobar(cambio["retorno_disponible"], "movimiento conserva salida")
	sueno.queue_free()


func _probar_fuera_de_campo() -> void:
	var sueno := SuenoBabaYaga.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var inicial := sueno.posiciones_actuales()
	var visible := sueno.aplicar_evento(SuenoBabaYaga.EVENTO_FUERA_CAMPO, false)
	_comprobar(not visible["ok"], "mirarlo impide movimiento fuera de campo")
	_comprobar(visible["posiciones"], inicial, "sin perderlo de vista no cambia nada")
	var oculto := sueno.aplicar_evento(SuenoBabaYaga.EVENTO_FUERA_CAMPO, true)
	_comprobar(oculto["ok"], "fuera de campo habilita la regla")
	_comprobar(
		(
			oculto["posiciones"][SuenoBabaYaga.OBJETO_ARCHIVADOR]
			!= inicial[SuenoBabaYaga.OBJETO_ARCHIVADOR]
		),
		"archivador cambia fuera de campo",
	)
	_comprobar(
		oculto["posiciones"][SuenoBabaYaga.OBJETO_ARBOL] == inicial[SuenoBabaYaga.OBJETO_ARBOL],
		"árbol no usa la regla fuera de campo",
	)
	_comprobar(
		oculto["posiciones"][SuenoBabaYaga.OBJETO_CABANA] == inicial[SuenoBabaYaga.OBJETO_CABANA],
		"cabaña no se mueve arbitrariamente fuera de campo",
	)
	var invalido := sueno.aplicar_evento("esperar_azar", true)
	_comprobar(not invalido["ok"], "no existe espera aleatoria como regla")
	_comprobar(
		invalido["posiciones"],
		oculto["posiciones"],
		"evento desconocido no cambia la arquitectura",
	)
	sueno.queue_free()


func _probar_controles_interactivos() -> void:
	var sueno := SuenoBabaYaga.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var actor := Node.new()
	get_root().add_child(actor)

	var cinta := sueno.get_node_or_null("ControlesBosque/CintaPersistente") as Interactuable3D
	_comprobar(cinta != null, "la cinta persistente existe en el mundo")
	_comprobar(cinta.interactuar(actor), "la cinta usa el contrato Interactuable3D")
	_comprobar(
		sueno.marcas_persistentes().has("cinta_jugador"),
		"interactuar deja una marca persistente real",
	)

	var inicial := sueno.posiciones_actuales()
	var umbral := sueno.get_node_or_null("ControlesBosque/UmbralBosque") as Interactuable3D
	_comprobar(umbral != null, "el umbral interactuable existe en el mundo")
	_comprobar(umbral.interactuar(actor), "el umbral se activa por interacción 3D")
	_comprobar(
		(
			sueno.posiciones_actuales()[SuenoBabaYaga.OBJETO_ARBOL]
			!= inicial[SuenoBabaYaga.OBJETO_ARBOL]
		),
		"usar el umbral mueve la arquitectura por su regla",
	)
	_comprobar(
		sueno.comparar_marca("cinta_jugador")["movido"],
		"la marca física permite comprobar el desplazamiento",
	)

	var antes_archivador := sueno.posiciones_actuales()[SuenoBabaYaga.OBJETO_ARCHIVADOR]
	var observatorio := (
		sueno.get_node_or_null("ControlesBosque/ObservatorioArchivador") as Interactuable3D
	)
	_comprobar(observatorio != null, "el punto de observación existe en el mundo")
	_comprobar(
		observatorio.interactuar(actor),
		"el punto de observación confirma la regla fuera de campo",
	)
	_comprobar(
		sueno.posiciones_actuales()[SuenoBabaYaga.OBJETO_ARCHIVADOR] != antes_archivador,
		"confirmar fuera de campo mueve solo el archivador",
	)
	_comprobar(sueno.cabana_visible(), "los controles conservan la cabaña-ancla")
	_comprobar(sueno.ruta_retorno_disponible(), "los controles conservan la ruta de retorno")

	actor.queue_free()
	sueno.queue_free()


func _probar_accesibilidad_y_reproduccion() -> void:
	var sueno := SuenoBabaYaga.new()
	get_root().add_child(sueno)
	sueno.preparar()
	sueno.dejar_marca("postit_1", SuenoBabaYaga.OBJETO_VALLA)
	var normal := sueno.aplicar_evento(SuenoBabaYaga.EVENTO_UMBRAL, false, false)
	_comprobar(normal["modo"], "fundido_desplazamiento", "modo normal usa transición breve")
	_comprobar(normal["duracion"], 0.24, "duración normal está acotada")
	_comprobar(normal["animar_geometria"], "modo normal permite animación")
	_comprobar(not normal["mover_camara"], "no exige giro de cámara")
	_comprobar(not normal["desplazar_jugador"], "geometría nunca desplaza al jugador")
	_comprobar(not normal["flash"], "no usa flash")

	var reducida := sueno.aplicar_evento(SuenoBabaYaga.EVENTO_UMBRAL, false, true)
	_comprobar(reducida["modo"], "corte_fundido", "reducción usa corte/fundido")
	_comprobar(reducida["duracion"], 0.0, "reducción no interpola")
	_comprobar(not reducida["animar_geometria"], "reducción evita geometría animada")
	_comprobar(reducida["cabana_visible"], "reducción conserva cabaña-ancla")
	_comprobar(reducida["retorno_disponible"], "reducción conserva retorno")

	var guardado := sueno.estado_reproducible()
	var copia := SuenoBabaYaga.new()
	get_root().add_child(copia)
	copia.preparar()
	copia.restaurar_estado(guardado)
	_comprobar(copia.estado_reproducible(), guardado, "estado se reproduce exactamente")
	_comprobar(
		copia.posiciones_actuales(),
		sueno.posiciones_actuales(),
		"mismas posiciones para mismo estado",
	)
	_comprobar(
		copia.marcas_persistentes(),
		sueno.marcas_persistentes(),
		"restauración conserva marcas",
	)
	_comprobar(copia.cabana_visible(), "restauración conserva cabaña")
	_comprobar(copia.ruta_retorno_disponible(), "restauración conserva salida")
	_comprobar(
		copia.get_node_or_null("CabanaAncla/InteriorImposible/SueloInterior") != null,
		"cabaña materializa interior mayor que su volumen",
	)
	sueno.queue_free()
	copia.queue_free()


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Baba Yaga: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
