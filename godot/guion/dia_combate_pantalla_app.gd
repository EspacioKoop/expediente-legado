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
	contexto: Dictionary,
	al_terminar: Callable,
) -> Dictionary:
	if activa() or anfitrion == null or not al_terminar.is_valid():
		return {"ok": false}
	var caminante := contexto.get("caminante") as CharacterBody3D
	var mundo := contexto.get("mundo") as Node3D
	var hud := contexto.get("hud") as CanvasLayer
	var ambiente := contexto.get("ambiente") as Environment
	var partida := contexto.get("partida") as Partida
	var jornada: Dictionary = contexto.get("jornada", {})
	var raiz := int(contexto.get("raiz", 0))
	if caminante == null or partida == null:
		return {"ok": false}

	_pantalla = CanvasLayer.new()
	_pantalla.name = "PantallaCombateContextual"
	anfitrion.add_child(_pantalla)

	_app = DiaCombateContextualApp.new()
	_app.name = "DiaCombateContextualApp"
	anfitrion.add_child(_app)
	_app.terminado.connect(al_terminar)

	if not (
		_app
		. abrir(
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
		)
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
