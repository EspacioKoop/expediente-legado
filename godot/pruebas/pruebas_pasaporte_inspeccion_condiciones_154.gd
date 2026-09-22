extends SceneTree

const Controller := preload("res://guion/pasaporte_inspeccion_runtime.gd")
const RUTA_PRUEBA := "user://prueba_pasaporte_inspeccion_condiciones_154.json"


class DiaFalso:
	extends Node3D
	var partida := Partida.new()
	var jornada: Dictionary
	var guardados := 0
	var _mundo: Node3D

	func _init() -> void:
		partida.estado = Partida.nueva()
		jornada = partida.estado["jornada"]

	func _guardar_o_avisar(_destino: String) -> bool:
		guardados += 1
		return true


var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_limpiar_temporales()
	_probar_condiciones_y_registro()
	_probar_persistencia_variantes()
	_probar_runtime_casa()
	_probar_resolucion_de_anclas()
	_limpiar_temporales()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_condiciones_y_registro() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var jornada: Dictionary = partida.estado["jornada"]
	var dia_lluvia := _primer_dia_lluvioso()
	_comprobar(dia_lluvia > 0, "existe un día determinista de lluvia para la regresión")

	jornada["dia"] = dia_lluvia
	jornada["fase"] = "trayecto"
	jornada["hora_minutos"] = 20 * 60
	jornada["vuelta"] = 2
	jornada["gato"]["presente"] = false

	var dinero_antes := int(jornada.get("dinero", 0))
	var acciones_antes := int(jornada.get("acciones", 0))
	var pistas_antes: Array = partida.estado.get("pistas_descubiertas", []).duplicate()
	var activas := PasaporteInspeccion.condiciones_activas(partida.estado)
	_comprobar(activas.size() == 4, "el contexto reconoce cuatro condiciones demostrables")
	_comprobar(activas.has("noche"), "la franja de Jornada activa noche")
	_comprobar(activas.has("lluvia"), "Clima del día activa lluvia")
	_comprobar(activas.has("reasignacion"), "la vuelta posterior activa reasignación")
	_comprobar(activas.has("gato-ausente"), "el estado persistido del gato activa su ausencia")

	var registro := PasaporteInspeccion.registrar_observacion_contextual(
		partida.estado, "trayecto:farola-sodio"
	)
	_comprobar(
		registro.get("resultado", "") == "registrado", "la observación contextual registra base"
	)
	_comprobar(bool(registro.get("cambio", false)), "el primer vistazo contextual declara cambio")
	_comprobar(
		registro.get("variantes_nuevas", []).size() == 4,
		"el mismo vistazo registra las cuatro variantes activas",
	)
	_comprobar(
		PasaporteInspeccion.observado(partida.estado, "trayecto:farola-sodio"),
		"la base queda registrada",
	)
	_comprobar(
		PasaporteInspeccion.variantes(partida.estado, "trayecto:farola-sodio").size() == 4,
		"las variantes quedan consultables por punto",
	)

	var repetida := PasaporteInspeccion.registrar_observacion_contextual(
		partida.estado, "trayecto:farola-sodio"
	)
	_comprobar(repetida.get("resultado", "") == "ya-observado", "repetir conserva la base")
	_comprobar(not bool(repetida.get("cambio", true)), "repetir el mismo contexto no muta estado")
	_comprobar(
		repetida.get("variantes_nuevas", []).is_empty(),
		"repetir no duplica variantes especiales",
	)
	_comprobar(
		_contar_ids_del_punto(partida.estado, "trayecto:farola-sodio") == 5,
		"base y cuatro variantes ocupan cinco ids únicos",
	)

	var antes := partida.estado.duplicate(true)
	var zona_invalida := PasaporteInspeccion.registrar_observacion_contextual(
		partida.estado, "casa:ventana"
	)
	_comprobar(
		zona_invalida.get("resultado", "") == "zona-invalida",
		"no se puede registrar una ventana de casa desde el trayecto",
	)
	_comprobar(partida.estado == antes, "la zona incorrecta no modifica Partida")

	var especial := PasaporteInspeccion.progreso_especial(partida.estado)
	_comprobar(
		int(especial.get("obtenidas", 0)) == 4, "el progreso especial cuenta variantes únicas"
	)
	_comprobar(int(jornada.get("dinero", 0)) == dinero_antes, "las variantes no conceden dinero")
	_comprobar(
		int(jornada.get("acciones", 0)) == acciones_antes, "las variantes no conceden acciones"
	)
	_comprobar(
		partida.estado.get("pistas_descubiertas", []) == pistas_antes,
		"las variantes no conceden pistas",
	)


func _probar_persistencia_variantes() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var jornada: Dictionary = partida.estado["jornada"]
	jornada["dia"] = _primer_dia_lluvioso()
	jornada["fase"] = "trayecto"
	jornada["hora_minutos"] = 20 * 60
	jornada["vuelta"] = 3
	jornada["gato"]["presente"] = false
	PasaporteInspeccion.registrar_observacion_contextual(partida.estado, "trayecto:farola-sodio")

	_comprobar(partida.guardar(RUTA_PRUEBA), "Partida guarda base y variantes")
	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA_PRUEBA)
	_comprobar(carga.get("resultado", "") == "cargada", "Partida recarga el pasaporte especial")
	_comprobar(
		PasaporteInspeccion.variantes(recargada.estado, "trayecto:farola-sodio").size() == 4,
		"las cuatro variantes sobreviven al roundtrip",
	)
	var repetida := PasaporteInspeccion.registrar_observacion_contextual(
		recargada.estado, "trayecto:farola-sodio"
	)
	_comprobar(
		not bool(repetida.get("cambio", true)),
		"la observación tras recargar sigue siendo idempotente",
	)


