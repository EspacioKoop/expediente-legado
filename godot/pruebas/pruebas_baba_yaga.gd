extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_gate_y_semilla()
	_probar_vigilia_deliberada()
	_probar_umbral_y_marcas()
	_probar_fuera_de_campo()
	_probar_controles_interactivos()
	_probar_acabado_ambiental()
	_probar_escalada_ambiental()
	_probar_interior_variable()
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
	_comprobar(
		sueno.ultima_comparacion()["movido"],
		"la comparación queda disponible como estado legible",
	)
	var lectura := sueno.get_node_or_null("LecturaComparacion")
	_comprobar(lectura != null, "existe el contenedor de lectura espacial")
	_comprobar(
		lectura.get_child_count() >= SuenoBabaYaga.PASOS_RASTRO,
		"comparar materializa origen, destino y pasos diegéticos",
	)
	sueno.aplicar_evento(SuenoBabaYaga.EVENTO_UMBRAL)
	_comprobar(
		lectura.get_child_count(),
		0,
		"una nueva reconfiguración retira el rastro ya obsoleto",
	)

	var antes_archivador: Vector3 = sueno.posiciones_actuales()[SuenoBabaYaga.OBJETO_ARCHIVADOR]
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


func _probar_acabado_ambiental() -> void:
	var sueno := SuenoBabaYaga.new()
	get_root().add_child(sueno)
	sueno.preparar()

	var acabado := sueno.get_node_or_null("AcabadoAmbiental")
	_comprobar(acabado != null, "existe pase ambiental separado de la lógica móvil")
	_comprobar(
		sueno.get_node_or_null("AcabadoAmbiental/BosqueFondo/TroncoColumna01") != null,
		"bosque de fondo mezcla tronco y columna SIGA-98",
	)
	_comprobar(
		sueno.get_node_or_null("AcabadoAmbiental/TechoOficinaInvertido/PanelTecho01") != null,
		"techo de oficina invertido refuerza la escalada onírica",
	)
	_comprobar(
		sueno.get_node_or_null("AcabadoAmbiental/PlanoAdministrativoPlegado/HojaA") != null,
		"plano administrativo plegado materializa la hibridación sin texto",
	)
	var cocina := sueno.get_node_or_null(
		"CabanaAncla/InteriorImposible/EstadosInterior/CocinaSIGA98"
	)
	_comprobar(cocina != null, "interior imposible contiene una cocina doméstica SIGA-98")
	_comprobar(
		cocina.get_child_count() >= 9, "cocina tiene mobiliario suficiente para leerse como espacio"
	)
	var colisiones := acabado.find_children("*", "CollisionShape3D", true, false)
	_comprobar(colisiones.is_empty(), "acabado ambiental no añade colisiones ni bloquea rutas")
	_comprobar(sueno.cabana_visible(), "acabado conserva la cabaña-ancla")
	_comprobar(sueno.ruta_retorno_disponible(), "acabado conserva el retorno seguro")
	sueno.queue_free()


func _probar_escalada_ambiental() -> void:
	var sueno := SuenoBabaYaga.new()
	get_root().add_child(sueno)
	sueno.preparar()

	var techo := sueno.get_node_or_null("AcabadoAmbiental/TechoOficinaInvertido") as Node3D
	var plano := sueno.get_node_or_null("AcabadoAmbiental/PlanoAdministrativoPlegado") as Node3D
	var fondo := sueno.get_node_or_null("AcabadoAmbiental/BosqueFondo") as Node3D
	var retorno := sueno.get_node_or_null("RetornoSeguro") as Node3D
	_comprobar(techo != null, "escalada conserva techo invertido")
	_comprobar(plano != null, "escalada conserva plano administrativo")
	_comprobar(fondo != null, "escalada conserva bosque de fondo")
	_comprobar(retorno != null, "escalada conserva retorno seguro")
	var retorno_inicial := retorno.position
	var posiciones_vistas: Array[Vector3] = []

	for i in SuenoBabaYaga.POSICIONES_TECHO_FASE.size():
		var posicion_techo: Vector3 = SuenoBabaYaga.POSICIONES_TECHO_FASE[i]
		var rotacion_techo: Vector3 = SuenoBabaYaga.ROTACIONES_TECHO_FASE[i]
		var posicion_plano: Vector3 = SuenoBabaYaga.POSICIONES_PLANO_FASE[i]
		var rotacion_plano: Vector3 = SuenoBabaYaga.ROTACIONES_PLANO_FASE[i]
		var posicion_fondo: Vector3 = SuenoBabaYaga.POSICIONES_FONDO_FASE[i]
		_comprobar(sueno.fase_ambiental_actual(), i, "fase ambiental sigue el umbral")
		_comprobar(techo.position, posicion_techo, "techo usa posición declarada")
		_comprobar(techo.rotation_degrees, rotacion_techo, "techo usa rotación declarada")
		_comprobar(plano.position, posicion_plano, "plano usa posición declarada")
		_comprobar(plano.rotation_degrees, rotacion_plano, "plano usa rotación declarada")
		_comprobar(fondo.position, posicion_fondo, "bosque de fondo usa posición declarada")
		_comprobar(not posiciones_vistas.has(techo.position), "cada fase tiene lectura visual propia")
		posiciones_vistas.append(techo.position)
		_comprobar(retorno.position, retorno_inicial, "escalada no mueve el retorno seguro")
		if i < SuenoBabaYaga.POSICIONES_TECHO_FASE.size() - 1:
			var cambio := sueno.aplicar_evento(SuenoBabaYaga.EVENTO_UMBRAL)
			_comprobar(cambio["fase_ambiental"], i + 1, "evento expone nueva fase ambiental")

	var cierre := sueno.aplicar_evento(SuenoBabaYaga.EVENTO_UMBRAL)
	_comprobar(cierre["fase_ambiental"], 0, "escalada ambiental forma un ciclo estable")
	_comprobar(retorno.position, retorno_inicial, "ciclo completo conserva retorno")
	sueno.queue_free()


