## Regresión física de la galería: instanciar la escena real, seleccionar una
## vitrina, entrar/salir de la posibilidad y conservar el estado del juego.
extends SceneTree

const ESCENA = preload("res://escenas/museo_vidas_no_ocurridas.tscn")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var contexto := {
		"dia": 3,
		"vuelta": 2,
		"fase": "trayecto",
		"companeros": ["mari"],
		"eventos": [{"id": "incidente"}],
	}
	var original := contexto.duplicate(true)
	var museo := ESCENA.instantiate() as SuenoMuseoEscena2430
	_comprobar(museo != null, "la escena instancia un Node3D con script compatible")
	if museo == null:
		_terminar()
		return
	museo.configurar(contexto, 2430)
	root.add_child(museo)
	await process_frame

	var opciones := museo.opciones()
	_comprobar(opciones.size() == 3, "tres vitrinas con posibilidades")
	_comprobar(
		(
			(
				opciones
				. filter(func(opcion: Dictionary) -> bool: return bool(opcion["explorable"]))
				. size()
			)
			== 1
		),
		"exactamente una posibilidad explorable",
	)
	_comprobar(contexto == original, "seleccionar no modifica Partida ni contexto")
	var actor := CharacterBody3D.new()
	root.add_child(actor)
	actor.global_position = Vector3(1.0, 0.0, 2.0)
	var regreso := actor.global_transform

	for indice in range(3):
		var zona := museo.get_node("InteraccionesMuseo/Examinar%d" % (indice + 1))
		_comprobar(zona is Interactuable3D, "hay interacción física en vitrina %d" % indice)
		_comprobar(zona.interactuar(actor), "se puede examinar la vitrina %d" % indice)
		_comprobar(museo.indice_seleccionado() == indice, "selección coincide con vitrina")
		var portal := museo.get_node("InteraccionesMuseo/EntrarVidaPosible")
		_comprobar(
			bool(portal.habilitado) == bool(opciones[indice]["explorable"]),
			"solo la vitrina elegida y explorable abre el portal",
		)
		_comprobar(contexto == original, "examinar no altera los datos de la campaña")

	var indice_explorable := -1
	for indice in range(opciones.size()):
		if bool(opciones[indice]["explorable"]):
			indice_explorable = indice
			break
	_comprobar(indice_explorable >= 0, "hay una ruta de exploración")
	var acceso := museo.get_node("InteraccionesMuseo/Examinar%d" % (indice_explorable + 1))
	acceso.interactuar(actor)
	var portal := museo.get_node("InteraccionesMuseo/EntrarVidaPosible")
	_comprobar(portal.interactuar(actor), "se entra físicamente en la vida posible")
	_comprobar(museo.explorando(), "el museo registra entrada local")
	_comprobar(museo.get_node("SalaPosible").visible, "la sala alternativa se muestra al entrar")
	_comprobar(
		not actor.global_transform.is_equal_approx(regreso),
		"el actor alcanza el espacio explorable"
	)
	var documento := museo.get_node("SalaPosible/LeerExpedientePosible")
	_comprobar(documento.interactuar(actor), "la vida alternativa se puede leer")
	var ficha := museo.get_node("VisorMuseo/FichaNoCanonica")
	_comprobar(ficha.visible, "la historia alternativa aparece al explorarla")
	var texto := museo.get_node("VisorMuseo/FichaNoCanonica/TextoPosibilidad")
	_comprobar(texto.text.contains("NO CANÓNICO"), "la lectura no se presenta como prueba")
	var salida := museo.get_node("SalaPosible/RegresarMuseo")
	_comprobar(salida.interactuar(actor), "la sala permite regresar sin softlock")
	_comprobar(not ficha.visible, "la lectura desaparece al volver al museo")
	_comprobar(not museo.explorando(), "salir termina la exploración")
	_comprobar(
		actor.global_transform.is_equal_approx(regreso), "se restituye el transform del actor"
	)
	_comprobar(contexto == original, "entrada y regreso no escriben estado canónico")
	actor.queue_free()
	museo.queue_free()
	await process_frame
	_terminar()


func _terminar() -> void:
	print("museo_escena_2430: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(descripcion)