func _probar_runtime_casa() -> void:
	var dia := DiaFalso.new()
	root.add_child(dia)
	dia.jornada["fase"] = "casa"
	var mundo := Node3D.new()
	mundo.name = "MundoCasa"
	dia._mundo = mundo
	dia.add_child(mundo)
	var ventana := Node3D.new()
	ventana.name = "VentanaCasa"
	mundo.add_child(ventana)
	var app := Controller.new()
	dia.add_child(app)
	app._process(0.0)

	var punto := ventana.find_child("PasaporteInspeccion_casa_ventana", true, false)
	_comprobar(punto is PuntoInspeccion3D, "el runtime monta EXAMINAR sobre la ventana real")
	var colision := punto.get_node_or_null("CollisionShape3D") if punto != null else null
	_comprobar(colision is CollisionShape3D, "el punto runtime tiene CollisionShape3D directa")
	_comprobar(
		colision != null and colision.shape is SphereShape3D,
		"la interacción usa una forma primitiva estable",
	)
	_comprobar((punto as PuntoInspeccion3D).interactuar(null), "la ventana se puede examinar")
	_comprobar(
		PasaporteInspeccion.observado(dia.partida.estado, "casa:ventana"),
		"examinar desde runtime registra el punto",
	)
	_comprobar(dia.guardados == 1, "el primer cambio pide un único guardado")
	(punto as PuntoInspeccion3D).interactuar(null)
	_comprobar(dia.guardados == 1, "repetir sin novedad no vuelve a guardar")
	dia.free()


func _probar_resolucion_de_anclas() -> void:
	var archivo := _dia_con_mundo("archivo")
	var posicion_mesa := _posicion_bulto("archivo", "mesa_clasificacion")
	var mesa := StaticBody3D.new()
	mesa.position = posicion_mesa
	archivo._mundo.add_child(mesa)
	var app_archivo := Controller.new()
	archivo.add_child(app_archivo)
	app_archivo._process(0.0)
	_comprobar(
		(
			mesa.find_child("PasaporteInspeccion_archivo_mesa_clasificacion", true, false)
			is PuntoInspeccion3D
		),
		"el rol declarativo resuelve la mesa de clasificación construida por Espacio3D",
	)
	archivo.free()

	var trayecto := _dia_con_mundo("trayecto")
	var farola := Node3D.new()
	farola.name = "FarolaRetroUrbanSur"
	trayecto._mundo.add_child(farola)
	var app_trayecto := Controller.new()
	trayecto.add_child(app_trayecto)
	app_trayecto._process(0.0)
	_comprobar(
		(
			farola.find_child("PasaporteInspeccion_trayecto_farola_sodio", true, false)
			is PuntoInspeccion3D
		),
		"el prefijo declarativo resuelve una farola real del kit urbano",
	)
	trayecto.free()

	var sueno := _dia_con_mundo("sueño")
	sueno.jornada["sueno_escenas"] = ["peine"]
	var luz := Node3D.new()
	luz.name = "LuzDeSala"
	sueno._mundo.add_child(luz)
	var app_sueno := Controller.new()
	sueno.add_child(app_sueno)
	app_sueno._process(0.0)
	_comprobar(
		luz.find_child("PasaporteInspeccion_sueno_peine", true, false) is PuntoInspeccion3D,
		"la forma peine habilita su punto de inspección onírico",
	)
	sueno.free()

	var otro_sueno := _dia_con_mundo("sueño")
	otro_sueno.jornada["sueno_escenas"] = ["patio"]
	var otra_luz := Node3D.new()
	otra_luz.name = "LuzDeSala"
	otro_sueno._mundo.add_child(otra_luz)
	var app_otro := Controller.new()
	otro_sueno.add_child(app_otro)
	app_otro._process(0.0)
	_comprobar(
		otra_luz.find_child("PasaporteInspeccion_sueno_peine", true, false) == null,
		"otra forma onírica no materializa el sello de peine",
	)
	otro_sueno.free()


func _dia_con_mundo(fase: String) -> DiaFalso:
	var dia := DiaFalso.new()
	root.add_child(dia)
	dia.jornada["fase"] = fase
	dia._mundo = Node3D.new()
	dia._mundo.name = "Mundo_" + fase
	dia.add_child(dia._mundo)
	return dia


func _posicion_bulto(zona: String, rol: String) -> Vector3:
	var espacio := EspaciosCatalogo.de_fase(zona)
	for bulto in espacio.get("bultos", []):
		if String(bulto.get("rol", "")) == rol:
			return bulto.get("pos", Vector3.ZERO)
	return Vector3.INF


func _primer_dia_lluvioso() -> int:
	for dia in range(1, 128):
		if Clima.estado(dia) == Clima.LLUVIA:
			return dia
	return -1


func _contar_ids_del_punto(estado: Dictionary, punto_id: String) -> int:
	var prefijo := PasaporteInspeccion.sello_id(punto_id)
	var cantidad := 0
	for sello in estado.get(Sellos.CLAVE_ESTADO, []):
		if String(sello).begins_with(prefijo):
			cantidad += 1
	return cantidad


func _limpiar_temporales() -> void:
	for ruta in [RUTA_PRUEBA, RUTA_PRUEBA + ".nuevo", RUTA_PRUEBA + ".roto"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PasaporteInspeccionCondiciones154: " + nombre)
