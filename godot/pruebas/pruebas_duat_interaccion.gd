## Smoke aislado del pesaje interactivo del Duat (#441).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var objetos := [
		{
			"id": "factura",
			"peso": 1.0,
			"peso_sellado": 1.5,
			"manipulado_hoy": true,
		},
		{
			"id": "rom",
			"peso": 2.0,
			"peso_sellado": 2.5,
			"manipulado_hoy": true,
		},
		{
			"id": "telefono",
			"peso": 3.0,
			"manipulado_hoy": true,
		},
		{
			"id": "objeto_no_tocado",
			"peso": 99.0,
			"manipulado_hoy": false,
		},
	]

	var encuentro := SuenoDuatInteraccion3D.new()
	root.add_child(encuentro)
	_comprobar(encuentro.configurar(objetos, 0, true), "pesaje interactivo configurado")
	_comprobar(
		encuentro.estado_pesaje().get("objetos", []).size() == 3, "solo recuerdos manipulados"
	)

	var factura := encuentro.interactuable("factura")
	var rom := encuentro.interactuable("rom")
	var telefono := encuentro.interactuable("telefono")
	_comprobar(factura != null and rom != null and telefono != null, "tres contrapesos alcanzables")

	var actor := Node.new()
	actor.name = "ActorPrueba"
	root.add_child(actor)

	if factura != null and rom != null and telefono != null:
		_comprobar(rom.interactuar(actor), "ROM colocada con peso observado")
		_comprobar(
			encuentro.seleccion_actual().get("rom", true) == false,
			"primer uso pesa valor observado"
		)
		_comprobar(
			rom.get_meta("duat_estado", "") == "observado", "estado observado visible en hotspot"
		)
		_comprobar(rom.interactuar(actor), "ROM pasa a variante sellada")
		_comprobar(
			encuentro.seleccion_actual().get("rom", false) == true, "segundo uso pesa valor sellado"
		)
		_comprobar(
			rom.get_meta("duat_estado", "") == "sellado", "estado sellado visible en hotspot"
		)
		_comprobar(rom.interactuar(actor), "tercer uso retira ROM")
		_comprobar(not encuentro.seleccion_actual().has("rom"), "ciclo vuelve a fuera")

		# Con semilla 0, el objetivo determinista es factura + telefono = 4.0.
		_comprobar(factura.interactuar(actor), "factura colocada")
		_comprobar(not encuentro.resuelto(), "una pieza no resuelve el pesaje")
		_comprobar(telefono.interactuar(actor), "telefono colocado")
		_comprobar(encuentro.resuelto(), "peso observable correcto equilibra la balanza")
		_comprobar(
			encuentro.resultado_actual().get("equilibrado", false) == true,
			"resultado físico equilibrado"
		)
		_comprobar(not factura.interactuar(actor), "interacciones bloqueadas tras resolver")
		_comprobar(not telefono.interactuar(actor), "resolución idempotente")

	var prototipo := encuentro.prototipo()
	_comprobar(prototipo != null, "prototipo monumental reutilizado")
	if prototipo != null:
		var presentacion: Dictionary = prototipo.get_meta("duat_presentacion", {})
		_comprobar(
			presentacion.get("transicion_piramide", "") == "estado_discreto",
			"reducción de movimiento conserva estado discreto",
		)
		var inferior := (
			prototipo.get_node_or_null("ArquitecturaPesable/PiramideInferior") as MeshInstance3D
		)
		var invertida := (
			prototipo.get_node_or_null("ArquitecturaPesable/PiramideInvertida") as MeshInstance3D
		)
		_comprobar(
			(
				inferior != null
				and inferior.position.is_equal_approx(SuenoDuat.POS_PIRAMIDE_INFERIOR_EQUILIBRIO)
			),
			"pirámide inferior transforma al equilibrar",
		)
		_comprobar(
			(
				invertida != null
				and invertida.position.is_equal_approx(SuenoDuat.POS_PIRAMIDE_INVERTIDA_EQUILIBRIO)
			),
			"pirámide invertida responde al peso",
		)

	_finalizar(encuentro, actor)


func _finalizar(encuentro: Node, actor: Node) -> void:
	if is_instance_valid(actor):
		actor.queue_free()
	if is_instance_valid(encuentro):
		encuentro.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO Duat interactivo: " + nombre)
