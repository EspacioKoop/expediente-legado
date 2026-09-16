extends SceneTree

## Smoke real del pase global de cuerpo/ropa de #275.
##
## No inspecciona texto fuente: carga `persona.fbx` mediante la misma ruta que el
## juego, deja actuar al autoload y comprueba el árbol 3D resultante. Además usa
## el color real de Puyi desde `Companeros` para demostrar que el perfil explícito
## por NPC sustituye al antiguo hash de orden sin tocar rig ni colisiones.

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var cuerpo := Node3D.new()
	root.add_child(cuerpo)

	var emperador: Dictionary = Companeros.ROSTER[0]
	_comprobar(String(emperador["id"]), "emperador", "el fixture usa a Puyi")
	var creada := Modelos.persona(cuerpo, "persona", emperador["color"])
	_comprobar(creada, "el modelo humano real se puede instanciar")
	if not creada:
		_terminar()
		return

	await process_frame
	await process_frame

	var pieza := cuerpo.get_child(0) as Node3D
	_comprobar(
		String(pieza.scene_file_path) == "res://assets/modelos/persona.fbx",
		"el smoke usa persona.fbx y no un doble de pruebas",
	)

	var esqueleto := _buscar_esqueleto(pieza)
	_comprobar(esqueleto != null, "persona.fbx conserva Skeleton3D")
	if esqueleto == null:
		_terminar()
		return

	_comprobar(esqueleto.has_meta("vestuario_humano_275"), "el autoload marca la figura vestida")
	_comprobar(
		String(esqueleto.get_meta("vestuario_humano_275")),
		"emperador",
		"Puyi recibe su perfil corporal explícito y no un fallback por hash",
	)
	_comprobar(
		String(esqueleto.get_meta("vestuario_identidad_275")),
		"emperador",
		"la identidad resuelta queda visible para depuración visual",
	)
	_comprobar(
		esqueleto.find_child("VestuarioTorso", true, false) is BoneAttachment3D,
		"el torso está anclado al rig",
	)
	_comprobar(
		esqueleto.find_child("VestuarioHombros", true, false) is BoneAttachment3D,
		"la línea de hombros está separada del bloque central",
	)
	_comprobar(
		esqueleto.find_child("VestuarioCintura", true, false) is BoneAttachment3D,
		"la cintura está anclada a pelvis",
	)
	_comprobar(
		not _contiene_colision(esqueleto),
		"el pase visual no introduce colisiones de gameplay",
	)

	cuerpo.queue_free()
	_terminar()


func _buscar_esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _buscar_esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null


func _contiene_colision(nodo: Node) -> bool:
	if nodo is CollisionShape3D or nodo is CollisionPolygon3D:
		return true
	for hijo in nodo.get_children():
		if _contiene_colision(hijo):
			return true
	return false


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error(
		"FALLO Vestuario humano #275: %s (actual=%s esperado=%s)" % [nombre, actual, esperado]
	)


func _terminar() -> void:
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)
