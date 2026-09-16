## Regresión end-to-end del ciclo real de Gilgamesh (#436).
##
## No prueba un vertical aislado: entra por `dia.tscn`, activa la semilla desde
## el libro físico de la casa, deja que Jornada componga la noche y resuelve el
## puzzle mediante las zonas `Interactuable3D` que usa el jugador.
extends SceneTree

const DIA := preload("res://escenas/dia.tscn")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	if OS.get_environment("LEGADO_PRUEBAS_AISLADAS") != "1":
		printerr("Ejecuta esta prueba desde unittest con datos aislados.")
		quit(1)
		return
	_probar.call_deferred()


func _probar() -> void:
	var dia = DIA.instantiate()
	root.add_child(dia)
	await process_frame
	await process_frame

	# La cinemática de primera vuelta no forma parte del contrato bajo prueba y
	# podría mantener el caminante pausado. Cerrarla conserva el mismo Dia real.
	if dia._entrada != null:
		dia._cerrar_vuelta()
		await process_frame

	dia._entrar_en("casa")
	await process_frame
	var libro := dia._mundo.get_node_or_null("GilgameshVigiliaCasa") as GilgameshVigilia
	_comprobar(libro != null, "el libro de Gilgamesh está alcanzable en la casa real")
	if libro == null:
		await _finalizar(dia, null)
		return

	var actor := Node.new()
	actor.name = "ActorGilgameshE2E"
	root.add_child(actor)
	_comprobar(not libro.esta_activada(), "la mera presencia del libro no activa la semilla")
	for indice in 4:
		_comprobar(libro.interactuar(actor), "interacción de vigilia %d aceptada" % (indice + 1))
	_comprobar(libro.esta_activada(), "cuatro interacciones deliberadas activan la semilla")
	_comprobar(
		SemillasOniricas.familias_activas(dia.jornada).has(SuenoGilgamesh.ID_MITO),
		"la jornada real contiene la familia Gilgamesh",
	)

	# Reproduce la misma regla que usa casa -> sueño sin necesitar la cinemática:
	# Jornada decide la noche, Dia aplica su política y monta la primera sala.
	var noche := Jornada.dormir(dia.jornada)
	_comprobar(not noche.is_empty(), "dormir desde casa compone la noche")
	dia._aplicar_politica_sueno()
	_comprobar(dia.jornada.get("fase", "") == "sueño", "la jornada entra en sueño")
	var seleccion := (
		SemillasOniricas
		. seleccionar_para_noche(
			dia.jornada,
			dia._raiz(),
			MitologiasNoche.MAX_FAMILIAS_NOCHE,
		)
	)
	_comprobar(
		seleccion.get("familias", []).has(SuenoGilgamesh.ID_MITO),
		"el selector común conserva Gilgamesh para esta noche",
	)

	dia._entrar_en("sueño")
	# Primer frame: el controller nocturno detecta el mundo nuevo y monta el
	# vertical. Segundo frame: Interaccion3D crea fragmentos/anclas físicos.
	await process_frame
	await process_frame
	await process_frame

	var sueno := dia._mundo.get_node_or_null("SuenoGilgameshNoche") as SuenoGilgamesh
	_comprobar(sueno != null, "Dia monta el vertical Gilgamesh en la noche real")
	if sueno == null:
		await _finalizar(dia, actor)
		return
	_comprobar(
		sueno.get_node_or_null("CamaraStandalone") == null,
		"el vertical integrado no secuestra la cámara del recorrido",
	)
	var interaccion := sueno.get_node_or_null("Interaccion3D")
	var puzzle := sueno.get_node_or_null("CiudadImposible/PuzzleTablilla") as Node3D
	_comprobar(interaccion != null, "el controller físico del puzzle está presente")
	_comprobar(puzzle != null, "el puzzle 3D está montado en el vertical nocturno")
	if interaccion == null or puzzle == null:
		await _finalizar(dia, actor)
		return

	# Un fallo real de colocación debe ser reversible y mantener la pieza en la
	# mano lógica; después se resuelve todo por las mismas zonas que ve el raycast.
	var fragmento_puerta := (
		puzzle.get_node_or_null("Interactuar_fragmento_puerta") as Interactuable3D
	)
	var ancla_ola := puzzle.get_node_or_null("Interactuar_ancla_ola") as Interactuable3D
	var ancla_puerta := puzzle.get_node_or_null("Interactuar_ancla_puerta") as Interactuable3D
	_comprobar(
		fragmento_puerta != null and ancla_ola != null and ancla_puerta != null,
		"fragmento y anclas iniciales tienen zonas físicas",
	)
	if fragmento_puerta == null or ancla_ola == null or ancla_puerta == null:
		await _finalizar(dia, actor)
		return

	fragmento_puerta.interactuar(actor)
	_comprobar(
		String(interaccion.call("fragmento_seleccionado")) == "fragmento_puerta",
		"coger una pieza la selecciona",
	)
	ancla_ola.interactuar(actor)
	_comprobar(
		String(interaccion.call("fragmento_seleccionado")) == "fragmento_puerta",
		"un anclaje incorrecto conserva la pieza seleccionada",
	)
	_comprobar(not sueno.resuelto(), "el fallo no consume la solución")
	ancla_puerta.interactuar(actor)
	_comprobar(
		String(interaccion.call("fragmento_seleccionado")).is_empty(),
		"un acierto suelta la pieza resuelta",
	)

	for pareja in [
		["fragmento_archivo", "ancla_archivo"],
		["fragmento_ola", "ancla_ola"],
		["fragmento_sello", "ancla_sello"],
	]:
		var fragmento := puzzle.get_node_or_null("Interactuar_%s" % pareja[0]) as Interactuable3D
		var ancla := puzzle.get_node_or_null("Interactuar_%s" % pareja[1]) as Interactuable3D
		_comprobar(fragmento != null and ancla != null, "%s tiene interacción física" % pareja[0])
		if fragmento == null or ancla == null:
			continue
		fragmento.interactuar(actor)
		ancla.interactuar(actor)

	_comprobar(sueno.resuelto(), "las cuatro colocaciones físicas resuelven el puzzle")
	var techo := sueno.get_node_or_null("CiudadImposible/MurallaArchivoTecho") as Node3D
	var puerta := sueno.get_node_or_null("CiudadImposible/PuertaBloqueada") as MeshInstance3D
	var ruta := sueno.get_node_or_null("CiudadImposible/RutaFinal") as MeshInstance3D
	_comprobar(techo != null and techo.visible, "resolver revela la continuidad imposible por techo")
	_comprobar(puerta != null and not puerta.visible, "resolver retira el bloqueo")
	_comprobar(ruta != null and ruta.visible, "resolver hace visible la ruta final")

	await _finalizar(dia, actor)


func _finalizar(dia: Node, actor: Node) -> void:
	if is_instance_valid(actor):
		actor.queue_free()
	if is_instance_valid(dia):
		dia.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO Gilgamesh recorrido: " + nombre)
