## Regresión standalone del primer vertical de huellas ambientales (#959).
extends SceneTree


class DiaDoble:
	extends Node
	var jornada := {"fase": "archivo", "dia": 1}
	var partida := Partida.new()
	var guardados := 0
	var _mundo: Node3D
	var _caminante: CharacterBody3D

	func _init() -> void:
		partida.estado = Partida.nueva()

	func _guardar_o_avisar(_mensaje: String = "") -> bool:
		guardados += 1
		return true


var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var estado := Partida.nueva()
	_comprobar(
		typeof(estado.get("huellas_ambientales")) == TYPE_DICTIONARY,
		"Partida crea el estado de huellas"
	)

	var primera := HuellasAmbientales.registrar(estado, "archivo:terminal_siga", "uso", "archivo")
	_comprobar(int(primera["usos"]) == 1, "el primer uso queda registrado")
	_comprobar(float(primera["intensidad"]) > 0.0, "la primera marca ya es sutilmente visible")
	var segunda := HuellasAmbientales.registrar(estado, "archivo:terminal_siga", "uso", "archivo")
	_comprobar(int(segunda["usos"]) == 2, "repetir incrementa uso")
	_comprobar(
		float(segunda["intensidad"]) > float(primera["intensidad"]),
		"repetir aumenta intensidad",
	)
	for _i in range(20):
		HuellasAmbientales.registrar(estado, "archivo:terminal_siga", "uso", "archivo")
	_comprobar(
		(
			int(estado["huellas_ambientales"]["archivo:terminal_siga"]["usos"])
			== HuellasAmbientales.USOS_MAX
		),
		"el desgaste queda acotado",
	)
	_comprobar(
		(
			HuellasAmbientales.intensidad_de(estado, "archivo:terminal_siga")
			<= HuellasAmbientales.INTENSIDAD_MAX
		),
		"la intensidad queda acotada",
	)
	HuellasAmbientales.registrar(estado, "casa:silla", "roce", "casa")
	_comprobar(HuellasAmbientales.de_fase(estado, "archivo").size() == 1, "filtra por espacio")
	_comprobar(HuellasAmbientales.de_fase(estado, "casa").size() == 1, "conserva otras fases")
	_comprobar(
		HuellasAmbientales.registrar(estado, "", "uso", "archivo").is_empty(), "rechaza id vacío"
	)
	_comprobar(
		HuellasAmbientales.validar(estado["huellas_ambientales"]).is_empty(),
		"el estado generado valida"
	)

	var invalido: Dictionary = estado["huellas_ambientales"].duplicate(true)
	invalido["rota"] = {"tipo": "laser", "fase": "archivo", "usos": 1, "intensidad": 0.2}
	_comprobar(not HuellasAmbientales.validar(invalido).is_empty(), "rechaza tipos inventados")
	var guardado_roto := Partida.nueva()
	guardado_roto["huellas_ambientales"] = []
	_comprobar(not Partida.validar(guardado_roto).is_empty(), "Partida rechaza forma inválida")

	var ruta := "user://huellas-ambientales-959-%d.json" % Time.get_ticks_usec()
	var partida := Partida.new()
	partida.estado = estado
	_comprobar(partida.guardar(ruta), "Partida guarda las huellas")
	var recargada := Partida.new()
	_comprobar(recargada.cargar(ruta)["resultado"] == "cargada", "Partida recarga el vertical")
	_comprobar(
		(
			int(recargada.estado["huellas_ambientales"]["archivo:terminal_siga"]["usos"])
			== HuellasAmbientales.USOS_MAX
		),
		"la recarga conserva intensidad acumulada",
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))

	var dia := DiaDoble.new()
	root.add_child(dia)
	var mundo := Node3D.new()
	mundo.name = "Mundo"
	dia.add_child(mundo)
	dia._mundo = mundo
	dia._caminante = CharacterBody3D.new()
	dia._caminante.name = "Caminante"
	dia.add_child(dia._caminante)
	dia._caminante.position = Vector3(0.2, 0.0, 0.2)
	var terminal := Interactuable3D.new()
	terminal.name = "TerminalMarcable"
	terminal.position = Vector3(1.2, 0.8, -0.7)
	terminal.set_meta("huella_ambiental_id", "archivo:test_terminal")
	terminal.set_meta("huella_ambiental_tipo", "uso")
	terminal.set_meta("huella_ambiental_offset", Vector3(0.0, 0.0, -0.3))
	mundo.add_child(terminal)

	var sin_meta := Interactuable3D.new()
	sin_meta.name = "SinMeta"
	mundo.add_child(sin_meta)

	var controller = load("res://guion/dia_huellas_ambientales_app.gd").new()
	dia.add_child(controller)
	controller._process(0.0)
	terminal.interactuar(dia)
	await process_frame
	_comprobar(
		dia.partida.estado["huellas_ambientales"].has("archivo:test_terminal"),
		"el controller escucha el contrato común",
	)
	_comprobar(dia.guardados == 1, "la interacción persiste inmediatamente")
	var raiz := mundo.get_node_or_null("HuellasAmbientales959")
	_comprobar(raiz != null, "las marcas viven en una raíz aislada")
	_comprobar(raiz.get_child_count() == 1, "una interacción crea una sola marca")
	var marca := raiz.get_child(0) as MeshInstance3D
	_comprobar(marca != null and marca.mesh is PlaneMesh, "la huella es una malla plana barata")
	_comprobar(
		marca.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"la huella no añade coste de sombras",
	)

	var material_marca := (marca.mesh as PlaneMesh).material as StandardMaterial3D
	var alpha_manana := material_marca.albedo_color.a
	var estado_huellas_antes := JSON.stringify(dia.partida.estado["huellas_ambientales"])
	dia.jornada["hora_minutos"] = 19 * 60
	controller._process(0.0)
	var alpha_noche := material_marca.albedo_color.a
	_comprobar(alpha_noche > alpha_manana, "la noche cambia solo la lectura visual")
	_comprobar(
		JSON.stringify(dia.partida.estado["huellas_ambientales"]) == estado_huellas_antes,
		"cambiar de franja no muta la persistencia",
	)

	var perfil_seco: Dictionary = (
		controller
		. perfil_visual(
			{
				"fase": "trayecto",
				"dia": 1,
				"hora_minutos": 12 * 60,
				"clima_forzado": Clima.DESPEJADO
			},
			"paso",
			0.2,
		)
	)
	var perfil_lluvia: Dictionary = (
		controller
		. perfil_visual(
			{"fase": "trayecto", "dia": 1, "hora_minutos": 12 * 60, "clima_forzado": Clima.LLUVIA},
			"paso",
			0.2,
		)
	)
	_comprobar(
		float(perfil_lluvia["alpha"]) > float(perfil_seco["alpha"]),
		"la precipitación hace más legible el desgaste de paso",
	)
	var perfil_sueno: Dictionary = (
		controller
		. perfil_visual(
			{"fase": "sueño", "dia": 1, "hora_minutos": 23 * 60},
			"uso",
			0.2,
		)
	)
	_comprobar(
		Color(perfil_sueno["tinte"]) != Color(perfil_seco["tinte"]),
		"el sueño deforma el tinte sin mover la huella",
	)

	dia.jornada["hora_minutos"] = 9 * 60
	sin_meta.interactuar(dia)
	_comprobar(
		dia.partida.estado["huellas_ambientales"].size() == 1,
		"objetos sin opt-in no generan huellas",
	)

	# El punto inicial solo siembra la celda: una carga o quedarse quieto no
	# cuentan como tránsito. La marca aparece al volver tres veces a la misma.
	for vuelta in range(3):
		# Cada salida pisa una celda distinta: solo la celda de origen se repite
		# tres veces y, por tanto, solo ella debe cruzar el umbral persistente.
		dia._caminante.position = Vector3(1.6 + float(vuelta) * 1.4, 0.0, 0.2)
		controller._process(0.0)
		dia._caminante.position = Vector3(0.2, 0.0, 0.2)
		controller._process(0.0)
	var id_transito := "transito:archivo:0:0"
	_comprobar(
		dia.partida.estado["huellas_ambientales"].has(id_transito),
		"tres retornos reales crean desgaste de tránsito",
	)
	var transito: Dictionary = dia.partida.estado["huellas_ambientales"][id_transito]
	_comprobar(transito.get("tipo") == "paso", "el tránsito usa el tipo paso")
	_comprobar(int(transito.get("usos", 0)) == 1, "el umbral crea un único uso persistente")
	_comprobar(dia.guardados == 2, "solo el desgaste efectivo añade un guardado")
	_comprobar(raiz.get_child_count() == 2, "el tránsito añade una segunda marca barata")

	controller._process(0.0)
	_comprobar(
		int(dia.partida.estado["huellas_ambientales"][id_transito]["usos"]) == 1,
		"quedarse en la celda no incrementa desgaste",
	)

	# Cambiar de mundo reconstruye la marca persistida, pero la propia carga no
	# cuenta como una nueva pasada por la celda.
	mundo.queue_free()
	var mundo_recargado := Node3D.new()
	mundo_recargado.name = "MundoRecargado"
	dia.add_child(mundo_recargado)
	dia._mundo = mundo_recargado
	controller._process(0.0)
	var raiz_recargada := mundo_recargado.get_node_or_null("HuellasAmbientales959")
	_comprobar(
		raiz_recargada != null and raiz_recargada.get_child_count() == 1,
		"la recarga reconstruye la huella de tránsito",
	)
	_comprobar(
		int(dia.partida.estado["huellas_ambientales"][id_transito]["usos"]) == 1,
		"reconstruir el mundo no suma una pasada fantasma",
	)

	# La vigilia puede reaparecer simbólicamente en sueño, pero el eco es solo
	# presentación: selecciona hechos persistidos y no registra nada nuevo.
	for _i in range(5):
		HuellasAmbientales.registrar(dia.partida.estado, "casa:televisor", "equipo", "casa")
	for _i in range(3):
		HuellasAmbientales.registrar(dia.partida.estado, "trayecto:portal", "apertura", "trayecto")
	for _i in range(2):
		HuellasAmbientales.registrar(
			dia.partida.estado, "archivo:archivador", "apertura", "archivo"
		)
	HuellasAmbientales.registrar(dia.partida.estado, "casa:silla", "roce", "casa")

	var estado_antes_ecos := JSON.stringify(dia.partida.estado["huellas_ambientales"])
	var destacadas: Array = controller._huellas_vigilia_destacadas(dia.partida.estado, 3)
	_comprobar(destacadas.size() == 3, "el sueño limita los ecos a tres huellas")
	_comprobar(
		String(destacadas[0].get("id", "")) == "casa:televisor",
		"la huella más intensa tiene prioridad onírica",
	)
	_comprobar(
		float(destacadas[0].get("intensidad", 0.0)) >= float(destacadas[1].get("intensidad", 0.0)),
		"los ecos se ordenan por intensidad",
	)

	dia.jornada["fase"] = "sueño"
	dia.jornada["hora_minutos"] = 23 * 60
	mundo_recargado.queue_free()
	var mundo_sueno := Node3D.new()
	mundo_sueno.name = "MundoSueno"
	dia.add_child(mundo_sueno)
	dia._mundo = mundo_sueno
	dia._caminante.position = Vector3(2.0, 0.0, 3.0)
	controller._process(0.0)
	var raiz_sueno := mundo_sueno.get_node_or_null("HuellasAmbientales959")
	_comprobar(raiz_sueno != null, "el sueño monta una raíz de ecos")
	_comprobar(raiz_sueno.get_child_count() == 3, "el sueño materializa solo tres ecos")
	for hijo in raiz_sueno.get_children():
		_comprobar(hijo is MeshInstance3D, "cada eco sigue siendo una malla barata")
		var origen := String(hijo.get_meta("huella_eco_origen_959", ""))
		_comprobar(
			not origen.is_empty() and origen.get_slice(":", 0) in ["archivo", "trayecto", "casa"],
			"cada eco conserva una referencia interna a un hecho de vigilia",
		)
		_comprobar(
			not (hijo is Interactuable3D),
			"los ecos no son interactuables ni crean progreso",
		)
		var distancia_entrada := (hijo as Node3D).global_position.distance_to(
			dia._caminante.global_position
		)
		_comprobar(distancia_entrada < 2.5, "los ecos quedan cerca de la entrada del sueño")
	_comprobar(
		JSON.stringify(dia.partida.estado["huellas_ambientales"]) == estado_antes_ecos,
		"entrar en sueño no muta ni duplica las huellas persistentes",
	)

	dia.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(valor: bool, nombre: String) -> void:
	if valor:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO huellas #959: %s" % nombre)
