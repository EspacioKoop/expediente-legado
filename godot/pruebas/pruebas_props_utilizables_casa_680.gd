## Integración de la palanca CC0 con una consecuencia doméstica real (#680/#93).
extends SceneTree

const Props := preload("res://guion/props_utilizables_cc0.gd")
const CasaConsecuencias := preload("res://guion/casa_consecuencias_3d.gd")
const CasaEstadoAmbiental := preload("res://guion/casa_estado_ambiental.gd")
const CasaUtileriaScript := preload("res://guion/casa_utileria.gd")
const PersianaScript := preload("res://guion/persiana_atascada_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var casa := Node3D.new()
	root.add_child(casa)
	CasaUtileriaScript.montar(casa)

	var jornada := Jornada.nueva(680093, 1)
	jornada["imprevistos"]["consecuencias"] = [
		"casa_persiana_atascada",
		"casa_grifo_averiado",
	]
	var inventario := Inventario.nuevo()
	var estado := CasaEstadoAmbiental.derivar(jornada, inventario)
	var capa := CasaConsecuencias.montar(casa, estado, jornada, inventario)
	var persiana := capa.get_node_or_null("PersianaAtascada") as PersianaScript

	_comprobar(persiana != null, "la avería monta una persiana interactuable")
	_comprobar(
		persiana != null and persiana.get_node_or_null("VolumenInteraccion") != null,
		"la persiana expone volumen de interacción"
	)
	_comprobar(
		persiana != null and String(persiana.get_meta("uso_requerido", "")) == "forzar",
		"la avería declara el uso semántico forzar"
	)
	if persiana == null:
		casa.queue_free()
		await process_frame
		print("%d pasadas, %d fallos" % [_pasadas, _fallos])
		quit(1)
		return

	_comprobar(not persiana.interactuar(root), "sin herramienta no se repara")
	_comprobar(
		Imprevistos.consecuencias(jornada).has("casa_persiana_atascada"),
		"rechazar la interacción conserva la consecuencia"
	)

	var palanca := Props.objeto_inventario("palanca_kkryy")
	_comprobar(palanca.get("usos", []).has("forzar"), "la palanca aporta el uso requerido")
	_comprobar(Inventario.recoger(inventario, palanca), "la palanca entra por Inventario")
	_comprobar(
		Inventario.guardar_en_casa(inventario, "palanca_kkryy"),
		"la herramienta puede estar guardada en casa"
	)
	var herramienta := persiana.herramienta_disponible()
	_comprobar(
		String(herramienta.get("id", "")) == "palanca_kkryy",
		"la persiana encuentra la palanca por uso y no por UI paralela"
	)

	_comprobar(persiana.interactuar(root), "la palanca permite forzar la persiana")
	_comprobar(
		not Imprevistos.consecuencias(jornada).has("casa_persiana_atascada"),
		"reparar retira la consecuencia de Imprevistos"
	)
	_comprobar(
		Imprevistos.consecuencias(jornada).has("casa_grifo_averiado"),
		"la reparación no borra otras consecuencias"
	)
	_comprobar(
		Inventario.contiene(inventario, "palanca_kkryy"),
		"usar la palanca no la consume"
	)
	_comprobar(
		String(persiana.get_meta("herramienta_usada", "")) == "palanca_kkryy",
		"la interacción registra qué herramienta resolvió la avería"
	)
	_comprobar(
		not Imprevistos.reparar_consecuencia(jornada, "consecuencia_inventada"),
		"Imprevistos no permite retirar consecuencias fuera de catálogo"
	)

	var reparado := CasaEstadoAmbiental.derivar(jornada, inventario)
	var capa_reparada := CasaConsecuencias.montar(casa, reparado, jornada, inventario)
	_comprobar(
		capa_reparada.get_node_or_null("PersianaAtascada") == null,
		"el siguiente montaje retira físicamente la persiana averiada"
	)
	_comprobar(
		capa_reparada.get_node_or_null("GrifoGoteando") != null,
		"otras huellas domésticas permanecen"
	)

	casa.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO props utilizables casa #680: " + mensaje)