func _probar_interior_variable() -> void:
	var sueno := SuenoBabaYaga.new()
	get_root().add_child(sueno)
	sueno.preparar()

	var marco := sueno.get_node_or_null("CabanaAncla/InteriorImposible/MarcoPuerta")
	var estados := sueno.get_node_or_null("CabanaAncla/InteriorImposible/EstadosInterior")
	_comprobar(marco != null, "el marco de puerta existe como ancla estable")
	_comprobar(estados != null, "la cabaña contiene estados interiores declarados")
	_comprobar(
		estados.get_child_count(),
		SuenoBabaYaga.INTERIORES_CABANA.size(),
		"hay un interior por fase del umbral",
	)

	var vistos: Array[String] = []
	for i in SuenoBabaYaga.INTERIORES_CABANA.size():
		var esperado: String = SuenoBabaYaga.INTERIORES_CABANA[i]
		_comprobar(sueno.interior_actual(), esperado, "interior sigue la fase espacial")
		var visibles := 0
		for estado in estados.get_children():
			if estado.visible:
				visibles += 1
				_comprobar(
					String(estado.name), esperado, "solo se muestra el interior seleccionado"
				)
		_comprobar(visibles, 1, "solo hay un interior visible por fase")
		_comprobar(sueno.get_node_or_null("CabanaAncla/InteriorImposible/MarcoPuerta"), marco)
		vistos.append(sueno.interior_actual())
		if i < SuenoBabaYaga.INTERIORES_CABANA.size() - 1:
			var cambio := sueno.aplicar_evento(SuenoBabaYaga.EVENTO_UMBRAL)
			_comprobar(
				cambio["interior_cabana"],
				SuenoBabaYaga.INTERIORES_CABANA[i + 1],
				"el evento expone el siguiente interior",
			)

	_comprobar(vistos, SuenoBabaYaga.INTERIORES_CABANA, "la secuencia interior es determinista")
	var vuelta := sueno.aplicar_evento(SuenoBabaYaga.EVENTO_UMBRAL)
	_comprobar(vuelta["interior_cabana"], SuenoBabaYaga.INTERIORES_CABANA[0], "el ciclo es estable")
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
	_comprobar(
		sueno.get_node_or_null("DintelRetorno") != null,
		"retorno seguro tiene una silueta vertical estable además del color",
	)
	_comprobar(
		sueno.comparar_marca("postit_1")["movido"],
		"la lectura espacial funciona también con reducción de movimiento",
	)

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
	_comprobar(
		copia.ultima_comparacion(),
		sueno.ultima_comparacion(),
		"restauración conserva la última lectura espacial",
	)
	var lectura_copia := copia.get_node_or_null("LecturaComparacion")
	_comprobar(
		lectura_copia != null and lectura_copia.get_child_count() >= SuenoBabaYaga.PASOS_RASTRO,
		"restauración rematerializa el rastro de comparación",
	)
	_comprobar(copia.cabana_visible(), "restauración conserva cabaña")
	_comprobar(copia.ruta_retorno_disponible(), "restauración conserva salida")
	_comprobar(
		copia.get_node_or_null("CabanaAncla/InteriorImposible/SueloInterior") != null,
		"cabaña materializa interior mayor que su volumen",
	)
	_comprobar(
		copia.interior_actual(),
		sueno.interior_actual(),
		"restauración conserva el interior ligado a la fase espacial",
	)
	_comprobar(
		copia.fase_ambiental_actual(),
		sueno.fase_ambiental_actual(),
		"restauración conserva la fase ambiental",
	)
	var techo_copia := copia.get_node("AcabadoAmbiental/TechoOficinaInvertido") as Node3D
	var techo_original := sueno.get_node("AcabadoAmbiental/TechoOficinaInvertido") as Node3D
	_comprobar(
		techo_copia.transform,
		techo_original.transform,
		"restauración recompone la escalada ambiental",
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
