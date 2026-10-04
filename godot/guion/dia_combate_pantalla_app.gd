## Lifecycle visual del combate contextual de DiaApp (#1761 / #2289).
##
## No autoriza combates ni interpreta resultados. Monta la superficie temporal
## bajo el anfitrión y conserva sus dos referencias para limpiarlas juntas.
class_name DiaCombatePantallaApp
extends RefCounted

var _pantalla: CanvasLayer
var _app: DiaCombateContextualApp


func abrir(
	anfitrion: Node,
	objetivo: Dictionary,
	decision: Dictionary,
	zona: Area3D,
	caminante: CharacterBody3D,
	mundo: Node3D,
	hud: CanvasLayer,
	ambiente: Environment,
	partida: Partida,
	jornada: Dictionary,
	raiz: int,
	al_terminar: Callable,
) -> Dictionary:
	if activa() or anfitrion == null or not al_terminar.is_valid():
		return {"ok": false}

	_pantalla = CanvasLayer.new()
	_pantalla.name = "PantallaCombateContextual"
	anfitrion.add_child(_pantalla)

	_app = DiaCombateContextualApp.new()
	_app.name = "DiaCombateContextualApp"
	anfitrion.add_child(_app)
	_app.terminado.connect(al_terminar)

	if not _app.abrir(
		objetivo,
		decision,
		zona,
		caminante,
		mundo,
		hud,
		ambiente,
		partida,
		jornada,
		raiz,
	):
		cerrar()
		return {"ok": false}

	return {
		"ok": true,
		"pantalla": _pantalla,
		"app": _app,
	}


func cerrar() -> void:
	var app := _app
	var pantalla := _pantalla
	_app = null
	_pantalla = null
	if is_instance_valid(app):
		app.queue_free()
	if is_instance_valid(pantalla):
		pantalla.queue_free()


func activa() -> bool:
	return is_instance_valid(_app) or is_instance_valid(_pantalla)
