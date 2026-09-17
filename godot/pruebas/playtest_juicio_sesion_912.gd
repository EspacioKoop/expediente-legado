## Runner manual para la matriz de playtest del Juicio por Combate (#912).
##
## Ejemplo:
## godot4 --path godot --script res://pruebas/playtest_juicio_sesion_912.gd -- \
##   --escenario=sol-maui
##
## Al terminar imprime una línea `PLAYTEST_912_JSON=...` con las métricas de la
## sesión. No carga ni guarda una Partida.
extends SceneTree

const ESCENARIOS := {
	"base": {},
	"luna-minotauro": {"arcano": "la-luna", "mito": "minotauro"},
	"justicia-duat": {"arcano": "la-justicia", "mito": "duat"},
	"fuerza-aquiles": {"arcano": "la-fuerza", "mito": "aquiles"},
	"sol-maui": {"arcano": "el-sol", "mito": "maui_tamanuitera"},
	"colgado-anansi": {"arcano": "el-colgado", "mito": "anansi_akan"},
	"muerte-hidra": {"arcano": "la-muerte", "mito": "hidra"},
}

var _juicio: JuicioCombatePlaytest912
var _escenario := "base"
var _reduccion_movimiento := false


func _initialize() -> void:
	call_deferred("_arrancar")


func _arrancar() -> void:
	_leer_argumentos()
	if not ESCENARIOS.has(_escenario):
		push_error("Escenario #912 desconocido: %s" % _escenario)
		print("Escenarios: %s" % ", ".join(ESCENARIOS.keys()))
		quit(2)
		return

	_juicio = JuicioCombatePlaytest912.new()
	_juicio.configurar(
		{"id": "playtest_912", "nombre": "PLAYTEST #912"},
		0,
		_reduccion_movimiento,
	)
	_configurar_ritual(_juicio, ESCENARIOS[_escenario])
	_juicio.terminado.connect(_al_terminar)
	root.add_child(_juicio)
	process_frame.connect(_vigilar_cancelacion)
	print("PLAYTEST #912 · %s" % _escenario)
	print("Movimiento: WASD/flechas · ligero: interactuar · fuerte: saltar · esquiva: agacharse")
	print("Cancelar: acción cancelar/ui_cancel · reducción de movimiento: %s" % _reduccion_movimiento)


func _leer_argumentos() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--escenario="):
			_escenario = argumento.trim_prefix("--escenario=").strip_edges()
		elif argumento == "--reduccion-movimiento":
			_reduccion_movimiento = true


func _configurar_ritual(juicio: JuicioCombatePlaytest912, datos: Dictionary) -> void:
	if datos.is_empty():
		return
	var arcano := {"id": String(datos["arcano"]), "recogida": true, "gastada": false}
	var mito := String(datos["mito"])
	juicio._arcano = arcano
	juicio._mito_id = mito
	juicio._ritual = JuicioSimbolico.ritual_para(arcano, mito)
	juicio._aplicar_configuracion_ritual()


func _vigilar_cancelacion() -> void:
	if _juicio == null or _juicio._acabado:
		return
	if Input.is_action_just_pressed("cancelar") or Input.is_action_just_pressed("ui_cancel"):
		_juicio.abandonar()


func _al_terminar(_gano: bool) -> void:
	var resumen := _juicio.resumen_playtest()
	resumen["escenario"] = _escenario
	resumen["reduccion_movimiento"] = _reduccion_movimiento
	print("PLAYTEST_912_JSON=%s" % JSON.stringify(resumen))
	call_deferred("_cerrar")


func _cerrar() -> void:
	quit(0)
