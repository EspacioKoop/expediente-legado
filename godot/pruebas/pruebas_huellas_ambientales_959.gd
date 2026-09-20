## Regresión standalone del primer vertical de huellas ambientales (#959).
extends SceneTree


class DiaDoble:
	extends Node
	var jornada := {"fase": "archivo", "dia": 1}
	var partida := Partida.new()
	var guardados := 0
	var _mundo: Node3D

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
	sin_meta.interactuar(dia)
	_comprobar(
		dia.partida.estado["huellas_ambientales"].size() == 1,
		"objetos sin opt-in no generan huellas",
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
