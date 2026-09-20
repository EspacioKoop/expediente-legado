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

	await _probar_figura_liberada(cuerpo)

	cuerpo.queue_free()
	_terminar()


## Regresión: una figura que desaparece entre `node_added` y el volcado diferido
## no puede romper el pase. Antes se difería la referencia al nodo, y
## `MessageQueue` rechazaba el argumento de una figura ya liberada antes de que
## `is_instance_valid` llegara a mirarlo. El pase entra ahora por id, que es
## justamente lo que sobrevive a la liberación.
func _probar_figura_liberada(cuerpo: Node3D) -> void:
	var efimero := Node3D.new()
	cuerpo.add_child(efimero)
	_comprobar(
		Modelos.persona(efimero, "persona", Color(0.4, 0.4, 0.45)),
		"la figura efímera se instancia con la misma ruta que el juego",
	)
	var caducado := efimero.get_child(0).get_instance_id()
	# Liberada en el mismo fotograma: el volcado diferido llega cuando ya no existe.
	efimero.free()

	var vestuario := root.get_node_or_null("VestuarioHumano3D")
	var correccion := root.get_node_or_null("CorreccionVisualNPC275")
	_comprobar(vestuario != null, "el autoload de vestuario está montado")
	_comprobar(correccion != null, "el autoload de corrección de rostro está montado")
	if vestuario == null or correccion == null:
		return
	_comprobar(
		vestuario.has_method("_vestir_diferido"),
		"el pase se difiere por id, que es lo que sobrevive a liberar la figura",
	)
	_comprobar(
		correccion.has_method("_corregir_diferido"),
		"la corrección de rostro también se difiere por id",
	)
	_comprobar(
		instance_from_id(caducado) == null,
		"el id de la figura liberada ya no resuelve a ningún objeto",
	)
	if vestuario.has_method("_vestir_diferido"):
		vestuario._vestir_diferido(caducado)
	if correccion.has_method("_corregir_diferido"):
		await correccion._corregir_diferido(caducado)
	_comprobar(true, "un id caducado atraviesa ambos pases sin efecto y sin error")

	await process_frame
	await process_frame

	var superviviente := Node3D.new()
	cuerpo.add_child(superviviente)
	var siguiente: Dictionary = Companeros.ROSTER[1]
	_comprobar(
		Modelos.persona(superviviente, "persona", siguiente["color"]),
		"tras la figura liberada se puede instanciar otra",
	)
	await process_frame
	await process_frame

	var esqueleto := _buscar_esqueleto(superviviente)
	_comprobar(esqueleto != null, "la figura posterior conserva Skeleton3D")
	if esqueleto != null:
		_comprobar(
			esqueleto.has_meta("vestuario_humano_275"),
			"una figura liberada antes del volcado no deja sin vestir a la siguiente",
		)
	superviviente.queue_free()


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
