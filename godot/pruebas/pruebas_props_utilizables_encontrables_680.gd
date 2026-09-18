## Recorrido normal de la palanca de #680: aparece, se recoge y no respawnea.
extends SceneTree

const Encontrables := preload("res://guion/props_utilizables_encontrables_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var mundo := Node3D.new()
	mundo.name = "CasaFixture"
	root.add_child(mundo)

	var ancla := Node3D.new()
	ancla.name = "AlmacenamientoCasa"
	ancla.position = Vector3(1.0, 0.0, 2.0)
	ancla.rotation_degrees.y = 180.0
	mundo.add_child(ancla)

	var inventario := Inventario.nuevo()
	var firma_inicial := Encontrables.firma("casa", 1, inventario)
	var capa := Encontrables.montar(mundo, "casa", 1, inventario)
	var palanca := capa.get_node_or_null("PropEncontrable_palanca_kkryy") as Recogible3D

	_comprobar(palanca != null, "la palanca aparece en casa desde el día 1")
	_comprobar(
		palanca != null and String(palanca.objeto_id) == "palanca_kkryy",
		"el pickup conserva el ID canónico"
	)
	_comprobar(
		(
			palanca != null
			and String(palanca.get_meta("ancla_prop_utilizable", "")) == "AlmacenamientoCasa"
		),
		"la ubicación queda anclada al almacenamiento doméstico"
	)
	_comprobar(
		palanca != null and bool(palanca.get_meta("encontrable_680", false)),
		"el nodo se identifica como encontrable de #680"
	)

	if palanca == null:
		mundo.queue_free()
		await process_frame
		print("%d pasadas, %d fallos" % [_pasadas, _fallos])
		quit(1)
		return

	var tipo_visual := String(palanca.get_meta("visual_prop_utilizable", ""))
	_comprobar(tipo_visual in ["proxy", "glb"], "el pickup siempre tiene representación visual")
	_comprobar(
		(
			palanca.get_node_or_null("ProxyPalanca") != null
			if tipo_visual == "proxy"
			else palanca.get_node_or_null("VisualStreetFurniture") != null
		),
		"el visual declarado existe"
	)
	_comprobar(
		(
			palanca.global_position.distance_to(
				ancla.to_global(Encontrables.DEFINICIONES[0]["offset"])
			)
			< 0.001
		),
		"el pickup se coloca respecto al ancla y no con coordenadas duplicadas"
	)
	_comprobar(not firma_inicial.ends_with("|"), "la firma incluye la palanca disponible")

	_comprobar(palanca.interactuar(root), "la palanca se recoge por Recogible3D")
	_comprobar(Inventario.contiene(inventario, "palanca_kkryy"), "el objeto entra en Inventario")
	await process_frame

	var firma_recogida := Encontrables.firma("casa", 1, inventario)
	_comprobar(firma_recogida != firma_inicial, "la firma cambia tras recoger el objeto")
	var capa_carried := Encontrables.montar(mundo, "casa", 1, inventario)
	_comprobar(
		capa_carried.get_node_or_null("PropEncontrable_palanca_kkryy") == null,
		"la palanca no respawnea mientras está en carried"
	)

	_comprobar(
		Inventario.guardar_en_casa(inventario, "palanca_kkryy"),
		"la palanca puede guardarse con el inventario doméstico"
	)
	var capa_casa := Encontrables.montar(mundo, "casa", 1, inventario)
	_comprobar(
		capa_casa.get_node_or_null("PropEncontrable_palanca_kkryy") == null,
		"la palanca tampoco respawnea desde home_storage"
	)
	_comprobar(
		Encontrables.montar(mundo, "archivo", 1, Inventario.nuevo()).get_child_count() == 0,
		"el pickup no aparece fuera de la casa"
	)

	mundo.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO palanca encontrable #680: " + mensaje)
