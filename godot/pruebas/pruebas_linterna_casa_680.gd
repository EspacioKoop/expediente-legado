## Recorrido real de la linterna #680 frente a la bombilla fundida de #93.
extends SceneTree

const Encontrables := preload("res://guion/props_utilizables_encontrables_3d.gd")
const LinternaCasa := preload("res://guion/linterna_casa_680.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var mundo := Node3D.new()
	mundo.name = "CasaLinternaFixture"
	root.add_child(mundo)

	var ancla := Node3D.new()
	ancla.name = "AlmacenamientoCasa"
	mundo.add_child(ancla)

	var caminante := Node3D.new()
	caminante.name = "CaminanteFixture"
	root.add_child(caminante)
	var camara := Camera3D.new()
	camara.name = "Camara"
	caminante.add_child(camara)

	var inventario := Inventario.nuevo()
	var capa := Encontrables.montar(mundo, "casa", 1, inventario)
	var linterna := capa.get_node_or_null("PropEncontrable_linterna_kkryy") as Recogible3D
	_comprobar(linterna != null, "la linterna aparece en casa desde el día 1")
	_comprobar(
		linterna != null and String(linterna.objeto_id) == "linterna_kkryy",
		"el pickup usa el ID canónico"
	)
	if linterna == null:
		await _terminar(mundo, caminante)
		return

	var tipo_visual := String(linterna.get_meta("visual_prop_utilizable", ""))
	_comprobar(tipo_visual in ["proxy", "glb"], "la linterna siempre tiene visual")
	_comprobar(
		(
			linterna.get_node_or_null("ProxyLinterna") != null
			if tipo_visual == "proxy"
			else linterna.get_node_or_null("VisualStreetFurniture") != null
		),
		"el visual declarado de linterna existe"
	)
	_comprobar(linterna.interactuar(caminante), "la linterna se recoge por Recogible3D")
	_comprobar(
		Inventario.contiene(inventario, "linterna_kkryy"),
		"la linterna entra en el inventario canónico"
	)
	await process_frame

	var normal := {"consecuencias_casa": []}
	_comprobar(
		LinternaCasa.refrescar(caminante, normal, inventario) == null,
		"sin bombilla fundida la linterna no crea luz automática"
	)

	var averia := {"consecuencias_casa": ["casa_luz_reducida"]}
	var luz := LinternaCasa.refrescar(caminante, averia, inventario)
	_comprobar(luz != null, "con avería y carried aparece el haz")
	_comprobar(
		luz != null and luz.get_parent() == camara,
		"el haz sigue la cámara de primera persona"
	)
	_comprobar(
		luz != null and String(luz.get_meta("prop_utilizable_id", "")) == "linterna_kkryy",
		"el haz conserva la identidad del prop"
	)
	_comprobar(
		luz != null and String(luz.get_meta("mitiga_consecuencia", "")) == "casa_luz_reducida",
		"el haz declara la consecuencia que mitiga"
	)
	_comprobar(
		luz != null and not luz.shadow_enabled,
		"la mitigación portátil evita sombras caras"
	)

	_comprobar(
		Inventario.guardar_en_casa(inventario, "linterna_kkryy"),
		"la linterna puede guardarse en casa"
	)
	_comprobar(
		LinternaCasa.refrescar(caminante, averia, inventario) == null,
		"guardada en home_storage no ilumina"
	)
	await process_frame

	_comprobar(
		Inventario.sacar_de_casa(inventario, "linterna_kkryy"),
		"la linterna vuelve a carried"
	)
	_comprobar(
		LinternaCasa.refrescar(caminante, averia, inventario) != null,
		"al volver a carried recupera el haz"
	)
	_comprobar(
		LinternaCasa.refrescar(caminante, normal, inventario) == null,
		"al desaparecer la avería desaparece el haz sin reparar nada"
	)
	_comprobar(
		averia["consecuencias_casa"].has("casa_luz_reducida"),
		"usar la linterna no muta ni repara el imprevisto"
	)

	await _terminar(mundo, caminante)


func _terminar(mundo: Node3D, caminante: Node3D) -> void:
	LinternaCasa.limpiar(caminante)
	mundo.queue_free()
	caminante.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO linterna casa #680: " + mensaje)
