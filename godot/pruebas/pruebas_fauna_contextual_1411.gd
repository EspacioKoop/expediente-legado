extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_catalogo_variantes()
	_probar_determinismo()
	_probar_contexto_calle()
	_probar_sueno_onirico()
	await _probar_microgestos()
	_probar_contrato_ligero()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_catalogo_variantes() -> void:
	for especie in ["paloma", "gorrion", "perro", "cuervo", "polilla", "ciervo"]:
		var variantes: Array = FaunaAmbiental.VARIANTES.get(especie, [])
		_comprobar(variantes.size() == 2, "#1411: " + especie + " tiene dos variantes")
		for variante in variantes:
			var ficha := variante as Dictionary
			_comprobar(not String(ficha.get("id", "")).is_empty(), "#1411: variante con id")
			_comprobar(ficha.has("color"), "#1411: variante declara color")
			_comprobar(float(ficha.get("escala", 0.0)) > 0.0, "#1411: variante declara escala")


func _probar_determinismo() -> void:
	var a := FaunaAmbiental.plan("trayecto", {}, 7, 998877)
	var b := FaunaAmbiental.plan("trayecto", {}, 7, 998877)
	_comprobar(a.size() == 6, "#1411: contexto vacío conserva seis piezas históricas")
	_comprobar(a == b, "#1411: mismo día y raíz repiten variantes y posiciones")
	for dato in a:
		var pieza := dato as Dictionary
		_comprobar(not String(pieza.get("variante", "")).is_empty(), "#1411: cada pieza tiene variante")
		_comprobar(is_equal_approx(float(pieza.get("ritmo", 0.0)), 1.0), "#1411: base conserva ritmo")


func _probar_contexto_calle() -> void:
	var lluvia := FaunaAmbiental.plan("trayecto", {}, 7, 998877, "", Clima.LLUVIA, "tarde")
	var noche := FaunaAmbiental.plan("trayecto", {}, 7, 998877, "", Clima.DESPEJADO, "noche")
	_comprobar(lluvia.size() == 5, "#1411: lluvia retira un gorrión")
	_comprobar(noche.size() == 4, "#1411: noche retira una paloma y un gorrión")
	_comprobar(_contar(lluvia, "gorrion") == 1, "#1411: lluvia conserva un gorrión")
	_comprobar(_contar(noche, "gorrion") == 1, "#1411: noche conserva un gorrión")
	_comprobar(_contar(noche, "paloma") == 2, "#1411: noche conserva dos palomas")
	var perro_lluvia := _primero(lluvia, "perro")
	var perro_noche := _primero(noche, "perro")
	_comprobar(float(perro_lluvia.get("ritmo", 1.0)) < 0.5, "#1411: perro se aquieta con lluvia")
	_comprobar(float(perro_noche.get("ritmo", 1.0)) < 1.0, "#1411: perro baja ritmo de noche")


func _probar_sueno_onirico() -> void:
	var espacio := {
		"entrada": Vector3(0, 0, 4),
		"salidas": [{"pos": Vector3(0, 1.1, -12)}],
	}
	var plan := FaunaAmbiental.plan("sueño", espacio, 7, 998877, "crucero")
	_comprobar(plan.size() == 6, "#1411: sueño conserva seis presencias")
	for dato in plan:
		var pieza := dato as Dictionary
		_comprobar(bool(pieza.get("onirico", false)), "#1411: fauna de sueño queda marcada")
	var ciervo := _primero(plan, "ciervo")
	_comprobar(
		String(ciervo.get("variante", "")) == "palido_onirico",
		"#1411: ciervo usa variante pálida en sueño",
	)
	_comprobar(float(ciervo.get("ritmo", 1.0)) < 0.6, "#1411: ciervo onírico se mueve despacio")
	var polilla := _primero(plan, "polilla")
	_comprobar(float(polilla.get("ritmo", 1.0)) > 1.0, "#1411: polilla onírica aletea más viva")


func _probar_microgestos() -> void:
	var perro := _animal_de("perro", Clima.LLUVIA, "tarde")
	var cabeza := perro.get_node_or_null("Visual/Cabeza") as Node3D
	var cola := perro.get_node_or_null("Visual/Cola") as Node3D
	var cabeza_antes := cabeza.rotation
	var cola_antes := cola.rotation
	perro.animar_pieza(perro.id_fauna(), 2.7, 0.0, AnimacionAmbiental.LOD_CERCA)
	_comprobar(cabeza.rotation != cabeza_antes, "#1411: perro añade gesto de olfateo")
	_comprobar(cola.rotation != cola_antes, "#1411: perro conserva cola viva")
	_comprobar(perro.variante() != "base", "#1411: AnimalAmbiental3D expone variante")
	_comprobar(perro.ritmo() < 0.5, "#1411: AnimalAmbiental3D recibe ritmo contextual")
	perro.queue_free()
	await process_frame

	var espacio := {
		"entrada": Vector3(0, 0, 4),
		"salidas": [{"pos": Vector3(0, 1.1, -12)}],
	}
	var ciervo_dato := _primero(FaunaAmbiental.plan("sueño", espacio, 4, 1122, "crucero"), "ciervo")
	var ciervo := AnimalAmbiental3D.new()
	root.add_child(ciervo)
	ciervo.configurar(ciervo_dato, null, false)
	var cuello := ciervo.get_node_or_null("Visual/Cuello") as Node3D
	var cuello_antes := cuello.rotation
	ciervo.animar_pieza(ciervo.id_fauna(), 3.1, 0.0, AnimacionAmbiental.LOD_CERCA)
	_comprobar(cuello.rotation != cuello_antes, "#1411: ciervo respira/tensa cuello")
	_comprobar(
		String(ciervo.get_meta("variante_fauna", "")) == "palido_onirico",
		"#1411: variante queda disponible como metadata",
	)
	ciervo.queue_free()
	await process_frame


func _probar_contrato_ligero() -> void:
	var script := FileAccess.get_file_as_string("res://guion/animal_ambiental_3d.gd")
	_comprobar(script.find("func _process(") < 0, "#1411: animal sigue sin _process")
	_comprobar(script.find("Area3D") < 0, "#1411: no añade Area3D")
	_comprobar(script.find("CollisionShape3D") < 0, "#1411: no añade colisiones")
	_comprobar(script.find("Navigation") < 0, "#1411: no añade navegación")


func _animal_de(especie: String, clima: String, franja: String) -> AnimalAmbiental3D:
	var plan := FaunaAmbiental.plan("trayecto", {}, 7, 998877, "", clima, franja)
	var dato := _primero(plan, especie)
	var animal := AnimalAmbiental3D.new()
	root.add_child(animal)
	animal.configurar(dato, null, false)
	return animal


func _primero(plan: Array, especie: String) -> Dictionary:
	for dato in plan:
		var pieza := dato as Dictionary
		if String(pieza.get("especie", "")) == especie:
			return pieza
	return {}


func _contar(plan: Array, especie: String) -> int:
	var total := 0
	for dato in plan:
		if String((dato as Dictionary).get("especie", "")) == especie:
			total += 1
	return total


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO FaunaV4: " + nombre)
