## Regresión headless del adaptador mixto 2+1 (#2295 / #2067).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const RUNTIME = preload("res://guion/juicio_combate_mixto_runtime_2067.gd")
const MIXTO = preload("res://guion/juicio_combate_mixto_host_3d.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_composicion_y_determinismo()
	_probar_presupuesto_enjambre()
	_probar_derrotas_independientes()
	_probar_terminacion_sin_softlock()
	_probar_reduccion_movimiento_no_altera_runtime()
	await _probar_limpieza_idempotente()
	print("mixto_host_2067: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_composicion_y_determinismo() -> void:
	for tipo in [ARQUETIPOS.BLOQUEADOR, ARQUETIPOS.HOSTIGADOR]:
		var primero := RUNTIME.nuevo(2067, tipo)
		var segundo := RUNTIME.nuevo(2067, tipo)
		_comprobar(primero == segundo, "misma seed conserva composición %s" % tipo)
		_comprobar(primero["enjambre"].size() == 2, "composición %s usa dos ENJAMBRE" % tipo)
		_comprobar(String(primero["singular"]["tipo"]) == tipo, "conserva singular %s" % tipo)


func _probar_presupuesto_enjambre() -> void:
	var estado := RUNTIME.nuevo(2067, ARQUETIPOS.BLOQUEADOR)
	for unidad in estado["enjambre"]:
		unidad["cooldown"] = 0.0
	for _tick in range(240):
		var paso := RUNTIME.avanzar(estado, 0.02)
		estado = paso["estado"]
		_comprobar(
			int(paso["enjambre"]["atacantes_activos"]) <= HOST.presupuesto_enjambre(),
			"el adaptador conserva como máximo dos ataques ENJAMBRE",
		)


func _probar_derrotas_independientes() -> void:
	var estado := RUNTIME.nuevo(2067, ARQUETIPOS.HOSTIGADOR)
	var paso := RUNTIME.avanzar(estado, 0.01, {}, [], true)
	_comprobar(not bool(paso["singular_vivo"]), "singular cae sin derrotar ENJAMBRE")
	_comprobar(int(paso["vivos_enjambre"]) == 2, "ENJAMBRE continúa tras caída singular")

	estado = RUNTIME.nuevo(2067, ARQUETIPOS.BLOQUEADOR)
	paso = RUNTIME.avanzar(estado, 0.01, {}, [0, 1])
	_comprobar(int(paso["vivos_enjambre"]) == 0, "ENJAMBRE puede caer antes que singular")
	_comprobar(bool(paso["singular_vivo"]), "singular continúa tras caída ENJAMBRE")


func _probar_terminacion_sin_softlock() -> void:
	var estado := RUNTIME.nuevo(2067, ARQUETIPOS.BLOQUEADOR)
	var paso := RUNTIME.avanzar(estado, 0.01, {}, [0, 1], true)
	_comprobar(bool(paso["terminado"]), "termina al caer los tres rivales")
	var repetido := RUNTIME.avanzar(paso["estado"], 1.0)
	_comprobar(bool(repetido["terminado"]), "terminación repetida no revive ni bloquea arena")


func _probar_reduccion_movimiento_no_altera_runtime() -> void:
	var estado := RUNTIME.nuevo(2067, ARQUETIPOS.HOSTIGADOR)
	var paso := RUNTIME.avanzar(estado, 0.2, {"distancia": 6.0, "rumbo_objetivo": 0.5})
	var estado_antes: Dictionary = paso["estado"].duplicate(true)
	var presentacion := ARQUETIPOS.presentacion(paso["singular"], true)
	_comprobar(
		String(presentacion["estilo"]) == "corte", "reducción usa presentación sin animación"
	)
	_comprobar(paso["estado"] == estado_antes, "reducción no cambia estados ni temporizadores")


func _probar_limpieza_idempotente() -> void:
	var anfitrion := Node3D.new()
	var rival := CharacterBody3D.new()
	anfitrion.add_child(rival)
	root.add_child(anfitrion)
	var estado := MIXTO.montar(anfitrion, rival, {"id": "prueba-mixto"}, "", 2067)
	_comprobar(not estado.is_empty(), "el adaptador monta composición mixta")
	MIXTO.limpiar(estado)
	_comprobar(estado.is_empty(), "limpieza vacía el estado del adaptador")
	MIXTO.limpiar(estado)
	_comprobar(estado.is_empty(), "limpieza repetida es idempotente")
	anfitrion.queue_free()
	await process_frame


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2295 mixto: " + mensaje)
