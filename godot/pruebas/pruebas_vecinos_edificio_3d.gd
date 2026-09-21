extends SceneTree

const Presentacion := preload("res://guion/vecinos_edificio_3d.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)

	var dia_uno := {"fase": "trayecto", "dia": 1}
	var capa_uno := Presentacion.montar(mundo, dia_uno, false)
	_comprobar(capa_uno != null, "monta la capa en trayecto")
	_comprobar(capa_uno.get_node_or_null("FelpudoPortal") != null, "monta el felpudo")
	_comprobar(capa_uno.get_node_or_null("TablonComunidad") != null, "monta el tablon")
	_comprobar(capa_uno.get_node_or_null("LuzPortal") != null, "monta la luz")
	_comprobar(capa_uno.get_node_or_null("Puerta2A") != null, "monta la puerta")
	_comprobar(capa_uno.get_node_or_null("Manuela3B") != null, "materializa a Manuela")

	var capa_reducida := Presentacion.montar(mundo, dia_uno, true)
	var manuela := capa_reducida.get_node_or_null("Manuela3B")
	_comprobar(manuela != null, "Manuela sigue presente con reduccion de movimiento")
	_comprobar(
		String(manuela.get_meta("movimiento", "")) == "estatico",
		"reduccion de movimiento elimina el gesto"
	)

	var dia_dos := {"fase": "trayecto", "dia": 2}
	var capa_dos := Presentacion.montar(mundo, dia_dos, false)
	_comprobar(
		capa_dos.get_node_or_null("PresenciaTelevisor2A") != null,
		"la presencia sonora del 2A tiene huella visual"
	)

	var dia_tres := {"fase": "trayecto", "dia": 3}
	var capa_tres := Presentacion.montar(mundo, dia_tres, false)
	_comprobar(
		capa_tres.get_node_or_null("PresenciaPasos4A") != null,
		"los pasos del 4A tienen huella visual"
	)

	var dia_ocho := {"fase": "trayecto", "dia": 8}
	var capa_ocho := Presentacion.montar(mundo, dia_ocho, false)
	var paquete := capa_ocho.get_node_or_null("PaqueteEquivocado")
	_comprobar(
		capa_ocho.get_node_or_null("RepartidorConfundido") != null,
		"materializa al repartidor"
	)
	_comprobar(paquete != null, "materializa el paquete equivocado cuando toca")
	_comprobar(paquete is Interactuable3D, "el paquete usa el contrato comun")
	_comprobar(
		String(paquete.get_meta("correo_postal", "")) == "buzon_portal",
		"el paquete comparte ancla conceptual con correo postal"
	)
	_comprobar(
		paquete.get_node_or_null("VolumenInteraccion") != null,
		"el paquete ofrece volumen de interaccion"
	)

	var resultado := VecinosEdificio.resolver_interaccion(
		dia_ocho, VecinosEdificio.ID_PAQUETE_EQUIVOCADO
	)
	_comprobar(bool(resultado.get("ok", false)), "la interaccion se resuelve")
	Presentacion.marcar_paquete_resuelto(capa_ocho)
	_comprobar(
		capa_ocho.get_node_or_null("PaqueteEquivocado") == null,
		"el paquete deja el suelo al resolverlo"
	)
	_comprobar(
		capa_ocho.get_node_or_null("Paquete4AColocado") != null,
		"el paquete queda representado junto al buzon"
	)

	var capa_recarga := Presentacion.montar(mundo, dia_ocho, false)
	_comprobar(
		capa_recarga.get_node_or_null("PaqueteEquivocado") == null,
		"la recarga no duplica la interaccion"
	)
	_comprobar(
		capa_recarga.get_node_or_null("Paquete4AColocado") != null,
		"la recarga conserva el resultado visual"
	)

	mundo.free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(0 if _fallos == 0 else 1)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO VecinosEdificio3D: " + nombre)
