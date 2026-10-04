## Ciclo visual del combate contextual de Dia (#1761/#2289).
##
## Solo monta y desmonta la superficie. La autorización, las consecuencias,
## el guardado y los cambios de fase siguen perteneciendo a DiaApp.
class_name DiaCombatePantallaApp
extends RefCounted


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
	if anfitrion == null or not al_terminar.is_valid():
		return {}

	var pantalla := CanvasLayer.new()
	pantalla.name = "PantallaCombateContextual"
	anfitrion.add_child(pantalla)

	var app := DiaCombateContextualApp.new()
	app.name = "CombateContextualApp"
	anfitrion.add_child(app)
	app.terminado.connect(al_terminar)

	if not app.abrir(
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
		cerrar(app, pantalla)
		return {}

	return {
		"pantalla": pantalla,
		"app": app,
	}


func cerrar(app: DiaCombateContextualApp, pantalla: CanvasLayer) -> void:
	if is_instance_valid(app):
		app.queue_free()
	if is_instance_valid(pantalla):
		pantalla.queue_free()
